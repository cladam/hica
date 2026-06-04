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

    ImGui::StyleColorsDark();

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
    glClearColor(0.10f, 0.10f, 0.12f, 1.00f);
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
