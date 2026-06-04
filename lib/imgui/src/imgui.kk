// imgui.kk — Koka FFI module for the hica Dear ImGui binding
//
// Provides a GUI API backed by Dear ImGui + SDL2 + OpenGL3.
// Function names use underscores to match hica's code generation:
//   hica: gui_text("hello")  →  Koka: gui_text("hello")  →  imgui/gui_text
//
// Usage from hica:
//   extern import "../../lib/imgui/src/imgui"
//
// examples/hello-gui/hica.hml:
//   @koka { flags: "-L../../lib/imgui/lib --cclib=imgui_hica --cclib=SDL2 -framework OpenGL" }
//
// Linux:
//   flags: "-L../../lib/imgui/lib --cclib=imgui_hica --cclib=SDL2 --cclib=GL"
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

module imgui

import std/num/float64

// ---------------------------------------------------------------------------
// C backend — compiled by Koka alongside this module
// ---------------------------------------------------------------------------

extern import
  c file "../backend/kk_imgui.c"

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

pub extern gui_init( title : string, w : int, h : int ) : io ()
  c "kk_hk_gui_init"

pub extern gui_begin_frame() : io bool
  c "kk_hk_gui_begin_frame"

pub extern gui_end_frame() : io ()
  c "kk_hk_gui_end_frame"

pub extern gui_shutdown() : io ()
  c "kk_hk_gui_shutdown"

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

pub extern gui_text( s : string ) : io ()
  c "kk_hk_gui_text"

pub extern gui_button( label : string ) : io bool
  c "kk_hk_gui_button"

pub extern gui_checkbox( label : string, checked : bool ) : io bool
  c "kk_hk_gui_checkbox"

pub extern gui_slider_int( label : string, min_val : int, max_val : int, def_val : int ) : io int
  c "kk_hk_gui_slider_int"

pub extern gui_slider_float( label : string, min_val : float64, max_val : float64, def_val : float64 ) : io float64
  c "kk_hk_gui_slider_float"

pub extern gui_input_text( label : string, capacity : int ) : io string
  c "kk_hk_gui_input_text"

pub extern gui_separator() : io ()
  c "kk_hk_gui_separator"

pub extern gui_same_line() : io ()
  c "kk_hk_gui_same_line"

pub extern gui_spacing() : io ()
  c "kk_hk_gui_spacing"

pub extern gui_begin_panel( label : string ) : io bool
  c "kk_hk_gui_begin_panel"

pub extern gui_end_panel() : io ()
  c "kk_hk_gui_end_panel"

// ---------------------------------------------------------------------------
// High-level: run the event loop
//
// Opens a window and runs the frame callback each vsync tick (~60 fps).
// Closes when the user dismisses the window.
//
//   gui_window("My App", 800, 600) fn()
//     gui_text("Hello!")
// ---------------------------------------------------------------------------

// Effect-polymorphic so closures that mutate captured vars work correctly.
pub fun gui_window( title : string, w : int, h : int, frame )
  gui_init(title, w, h)
  while { gui_begin_frame() }
    frame()
    gui_end_frame()
  gui_shutdown()
