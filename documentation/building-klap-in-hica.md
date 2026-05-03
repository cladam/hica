# Building a CLI Argument Parser in hica

> Draft — what it would take to build something like klap entirely in hica,
> and how to bundle klap as a built-in module in the meantime.

## Goal

Two goals, short-term and long-term:

1. **Short-term:** Bundle klap (the Koka library already in `lib/klap`) as
   built-in CLI parsing functions available to every hica program, no imports needed.
2. **Long-term:** Write a CLI argument parsing library in hica itself once
   the language has enums, maps, and modules.

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

## Bundling hica-klap — the short-term plan

Since hica compiles to Koka and klap is already a Koka library in `lib/klap`,
we can expose klap's functionality as **built-in functions** — the same pattern
used for `get_args()`, `get_env()`, and `eprintln()`.

### Proposed hica API

```
// Define arguments
let verbose = cli_flag("verbose", "v", "Enable verbose output")
let output  = cli_option("output", "o", "Output file")
let file    = cli_positional("file", "Input file")

// Build command and parse
let app = cli_command("mytool", "1.0", "A tool that does things",
                      [verbose, output, file])

match cli_parse(app) {
  Err(msg)      => eprintln(msg),
  Ok(matches)   => {
    let is_verbose = cli_get_flag(matches, "verbose");
    let out_file   = cli_get_option(matches, "output");
    let in_file    = cli_get_positional(matches, 0);
    // ...
  }
}
```

Or with pipe syntax:

```
fun main() {
  let matches = cli_command("mytool", "1.0", "Does things", [
    cli_flag("verbose", "v", "Be noisy"),
    cli_option("output", "o", "Output file"),
    cli_positional("file", "Input file")
  ]) |> cli_parse_or_exit;

  if cli_get_flag(matches, "verbose") {
    eprintln("verbose mode on")
  };

  let file = cli_get_positional(matches, 0);
  println("processing: {file}")
}
```

### Types needed

Two opaque built-in types (no user access to internals):

| hica type      | Maps to Koka          | Description               |
|----------------|-----------------------|---------------------------|
| `CliArg`       | `klap/arg/arg-def`    | Argument definition       |
| `CliMatches`   | `klap/matches/arg-matches` | Parsed result        |

These are opaque — hica users interact through functions only.
The command itself is not a type; `cli_command()` + `cli_parse()` combines
building and parsing in one step.

### Built-in functions

**Argument builders:**

| hica function | Signature | Emits Koka |
|---------------|-----------|------------|
| `cli_flag(name, short, help)` | `(string, string, string) -> CliArg` | `flag(name, Just(short[0])).help(help)` |
| `cli_option(name, short, help)` | `(string, string, string) -> CliArg` | `option(name, Just(short[0])).help(help)` |
| `cli_positional(name, help)` | `(string, string) -> CliArg` | `positional(name).help(help)` |
| `cli_required(arg)` | `(CliArg) -> CliArg` | `arg.required` |
| `cli_default(arg, val)` | `(CliArg, string) -> CliArg` | `arg.default-value(val)` |

**Parsing:**

| hica function | Signature | Emits Koka |
|---------------|-----------|------------|
| `cli_command(name, ver, about, args)` | `(string, string, string, list<CliArg>) -> CliCommand` | builds a klap `command` |
| `cli_parse(cmd)` | `(CliCommand) -> result<CliMatches, string>` | `try-klap { cmd.parse(get-args()) }` |
| `cli_parse_or_exit(cmd)` | `(CliCommand) -> CliMatches` | `cmd.parse-or-exit(get-args())` |

**Querying results:**

| hica function | Signature | Emits Koka |
|---------------|-----------|------------|
| `cli_get_flag(m, name)` | `(CliMatches, string) -> bool` | `m.get-flag(name)` |
| `cli_get_option(m, name)` | `(CliMatches, string) -> maybe<string>` | `m.get-one(name)` |
| `cli_get_option_or(m, name, default)` | `(CliMatches, string, string) -> string` | `m.get-one-or(name, default)` |
| `cli_get_positional(m, index)` | `(CliMatches, int) -> maybe<string>` | list indexing on `m.get-positionals()` |
| `cli_get_positionals(m)` | `(CliMatches) -> list<string>` | `m.get-positionals()` |
| `cli_get_count(m, name)` | `(CliMatches, int) -> int` | `m.get-count(name)` |

