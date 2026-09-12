-- Autocmds are loaded on the VeryLazy event.
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Cursor-style chrome: file tree on the left, Avante chat on the right,
-- tab line on top. Opens for real files without stealing focus.
local skip_ft = {
  ["neo-tree"] = true,
  Avante = true,
  AvanteInput = true,
  AvanteSelectedFiles = true,
  AvanteSelectedCode = true,
  snacks_dashboard = true,
  snacks_picker_input = true,
  lazy = true,
  mason = true,
  TelescopePrompt = true,
  help = true,
  qf = true,
}

local layout_pending = false

local function is_editable_file(buf)
  buf = buf or 0
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if not vim.bo[buf].buflisted then
    return false
  end
  if skip_ft[vim.bo[buf].filetype] then
    return false
  end
  return true
end

local function ensure_ide_layout(buf)
  if layout_pending then
    return
  end
  layout_pending = true
  vim.schedule(function()
    layout_pending = false
    if not is_editable_file(buf) then
      buf = vim.api.nvim_get_current_buf()
      if not is_editable_file(buf) then
        return
      end
    end

    local win = vim.api.nvim_get_current_win()
    vim.o.showtabline = 2

    pcall(function()
      require("neo-tree.command").execute({
        action = "show",
        source = "filesystem",
        position = "left",
        reveal = true,
      })
    end)

    pcall(function()
      local avante = require("avante")
      if not avante.is_sidebar_open() then
        avante.open_sidebar({ ask = false })
      end
    end)

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end)
end

autocmd({ "VimEnter", "BufNewFile", "BufReadPost", "BufWinEnter" }, {
  group = augroup("ide_layout", { clear = true }),
  callback = function(event)
    ensure_ide_layout(event.buf)
  end,
})

-- This file loads on VeryLazy, after the first file's VimEnter/BufRead.
-- Open the layout for whatever is already on screen.
ensure_ide_layout(vim.api.nvim_get_current_buf())
