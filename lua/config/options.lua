-- Options are loaded before lazy.nvim startup.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = "\\"

opt.mouse = "a"
opt.mousemodel = "popup"
opt.mousescroll = "ver:3,hor:6"

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2

opt.swapfile = false
opt.backup = false
opt.timeoutlen = 400

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Markdown rendering (render-markdown) needs conceal; code stays literal.
opt.conceallevel = 0
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "quarto" },
  callback = function() vim.opt_local.conceallevel = 2 end,
})

-- Private Python env for Jupyter/Molten (created by Settings -> Packs -> "Set up Python env").
local venv_py = vim.fn.stdpath("data") .. "/nvil-venv/bin/python"
if vim.uv.fs_stat(venv_py) then g.python3_host_prog = venv_py end

-- Always show the buffer tab line, even with a single file.
opt.showtabline = 2
