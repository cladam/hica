// hica — M5.5 stateful handler with a match-shaped op body
//
// A stateful handler that manages a bounded list buffer. Compared to the
// `counter.hc` example, this one exercises two extra codegen paths that
// were previously broken:
//
//   1. Multiple `with var …` bindings (`items` and `size`) share the same
//      handler scope. Both are hoisted above the `with handler` block.
//   2. `pop()` has a *match*-shaped body with block arms that mutate state
//      (`items = rest; size = size - 1`) before yielding the popped value.
//      The M5 codegen dropped this on the floor — the `resume(match …)`
//      form fought Koka's layout parser. See documentation/effects-journal.md
//      milestone M5.5 for the fix (hoist the match to a local `val`, then
//      `resume(val)`).
//
// Expected output:
//   count = 2
//
// Run:
//   hica run examples/effects/buffer.hc

effect Buffer {
  fun push(x: int)
  fun pop() : maybe<int>
  fun count() : int
}

fun main() {
  let n = handle Buffer {
    push(x) => {
      items = items + [x]
      size = size + 1
    },
    pop() => match items {
      [] => None,
      [x, ..rest] => {
        items = rest
        size = size - 1
        Some(x)
      }
    },
    count() => size
  } with var items = [], var size = 0 in {
    push(1)
    push(2)
    push(3)
    let _ = pop()
    count()
  }
  println("count = {show(n)}")
}
