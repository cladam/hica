---
layout: default
title: CLI Reference - hica
---

# CLI Reference

```
$ hica --help

Usage: hica [OPTIONS] [COMMAND] [FILE]
The hica compiler

Options:
      --check            Check formatting without modifying the file
      --cache            Remove the stdlib cache (~/.hica/stdlib)
      --target=TARGET    Output target: koka (default) or js
  -o, --output=OUTPUT    Output binary name (build only)
      --help                 display this help and exit
      --version              output version information and exit

Commands:
  build, b               Compile a .hc file and build a binary
  run, r                 Compile and run a .hc file
  check, c               Analyse a .hc file and report errors
  fmt, f                 Format a .hc file
  clean                  Remove generated build artifacts
  test, t                Run tests in a .hc file
  new                    Create a new hica project
  init                   Initialise a hica project in the current directory
  add                    Add a dependency
  remove                 Remove a dependency
  fetch                  Fetch all dependencies
  pkg                    Manage packages (list, info, search, tree, update)
  repl                   Start an interactive REPL
  help                   Show help for a command
```

## Commands

### `hica run` (alias: `r`)

Compile and immediately run a `.hc` file:

```sh
hica run examples/hello.hc
```

### `hica build` (alias: `b`)

Compile a `.hc` file. By default targets Koka, outputting a `.kk` file alongside the source:

```sh
hica build examples/arrow.hc
```

Use `--target=js` to emit JavaScript instead:

```sh
hica build --target=js examples/arrow.hc
```

### `hica check` (alias: `c`)

Type-check a `.hc` file and report diagnostics without generating code:

```sh
hica check examples/hello.hc
```

### `hica clean`

Remove generated build artifacts for a file:

```sh
hica clean examples/hello.hc
```

Remove the stdlib cache (`~/.hica/stdlib/`). Use this after upgrading hica to force re-extraction of the updated standard library:

```sh
hica clean --cache
```

### `hica fmt` (alias: `f`)

Format a `.hc` file according to the [style guide](/hica/docs/style-guide):

```sh
hica fmt examples/hello.hc
```

Use `--check` to verify formatting without modifying the file. Returns exit code 1 if changes are needed (useful in CI):

```sh
hica fmt --check examples/hello.hc
```

**Formatting rules applied:**

- Remove trailing whitespace
- Space around operators (`+`, `*`, `/`, `%`, `=`, `==`, `!=`, `<=`, `>=`, `&&`, `||`, `|>`, `=>`)
- Collapse consecutive blank lines to one
- Remove spaces inside `()` and `[]`
- Remove space before function-call parentheses
- Space after commas (not before)
- Space after colon in type annotations (not before)
- Ensure trailing newline at end of file

### `hica test` (alias: `t`)

Run tests defined in a `.hc` file:

```sh
hica test examples/test-example.hc
```

Tests are written with `test` blocks and assertions:

```hica
fun double(n: int) : int => n * 2

test "double works" {
  assert(double(3) == 6)
  assert_eq(double(0), 0)
}
```

Output:

```
running 2 test(s)...

  ✓ double works
  ✓ basic math

2 test(s) passed
```

**Assertions:**

| Function | Description |
|----------|-------------|
| `assert(cond)` | Fails if `cond` is `false` |
| `assert_eq(expected, actual)` | Fails if values differ; shows both values |
| `assert_ne(a, b)` | Fails if values are equal |
| `assert_true(cond)` | Fails if `cond` is `false` (descriptive message) |
| `assert_false(cond)` | Fails if `cond` is `true` |
| `assert_contains(list, elem)` | Fails if list does not contain element |
| `assert_empty(list)` | Fails if list is not empty |
| `assert_not_empty(list)` | Fails if list is empty |

**Exit codes:** 0 if all tests pass, 1 if any test fails.

### `hica new`

Create a new hica project with a starter file structure:

```sh
hica new my-project
```

### `hica init`

Initialise a hica project in the current directory:

```sh
mkdir my-project && cd my-project
hica init
```

### Dependencies

