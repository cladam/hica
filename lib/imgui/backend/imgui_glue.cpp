/*
 * imgui_glue.cpp — Dear ImGui + SDL2 + OpenGL3 backend for hica
 *
 * Implements the plain-C API declared in imgui_glue.h.
 * Linked as a pre-built static library (libimgui_hica.a) by build.sh.
 *
 * Vendor layout expected:
 *   lib/imgui/vendor/imgui/               ← Dear ImGui source
 *   lib/imgui/vendor/imgui/backends/      ← SDL2 + OpenGL3 backend sources
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 */

#include "imgui_glue.h"
#include "inter_font.h"   /* Inter-Regular — embedded via xxd -i */

#include <SDL.h>
#include <SDL_opengl.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

/* Dear ImGui — C++ API used internally, C API exposed via imgui_glue.h */
#include "../vendor/imgui/imgui.h"
#include "../vendor/imgui/backends/imgui_impl_sdl2.h"
#include "../vendor/imgui/backends/imgui_impl_opengl3.h"

/* ---------------------------------------------------------------------------
 * Internal state
 * -------------------------------------------------------------------------*/

static SDL_Window*    g_window  = nullptr;
static SDL_GLContext  g_gl_ctx  = nullptr;
static bool           g_quit    = false;

/* ---------------------------------------------------------------------------
 * Per-widget state tables
 *
 * Widgets with persistent state (sliders, checkboxes, text inputs) are keyed
 * by a FNV-1a hash of their label string.  Up to HK_MAX_SLOTS distinct widgets
 * of each kind are supported per window.
 * -------------------------------------------------------------------------*/

#define HK_MAX_SLOTS 256
#define HK_TEXT_BUF  512

static uint32_t fnv1a(const char* s) {
    uint32_t h = 2166136261u;
    while (*s) { h ^= (uint8_t)*s++; h *= 16777619u; }
    return h;
}

/* --- int state (sliders) --- */
struct hk_int_slot { uint32_t hash; int value; bool init; };
static hk_int_slot g_int_slots[HK_MAX_SLOTS];
static int         g_int_n = 0;

static int* int_state(const char* label, int def) {
    uint32_t h = fnv1a(label);
    for (int i = 0; i < g_int_n; i++)
        if (g_int_slots[i].hash == h) return &g_int_slots[i].value;
    if (g_int_n < HK_MAX_SLOTS) {
        g_int_slots[g_int_n] = { h, def, true };
        return &g_int_slots[g_int_n++].value;
    }
    fprintf(stderr, "hica imgui: int state table full (max %d slots)\n", HK_MAX_SLOTS);
    return nullptr;
}

/* --- float state (sliders) --- */
struct hk_float_slot { uint32_t hash; float value; };
static hk_float_slot g_float_slots[HK_MAX_SLOTS];
static int           g_float_n = 0;

static float* float_state(const char* label, float def) {
    uint32_t h = fnv1a(label);
    for (int i = 0; i < g_float_n; i++)
        if (g_float_slots[i].hash == h) return &g_float_slots[i].value;
    if (g_float_n < HK_MAX_SLOTS) {
        g_float_slots[g_float_n] = { h, def };
        return &g_float_slots[g_float_n++].value;
    }
    fprintf(stderr, "hica imgui: float state table full (max %d slots)\n", HK_MAX_SLOTS);
    return nullptr;
}

/* --- bool state (checkboxes) --- */
struct hk_bool_slot { uint32_t hash; bool value; };
static hk_bool_slot g_bool_slots[HK_MAX_SLOTS];
static int          g_bool_n = 0;

static bool* bool_state(const char* label, bool def) {
    uint32_t h = fnv1a(label);
    for (int i = 0; i < g_bool_n; i++)
        if (g_bool_slots[i].hash == h) return &g_bool_slots[i].value;
    if (g_bool_n < HK_MAX_SLOTS) {
        g_bool_slots[g_bool_n] = { h, def };
        return &g_bool_slots[g_bool_n++].value;
    }
    fprintf(stderr, "hica imgui: bool state table full (max %d slots)\n", HK_MAX_SLOTS);
    return nullptr;
}

/* --- text state (input fields) --- */
struct hk_text_slot { uint32_t hash; char buf[HK_TEXT_BUF]; };
static hk_text_slot g_text_slots[HK_MAX_SLOTS];
static int          g_text_n = 0;

