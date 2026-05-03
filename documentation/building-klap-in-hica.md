# Building a CLI Argument Parser in hica

> Draft — what it would take to build something like klap entirely in hica.

## Goal

Write a CLI argument parsing library (like klap, clap, argparse) in hica itself.
A user would define commands, flags, and options, then parse `get_args()` into a
structured result with auto-generated `--help`.

## What klap does today (in Koka)

klap provides:

- **Argument types** — flags (`-v`, `--verbose`), options (`--sort=name`, `-I PATTERN`), positionals (`FILE`)
- **Builder API** — `command("myapp").version("1.0").arg(flag("verbose").short('v').help("..."))`
- **Parsing** — POSIX-style: combined short flags (`-arF`), `--key=value`, `--` separator
- **Match queries** — `get-flag("verbose")`, `get-one("sort")`, `get-many("include")`, `get-positionals()`
- **Auto help** — formatted `--help` and `--version` output
- **Error handling** — algebraic effects for parse failures

## What hica can do today

A basic CLI tool is already possible — see `examples/cli.hc`:

```
struct Config { command: string, rest: list<string> }

fun parse_config(input: list<string>) =>
  if length(input) == 0 { Err("no command") }
  else { Ok(Config { command: input[0], rest: drop(input, 1) }) }

fun main() {
  match parse_config(get_args()) {
    Ok(cfg)  => dispatch(cfg),
    Err(msg) => eprintln("error: {msg}")
  }
}
```

Available building blocks:
- `get_args()` → `list<string>`
- Structs for config records
- `Result`/`Maybe` for error handling
- `match` on strings, ints, constructors
- String operations (`starts_with`, `contains`, `split`, `trim`, `slice`, etc.)
- List operations (`map`, `filter`, `fold`, `find`, `drop`, `take`, etc.)
- Higher-order functions, closures, pipe operator

## Gap analysis

### Tier 1 — Blockers (must fix to build any parser)

| Gap | Why it blocks | Complexity |
|-----|---------------|------------|
| **`let` in if-else branches** | Codegen emits `val` inline in Koka if-then-else, which is invalid. Workaround: extract to helper functions. Real fix: indentation-aware codegen. | Medium |
| **`while` loops** | Parsing is inherently stateful iteration. Must use recursion today, which is awkward for consuming a token list. | Medium |
| **Mutable variables (`var`)** | Parser state (current index, accumulated results) needs mutation. Pure recursion works but is verbose. | Medium |
| **Maps / dictionaries** | Parsed results are key→value pairs. Without maps, must use `list<(string, string)>` and linear scan. | High |

### Tier 2 — Important (needed for a good API)

| Gap | Why it matters | Complexity |
|-----|----------------|------------|
| **User-defined enums** | Argument kinds (Flag, Option, Positional) need sum types. Today only built-in `Maybe`/`Result` exist. | High |
| **Modules / imports** | A library must be importable. Today everything is single-file. | High |
| **Struct update syntax** | `{ ...old, verbose: true }` — needed for builder pattern. Must reconstruct fully today. | Low |
| **`parse_int` / `parse_float` → `maybe`** | `to_int` returns `-1` on failure. Need safe parsing for option values. | Low |
| **Result/Maybe combinators** | `unwrap_or`, `map`, `and_then`, `?` operator — reduce boilerplate in chained validation. | Medium |
| **Char operations** | Need `==` on chars, `is_alpha`, `is_digit` for parsing `-v` vs `--verbose` vs positionals. | Low |

### Tier 3 — Nice to have

| Gap | Why it matters | Complexity |
|-----|----------------|------------|
| **Closures in struct fields** | Validator callbacks, custom parsers per argument. | Medium |
| **String→char iteration** | Walk a combined flag string like `-arF` char by char. `chars()` exists but `for c in chars(s)` may not work. | Low |
| **Default function parameters** | `flag("verbose").help("be noisy")` chaining — without defaults, every builder call must pass all fields. | Medium |
| **Multiline string literals** | Help text for `--help` output. | Low |

## Incremental implementation plan

### Phase 1 — Manual parsing (works today)

Write argument parsing as plain functions over `list<string>`, returning structs.
This is what `examples/cli.hc` already does.

```
// Already possible today
fun has_flag(args: list<string>, name: string) : bool =>
  any(args, fn(a) => a == name)

fun get_option(args: list<string>, name: string) : maybe<string> =>
  match find_index(args, fn(a) => a == name) {
    None    => None,
    Some(i) => args[i + 1]
  }
```

**Limitations:** No builder API, no help generation, no validation.

### Phase 2 — Struct-based definitions (needs: enums or tagged structs)

Define argument specs as data, parse against them.

```
// Needs: user-defined enums
enum ArgKind { Flag, Option, Positional }

struct ArgDef {
  name: string,
  short: maybe<char>,
  kind: ArgKind,
  help: string,
  default_value: maybe<string>
}

// Needs: maps for results
fun parse(defs: list<ArgDef>, args: list<string>) : result<map<string, string>, string>
```

**Requires:** enums, maps, `while`/`var` or comfortable recursion patterns.

### Phase 3 — Builder API (needs: struct update, modules)

Chainable configuration with `.help()`, `.required()` etc.

```
// Needs: struct update syntax
fun help(arg: ArgDef, text: string) : ArgDef =>
  { ...arg, help: text }

// Needs: modules
import klap

fun main() {
  let cmd = command("mytool")
    |> version("1.0")
    |> arg(flag("verbose").short('v').help("enable logging"))
    |> arg(option("output").short('o').help("output file"))
  ...
}
```

**Requires:** struct update, modules/imports, pipe-friendly API design.

### Phase 4 — Help generation (needs: string formatting)

Auto-generate `--help` output with aligned columns.

```
// Needs: string padding/formatting
fun format_help(cmd: Command) : string =>
  let lines = map(cmd.args, fn(a) =>
    pad_right(a.usage_str(), 20) ++ a.help
  );
  join(lines, "\n")
```

**Requires:** `pad_left`/`pad_right` (already in prelude), good string interpolation.

## Recommended feature priority

To get from "works manually" to "has a real library":

1. **`parse_int`/`parse_float` → `maybe`** — low hanging fruit, unblocks safe value parsing
2. **Result/Maybe combinators** — `unwrap_or`, `map_result`, `and_then` — reduce match nesting
3. **Struct update syntax** — enables builder pattern
4. **`while` loops + `var`** — makes parsing natural
5. **User-defined enums** — enables proper argument kind modeling
6. **Maps** — enables parsed result storage
7. **Modules/imports** — makes it a real library

Items 1–3 are incremental additions. Items 4–7 are larger language features
that each unlock a qualitative jump in what's expressible.

## What works well already

- **Structs** for config records — clean, readable
- **Result type** for error propagation — idiomatic
- **Pattern matching** on strings — natural for command dispatch
- **String interpolation** — good for error messages and help text
- **`get_args()` + `get_env()`** — environment access works
- **Pipe operator** — enables fluent data transformation
- **Higher-order functions** — `map`, `filter`, `fold` on lists