hica has a built-in package manager. Dependencies are declared in the
`@dependencies` block of `hica.hml` and cached under `~/.hica/cache`.

#### `hica add`

Add a dependency, fetch it, and record it in `hica.hml` + `hica.lock`:

```sh
hica add json                          # registry package (latest)
hica add json@0.1.0                    # registry package (pinned version)
hica add github.com/cladam/yaml@v1.0.0 # git dependency
hica add path:../local-lib             # local path dependency
```

#### `hica remove`

Remove a dependency from the manifest:

```sh
hica remove json
```

#### `hica fetch`

Fetch all declared dependencies and regenerate `hica.lock`:

```sh
hica fetch
```

### `hica pkg`

Package-management subcommands, kept out of the top-level namespace so the
compiler commands stay uncluttered:

```
$ hica pkg --help

Usage: hica pkg [SUBCOMMAND] [ARG]
Manage packages

Commands:
  list, ls               List declared dependencies and cache status
  info                   Show registry metadata for a package
  search                 Search cached packages
  tree                   Show the dependency graph
  update, up             Re-resolve dependencies and refresh hica.lock
```

#### `hica pkg list` (alias `ls`)

List declared dependencies with their source and cache status. Works offline; a
`*` marks packages already present in `~/.hica/cache`:

```sh
hica pkg list
```

```
Dependencies (2):
  * imgui             registry  latest
  * json              registry  latest

  * = present in local cache (~/.hica/cache)
```

#### `hica pkg info`

Show registry metadata (version, tarball, checksum) for a package from
`pkg.hica.dev`:

```sh
hica pkg info json
```

```
json (0.1.0)
  tarball:      https://pkg.hica.dev/json/json-0.1.0.tar.gz
  checksum:     sha256:49fc1f82…

  install with: hica add json
```

#### `hica pkg search`

Search locally-cached packages by substring. The registry has no server-side
search index yet, so this searches packages already downloaded to the cache:

```sh
hica pkg search json
```

#### `hica pkg tree`

Render the dependency graph, recursing into each cached dependency's own
`hica.hml`:

```sh
hica pkg tree
```

```
.
├─ imgui (latest)
└─ json (latest)
```

#### `hica pkg update` (alias `up`)

Re-resolve `latest` registry dependencies to concrete versions and pin them in
`hica.lock`. The manifest is left untouched, so `latest` remains as declared
intent:

```sh
hica pkg update
```

```
Resolving dependencies...
  imgui: latest -> 0.5.0
  json: latest -> 0.1.0
updated hica.lock (2 packages, 4 include paths)
```

### `hica repl`

Start an interactive Read-Eval-Print Loop:

```sh
hica repl
```

For history navigation, line editing, and tab completion, wrap with `rlwrap`:

```sh
rlwrap hica repl
```

Optionally preload a file to make its definitions available in the session:

```sh
hica repl lib/helpers.hc
```

**Example session:**

```
hica=> 1 + 2
3
hica=> _ * 10
30
hica=> let x = 5
5
hica=> x + _
35
hica=> "hello" + " world"
hello world
hica=> fun double(n) { n * 2 }
  defined: double
hica=> double(21)
42
```

**Features:**

| Feature | Description |
|---------|-------------|
| `_` variable | Holds the result of the last evaluated expression |
| `let` bindings | `let x = 5` persists across the session |
| Function defs | `fun f(x) { ... }` available for subsequent calls |
| Structs & types | `struct` and `type` declarations persist |
| Multiline input | Unbalanced `{`, `(`, `[` triggers continuation (`...>`) |
| History file | Input saved to `~/.hica_history` |
| Startup file | `~/.hicarc` loaded automatically on start (if present) |
| Error recovery | Type errors display cleanly; session continues |

**REPL commands:**

| Command | Description |
|---------|-------------|
| `:help` (`:h`) | Show available commands |
| `:defs` | List all defined functions |
| `:reset` | Clear all definitions and bindings |
| `:history` | Show recent input history |
| `:load FILE` | Load and evaluate a `.hc` file |
| `:quit` (`:q`) | Exit the REPL (also Ctrl-D) |