static char* text_state(const char* label, int capacity) {
    (void)capacity; /* clamped to HK_TEXT_BUF internally */
    uint32_t h = fnv1a(label);
    for (int i = 0; i < g_text_n; i++)
        if (g_text_slots[i].hash == h) return g_text_slots[i].buf;
    if (g_text_n < HK_MAX_SLOTS) {
        g_text_slots[g_text_n].hash = h;
        g_text_slots[g_text_n].buf[0] = '\0';
        return g_text_slots[g_text_n++].buf;
    }
    fprintf(stderr, "hica imgui: text state table full (max %d slots)\n", HK_MAX_SLOTS);
    return nullptr;
}

/* ---------------------------------------------------------------------------
 * Ilseon theme — OLED-focused dark palette, Inter font
 *
 * Palette values taken from stdlib/std/term.hc ilseon_* functions.
 * -------------------------------------------------------------------------*/

static void hk_apply_ilseon_theme() {
    ImGuiStyle& s = ImGui::GetStyle();
    ImVec4* c = s.Colors;

    // --- Palette ---
    const ImVec4 teal       = ImVec4(0.000f, 0.749f, 0.647f, 1.00f); // #00BFA5 TealAccent
    const ImVec4 teal_hover = ImVec4(0.200f, 0.820f, 0.730f, 1.00f); // brightened
    const ImVec4 teal_med   = ImVec4(0.000f, 0.749f, 0.647f, 0.60f);
    const ImVec4 teal_dim   = ImVec4(0.000f, 0.749f, 0.647f, 0.28f);
    const ImVec4 text_main  = ImVec4(0.910f, 0.910f, 0.925f, 1.00f); // #E8E8EC
    const ImVec4 text_muted = ImVec4(0.533f, 0.533f, 0.533f, 1.00f); // #888888 MutedDetail
    const ImVec4 border     = ImVec4(0.369f, 0.427f, 0.494f, 0.38f); // #5E6D7E SlateBlue
    const ImVec4 bg_deep    = ImVec4(0.047f, 0.047f, 0.063f, 1.00f); // #0C0C10 OLED black
    const ImVec4 bg_base    = ImVec4(0.071f, 0.071f, 0.090f, 1.00f); // #121217
    const ImVec4 bg_frame   = ImVec4(0.110f, 0.110f, 0.141f, 1.00f); // #1C1C24
    const ImVec4 bg_hover   = ImVec4(0.150f, 0.150f, 0.188f, 1.00f);
    const ImVec4 bg_popup   = ImVec4(0.102f, 0.102f, 0.125f, 0.97f); // #1A1A20
    const ImVec4 none       = ImVec4(0.000f, 0.000f, 0.000f, 0.00f);

    c[ImGuiCol_Text]                  = text_main;
    c[ImGuiCol_TextDisabled]          = text_muted;
    c[ImGuiCol_WindowBg]              = bg_base;
    c[ImGuiCol_ChildBg]               = bg_deep;
    c[ImGuiCol_PopupBg]               = bg_popup;
    c[ImGuiCol_Border]                = border;
    c[ImGuiCol_BorderShadow]          = none;
    c[ImGuiCol_FrameBg]               = bg_frame;
    c[ImGuiCol_FrameBgHovered]        = bg_hover;
    c[ImGuiCol_FrameBgActive]         = teal_dim;
    c[ImGuiCol_TitleBg]               = bg_deep;
    c[ImGuiCol_TitleBgActive]         = ImVec4(0.000f, 0.380f, 0.330f, 1.0f);
    c[ImGuiCol_TitleBgCollapsed]      = bg_deep;
    c[ImGuiCol_MenuBarBg]             = bg_deep;
    c[ImGuiCol_ScrollbarBg]           = bg_deep;
    c[ImGuiCol_ScrollbarGrab]         = ImVec4(0.369f, 0.427f, 0.494f, 0.55f);
    c[ImGuiCol_ScrollbarGrabHovered]  = ImVec4(0.490f, 0.522f, 0.592f, 0.80f);
    c[ImGuiCol_ScrollbarGrabActive]   = teal;
    c[ImGuiCol_CheckMark]             = teal;
    c[ImGuiCol_SliderGrab]            = teal_med;
    c[ImGuiCol_SliderGrabActive]      = teal_hover;
    c[ImGuiCol_Button]                = bg_frame;
    c[ImGuiCol_ButtonHovered]         = teal_med;
    c[ImGuiCol_ButtonActive]          = teal;
    c[ImGuiCol_Header]                = teal_dim;
    c[ImGuiCol_HeaderHovered]         = teal_med;
    c[ImGuiCol_HeaderActive]          = teal;
    c[ImGuiCol_Separator]             = border;
    c[ImGuiCol_SeparatorHovered]      = teal_med;
    c[ImGuiCol_SeparatorActive]       = teal;
    c[ImGuiCol_ResizeGrip]            = teal_dim;
    c[ImGuiCol_ResizeGripHovered]     = teal_med;
    c[ImGuiCol_ResizeGripActive]      = teal;
    c[ImGuiCol_Tab]                   = bg_frame;
    c[ImGuiCol_TabHovered]            = teal_med;
    c[ImGuiCol_TabSelected]           = teal_dim;
    c[ImGuiCol_TabSelectedOverline]   = teal;
    c[ImGuiCol_TabDimmed]             = bg_deep;
    c[ImGuiCol_TabDimmedSelected]     = bg_frame;
    c[ImGuiCol_PlotLines]             = ImVec4(0.353f, 0.608f, 0.502f, 1.0f); // MutedTeal
    c[ImGuiCol_PlotLinesHovered]      = teal_hover;
    c[ImGuiCol_PlotHistogram]         = ImVec4(0.753f, 0.541f, 0.243f, 1.0f); // QuietAmber
    c[ImGuiCol_PlotHistogramHovered]  = ImVec4(0.886f, 0.690f, 0.369f, 1.0f); // Ochre
    c[ImGuiCol_TableHeaderBg]         = bg_deep;
    c[ImGuiCol_TableBorderStrong]     = border;
    c[ImGuiCol_TableBorderLight]      = ImVec4(0.20f, 0.20f, 0.25f, 0.5f);
    c[ImGuiCol_TableRowBg]            = none;
    c[ImGuiCol_TableRowBgAlt]         = ImVec4(1.0f, 1.0f, 1.0f, 0.03f);
    c[ImGuiCol_TextSelectedBg]        = teal_dim;
    c[ImGuiCol_DragDropTarget]        = teal;
    c[ImGuiCol_NavHighlight]          = teal;
    c[ImGuiCol_NavWindowingHighlight] = ImVec4(1.0f, 1.0f, 1.0f, 0.70f);
    c[ImGuiCol_NavWindowingDimBg]     = ImVec4(0.0f, 0.0f, 0.0f, 0.20f);
    c[ImGuiCol_ModalWindowDimBg]      = ImVec4(0.0f, 0.0f, 0.0f, 0.35f);

    // --- Rounding & spacing ---
    s.WindowRounding    = 6.0f;
    s.FrameRounding     = 4.0f;
    s.ScrollbarRounding = 6.0f;
    s.GrabRounding      = 4.0f;
    s.TabRounding       = 4.0f;
    s.WindowPadding     = ImVec2(12.0f, 10.0f);
    s.FramePadding      = ImVec2(8.0f, 4.0f);
    s.ItemSpacing       = ImVec2(8.0f, 6.0f);
    s.WindowBorderSize  = 1.0f;
    s.FrameBorderSize   = 0.0f;
}