### Implementation plan

**Step 1: Add opaque types to the type system**

Add `TCliArg`, `TCliMatches`, `TCliCommand` to the `hica-type` enum in `ast.kk`.
These are opaque — not constructable by users, only returned by built-in functions.

```koka
// In ast.kk
TCliArg
TCliMatches
TCliCommand
```

**Step 2: Add built-in function signatures to the prelude**

In `prelude.kk`, add `extern-cli()` returning the function type environment:

```koka
("cli_flag",         TFun([TString, TString, TString], TCliArg))
("cli_option",       TFun([TString, TString, TString], TCliArg))
("cli_positional",   TFun([TString, TString], TCliArg))
("cli_required",     TFun([TCliArg], TCliArg))
("cli_default",      TFun([TCliArg, TString], TCliArg))
("cli_command",      TFun([TString, TString, TString, TList(TCliArg)], TCliCommand))
("cli_parse",        TFun([TCliCommand], TResult(TCliMatches, TString)))
("cli_parse_or_exit",TFun([TCliCommand], TCliMatches))
("cli_get_flag",     TFun([TCliMatches, TString], TBool))
("cli_get_option",   TFun([TCliMatches, TString], TMaybe(TString)))
("cli_get_option_or",TFun([TCliMatches, TString, TString], TString))
("cli_get_positional",  TFun([TCliMatches, TInt], TMaybe(TString)))
("cli_get_positionals", TFun([TCliMatches], TList(TString)))
("cli_get_count",    TFun([TCliMatches, TString], TInt))
```

**Step 3: Add codegen match arms**

In `codegen.kk`, emit the appropriate klap Koka calls for each built-in:

```koka
(Var("cli_flag"), [name, short, help]) ->
  "flag(" ++ emit-expr(name) ++ ", Just('" ++ ... ++ "')).help(" ++ emit-expr(help) ++ ")"
```

**Step 4: Conditional `import klap` in generated code**

Like the existing `import std/os/env` detection, add a `program-uses-cli` check.
When any `cli_*` function is used, emit:

```koka
import arg
import command
import parse
import matches
import error
```

**Step 5: Pass `-ilib/klap/src` to koka**

In `run-koka()` and `compile-koka()`, detect when the generated `.kk` imports
klap and add `-ilib/klap/src` to the koka command line.

The klap source ships with hica already (as a git submodule in `lib/klap`).
For installed binaries, klap `.kk` files would be installed alongside hica
(e.g., `~/.hica/lib/klap/`).

### What this gives users

- Full POSIX-style CLI parsing: `-arF`, `--sort=name`, `--`, combined flags
- Auto-generated `--help` and `--version`
- Type-safe flag/option/positional access
- Error messages on invalid arguments
- No imports needed — just call `cli_*` functions
- Zero new language features required — works with hica as-is

### Example: a complete CLI tool

```
struct Config {
  verbose: bool,
  output: string,
  files: list<string>
}

fun main() {
  let matches = cli_command("filetool", "0.1.0", "Process files", [
    cli_flag("verbose", "v", "Enable verbose output"),
    cli_option("output", "o", "Output file") |> cli_default("out.txt"),
    cli_positional("files", "Input files")
  ]) |> cli_parse_or_exit;

  let cfg = Config {
    verbose: cli_get_flag(matches, "verbose"),
    output:  cli_get_option_or(matches, "output", "out.txt"),
    files:   cli_get_positionals(matches)
  };

  if cfg.verbose { eprintln("processing {length(cfg.files)} files...") };
  println("output: {cfg.output}")
}
```

```
$ ./filetool --help
filetool 0.1.0 — Process files

USAGE: filetool [OPTIONS] [files...]

OPTIONS:
  -v, --verbose       Enable verbose output
  -o, --output VALUE  Output file [default: out.txt]
  -h, --help          Show this help
      --version       Show version

$ ./filetool -v --output=result.txt a.txt b.txt
processing 2 files...
output: result.txt
```
