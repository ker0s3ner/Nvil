-- freebuff/settings/apply.lua
-- Applies every saved setting at startup (previously settings only took effect
-- when toggled in the UI, then were forgotten on the next launch).

local M = {}

function M.all()
  local Data = require("freebuff.settings.data")
  local Packs = require("freebuff.settings.packs")
  local s = Data.get()
  local a, g = s.appearance or {}, s.general or {}

  -- Colorscheme first: the ColorScheme autocmd in freebuff.theme repaints the accent.
  if a.colorscheme and a.colorscheme ~= vim.g.colors_name then
    pcall(vim.cmd.colorscheme, a.colorscheme)
  end

  -- Editor options
  pcall(function()
    vim.opt.number = a.show_line_numbers ~= false
    vim.opt.relativenumber = a.show_line_numbers ~= false and a.show_relative_line_numbers ~= false
    vim.opt.signcolumn = a.show_sign_column == false and "no" or "yes"
    vim.opt.cursorline = a.cursorline ~= false
    vim.opt.cursorcolumn = a.cursorcolumn == true
    vim.opt.showtabline = a.show_tabline == false and 0 or 2
    vim.opt.mouse = g.mouse or "a"
    vim.opt.spell = g.spell == true
    vim.opt.wrap = g.wrap == true
    vim.opt.timeoutlen = g.timeout_len or 400
    if g.clipboard and g.clipboard ~= "" then vim.opt.clipboard = g.clipboard end
    vim.opt.ignorecase = g.case_sensitive_search ~= true
  end)

  -- Packs: colours, font, editor preset, keybind preset
  Packs.apply_all()

  -- Custom keybinds added in Settings -> General
  for _, b in ipairs(g.custom_keybinds or {}) do
    if b.lhs and b.rhs then
      pcall(vim.keymap.set, b.mode or "n", b.lhs, b.rhs, { desc = b.desc or "custom", silent = true })
    end
  end
end

return M
