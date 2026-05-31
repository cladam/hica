# 📖 Glossary

| Word | What it means |
| --- | --- |
| `fun` | Declares a new function (a little machine) |
| `3.14` | A float literal — a number with a decimal point |
| `let` | Creates a named value (an immutable labelled box) |
| `var` | Creates a changeable value (a box with a lid) |
| `=>` | The magic arrow — shortcut for simple functions |
| `test "name"` | Declares a test block — checks that your code works |
| `assert(cond)` | Test tool — fails if condition is false |
| `assert_eq(a, b)` | Test tool — fails if a and b are different |
| `match` | A sorting machine that picks a path based on a value |
| `_` | The wildcard — matches anything |
| `x if cond` | A match guard — adds a condition to a pattern |
| `a \| b` | Or-pattern — match this *or* that in a match arm |
| `0..=59` | Range pattern — match any integer in a range (inclusive) |
| `[x, ..rest]` | Slice pattern — grab the first item, keep the rest |
| `if / else` | A fork in the road — pick one path |
| `else if` | Chain multiple conditions without nesting |
| `repeat(n)` | Do something n times |
| `for i in a..b` | Counted loop — run with i going from a to b (inclusive) |
| `while cond` | Loop while a condition is true |
| `loop` | Infinite loop — runs until `break` |
| `break` | Emergency exit — jump out of any loop |
| `continue` | Skip the rest of this round and go to the next one |
| `Some(x)` | A maybe that has a value inside |
| `None` | A maybe with nothing inside |
| `Ok(x)` | A result that succeeded |
| `Err(x)` | A result that failed, with a reason |
| `..` | Range operator — used in for loops: `1..10` |
| `+` on strings | Glue two strings together (concatenation) |
| `"{expr}"` | String interpolation — embed a value inside a string |
| `s[i]` | String indexing — get the character at position i |
| `s[i:j]` | String slicing — get a substring from i to j |
| `\|>` | The pipe — passes a value into a function: `a \|> f` means `f(a)` |
| `(a, b)` | A tuple — bundles two (or more) values together |
| `.0`, `.1` | Tuple access — get the first or second item from a tuple |
| `let (x, y)` | Tuple destructuring — unpack a tuple into separate variables |
| `struct` | Declares a new type with named fields — like designing a custom box |
| `Name { f: v }` | Create a struct value — fill in the labelled compartments |\n| `{\"k\": v}` | A map literal — a lookup table of key-value pairs |\n| `{:}` | An empty map |\n| `map_get(m, k)` | Look up a key in a map — returns `Some(v)` or `None` |\n| `map_set(m, k, v)` | Add or update a key in a map |
| `.field` | Struct field access — read a named compartment |
| `type` | Declares an enum type — a value that can be one of several variants |
| `Red`, `Circle(r)` | Enum variants — the possible shapes a value can take |
| `input(prompt)` | Ask the user for text input — prints prompt, waits for answer |
| `random(min, max)` | Pick a random number from min to max (both included) |
| `show_fixed(v, n)` | Format a float with exactly n decimal places — `show_fixed(3.14159, 2)` gives `"3.14"` |
| `parse_int(s)` | Try to turn a string into an integer — returns `Some(n)` or `None` |
| `parse_float(s)` | Try to turn a string into a float — returns `Some(n)` or `None` |
| `is_valid_date(s)` | Check if a string is a real date like `"2024-05-15"` — needs `import "std/datetime"` |
| `is_valid_time(s)` | Check if a string is a real time like `"07:32:00"` — needs `import "std/datetime"` |
| `datetime_kind(s)` | Tell you what kind of datetime a string is — needs `import "std/datetime"` |
| `date_parts(s)` | Break a date into year, month, day — needs `import "std/datetime"` |
| `time_parts(s)` | Break a time into hour, minute, second — needs `import "std/datetime"` |
| `is_before(d1, d2)` | True if the first date/time comes before the second — needs `import "std/datetime"` |
| `day_of_week(s)` | What day of the week is this date? Returns `"monday"` etc. — needs `import "std/datetime"` |
| `offset_to_minutes(s)` | Convert a timezone offset to minutes — `"+02:00"` gives `120` — needs `import "std/datetime"` |
| `is_digit(c)` | True if `c` is a digit (`0`–`9`) |
| `is_alpha(c)` | True if `c` is a letter (`a`–`z` or `A`–`Z`) |
| `is_upper(c)` | True if `c` is an uppercase letter |
| `is_lower(c)` | True if `c` is a lowercase letter |
| `is_alnum(c)` | True if `c` is a letter or digit |
| `all_digits(s)` | True if every character in `s` is a digit |
| `all_upper(s)` | True if every character in `s` is uppercase |
| `all_lower(s)` | True if every character in `s` is lowercase |
| `glob_match(p, s)` | Match a string against a glob pattern (`*` and `?`) |
| `glob_match_path(p, s)` | Match a path against a glob pattern (supports `**`) |
| `-x` | Negate a number (flip positive/negative) |
| `!x` | Negate a boolean (flip true/false) |
| `&&` | AND — both sides must be true |
| `==` | Equals — asks "are these the same?" |
| `println()` | Print a value to the screen |
| `show()` | Turn a value into a string — `show(42)` gives `"42"` |
| `str_length()` | Count the characters in a string |
| `trim()` | Remove spaces from the edges of a string |
| `contains()` | Check if a string contains another string |
| `to_upper()` | Convert a string to UPPERCASE |
| `to_lower()` | Convert a string to lowercase |
| `split()` | Break a string into a list — `split("a,b", ",")` gives `["a", "b"]` |
| `join()` | Glue a list into a string — `join(["a", "b"], "-")` gives `"a-b"` |
| `center()` | Center a string inside padding — `center("hi", 10, "-")` gives `"----hi----"` |
| `replace()` | Swap parts of a string |
| `length()` | Count how many items are in a list |
| `reverse()` | Flip a list backwards |
| `head()` | First element of a list — returns `Some(x)` or `None` |
| `tail()` | Everything after the first element |
| `last()` | Last element of a list — returns `Some(x)` or `None` |
| `sum()` | Add up all numbers in a list |
| `sort_by()` | Sort a list using a comparison function |
| `unique()` | Remove duplicates from a list |
| `for x in list` | Walk through each item in a list |
| `foreach()` | Function form of for-each — `foreach(list, fn)` |
| `pow(base, exp)` | Exponentiation — `pow(2, 10)` gives `1024` |
| `sqrt(x)` | Square root — `sqrt(25.0)` gives `5.0` |
| `floor(x)` | Round a float down — `floor(3.7)` gives `3` |
| `ceil(x)` | Round a float up — `ceil(3.2)` gives `4` |
| `round(x)` | Round to nearest integer |
| `to_float(n)` | Turn an integer into a float |
| `chars(s)` | Break a string into a list of characters |
| `from_chars(cs)` | Turn a list of characters back into a string |
| closure | A function that remembers values from where it was created |
| higher-order function | A function that takes or returns other functions |
| `import` | Bring functions from another file into yours |
| `pub` | Mark a function as public — other files can use it |
| `from ... import` | Pick specific functions from another file |
| `pub import` | Import and re-share — pass functions along to your importers |
| `: int` | A type annotation — labels a variable or parameter with its type |
| block `{ }` | A group of steps; the last line is the answer |
| `.hc` | The file extension for Hica source code |
| Koka | The language Hica is built in and translates to |
| Perceus | The smart memory cleaner — no garbage collector needed |


*Happy coding!*
