-- ~/.config/nvim/lua/config/options.lua
-- Core editor + UI behavior. Think of this as your "settings page" for
-- anything that isn't a keybind — it's just plain Lua, grouped and commented
-- so you can scan it like a settings panel instead of hunting through :help.

local opt = vim.opt
local g = vim.g

g.mapleader = " "      -- space is leader, set BEFORE plugins load
g.maplocalleader = " "

-- ── Mouse & cursor control ────────────────────────────────────────────────
opt.mouse = "a"              -- full mouse support: click to move cursor,
                              -- drag to select, scroll wheel, click to resize
                              -- splits — works alongside every vim keybind
opt.mousemodel = "extend"    -- right-click extends selection (more IDE-like)
opt.mousescroll = "ver:3,hor:6"

-- ── Line numbers & cursor ──────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true    -- relative numbers make vim motions (5j, 3dd) trivial
opt.cursorline = true
opt.scrolloff = 8            -- keep 8 lines visible above/below cursor
opt.sidescrolloff = 8

-- ── Indentation ─────────────────────────────────────────────────────────────
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true

-- ── Search ──────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true         -- case-sensitive only if you type a capital
opt.incsearch = true
opt.hlsearch = true

-- ── Splits ──────────────────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true

-- ── Appearance ──────────────────────────────────────────────────────────────
opt.termguicolors = true     -- required for the dark minimal colorschemes
opt.signcolumn = "yes"       -- always show sign column (git signs / diagnostics)
                              -- so text doesn't shift when they appear
opt.cmdheight = 1
opt.pumheight = 10           -- max items in autocomplete popup
opt.showmode = false         -- statusline already shows mode
opt.laststatus = 3           -- one global statusline, not one per window
opt.winblend = 0
opt.pumblend = 0
opt.conceallevel = 0
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- ── Files & undo ─────────────────────────────────────────────────────────────
opt.undofile = true          -- persistent undo across sessions
opt.swapfile = false
opt.backup = false
opt.updatetime = 250         -- faster gitsigns / diagnostics / CursorHold
opt.timeoutlen = 400         -- faster which-key popup

-- ── Clipboard ─────────────────────────────────────────────────────────────
opt.clipboard = "unnamedplus" -- yank/paste shares your system clipboard

-- ── Completion ──────────────────────────────────────────────────────────────
opt.completeopt = { "menu", "menuone", "noselect" }

-- ── Folding (treesitter-based, but starts fully open) ───────────────────────
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"

-- ── Diagnostics look ──────────────────────────────────────────────────────
vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
})
