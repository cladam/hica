---
layout: post
title: "Test-Driven Development with hica"
date: 2026-05-20
tags: [hica, TDD, testing]
comments: true
---

hica has inline `test` blocks. They sit right next to your functions: no extra test files, no additional imports and no framework. 
Run `hica test` and you're done. Early on in hica's design I wanted a super-easy way to run tests, like the easiest way possible and I succeeded (IMHO)

This post walks through how TDD works in hica and why the compiler changes what you need to test.

### TDD isn't new

TDD has a reputation as a methodology someone invented. It's not. Kent Beck has said he "rediscovered" it by studying older literature and watching what good programmers already did. 
Dijkstra argued in 1972 that correctness proofs and programs should "grow hand in hand." 

Andrea LaForgia captures this well in his [T*D piece](https://a4al6a.substack.com/p/td). 
TDD, trunk-based development, and collaborative programming are patterns that keep emerging when teams care about quality and fast delivery. 
When you remove friction from testing, people test first. That's what happened with hica.

### The compiler does half the work

hica has Hindley-Milner inference and exhaustive pattern matching. A lot of the defensive tests I'd write in other languages just aren't needed:

```rust
type Direction {
  North, South, East, West
}

fun move(pos, dir) {
  match dir {
    North => (pos.0, pos.1 + 1),
    South => (pos.0, pos.1 - 1),
    East  => (pos.0 + 1, pos.1),
    West  => (pos.0 - 1, pos.1)
  }
}
```

Forget the null case (there's no null). Pass a string where a `Direction` is expected? It won't compile. Leave out `West`? Compile error. 
The type checker handles structural correctness. What's left for tests is whether the function *does the right thing*. If the compiler can't tell a correct implementation from an incorrect one, write a test.

### Red-green-refactor

Building a password validator from scratch.

**Red.** Stub the interface, assert what you want:

```rust
fun validate(password) => false

test "valid password has 6+ characters" {
  assert(validate("secret!123"))
}
```

`hica test password.hc` fails. Good.

**Green.** Minimum code to pass:

```rust
fun validate(password) => str_length(password) >= 6
```

Passes.

**Red again.** Passwords must also contain an exclamation mark:


```rust
fun validate(password) {
  let long_enough = str_length(password) >= 6
  let has_bang = contains(password, "!")
  long_enough && has_bang
}

test "valid password has 6+ characters" {
  assert(validate("secret!123"))
}

test "rejects password without special char" {
  assert_false(validate("noSpecialHere"))
}

test "rejects short password" {
  assert_false(validate("ab!"))
}
```

All three pass. Refactor whenever, the tests catch regressions.

### No context switch

Tests live next to the code:

```rust
fun double(x) => x * 2

test "double works" {
  assert_eq(double(3), 6)
  assert_eq(double(0), 0)
}
```

```
running 1 test(s)...

  ✓ double works

1 test(s) passed
```

When something breaks:

```
  ✗ double works
    assertion failed: assert_eq(double(3), 5)
      expected: 5
      actually: 6
```

Use `assert_eq` over `assert`: "expected 5, got 6" tells you what happened, `assert` just says "false".


### A typical session

```sh
vim password.hc          # write a failing test
hica test password.hc    # see it fail
vim password.hc          # make it pass
hica test password.hc    # see it pass
hica check password.hc   # fast type-check between edits
tbdflow commit -t feat -m "add password validation"
```

`hica check` only type-checks, no compilation and near instant. I run it between every edit, like a spellchecker for logic.

### One test per behaviour

"Validates length" and "requires digit" are separate tests. If a test name needs "and" in it, split it.
