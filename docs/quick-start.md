---
layout: default
title: Quick Start - hica
---

# Quick Start

Get hica running and compile your first program in a few minutes.

## Prerequisites

Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) version 3.2 or newer.

## Install hica

The quickest way to install hica:

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | sh
```

This downloads the latest release binary and installs it to `~/.local/bin`.
Make sure that directory is on your `PATH`.

To install elsewhere:

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

Verify the installation:

```sh
hica --version
```

### Build from source

```sh
git clone https://github.com/cladam/hica.git
cd hica
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
./hica --version
```

## Run Your First Programs

Create `hello.hc`:

```rust
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
| `hica clean` | Remove generated build artifacts |
| `hica new <name>` | Create a new hica project |
| `hica init` | Initialise a project in the current directory |
| `hica help <command> | Show help for a command |

Short aliases work too: `hica r`, `hica b`, `hica c`.

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

```rust
// helpers.hc
pub fun double(x) => x * 2
```

```rust
// main.hc
import "helpers"

fun main() {
  println(double(5))
}
```

See the [Language Reference](/hica/docs/language-reference#modules--imports) for selective imports and re-exporting.

## Next Steps

- **[Learn hica](/hica/docs/learn)**: 36 standalone programs, each teaching one concept. Run them, modify them, break them.
- **[Language Reference](/hica/docs/language-reference)**: every syntax detail, for when you need the precise rules.
- **[Standard Library](/hica/docs/standard-library)**: all built-in functions covering strings, lists, math, and more.
