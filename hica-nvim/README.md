# hica-nvim

Neovim support for the [hica programming language](https://github.com/cladam/hica).

## Features

| Feature | Status | How |
|---|---|---|
| Filetype detection (`.hc`) | ✅ Ready | `ftdetect/hica.lua` |
| Syntax highlighting (regex) | ✅ Ready | `syntax/hica.vim` |
| Tree-sitter highlighting | ✅ Ready | `tree-sitter-hica/` + `queries/highlights.scm` |
| Indentation | ✅ Ready | `indent/hica.vim` |
| Comment toggling (`gcc`) | ✅ Ready | `commentstring = "// %s"` |
| Text objects (functions, blocks) | ✅ Ready | `queries/textobjects.scm` |
| Indent-based folding | ✅ Ready | `foldmethod = indent` |
| LSP (diagnostics, hover, go-to-def) | 🔜 Planned | Needs `hica lsp` |

**Editor settings applied automatically for `.hc` files:**
- 2-space indentation (spaces, not tabs)
- Line width 100
- Comment string `// %s`
- Matchpairs extended with `<:>` for generics

## Installation

### lazy.nvim (from local checkout)

```lua
{
  dir = vim.fn.expand("~/path/to/hica/hica-nvim"),
  ft = "hica",
}
```

Once published as a standalone plugin:

```lua
{ "cladam/hica-nvim", ft = "hica" }
```

### Manual

Add `hica-nvim/` to your `runtimepath`:

```lua
vim.opt.runtimepath:append("/path/to/hica/hica-nvim")
```

## Tree-sitter (recommended)

The `tree-sitter-hica/` directory contains a complete Tree-sitter grammar with
`src/parser.c` already generated. No build step required for the parser itself.

Add this to your nvim-treesitter config:

```lua
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.hica = {
  install_info = {
    url = "/path/to/hica/tree-sitter-hica",
    files = { "src/parser.c" },
    branch = "main",
    generate_requires_npm = false,
    requires_generate_from_grammar = false,
  },
  filetype = "hica",
}
```

Then run `:TSInstall hica`. The highlights, indents, and textobjects queries
are in `tree-sitter-hica/queries/`.

For nvim-treesitter-textobjects you also need:

```lua
require("nvim-treesitter.configs").setup({
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      },
    },
  },
})
```

## LSP (future)

Once `hica lsp` is implemented:

```lua
vim.lsp.start({
  name = "hica",
  cmd = { "hica", "lsp" },
  filetypes = { "hica" },
  root_dir = vim.fn.getcwd(),
})
```

Hack to manually register the hica.so file:

cc -shared -fPIC -o /tmp/hica.so ~/cladam/code/hica-ecosystem/hica/tree-sitter-hica/src/parser.c -I ~/cladam/code/hica-ecosystem/hica/tree-sitter-hica/src && echo "compiled ok"

mkdir -p ~/.local/share/nvim/site/parser && cp /tmp/hica.so ~/.local/share/nvim/site/parser/hica.so && echo "installed to $(ls -lh ~/.local/share/nvim/site/parser/hica.so)"

cc -shared -fPIC \
  -o ~/.local/share/nvim/site/parser/hica.so \
  ~/cladam/code/hica-ecosystem/hica/tree-sitter-hica/src/parser.c \
  -I ~/cladam/code/hica-ecosystem/hica/tree-sitter-hica/src