# Contributing to hica

Thanks for your interest in contributing! This document covers the essentials. The full step-by-step guide is in [documentation/developer-guide.md](documentation/developer-guide.md).

## Prerequisites

- Koka ≥ 3.2 installed
- Repository cloned with submodules:
  ```bash
  git clone --recurse-submodules https://github.com/cladam/hica.git
  # or, if already cloned:
  git submodule update --init --recursive
  ```

## Building

```bash
make build      # debug build (fast)
make release    # optimised release build
make bundle     # re-bundle prelude + stdlib, then release build
```

After editing a file in `prelude/` or `stdlib/`, always use `make bundle` rather than a plain build.

## Running Tests

```bash
make test           # full test suite
make test-lexer     # lexer unit tests
make test-parser    # parser unit tests
make test-codegen   # codegen unit tests
make test-cli       # end-to-end CLI tests (requires a built binary)
make test-js        # JS backend tests
make choreo-cli     # ATDD CLI acceptance tests
make choreo-repl    # ATDD REPL acceptance tests
```

## Workflow for a New Feature

The developer guide in [documentation/developer-guide.md](documentation/developer-guide.md) walks through the full pipeline:

1. Check `documentation/backlog.md` for existing issues and feature status
2. Write a `.hc` example in `examples/` first — this is your design spec
3. Update lexer → AST → parser → type checker → codegen (in that order)
4. If it affects the JS target, also update `src/emit/codegen-js.kk`
5. Write tests (`test-lexer.kk`, `test-parser.kk`, `test-codegen.kk`, `test-cli.kk`)
6. Update docs (`docs/language-reference.md`, `docs/standard-library.md` as needed)
7. Commit with a conventional commit message:
   ```bash
   tbdflow commit -t feat -m "add <feature description>"
   # or with plain git:
   git commit -m "feat: add <feature description>"
   ```

## Project Layout

| Directory | Contents |
|-----------|----------|
| `src/syntax/` | Lexer, parser, AST |
| `src/semantics/` | Type checker, prelude signatures |
| `src/transform/` | Desugaring passes |
| `src/emit/` | Koka and JS code generation |
| `src/diagnostics/` | Error reporting |
| `prelude/` | Built-in hica functions (bundled into the binary) |
| `stdlib/std/` | Standard library modules |
| `examples/` | Example `.hc` programs |
| `tests/` | Unit and end-to-end tests |
| `docs/` | User-facing documentation |
| `documentation/` | Internal development notes and backlog |

## Reporting Bugs

Open an issue on GitHub. If you have a minimal `.hc` reproducer, include it – that makes diagnosis much faster.
