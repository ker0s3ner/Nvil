-- Avante UI enhancements: clickable buttons in the sidebar header.
--
-- Adds:
--   • Chat / Model buttons in the result-window winbar (clickable with mouse)
--   • Sends button in the input area via virtual text
--
-- Model dropdown in the input area is handled by freebuff/settings/avante_model_dropdown.lua

local api = vim.api
local Config = require("avante.config")
local Highlights = require("avante.highlights")

local NS = api.nvim_create_namespace("avante_ui_buttons")

---@return string
local function current_model_label()
  local provider = Config.providers[Config.provider]
  if not provider then return "Model" end
  local model = provider.model or "unknown"
  local short = model:match("^([^:]+)") or model
  return short
end

--- Build the winbar for the result window: "  Chat  |  Model"
local function setup_result_winbar(sidebar)
  if not sidebar or not sidebar.containers.result then return end
  local winid = sidebar.containers.result.winid
  if not winid or not api.nvim_win_is_valid(winid) then return end

  if not _G._avante_ui_click_chat then
    _G._avante_ui_click_chat = function()
      vim.schedule(function()
        local ok, avante_api = pcall(require, "avante.api")
        if ok then avante_api.select_history() end
      end)
    end
  end
  if not _G._avante_ui_click_model then
    _G._avante_ui_click_model = function()
      vim.schedule(function()
        local ok, model_selector = pcall(require, "avante.model_selector")
        if ok then model_selector.open(true) end
      end)
    end
  end

  local hl = Highlights.TITLE
  local sep = Highlights.AVANTE_SIDEBAR_WIN_HORIZONTAL_SEPARATOR

  local function fmt(text, highlight) return "%#" .. highlight .. "#" .. text end

  local chat_btn = fmt("  Chat ", hl)
  local model_label = current_model_label()
  local model_btn = fmt("  " .. model_label .. " ", hl)

  local winbar = ""
    .. fmt(" %= ", sep)
    .. "%@v:lua._avante_ui_click_chat@" .. chat_btn .. "%X"
    .. "  "
    .. "%@v:lua._avante_ui_click_model@" .. model_btn .. "%X"
    .. fmt(" %= ", sep)

  api.nvim_set_option_value("winbar", winbar, { win = winid })
end

--- Wire up button rendering after the sidebar opens / content updates.
local function attach(sidebar)
  if not sidebar then return end

  vim.schedule(function()
    setup_result_winbar(sidebar)
  end)
end

return {
  {
    "yetone/avante.nvim",
    opts = function(_, opts)
      local existing_post = opts.sidebar_post_render
      opts.sidebar_post_render = function(sidebar)
        if existing_post then existing_post(sidebar) end
        attach(sidebar)
      end
    end,
  },
}
