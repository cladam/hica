# cimgui Integration for Hica — Design Exploration

> Goal: let hica users spin up a native GUI window as easily and naturally as they spin up a CLI.
> The user should not have to think about event loops, frame calls, or C backends.

---

## What is cimgui?

**Dear ImGui** is an immediate-mode GUI library for C++.  
**cimgui** is a plain-C wrapper generated from the ImGui headers (`igText()`, `igButton()`, `igSliderInt()`, etc.), making it callable from any language with a C FFI — including Koka.

Immediate-mode means: you _don't_ build a widget tree or register callbacks. Every frame you call functions that both declare and update widgets. The library tracks state internally (slider value, checkbox state). This is the same mental model as a game loop, and it maps well to hica's functional style.

---

## Target User Experience

The ideal hica GUI program should look like a CLI program with a window:

```hica
extern import "lib/imgui/src/imgui"

fun main() {
  gui_window("Counter", 400, 300, fun() {
    gui_text("Hello from hica!")
    if gui_button("Increment") {
      println("clicked!")
    }
    gui_separator()
    gui_text("Use sliders, inputs, tables — all immediate mode.")
  })
}
```

Run it with `hica run my-gui.hc`. The window opens, the loop runs, close the window to exit.
No init calls, no render calls, no event polling — all hidden in `gui_window`.

---

## Architecture: Three Layers

```
┌───────────────────────────────────────────────┐
│  hica user code  (my-gui.hc)                  │  call gui_* functions
├───────────────────────────────────────────────┤
│  Koka FFI module  (lib/imgui/src/imgui.kk)    │  extern declarations + loop abstraction
├───────────────────────────────────────────────┤
│  C backend glue   (lib/imgui/backend/)        │  SDL2 + OpenGL3 + cimgui init/render/loop
├───────────────────────────────────────────────┤
│  System libraries: cimgui, SDL2, OpenGL       │  linked via hica.ini flags
└───────────────────────────────────────────────┘
```

### Layer 1: C backend glue (`lib/imgui/backend/imgui_impl.c`)

This is the only C++ complexity. It:
- Initialises SDL2 + OpenGL3 context
- Initialises Dear ImGui + ImGui_ImplSDL2 + ImGui_ImplOpenGL3
- Runs the event loop, calling a user-supplied C function pointer each frame
- Tears down everything on window close

```c
// Public API — called from Koka externs
void hk_gui_run(const char* title, int w, int h, void (*frame_cb)(void));
void hk_gui_text(const char* s);
int  hk_gui_button(const char* label);         // returns 1 if clicked this frame
int  hk_gui_checkbox(const char* label, int* v);
int  hk_gui_slider_int(const char* label, int* v, int min, int max);
void hk_gui_separator(void);
void hk_gui_same_line(void);
int  hk_gui_begin_panel(const char* label);    // collapsible section
void hk_gui_end_panel(void);
void hk_gui_input_text(const char* label, char* buf, int buf_size);
```

State (slider values, checkbox state) lives in C `static` variables or a small heap struct owned by the callback. The Koka side sees only the result of each frame.

### Layer 2: Koka FFI (`lib/imgui/src/imgui.kk`)

```koka
module imgui

extern import
  c file "../backend/imgui_impl.c"

// Internal: run the main loop with a Koka callback as the frame function.
// The callback must be a C function pointer — we use Koka's `c inline` trick.
extern hk-gui-run( title: string, w: int, h: int, cb: () -> io () ) : io ()
  c "kk_hk_gui_run"   // thin wrapper that converts the Koka closure to a C fn ptr

pub extern gui-text( s: string ) : io ()
  c inline "hk_gui_text(kk_string_cbuf_borrow(#1,NULL,kk_context()))"

pub extern gui-button( label: string ) : io bool
  c inline "hk_gui_button(kk_string_cbuf_borrow(#1,NULL,kk_context())) != 0"

pub extern gui-separator() : io ()
  c inline "hk_gui_separator()"

pub extern gui-same-line() : io ()
  c inline "hk_gui_same_line()"

// High-level: run the event loop with a per-frame callback.
pub fun gui-window( title: string, w: int, h: int, frame: () -> io () ) : io ()
  hk-gui-run(title, w, h, frame)
```

### Layer 3: Hica user side

hica imports the Koka module via `extern import` (pass-through, no `.hc` compilation):

```hica
extern import "lib/imgui/src/imgui"

fun main() {
  gui_window("My App", 800, 600, fun() {
    gui_text("Hello!")
    if gui_button("OK") {
      println("pressed")
    }
  })
}
```

Function names: hica maps underscores to hyphens in Koka, so `gui_window` in hica → `gui-window` in Koka. This is already how the existing HTTP library works.

---

## The State Problem

Immediate-mode UIs keep per-widget state across frames (slider position, text input buffer, checkbox checked state). In C this is trivial with `static` locals. In Koka there are two approaches:

### Option A: C-owned state (simplest)

The C backend owns all state. Koka widgets return the current value each frame:

```koka
// Each call returns the current value (C owns the int)
pub extern gui-slider-int( label: string, min: int, max: int, initial: int ) : io int
  c "kk_hk_gui_slider_int"
```

The user reads state each frame:
```hica
fun main() {
  gui_window("Demo", 400, 300, fun() {
    let n = gui_slider_int("Count", 0, 100, 50)
    gui_text("Value: " + show(n))
  })
}
```

