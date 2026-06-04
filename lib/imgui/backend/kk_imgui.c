/*
 * kk_imgui.c — Koka FFI trampoline for lib/imgui
 *
 * This file is compiled by Koka via:
 *   extern import
 *     c file "backend/kk_imgui.c"
 * in imgui.kk.
 *
 * It converts between Koka's runtime types (kk_string_t, kk_integer_t, …)
 * and the plain-C types expected by imgui_glue.h.
 *
 * No C++ is used here.  The actual Dear ImGui logic lives in imgui_glue.cpp,
 * which is pre-compiled into libimgui_hica.a by build.sh.
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 */

#include "imgui_glue.h"

/* ---------------------------------------------------------------------------
 * Lifecycle
 * -------------------------------------------------------------------------*/

static kk_unit_t kk_hk_gui_init(kk_string_t title, kk_integer_t w, kk_integer_t h,
                                  kk_context_t* ctx) {
    const char* t = kk_string_cbuf_borrow(title, NULL, ctx);
    hk_gui_init(t, kk_integer_clamp32(w, ctx), kk_integer_clamp32(h, ctx));
    kk_string_drop(title, ctx);
    return kk_Unit;
}

static kk_bool_t kk_hk_gui_begin_frame(kk_context_t* ctx) {
    return hk_gui_begin_frame() != 0;
}

static kk_unit_t kk_hk_gui_end_frame(kk_context_t* ctx) {
    hk_gui_end_frame();
    return kk_Unit;
}

static kk_unit_t kk_hk_gui_shutdown(kk_context_t* ctx) {
    hk_gui_shutdown();
    return kk_Unit;
}

/* ---------------------------------------------------------------------------
 * Widgets
 * -------------------------------------------------------------------------*/

static kk_unit_t kk_hk_gui_text(kk_string_t s, kk_context_t* ctx) {
    const char* cs = kk_string_cbuf_borrow(s, NULL, ctx);
    hk_gui_text(cs);
    kk_string_drop(s, ctx);
    return kk_Unit;
}

static kk_bool_t kk_hk_gui_button(kk_string_t label, kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    int r = hk_gui_button(lbl);
    kk_string_drop(label, ctx);
    return r != 0;
}

static kk_bool_t kk_hk_gui_checkbox(kk_string_t label, kk_bool_t def,
                                      kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    int r = hk_gui_checkbox(lbl, def ? 1 : 0);
    kk_string_drop(label, ctx);
    return r != 0;
}

static kk_integer_t kk_hk_gui_slider_int(kk_string_t label,
                                           kk_integer_t min, kk_integer_t max,
                                           kk_integer_t def,
                                           kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    int r = hk_gui_slider_int(lbl,
                               kk_integer_clamp32(min, ctx),
                               kk_integer_clamp32(max, ctx),
                               kk_integer_clamp32(def, ctx));
    kk_string_drop(label, ctx);
    return kk_integer_from_int(r, ctx);
}

static kk_double_t kk_hk_gui_slider_float(kk_string_t label,
                                            kk_double_t min, kk_double_t max,
                                            kk_double_t def,
                                            kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    double r = hk_gui_slider_float(lbl, min, max, def);
    kk_string_drop(label, ctx);
    return r;
}

static kk_string_t kk_hk_gui_input_text(kk_string_t label, kk_integer_t capacity,
                                          kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    const char* result = hk_gui_input_text(lbl, kk_integer_clamp32(capacity, ctx));
    kk_string_drop(label, ctx);
    if (!result) return kk_string_empty();
    return kk_string_alloc_dup(result, ctx);
}

static kk_unit_t kk_hk_gui_separator(kk_context_t* ctx) {
    hk_gui_separator();
    return kk_Unit;
}

static kk_unit_t kk_hk_gui_same_line(kk_context_t* ctx) {
    hk_gui_same_line();
    return kk_Unit;
}

static kk_unit_t kk_hk_gui_spacing(kk_context_t* ctx) {
    hk_gui_spacing();
    return kk_Unit;
}

static kk_bool_t kk_hk_gui_begin_panel(kk_string_t label, kk_context_t* ctx) {
    const char* lbl = kk_string_cbuf_borrow(label, NULL, ctx);
    int r = hk_gui_begin_panel(lbl);
    kk_string_drop(label, ctx);
    return r != 0;
}

static kk_unit_t kk_hk_gui_end_panel(kk_context_t* ctx) {
    hk_gui_end_panel();
    return kk_Unit;
}
