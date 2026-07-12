---
layout: default
title: Quick Start - hica
---

# Quick Start

Get hica running and compile your first program in a few minutes.

## Prerequisites

No prerequisites for the pre-built binary — the install script handles everything.

Building from source requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

## Install hica

### Linux / macOS / Chromebook

```sh
curl -fsSL https://www.hica.dev/install.sh | sh
```

This downloads the latest release binary and installs it to `~/.local/bin`.
Make sure that directory is on your `PATH`.

To install elsewhere:

```sh
curl -fsSL https://www.hica.dev/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

### Windows (PowerShell)

```powershell
irm https://www.hica.dev/install.ps1 | iex
```

This installs hica to `%LOCALAPPDATA%\hica` and adds it to your user PATH.
Override the install directory with `$env:HICA_INSTALL_DIR`.

Verify the installation:

```sh
hica --version
```

### Build from source

```sh
git clone https://github.com/cladam/hica.git
cd hica
make release
./hica --version
```

## Run Your First Programs

Create `hello.hc`:

```hica
fun main() {
  println("Hello, world!")
}
```

Then build and run it:

```sh
./hica run hello.hc
```

Output:

```
Hello, world!
```

`run` transpiles the file to Koka, compiles it, and executes the result.

## CLI Commands

| Command | Description |
| ------- | ----------- |
| `hica run <file>` | Compile and run a `.hc` file |
| `hica build <file>` | Compile a `.hc` file and build a binary |
| `hica check <file>` | Analyse a `.hc` file and report errors |
| `hica fmt <file>` | Format a `.hc` file according to the style guide |
| `hica repl` | Start an interactive REPL |
| `hica test <file>` | Run tests in a `.hc` file |
| `hica new <name>` | Create a new hica project |
| `hica init` | Initialise a project in the current directory |
| `hica add <dep>` | Add a dependency |
| `hica remove <dep>` | Remove a dependency |
| `hica fetch` | Fetch all dependencies |
| `hica pkg <sub>` | Manage packages (list, info, search, tree, update) |
| `hica clean` | Remove generated build artifacts |
| `hica help <command>` | Show help for a command |

Short aliases work too: `hica r`, `hica b`, `hica c`, `hica f`, `hica t`.

Useful global options:

| Option | Description |
| ------ | ----------- |
| `--target=js` | Compile to JavaScript instead of native |
| `--output=NAME` | Output binary name (with `build`) |
| `--check` | Check formatting without modifying the file |
| `--cache` | Remove the stdlib cache (`~/.hica/stdlib/`) |

## Try the Examples

The repo ships with ready-to-run [examples](https://github.com/cladam/hica/tree/main/examples):

```sh
./hica run examples/hello.hc
./hica run examples/fizzbuzz.hc
./hica run examples/pipe.hc
./hica run examples/match.hc
./hica run examples/closures.hc
```

## Multi-file Projects

Split code across files with `import`. Mark shared functions with `pub`:

```hica
// helpers.hc
pub fun double(x) => x * 2
```

```hica
// main.hc
import "helpers"

fun main() {
  println(double(5))
}
```

See the [Language Reference](/hica/docs/language-reference#modules--imports) for selective imports and re-exporting.

## Next Steps

- **[Playground](/hica/playground)**: try hica in the browser, no installation needed.
- **[Language Reference](/hica/docs/language-reference)**: every syntax detail, for when you need the precise rules.
- **[Standard Library](/hica/docs/standard-library)**: all built-in functions covering strings, lists, math, and more.
