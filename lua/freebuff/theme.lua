-- freebuff/theme.lua
-- One place that owns the accent colour of the whole UI (dashboard, Avante chat,
-- settings, bufferline, statusline-ish bits). Default pack is "crimson" (red).
-- Re-applied on every ColorScheme event so switching colorscheme never turns
-- the dashboard blue again.

local M = {}

--- Colour packs: accent + soft accent + backgrounds. Add your own here.
M.packs = {
  crimson = { label = "Crimson (red)",   accent = "#ff304f", soft = "#ff7a8a", dim = "#3a1018", bg = "#090909", float = "#111111", fg = "#f2f2f2" },
  ember   = { label = "Ember (orange)",  accent = "#ff8a30", soft = "#ffb070", dim = "#3a2010", bg = "#0a0907", float = "#12100d", fg = "#f2ede6" },
  violet  = { label = "Violet",          accent = "#a78bfa", soft = "#c4b5fd", dim = "#241a3d", bg = "#0a0910", float = "#110f1a", fg = "#ece8f5" },
  ocean   = { label = "Ocean (blue)",    accent = "#4aa3ff", soft = "#8cc4ff", dim = "#102338", bg = "#080a0d", float = "#0e1218", fg = "#e6eef7" },
  matrix  = { label = "Matrix (green)",  accent = "#3ddc84", soft = "#86efac", dim = "#0f2d1c", bg = "#070a08", float = "#0d130f", fg = "#e6f2ea" },
  mono    = { label = "Mono (white)",    accent = "#e5e5e5", soft = "#ffffff", dim = "#2a2a2a", bg = "#0a0a0a", float = "#141414", fg = "#e5e5e5" },
}
M.order = { "crimson", "ember", "violet", "ocean", "matrix", "mono" }

function M.current()
  local ok, Data = pcall(require, "freebuff.settings.data")
  local name = ok and Data.get_value("packs.color") or nil
  return M.packs[name or "crimson"] or M.packs.crimson, name or "crimson"
end

local function set(group, spec) vim.api.nvim_set_hl(0, group, spec) end

function M.apply()
  local p = M.current()

  -- Base editor chrome
  set("Normal", { fg = p.fg, bg = p.bg })
  set("NormalFloat", { fg = p.fg, bg = p.float })
  set("FloatBorder", { fg = p.accent, bg = p.float })
  set("FloatTitle", { fg = p.bg, bg = p.accent, bold = true })
  set("CursorLine", { bg = p.float })
  set("CursorLineNr", { fg = p.accent, bold = true })
  set("LineNr", { fg = "#666666" })
  set("Visual", { bg = p.dim })
  set("Search", { fg = p.bg, bg = p.accent, bold = true })
  set("IncSearch", { fg = p.bg, bg = p.soft, bold = true })
  set("WinSeparator", { fg = p.dim })
  set("Title", { fg = p.accent, bold = true })
  set("PmenuSel", { fg = p.bg, bg = p.accent })
  set("TabLineSel", { fg = p.bg, bg = p.accent, bold = true })

  -- Snacks dashboard: everything red (header, icons, labels, keys, footer)
  set("SnacksDashboardHeader", { fg = p.accent, bold = true })
  set("SnacksDashboardIcon", { fg = p.accent })
  set("SnacksDashboardDesc", { fg = p.fg })
  set("SnacksDashboardKey", { fg = p.accent, bold = true })
  set("SnacksDashboardFooter", { fg = p.accent, italic = true })
  set("SnacksDashboardTitle", { fg = p.accent, bold = true })
  set("SnacksDashboardSpecial", { fg = p.soft })
  set("SnacksDashboardDir", { fg = "#777777" })
  set("SnacksDashboardFile", { fg = p.fg })
  set("SnacksDashboardTerminal", { fg = p.accent })

  -- Avante chat sidebar
  set("AvanteTitle", { fg = p.bg, bg = p.accent, bold = true })
  set("AvanteReversedTitle", { fg = p.accent, bg = p.float })
  set("AvanteSubtitle", { fg = p.bg, bg = p.soft, bold = true })
  set("AvanteReversedSubtitle", { fg = p.soft, bg = p.float })
  set("AvanteThirdTitle", { fg = p.fg, bg = p.dim })
  set("AvanteReversedThirdTitle", { fg = p.dim, bg = p.float })
  set("AvanteSidebarNormal", { fg = p.fg, bg = p.float })
  set("AvanteSidebarWinSeparator", { fg = p.dim, bg = p.float })
  set("AvanteSidebarWinHorizontalSeparator", { fg = p.dim, bg = p.float })
  set("AvantePromptInput", { fg = p.fg, bg = p.bg })
  set("AvantePromptInputBorder", { fg = p.accent, bg = p.float })
  set("AvanteConfirmTitle", { fg = p.bg, bg = p.accent })
  set("AvanteStateSpinnerGenerating", { fg = p.bg, bg = p.accent })
  set("AvanteStateSpinnerThinking", { fg = p.bg, bg = p.soft })
  set("AvanteTaskRunning", { fg = p.soft })
  set("AvanteThinking", { fg = p.soft })
  set("AvanteInlineHint", { fg = p.accent })
  -- Our own chat-bar groups
  set("NvilChatBar", { fg = p.fg, bg = p.float })
  set("NvilChatTitle", { fg = p.bg, bg = p.accent, bold = true })
  set("NvilChatBtn", { fg = p.fg, bg = p.dim })
  set("NvilChatBtnHot", { fg = p.bg, bg = p.soft, bold = true })
  set("NvilChatHint", { fg = "#777777", bg = p.float })

  -- Settings UI
  set("FbSidebarActive", { fg = p.bg, bg = p.accent, bold = true })
  set("FbSidebarFg", { fg = "#8a8a8a", bg = p.float })
  set("FbSectionTitle", { fg = p.accent, bold = true })
  set("FbToggleOn", { fg = p.accent, bold = true })
  set("FbToggleOff", { fg = "#666666" })
  set("FbSettingDesc", { fg = "#777777" })
  set("FbHeaderBg", { fg = p.fg, bold = true })
  set("FbPackActive", { fg = p.accent, bold = true })
  set("FbHeatmap0", { fg = "#2a2a2a" })
  set("FbHeatmap1", { fg = p.dim })
  set("FbHeatmap2", { fg = p.accent })
  set("FbHeatmap3", { fg = p.soft })
  set("FbHeatmap4", { fg = "#ffffff" })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("freebuff_theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.apply })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "LazyVimStarted", callback = M.apply })
  M.apply()
end

return M
