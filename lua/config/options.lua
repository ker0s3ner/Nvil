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

-- Keep markdown/code punctuation visible (LazyVim defaults conceallevel to 2).
opt.conceallevel = 0

-- Always show the buffer tab line, even with a single file.
opt.showtabline = 2
