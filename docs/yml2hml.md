---
layout: default
title: yml2hml — YAML to HML Converter - hica
---

# yml2hml — YAML to HML Converter

`yml2hml` is a standalone tool written in hica that converts YAML files to [HML](HML-specification) format. It demonstrates how hica handles real-world parsing, recursive data structures, and formatted output.

## Run from source

Requires hica and Koka:

```sh
hica run programs/yml2hml.hc -- input.yml
```

Or build a standalone binary:

```sh
hica build programs/yml2hml.hc
./programs/yml2hml input.yml
```

## Usage

```
$ yml2hml --help
yml2hml 1.0.0 — convert YAML files to HML format

USAGE: yml2hml [OPTIONS] <input> [output]

OPTIONS:
  -h, --help            Show this help
      --version         Show version

ARGS:
  <input>               YAML file to convert (required)
  <output>              output HML file (default: stdout)
```

```sh
# Print HML to stdout
yml2hml config.yml

# Write to a file
yml2hml config.yml output.hml
```

## Example

Given a GitHub Actions workflow (`build.yml`):

```yaml
name: Build, Test, and Release

permissions:
  contents: read

on:
  push:
    branches: [ "main" ]
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+*'
    paths-ignore:
      - 'README.md'
      - 'docs/**'

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            artifact: hica-linux-x86_64
          - os: macos-latest
            artifact: hica-macos-arm64
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - name: Build
        run: |
          koka -O2 -ilib/klap -isrc src/main.kk -o hica
        shell: bash
```

Running `yml2hml build.yml` produces:

```
name: "Build, Test, and Release"
@permissions {
    contents: "read"
}
@on {
    @push {
        branches: ["main"]
        tags: ["v[0-9]+.[0-9]+.[0-9]+*"]
        paths-ignore: ["README.md", "docs/**"]
    }
}
@jobs {
    @build {
        @strategy {
            @matrix {
                @include {
                    os: "ubuntu-latest"
                    artifact: "hica-linux-x86_64"
                }
                @include {
                    os: "macos-latest"
                    artifact: "hica-macos-arm64"
                }
            }
        }
        runs-on: "${{ matrix.os }}"
        @steps {
            uses: "actions/checkout@v4"
            @with {
                submodules: true
            }
        }
        @steps {
            name: "Build"
            run: """
koka -O2 -ilib/klap -isrc src/main.kk -o hica
"""
            shell: "bash"
        }
    }
}
```

## What it handles

| YAML feature | HML output |
|---|---|
| Scalars (strings, ints, floats, bools, null) | Typed values (`"hello"`, `42`, `true`, `null`) |
| Nested objects | `@element { ... }` blocks |
| Scalar lists (`- item`) | Arrays (`["a", "b", "c"]`) |
| Lists of objects (`- key: val`) | Repeated `@element` blocks |
| Flow sequences (`[a, b, c]`) | Arrays |
| Flow mappings (`{key: val}`) | Inline `@element(attrs)` |
| Multi-line strings (`\|` and `>`) | Triple-quoted strings (`"""..."""`) |
| Comments (`#`) | HML comments (`//`) |
| Underscore keys (`my_key`) | Dashed keys (`my-key`) |

## Limitations

- Anchors and aliases (`&anchor`, `*alias`)
- Complex or multi-line keys
- Merge keys (`<<`)
- YAML tags (`!tag`)

## Language features used

`yml2hml` is also a showcase of hica language features:

- **Enum types** — `type YamlLine { YKeyVal(...), YListItem(...), ... }` for classifying parsed lines
- **Structs** — `struct ConvertState { remaining: list<string> }` for parser state
- **Slice patterns** — `[" ", ..rest] =>` for counting indentation
- **Or-patterns** — `"true" | "yes" | "on" =>` for YAML boolean mapping
- **Pattern matching** — `match`/`Some`/`None` throughout for safe value handling
- **String interpolation** — `"@{hkey} \{"` for building output
- **Recursion** — `convert_block` recursively processes nested YAML structure
- **Pipe operator** — `read_file(path) |> unwrap` for chaining
- **Closures** — `map(items, (item) => hml_value(strip(item)))` for transformations
- **Dot-call syntax** — `trimmed.strip()`, `items.length()` for readability
- **File I/O** — `read_file`, `write_file` with `Result` error handling
- **CLI prelude** — `cli() |> arg()` builder for `--help`, `--version`, and argument validation
- **CLI args** — `cli_parse`, `Parsed(r)`, `get_positional` for structured argument handling

## Source

The full source is in [`programs/yml2hml.hc`](https://github.com/cladam/hica/blob/main/programs/yml2hml.hc) (~580 lines).