/* ---------------------------------------------------------------------------
 * Lifecycle
 * -------------------------------------------------------------------------*/

void hk_gui_init(const char* title, int w, int h) {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        fprintf(stderr, "SDL_Init error: %s\n", SDL_GetError());
        return;
    }

    /* Request OpenGL 3.2 Core Profile (required for GLSL #version 150 on macOS) */
#ifdef __APPLE__
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
#endif
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

    g_window = SDL_CreateWindow(
        title,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        w, h,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI
    );
    if (!g_window) {
        fprintf(stderr, "SDL_CreateWindow error: %s\n", SDL_GetError());
        SDL_Quit();
        return;
    }

    g_gl_ctx = SDL_GL_CreateContext(g_window);
    if (!g_gl_ctx) {
        fprintf(stderr, "SDL_GL_CreateContext error: %s\n", SDL_GetError());
        SDL_DestroyWindow(g_window);
        SDL_Quit();
        return;
    }

    SDL_GL_MakeCurrent(g_window, g_gl_ctx);
    SDL_GL_SetSwapInterval(1); /* vsync */

    /* Dear ImGui setup */
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    /* --- Inter font, HiDPI-aware --- */
    int ww, wh, dw, dh;
    SDL_GetWindowSize(g_window, &ww, &wh);
    SDL_GL_GetDrawableSize(g_window, &dw, &dh);
    float dpi_scale = (ww > 0) ? (float)dw / (float)ww : 1.0f;
    ImFontConfig font_cfg;
    font_cfg.FontDataOwnedByAtlas = false;  /* static array — do not free */
    io.Fonts->AddFontFromMemoryTTF(
        (void*)Inter_Regular_ttf, (int)Inter_Regular_ttf_len,
        16.0f * dpi_scale, &font_cfg);
    io.FontGlobalScale = 1.0f / dpi_scale;  /* render at logical pixels */

    /* --- Ilseon colour theme --- */
    hk_apply_ilseon_theme();

    /* Backends: GLSL version must match the context we requested above */
    ImGui_ImplSDL2_InitForOpenGL(g_window, g_gl_ctx);
    ImGui_ImplOpenGL3_Init("#version 150");

    g_quit = false;
}

