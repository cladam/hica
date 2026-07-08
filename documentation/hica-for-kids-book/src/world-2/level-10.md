# Level 10. Testing: Did It Work?

You've built a little machine (a function). But how do you **know** it works?
You test it! In hica, you write `test` blocks right next to your functions.

### Your first test

```hica
fun double(n) => n * 2

test "double works" {
  assert(double(3) == 6)
  assert(double(0) == 0)
}
```

Run it:

```sh
./hica test my_file.hc
```

```
running 1 test(s)...

  ✓ double works

1 test(s) passed
```

The green ✓ means your function works! 🎉

### What happens when a test fails?

Try changing the test to something wrong on purpose:

```hica
test "this will fail" {
  assert_eq(double(3), 5)
}
```

```
  ✗ this will fail
    expected 6 but got 5
```

The red ✗ shows you exactly what went wrong. That's the magic of testing: you
find bugs **before** they surprise you.

### Testing tools

Think of these as your detective kit:

| Tool | What it checks | Example |
| --- | --- | --- |
| `assert(cond)` | Is this true? | `assert(1 + 1 == 2)` |
| `assert_eq(a, b)` | Are these equal? | `assert_eq(double(5), 10)` |
| `assert_ne(a, b)` | Are these different? | `assert_ne("cat", "dog")` |
| `assert_true(cond)` | Is this true? (clearer message) | `assert_true(10 > 5)` |
| `assert_false(cond)` | Is this false? | `assert_false(1 > 100)` |
| `assert_contains(list, x)` | Is `x` in the list? | `assert_contains([1, 2, 3], 2)` |
| `assert_empty(list)` | Is the list empty? | `assert_empty([])` |
| `assert_not_empty(list)` | Does the list have items? | `assert_not_empty([1, 2])` |

### Why test early?

Imagine building a Lego spaceship. Would you rather find a missing piece now,
or when the whole thing falls apart at launch? Tests let you check each piece
as you build.

**Golden rule:** Write a function, write a test. Always.

**🎯 Try it:** Write a function `triple(n)` that multiplies by 3, then write a
test for it:

```hica
fun triple(n) => n * 3

test "triple works" {
  assert_eq(triple(4), 12)
  assert_eq(triple(0), 0)
}
```