This is clean, simple, and works immediately. State resets when the widget disappears from the frame (same as Dear ImGui's model).

### Option B: Koka `var` in the frame closure (more control)

```hica
fun main() {
  var count = 0
  gui_window("Counter", 400, 300, fun() {
    if gui_button("+") {
      count = count + 1
    }
    gui_text("Count: " + show(count))
  })
}
```

This requires the frame callback to close over mutable Koka state. Koka's `var` in closures uses reference cells — this works as long as `var count` is declared outside the `gui_window` call. This is the most ergonomic model.

**Option B is the right default** — it's the most hica-like and requires no new language features.

---

## hica.ini Setup

Users add to their project's `hica.ini`:

```ini
[koka]
flags = --cclib=cimgui --cclib=SDL2 --cclib=GL
```

And install system dependencies:
- **macOS**: `brew install cimgui sdl2` (cimgui may need manual build from source)
- **Linux**: `apt install libsdl2-dev` + build cimgui from source
- **Windows**: vcpkg or manual

The `--cclib=cimgui` flag is identical to the `--cclib=curl` used by the HTTP library.

---

## Distribution

Same model as `http`, `yaml`, `toml`:

```sh
git submodule add https://github.com/cladam/imgui.git lib/imgui
```

```hica
extern import "lib/imgui/src/imgui"
```

---

## Proof-of-Concept Scope (Phase 1)

A minimal but useful first implementation:

| Widget | Koka name | Notes |
|--------|-----------|-------|
| Window loop | `gui_window(title, w, h, frame)` | Core — runs SDL2+GL event loop |
| Text label | `gui_text(s)` | `igText()` |
| Button | `gui_button(label) : bool` | True on click frame |
| Separator | `gui_separator()` | Horizontal rule |
| Same-line | `gui_same_line()` | Place next widget on same line |
| Int slider | `gui_slider_int(label, min, max) : int` | C-owned state, returns value |
| Float slider | `gui_slider_float(label, min, max) : float` | Same |
| Checkbox | `gui_checkbox(label, checked) : bool` | Returns new state |
| Text input | `gui_input_text(label, buf_size) : string` | C-managed buffer |
| Collapsible | `gui_begin_panel(label) : bool` / `gui_end_panel()` | Section header |

This set covers ~80% of real-world use cases.

---

## What's Genuinely Hard

### 1. Koka closure → C function pointer

`gui_window`'s frame callback must be called by C on each frame. Koka closures are heap objects, not C function pointers. The standard Koka pattern is:

```c
// The trampoline: C calls this, it invokes the Koka closure
static kk_function_t g_frame_cb;
static kk_context_t* g_ctx;

void frame_trampoline(void) {
  kk_function_call(kk_unit_t, (kk_function_t, kk_context_t*),
                   g_frame_cb, g_frame_cb, g_ctx);
}
```

This is exactly what `node-subprocess-inline.c` does for hica's REPL. It's boilerplate but well-understood.

### 2. cimgui build distribution

cimgui is not in most package managers. Users need to build it from source:

```sh
git clone https://github.com/cimgui/cimgui.git
cd cimgui
cmake -DIMGUI_STATIC=ON .
make
```

The library may need to be vendored into `lib/imgui/vendor/` similar to how some libraries handle their C dependencies.

### 3. macOS requires Metal or SDL-rendered OpenGL

On macOS, pure OpenGL is deprecated. SDL2 handles this transparently with its OpenGL compatibility layer, but users need SDL2 2.x+. A Metal backend would be ideal long-term but is significantly more work.

### 4. Effect inference

`gui_window` and all widget functions are `io` effects. This means hica programs using the GUI will infer `io` on `main`, which is normal — every `println` call already does this. No effect annotations needed in hica code.

---

## Comparison: CLI vs GUI in hica

```hica
// CLI — today
fun main() {
  let name = input("Your name: ")
  println("Hello, " + name + "!")
}
```

```hica
// GUI — with cimgui
extern import "lib/imgui/src/imgui"

fun main() {
  var name = ""
  gui_window("Greeter", 400, 200, fun() {
    name = gui_input_text("Your name", 128)
    gui_text("Hello, " + name + "!")
  })
}
```

The structure is near-identical: declare variables, read input, display output. The only differences are `gui_window` as the outer frame and using `var` for state that persists across frames.

---

## Implementation Plan

| Step | What |
|------|------|
| 1 | Build cimgui from source + confirm SDL2+GL3 works |
| 2 | Write `imgui_impl.c`: SDL2 + OpenGL3 event loop + widget wrappers |
| 3 | Write `imgui.kk`: extern declarations + Koka closure trampoline |
| 4 | Write `hello-gui.hc` example and confirm `hica run` works end-to-end |
| 5 | Write `demo-widgets.hc` covering all Phase 1 widgets |
| 6 | Write `lib/imgui/README.md` + update `docs/libraries.md` |

---

## Open Questions

1. **Backend portability**: SDL2+OpenGL3 works everywhere but is heavy. For a future `--backend=metal` or `--backend=dx12` option, the C layer needs a backend abstraction. Start with SDL2 and defer this.

2. **Font and theme**: Dear ImGui ships with one default font. Do we expose `gui_set_font(path, size)` in Phase 1, or leave it for later?

3. **Tables**: `igBeginTable` / `igTableNextRow` / `igTableSetColumnIndex` / `igEndTable` would be very useful for hica programs that display data. Worth including in Phase 1 or Phase 2?

4. **Standalone binary size**: ImGui + SDL2 + OpenGL adds ~2–4 MB to the binary on macOS. Acceptable for a GUI program.

5. **REPL integration**: Could `hica repl` grow a `--gui` flag that evaluates GUI snippets in a persistent ImGui window? Interesting but far future.