int hk_gui_begin_frame(void) {
    if (g_quit || !g_window) return 0;

    /* Poll SDL events — ImGui needs them for mouse/keyboard */
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        ImGui_ImplSDL2_ProcessEvent(&e);
        if (e.type == SDL_QUIT) return 0;
        if (e.type == SDL_WINDOWEVENT
                && e.window.event == SDL_WINDOWEVENT_CLOSE
                && e.window.windowID == SDL_GetWindowID(g_window))
            return 0;
    }

    /* Start a new ImGui frame */
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();

    /* Full-screen root panel that fills the OS window.
     * The hica user draws widgets directly into this panel. */
    int w, h;
    SDL_GetWindowSize(g_window, &w, &h);
    ImGui::SetNextWindowPos(ImVec2(0, 0), ImGuiCond_Always);
    ImGui::SetNextWindowSize(ImVec2((float)w, (float)h), ImGuiCond_Always);
    ImGui::Begin("##hica_root", nullptr,
        ImGuiWindowFlags_NoTitleBar  |
        ImGuiWindowFlags_NoResize    |
        ImGuiWindowFlags_NoMove      |
        ImGuiWindowFlags_NoBringToFrontOnFocus |
        ImGuiWindowFlags_NoSavedSettings);

    return 1;
}

void hk_gui_end_frame(void) {
    ImGui::End(); /* close the root panel */
    ImGui::Render();

    ImGuiIO& io = ImGui::GetIO();
    SDL_GL_MakeCurrent(g_window, g_gl_ctx);
    glViewport(0, 0, (int)io.DisplaySize.x, (int)io.DisplaySize.y);
    glClearColor(0.047f, 0.047f, 0.063f, 1.00f); /* Ilseon OLED black #0C0C10 */
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(g_window);
}

void hk_gui_shutdown(void) {
    if (!g_window) return;
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_GL_DeleteContext(g_gl_ctx);
    SDL_DestroyWindow(g_window);
    SDL_Quit();
    g_window = nullptr;
    g_gl_ctx = nullptr;
}

/* ---------------------------------------------------------------------------
 * Widgets
 * -------------------------------------------------------------------------*/

void hk_gui_text(const char* s) {
    ImGui::TextUnformatted(s);
}

int hk_gui_button(const char* label) {
    return ImGui::Button(label) ? 1 : 0;
}

int hk_gui_checkbox(const char* label, int def) {
    bool* v = bool_state(label, def != 0);
    if (!v) return def;
    ImGui::Checkbox(label, v);
    return *v ? 1 : 0;
}

int hk_gui_slider_int(const char* label, int min, int max, int def) {
    int* v = int_state(label, def);
    if (!v) return def;
    ImGui::SliderInt(label, v, min, max);
    return *v;
}

double hk_gui_slider_float(const char* label, double min, double max, double def) {
    float* v = float_state(label, (float)def);
    if (!v) return def;
    ImGui::SliderFloat(label, v, (float)min, (float)max);
    return (double)*v;
}

const char* hk_gui_input_text(const char* label, int capacity) {
    char* buf = text_state(label, capacity);
    if (!buf) return "";
    int cap = capacity < HK_TEXT_BUF ? capacity : HK_TEXT_BUF - 1;
    ImGui::InputText(label, buf, (size_t)cap);
    return buf;
}

void hk_gui_separator(void) { ImGui::Separator(); }
void hk_gui_same_line(void) { ImGui::SameLine(); }
void hk_gui_spacing(void)   { ImGui::Spacing(); }

int hk_gui_begin_panel(const char* label) {
    return ImGui::CollapsingHeader(label) ? 1 : 0;
}

void hk_gui_end_panel(void) {
    /* CollapsingHeader is a single widget — no explicit End call needed.
     * This function exists so the hica API is symmetric (begin/end pairs)
     * and the Koka layer can enforce correct usage at compile time.
     * It intentionally does nothing. */
}
