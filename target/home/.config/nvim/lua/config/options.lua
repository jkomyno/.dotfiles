-- Options are loaded before lazy.nvim startup.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.lazyvim_ts_lsp = "vtsls"
vim.g.lazyvim_python_lsp = "pyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.spelllang = { "en", "it" }

require("nvim.spellfile").config({ confirm = false })

local custom_spellfile = vim.fn.stdpath("config") .. "/spell/custom.utf-8.add"
vim.opt.spellfile = custom_spellfile

if vim.fn.getftime(custom_spellfile) > vim.fn.getftime(custom_spellfile .. ".spl") then
  vim.cmd("silent mkspell! " .. vim.fn.fnameescape(custom_spellfile))
end

vim.filetype.add({
  extension = {
    wat = "wat",
    wast = "wat",
    wit = "wit",
  },
})
