-- ~/.config/nvim/lua/config/keymaps.lua
-- General-purpose keymaps. Plugin-specific keymaps (explorer, AI, git, etc.)
-- live next to their plugin's config in lua/plugins/, so this file stays the
-- "core editing" layer. which-key.nvim (see lua/plugins/which-key.lua) will
-- show you all of these — including plugin ones — grouped under <leader>,
-- so you never have to memorize this file cold.

local map = vim.keymap.set
local opts = { silent = true }

-- ── Better window navigation (Ctrl+hjkl to move between splits) ────────────
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- ── Resize splits with arrows ────────────────────────────────────────────
map("n", "<C-Up>", ":resize +2<CR>", opts)
map("n", "<C-Down>", ":resize -2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- ── Clear search highlight ────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- ── Keep cursor centered while jumping / scrolling ──────────────────────────
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- ── Move selected lines up/down in visual mode ──────────────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- ── Indent without losing selection ─────────────────────────────────────────
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- ── Buffer navigation (bufferline provides the visual tab row) ─────────────
map("n", "<S-l>", "<cmd>bnext<CR>", { silent = true, desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { silent = true, desc = "Delete buffer" })

-- ── Save / quit ─────────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>w<CR>", { silent = true, desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { silent = true, desc = "Quit window" })

-- ── Quickfix / diagnostics navigation ────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Everything below this line is intentionally left to you — this is your
-- personal remap zone. Add whatever you want here and it'll always load last.
