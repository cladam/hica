# Hica for VS Code

Syntax highlighting and language support for the [Hica](https://github.com/cladam/hica) programming language.

## Features

- Syntax highlighting for `.hc` files
- Bracket matching and auto-closing
- Comment toggling (`Ctrl+/` / `Cmd+/`)
- Code folding on `{ }` blocks

## What Gets Highlighted

| Element | Examples |
|---------|---------|
| Keywords | `fun`, `let`, `var`, `if`, `else`, `match`, `for`, `while`, `loop`, `break`, `continue` |
| Declarations | `struct`, `type`, `extern`, `pub`, `import`, `from`, `test` |
| Constants | `true`, `false`, `None` |
| Constructors | `Some`, `Ok`, `Err`, PascalCase names |
| Types | `int`, `float`, `bool`, `string`, `char`, `list`, `maybe`, `result` |
| Numbers | `42`, `3.14`, `0xFF`, `0b1010`, `1_000_000` |
| Strings | `"hello"`, `"score: {n}"` (with interpolation highlighting) |
| Characters | `'a'`, `'x'` |
| Operators | `|>`, `=>`, `->`, `==`, `!=`, `&&`, `||`, `..`, `..=`, `...`, `?` |
| Comments | `// line comments` |
| Functions | Declaration names and call sites |

## Installation

### From Source (Development)

```bash
cd hica-vscode
# Install in VS Code's extension directory
ln -s "$(pwd)" ~/.vscode/extensions/hica
```

Then reload VS Code. Any `.hc` file will activate the extension.

### From VSIX (future)

```bash
code --install-extension hica-0.1.0.vsix
```

## Roadmap

- [x] Syntax highlighting (TextMate grammar)
- [x] Bracket matching and auto-closing
- [ ] Diagnostics on save via `hica check --json`
- [ ] Live diagnostics on change
- [ ] Hover for type information
- [ ] Go-to-definition
- [ ] Autocomplete
- [ ] Format on save via `hica fmt`
