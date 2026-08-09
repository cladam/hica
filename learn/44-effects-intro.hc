// ============================================================
// Lesson 44: User-Defined Algebraic Effects
// ============================================================
//
// hica carries effects implicitly: `println` gives you `<console>`,
// `read_file` gives you `<fsys>`, the `?` operator gives you `<exn>`.
// Up to now you could *observe* those effects with `hica check` but
// you could not *define your own*.
//
// From Milestone 1 onward you can. This lesson walks through every
// concept you need, step by step.
//
// ── Why effects at all? ───────────────────────────────────────
//
// Suppose you are writing an editor loop:
//
//   fun editor_loop(buf) {
//     print("\e[2J")          // baked-in IO — cannot test without a real terminal
//     let raw = input("")
//     match decode(raw) { ... }
//   }
//
// The IO and the logic are the same function. You cannot test
// `editor_loop` without a real terminal, and you cannot swap the
// output driver without touching the logic.
//
// With an effect, you *name* the capability the logic needs, and let
// the caller decide how to fulfil it. The loop becomes testable by
// swapping the handler.
//
// ── Core vocabulary ───────────────────────────────────────────
//
// 1. `effect Name { fun op(…) : T … }` — declares an effect.
//    Effect names are PascalCase; operation names are snake_case.
//
// 2. Operations are called like ordinary functions — no special
//    punctuation. Inside a `handle` block they resolve to the
//    installed handler arm.
//
// 3. `handle Name { op(args) => body, … } in { block }` — installs a
//    handler. Every operation declared by `Name` must appear exactly
//    once (exhaustiveness, checked at compile time). The whole
//    expression evaluates to the value of `block`.
//
// ── Sections in this lesson ───────────────────────────────────
//
//   1. Minimal effect: Log (one op, unit return)
//   2. Typed op params and return values
//   3. Multiple operations
//   4. Reusing the same logic with different handlers (testability)
//   5. Effects as capabilities
//
// ============================================================

// ── 1. Minimal effect: Log ────────────────────────────────────
//
// `effect Log` declares a capability with a single operation:
//   fun info(s: string)           — takes a string, returns ()
//
// Any function that calls `info` requires the `<Log>` effect.
// The handler below fulfils it by prepending "[LOG]" and printing.

effect Log {
  fun info(s: string)
}

fun greet_log(name: string) {
  info("hello, " + name)
}

// ── 2. Typed op params and return values ─────────────────────
//
// Operations can return values too. The handler arm's parameter `name`
// is already typed `string` (inferred from the op signature), so
// string concatenation compiles without any annotation.

effect Greet {
  fun hello(name: string) : string
}

// ── 3. Multiple operations ─────────────────────────────────────
//
// An effect can group several related operations. The `handle` block
// must cover every one of them — missing an op is a compile error:
//
//   error: handler for effect 'Counter' is missing operation 'get'
//
// Note: the `with var` clause for stateful handlers (Counter, Buffer)
// lands in Milestone 5. For now, capture state in the enclosing scope.

effect Printer {
  fun print_line(s: string)
  fun print_sep()
}

fun print_items(items: list<string>) {
  foreach(items, (item) => {
    print_line(item)
    print_sep()
  })
}

// ── 4. Reusing logic with different handlers ──────────────────
//
// The same `greet_log` function runs against two completely different
// handlers below. The production handler prints; the test handler
// collects into a list. The *logic* never changes.

fun main() {
  // --- Section 1: basic Log ---
  handle Log {
    info(s) => println("[LOG] " + s)
  } in {
    greet_log("world")
    greet_log("effects")
  }

  // --- Section 2: typed op with a return value ---
  handle Greet {
    hello(name) => "hello, " + name
  } in {
    println(hello("world"))
    println(hello("effects"))
  }

  // --- Section 3: multiple operations ---
  handle Printer {
    print_line(s) => print(s),
    print_sep()   => println(" ---")
  } in {
    print_items(["alpha", "beta", "gamma"])
  }

  // --- Section 4: same logic, different handler ---
  // Production: sends to stdout with a prefix
  handle Log {
    info(s) => println("[INFO] " + s)
  } in {
    greet_log("production")
  }

  // Test: collects into a list (no IO)
  var collected: list<string> = []
  handle Log {
    info(s) => { collected = collected + [s] }
  } in {
    greet_log("test-1")
    greet_log("test-2")
  }
  println("captured: " + show(length(collected)) + " messages")
  println("first:    " + collected[0])
}

// ── 5. Effects as capabilities ────────────────────────────────
//
// A function that accepts a callback can constrain what the callback
// is allowed to do by handling the effect *outside* the callback.
// The callback can only call the operations that are in scope.
//
// Effect-row polymorphic function signatures (e.g. `(A) -> <Log> R`)
// arrive in Milestone 4. For now, the effect is still inferred.

test "handler counts messages without IO" {
  var count = 0
  handle Log {
    info(_s) => count = count + 1
  } in {
    greet_log("a")
    greet_log("b")
    greet_log("c")
  }
  assert(count == 3)
}

test "typed op returns value" {
  handle Greet {
    hello(name) => "Hi, " + name + "!"
  } in {
    let r = hello("tester")
    assert(r == "Hi, tester!")
  }
}

test "multiple operations all required" {
  var lines: list<string> = []
  var seps: int = 0
  handle Printer {
    print_line(s) => { lines = lines + [s] },
    print_sep()   => { seps = seps + 1 }
  } in {
    print_items(["x", "y"])
  }
  assert(length(lines) == 2)
  assert(seps == 2)
}
