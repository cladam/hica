if vim.b.did_ftplugin then
  return
end
vim.b.did_ftplugin = true

vim.opt_local.commentstring = "// %s"
vim.opt_local.comments = "://,b:#"

vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2

vim.opt_local.textwidth = 100

-- Match pairs: add angle brackets for generics
vim.opt_local.matchpairs:append("<:>")

-- Fold by indentation (works without tree-sitter)
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99
