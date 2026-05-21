# Level 9. The Magic Arrow (`=>`)

When a function does just one thing, you can use the **Hica Arrow** instead of
writing curly braces. Think of it as: *"this goes in, that comes out."*

```hica
// With curly braces (block body)
fun double(n) {
  n * 2
}

// With the arrow (same thing, shorter!)
fun double(n) => n * 2
```

The arrow is like a shortcut — one line, no braces, no fuss. Professional
programmers love shortcuts like this.

**🎯 Try it:** Rewrite this block-body function using the arrow:
```hica
fun add_ten(n) {
  n + 10
}
```

