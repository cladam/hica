---
layout: default
title: Style Guide - hica
---

# Style Guide

> **Tip:** Run `hica fmt <file>` to automatically format your code according to these rules.
> Use `hica fmt --check <file>` to verify formatting in CI without modifying the file.

### A Note on Consistency

A style guide is about consistency. Consistency within a project is important.
Consistency within a single file is *the most* important. However, know when
to be inconsistent. Sometimes a rule just doesn't fit. When in doubt, look at
the surrounding code and match its style. Readability always wins.

### 1. The Hica Philosophy

 - **Be Explicit with Data, Implicit with Types:** Lean on type inference for local variables, but use names that describe the *content*, not the type.
 - **Flow over Nesting:** Prefer the pipe operator `|>` or UFCS (dot-notation) over deeply nested function calls.
 - **Expression First:** Every block should have a clear "result" (no floating side effects if possible).

### 2. Naming Conventions (The "Social Contract")

| Entity | Style | Example |
|---|---|---|
| **Variables/Params** | snake_case | user_name, retry_count |
| **Functions** | snake_case | calculate_total(), make_adder() |
| **Structs** | PascalCase | UserAccount, Point2D |
| **Constructors** | PascalCase | Some(), Err(), Ok() |
| **Files** | kebab-case | file-utils.hc, main.hc |
| **Constants** | UPPER_CASE | MAX_RETRIES, DEFAULT_PORT |

 - **Avoid single-letter names** except for standard math (x, y) or list indices (i, j).
 - **Boolean prefixes:** Use is_, has_, or can_ for boolean variables (e.g., is_empty, has_permission).

### 3. Layout and Indentation

 - **Indentation:** Use **2 spaces**. This keeps deeply nested functional structures (like match inside a fun) from drifting too far right.
 - **Line Length:** Limit lines to **80–100 characters**.
 - **Blank Lines:**
   - One blank line between top-level function/struct definitions.
   - One blank line inside a function to separate logical "steps."

### 4. Whitespace

 - **No space** inside parentheses, brackets, or braces:
   ```hica
   // Good
   println(nums[0])
   let p = Point { x: 3, y: 4 }

   // Avoid
   println( nums[ 0 ] )
   ```

 - **No space** before the opening parenthesis of a function call:
   ```hica
   // Good
   println("hello")

   // Avoid
   println ("hello")
   ```

 - **One space** after commas, not before:
   ```hica
   // Good
   let nums = [1, 2, 3]
   fun add(a, b) => a + b

   // Avoid
   let nums = [1 ,2 ,3]
   ```

 - **Type annotations:** Space after the colon, not before:
   ```hica
   // Good
   fun add(a: int, b: int) : int => a + b
   let x: int = 42

   // Avoid
   fun add(a :int, b :int) :int => a + b
   ```

 - **Operator precedence:** You may omit spaces around high-precedence operators when it aids readability:
   ```hica
   // Both acceptable
   let h = x*x + y*y
   let h = x * x + y * y
   ```

### 5. Functions, Arrows, and Pipes

The `=>` arrow separates a function's signature from its body. Consistent placement of `=>` and `|>` is key to readable hica code.

 - **Single-line functions:** Keep on one line if it's short.
   ```hica
   fun double(n) => n * 2
   ```

 - **Multi-line functions:** Use braces for functions with multiple statements.
   ```hica
   fun handle_user(user) {
     let greeting = "Hello, {user.name}"
     println(greeting)
   }
   ```

 - **Expression functions:** Use `=>` when the body is a single expression, even if it spans multiple lines.
   ```hica
   fun fizzbuzz(n) =>
     if n % 15 == 0 { "fizzbuzz" }
     else if n % 3 == 0 { "fizz" }
     else if n % 5 == 0 { "buzz" }
     else { "{n}" }
   ```

 - **Pipe Placement:** Always place the pipe |> at the **start** of the following line, indented.
   ```hica
   let result = raw_data
     |> parse_json()
     |> filter(is_valid)
     |> calculate_metrics()
   ```

 - **Line breaks before operators:** When an expression spans multiple lines, break *before* the operator. This keeps operators visually aligned with their operands:

   ```hica
   // Good: operator at start of continuation
   let total = base_price
     + tax
     + shipping

   // Avoid: operator at end of line
   let total = base_price +
     tax +
     shipping
   ```

### 6. Pattern Matching (match)

Pattern matching is where Hica code can get "busy." Formatting is key to keeping it safe.

 - **Align the Arrows:** For better readability, try to align the => in match arms.
   ```hica
   match result {
     Ok(val)  => println("Success: {val}"),
     Err(msg) => println("Error: {msg}"),
     _        => println("Unknown state")
   }
   ```

 - **Guard Clauses:** Keep guards on the same line as the pattern.
   ```hica
   match n {
     n if n < 0 => "Negative",
     _          => "Positive"
   }
   ```

### 7. Structs and Tuples

 - **Struct Definitions:** One field per line for anything more than two fields.
   ```hica
   struct Config {
     port: int,
     host: string,
     debug: bool
   }
   ```

 - **Tuple Access:** Avoid using .0, .1 for long-lived logic. Use **destructuring** to give values meaningful names.
   ```hica
   // Good
   let (width, height) = get_dimensions()

   // Avoid
   let dims = get_dimensions()
   println(dims.0)
   ```

 - **Struct patterns:** Use struct destructuring in `match` when you need specific fields. List fields in declaration order:
   ```hica
   match p {
     Point { x: 0, y: 0 } => "origin",
     Point { x, y }       => "({x}, {y})"
   }
   ```

 - **List slice patterns:** Prefer `[x, ..rest]` over manual `head`/`tail` calls. Put the empty case first:
   ```hica
   match xs {
     []          => 0,
     [x, ..rest] => x + sum(rest)
   }
   ```

 - **Trailing commas:** Use a trailing comma on the last field when struct definitions or literals span multiple lines. This makes diffs cleaner when fields are added later:
   ```hica
   struct Config {
     port: int,
     host: string,
     debug: bool,
   }
   ```

### 8. Error Propagation

 - **Prefer `?` over nested match:** When a function returns `maybe`, use `?` to unwrap intermediate values instead of nesting `match` expressions:
   ```hica
   // Good: flat and readable
   fun add_strings(a: string, b: string) : maybe<int> {
     let x = parse_int(a)?
     let y = parse_int(b)?
     Some(x + y)
   }

   // Avoid: deeply nested
   fun add_strings(a: string, b: string) : maybe<int> {
     match parse_int(a) {
       None => None,
       Some(x) => match parse_int(b) {
         None => None,
         Some(y) => Some(x + y)
       }
     }
   }
   ```

 - **Use combinators for single transforms:** For a single mapping or chaining step, `map_maybe` or `and_then` may be clearer than `?`.

### 9. Comments and Documentation

 - **Line Comments:** Use // for brief explanations.
 - **Inline comments:** Use sparingly. Separate from code by at least two spaces. Don't state the obvious:
   ```hica
   // Good
   let mask = 0xFF  // high byte only

   // Avoid
   let x = x + 1  // add one to x
   ```
 - **Function Docs:** Place a comment block immediately above a function to describe inputs/outputs if they aren't obvious.
   ```hica
   // calculate_area: (float, float) => float
   // Computes the area of a rectangle given dimensions.
   fun calculate_area(w, h) => w * h

   ```
