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

Given a [tbdflow](https://github.com/cladam/tbdflow) configuration file (`.tbdflow.yml`):

```yaml
main_branch_name: main
stale_branch_threshold_days: 1
monorepo:
  enabled: false
  project_dirs: []
review:
  enabled: false
  strategy: github-issue
  labels:
    pending: review-pending
    concern: review-concern
    accepted: review-accepted
    dismissed: review-dismissed
radar:
  enabled: true
  level: file
  on_sync: true
  on_commit: off
  ignore_patterns:
  - '*.lock'
  - '*-lock.*'
  - CHANGELOG.md
branch_types:
  feat: feat/
  fix: fix/
  docs: docs/
  chore: chore/
lint:
  conventional_commit_type:
    enabled: true
    allowed_types:
    - feat
    - fix
    - docs
    - refactor
    - test
    - chore
```

Running `yml2hml .tbdflow.yml` produces:

```hica
main-branch-name: "main"
stale-branch-threshold-days: 1
@monorepo {
    enabled: false
    project-dirs: []
}
@review {
    enabled: false
    strategy: "github-issue"
    @labels {
        pending: "review-pending"
        concern: "review-concern"
        accepted: "review-accepted"
        dismissed: "review-dismissed"
    }
}
@radar {
    enabled: true
    level: "file"
    on-sync: true
    on-commit: false
    ignore-patterns: ["*.lock", "*-lock.*", "CHANGELOG.md"]
}
@branch-types {
    feat: "feat/"
    fix: "fix/"
    docs: "docs/"
    chore: "chore/"
}
@lint {
    @conventional-commit-type {
        enabled: true
        allowed-types: ["feat", "fix", "docs", "refactor", "test", "chore"]
    }
}
```

Notice how yml2hml automatically converts underscore keys (`main_branch_name`) to HML's dash convention (`main-branch-name`), nested objects become `@element` blocks, and scalar lists become arrays.

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

- **Structs**: `struct ConvertState { remaining: list<string> }` for parser state
- **Slice patterns**: `[" ", ..rest] =>` for counting indentation
- **Or-patterns**: `"true" | "yes" | "on" =>` for YAML boolean mapping
- **Pattern matching**: `match`/`Some`/`None` throughout for safe value handling
- **String concatenation**: `pad + "@" + hkey + " \{"` for building output
- **Recursive descent with helper dispatch**: `convert_block` delegates to focused helpers (`convert_comment`, `convert_list_line`, `convert_nested_key`, `convert_scalar_key`) and recurses through state
- **Closures**: `map(items, (item) => hml_value(strip(item)))` for transformations
- **File I/O**: `read_file`, `write_file` with `Result` error handling
- **CLI prelude**: `cli() |> arg()` builder for `--help`, `--version`, and argument validation
- **CLI args**: `cli_parse`, `Parsed(r)`, `get_positional` for structured argument handling

## Tests

`yml2hml` includes inline tests for core helpers and full conversion paths.

```sh
hica test programs/yml2hml.hc
```

Current coverage includes:

- Scalar conversion and key normalization
- Flow sequence / flow mapping conversion
- Comment stripping and key separator detection
- Nested objects and lists of objects
- Block scalar conversion

## Source

The full source is in [`programs/yml2hml.hc`](https://github.com/cladam/hica/blob/main/programs/yml2hml.hc) (~700 lines, including inline tests).
