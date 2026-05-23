# hica-nvim

Neovim support for the [Hica programming language](https://github.com/cladam/hica).

## Features

| Feature | Status | How |
|---|---|---|
| Filetype detection (`.hc`) | ✅ Ready | `ftdetect/hica.lua` |
| Syntax highlighting | ✅ Ready | `syntax/hica.vim` (Vim regex) |
| Indentation | ✅ Ready | `indent/hica.vim` |
| Comment toggling | ✅ Ready | `commentstring = "// %s"` |
| Tree-sitter highlighting | 🔜 Pending | Needs `tree-sitter generate` |
| LSP (diagnostics, hover, go-to-def) | 🔜 Planned | Needs `hica lsp` |

## Installation

### lazy.nvim

```lua
{
  "cladam/hica",
  -- Point to the hica-nvim subdirectory
  dir = vim.fn.expand("~/path/to/hica/hica-nvim"),
  ft = "hica",
}
```

Or, once published as a standalone plugin:

```lua
{ "cladam/hica-nvim", ft = "hica" }
```

### Manual

Add `hica-nvim/` to your `runtimepath`:

```lua
vim.opt.runtimepath:append("/path/to/hica/hica-nvim")
```

## Tree-sitter (optional, better highlighting)

Once `tree-sitter generate` has been run to produce `src/parser.c`:

```lua
-- In your nvim-treesitter config:
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.hica = {
  install_info = {
    url = "/path/to/hica/tree-sitter-hica",
    files = { "src/parser.c" },
    branch = "main",
  },
  filetype = "hica",
}
```

Then run `:TSInstall hica`.

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

Or with `nvim-lspconfig` (once the server is registered):

```lua
require("lspconfig").hica.setup({})
```
