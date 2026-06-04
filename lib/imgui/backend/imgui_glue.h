/*
 * imgui_glue.h — plain-C API for the hica Dear ImGui backend
 *
 * This header is included by kk_imgui.c (compiled by Koka) and by
 * imgui_glue.cpp (the C++ implementation).  The C++ side wraps Dear ImGui's
 * SDL2 + OpenGL3 backends and exports every symbol with extern "C" so the
 * C side can link against them.
 *
 * Design principle: hica never sees ImGui or SDL2 types.  Everything crossing
 * the boundary is a plain-C int/float/char*.
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* ---------------------------------------------------------------------------
 * Lifecycle — call in this order:
 *   hk_gui_init(...)
 *   while (hk_gui_begin_frame()) { ... widgets ... hk_gui_end_frame(); }
 *   hk_gui_shutdown()
 * -------------------------------------------------------------------------*/

/* Open the window and initialise SDL2 / OpenGL3 / Dear ImGui.
 * Must be called once before any other function.
 * title : window title (UTF-8)
 * w, h  : initial window size in pixels */
void hk_gui_init(const char* title, int w, int h);

/* Poll events and start a new Dear ImGui frame.
 * Returns 1 if the frame should be rendered; 0 when the window has been
 * closed (the caller should exit the loop and call hk_gui_shutdown). */
int hk_gui_begin_frame(void);

/* Finish the frame: end the root window, render ImGui draw data, swap buffers. */
void hk_gui_end_frame(void);

/* Tear down ImGui, SDL2 and OpenGL3.  Call once after the loop exits. */
void hk_gui_shutdown(void);

/* ---------------------------------------------------------------------------
 * Widgets — call only between hk_gui_begin_frame() and hk_gui_end_frame()
 * -------------------------------------------------------------------------*/

/* Display a text label. */
void hk_gui_text(const char* s);

/* Display a button.  Returns 1 on the frame it was clicked, 0 otherwise. */
int hk_gui_button(const char* label);

/* Display a checkbox.  Manages its own state keyed by label.
 * def    : initial value (0 = unchecked, 1 = checked)
 * Returns the current checked state (0 or 1). */
int hk_gui_checkbox(const char* label, int def);

/* Display an integer slider in [min, max].  Manages its own state.
 * def    : initial value
 * Returns the current value. */
int hk_gui_slider_int(const char* label, int min, int max, int def);

/* Display a float slider in [min, max].  Manages its own state.
 * def    : initial value (as a double for easier FFI; truncated to float internally)
 * Returns the current value as a double. */
double hk_gui_slider_float(const char* label, double min, double max, double def);

/* Display a single-line text input.  Manages its own buffer (capacity bytes).
 * Returns a pointer to the current buffer contents (valid until next call
 * with the same label). */
const char* hk_gui_input_text(const char* label, int capacity);

/* Horizontal separator rule. */
void hk_gui_separator(void);

/* Place the next widget on the same line as the previous one. */
void hk_gui_same_line(void);

/* Extra vertical spacing. */
void hk_gui_spacing(void);

/* Collapsible section header.
 * Returns 1 if the section is expanded (caller should render children and
 * call hk_gui_end_panel); returns 0 if collapsed (skip children). */
int hk_gui_begin_panel(const char* label);

/* Close a collapsible section opened by hk_gui_begin_panel.
 * Must be called only when hk_gui_begin_panel returned 1. */
void hk_gui_end_panel(void);

#ifdef __cplusplus
}
#endif
