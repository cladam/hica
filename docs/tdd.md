---
layout: default
title: Test-Driven Development - hica
---

# Test-Driven Development in Hica

Test-Driven Development (TDD) pairs naturally with hica's compile-time guarantees. Because the compiler already eliminates type errors, null pointer bugs, and effect mismatches before your code runs, TDD in hica focuses purely on validating **business logic** and **API design**.

## The Red-Green-Refactor Cycle

The standard TDD loop maps directly onto `hica test`:

```
  ┌──────────────────────────────────────────────┐
  │                                              │
  ▼                                              │
1. RED: Write a failing test ──► 2. GREEN: Write minimal code ──► 3. REFACTOR: Clean up
```

1. **Red** — Write a `test` block that asserts a feature that doesn't exist yet. Run `hica test` and watch it fail.
2. **Green** — Write the minimum production code to make the test pass.
3. **Refactor** — Clean up the implementation while keeping your tests green.

## Practical Example: Building a Password Validator

### Step 1: Red (The Failing Test)

Start by writing what you *want* to be true. The function doesn't need to work yet — just compile:

```rust
fun validate(password) => false

test "valid password has 6+ characters" {
  assert(validate("secret123"))
}
```

Run `hica test password.hc`. The test fails because the stub always returns `false`.

### Step 2: Green (Passing the Test)

Write just enough logic to satisfy the assertion:

```rust
fun validate(password) => str_length(password) >= 6

test "valid password has 6+ characters" {
  assert(validate("secret123"))
}
```

Run `hica test password.hc` — the test passes.

### Step 3: Refactor and Add Edge Cases

Now move back to Red. Add a requirement: the password must contain a digit.

```rust
fun has_digit(s) {
  let chars = to_list(s)
  any(chars, fun(c) => c >= '0' && c <= '9')
}

fun validate(password) {
  let long_enough = str_length(password) >= 6
  let has_number = has_digit(password)
  long_enough && has_number
}

test "valid password has 6+ characters" {
  assert(validate("secret123"))
}

test "rejects password without digit" {
  assert_false(validate("noNumbersHere"))
}

test "rejects short password" {
  assert_false(validate("ab1"))
}
```

Run `hica test password.hc` — all three pass. You're back to Green.

## How Hica Tests Work

Tests live right next to the code they verify. No separate files, no framework imports, no boilerplate:

```rust
fun double(x) => x * 2

test "double works" {
  assert(double(3) == 6)
  assert_eq(double(0), 0)
}
```

Run with:

```sh
hica test my_file.hc
```

Output:

```
running 1 test(s)...

  ✓ double works

1 test(s) passed
```

When a test fails, you see what went wrong:

```
running 1 test(s)...

  ✗ double works
    assertion failed: assert_eq(double(3), 5)
      expected: 5
      actually: 6

0 test(s) passed, 1 failed
```

### Assertions

| Function | Description |
|----------|-------------|
| `assert(cond)` | Fails if `cond` is `false` |
| `assert_eq(expected, actual)` | Fails if values differ; shows both |
| `assert_ne(a, b)` | Fails if values are equal |
| `assert_true(cond)` | Fails if `false` |
| `assert_false(cond)` | Fails if `true` |
| `assert_contains(list, elem)` | Fails if list doesn't contain element |
| `assert_empty(list)` | Fails if list is not empty |
| `assert_not_empty(list)` | Fails if list is empty |

## Compiler-Driven Development

Hica's type inference catches entire categories of bugs at compile time. Instead of writing tests for every boundary error, you can **design strict types** that make invalid states unrepresentable:

```rust
type Direction {
  North,
  South,
  East,
  West
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

There's no need to test "what if direction is `null`?" or "what if someone passes `"northwest"`?" — the compiler enforces exhaustive matching. Save your `test` blocks for verifying **behaviour**:

```rust
test "move north increases y" {
  let result = move((0, 0), North)
  assert_eq(result, (0, 1))
}
```

## The Hica TDD Toolkit

| Purpose | Tool | What it does |
|---------|------|--------------|
| Test runner | `hica test file.hc` | Runs all `test` blocks in a file |
| Type checker | `hica check file.hc` | Validates types without compiling (fast feedback) |
| Formatter | `hica fmt file.hc` | Keeps code consistent during refactoring |
| REPL | `hica repl` | Explore APIs interactively before writing tests |

### A Typical TDD Workflow

```sh
# 1. Write a failing test
vim password.hc

# 2. Run the test — see it fail (Red)
hica test password.hc

# 3. Write minimal code to pass
vim password.hc

# 4. Run the test — see it pass (Green)
hica test password.hc

# 5. Refactor, re-run tests
hica test password.hc

# 6. Type-check everything is still sound
hica check password.hc

# 7. Commit
tbdflow commit -t feat -m "add password validation"
```

## TDD vs Compiler: When to Write Tests

The compiler handles **structural correctness** — types, exhaustiveness, effect safety. Tests handle **semantic correctness** — does the function return the right answer?

| The compiler catches | Tests catch |
|---------------------|------------|
| Type mismatches | Wrong algorithm |
| Missing match arms | Off-by-one errors |
| Effect violations | Incorrect business rules |
| Undefined variables | Edge-case behaviour |

A good rule of thumb: if the compiler can't tell the difference between a correct and incorrect implementation, write a test.

## Tips

- **Start with the test.** Even a simple `assert(f(x) == expected)` clarifies what you're building before you build it.
- **One test block per behaviour.** Keep tests focused — "validates length" and "requires digit" are separate tests.
- **Use `assert_eq` over `assert`.** When a test fails, `assert_eq` shows both expected and actual values. `assert` just says "false".
- **Run `hica check` often.** It's faster than `hica test` and catches type-level regressions instantly.
- **Keep tests next to the code.** Hica's inline `test` blocks eliminate the friction of switching between source and test files.