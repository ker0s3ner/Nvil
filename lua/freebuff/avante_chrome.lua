-- freebuff/avante_chrome.lua
-- Clean, clickable winbars for the Avante chat sidebar.
--
--   result window  winbar:   󰚩 AI ·························  󰭹 History   New   ✕
--   input window   winbar:    gemma4:e4b ▾ ·················  ⏎ send · ⇧⏎ newline
--
-- Colours come from freebuff/theme.lua (NvilChat* + Avante* groups).

local api = vim.api
local M = {}

local function valid(win) return win and api.nvim_win_is_valid(win) end

-- %@v:lua.fn@ click handlers need to be reachable as plain globals.
local function ensure_handlers()
  if _G._nvil_chat_model then return end
  local function run(c) return function() vim.schedule(function() pcall(vim.cmd, c) end) end end
  _G._nvil_chat_history = run("AvanteHistory")
  _G._nvil_chat_new = run("AvanteChatNew")
  _G._nvil_chat_close = run("AvanteToggle")
  _G._nvil_chat_model = function()
    vim.schedule(function()
      require("freebuff.settings.avante_model_dropdown").open_selector(function()
        local ok, avante = pcall(require, "avante")
        local sidebar = ok and avante.get and avante.get() or nil
        if sidebar then M.attach(sidebar) end
      end)
    end)
  end
end

local function btn(fn, text, hl)
  return ("%%@v:lua.%s@%%#%s#%s%%#NvilChatBar#%%X"):format(fn, hl or "NvilChatBtn", text)
end

--- (Re)build the winbars for the current sidebar. Safe to call repeatedly.
function M.attach(sidebar)
  if not sidebar or not sidebar.containers then return end
  ensure_handlers()

  local result = sidebar.containers.result and sidebar.containers.result.winid
  if valid(result) then
    api.nvim_set_option_value("winbar", table.concat({
      "%#NvilChatTitle#  󰚩 AI ",
      "%#NvilChatBar#%=",
      btn("_nvil_chat_history", " 󰭹 History "),
      "%#NvilChatBar# ",
      btn("_nvil_chat_new", "  New "),
      "%#NvilChatBar# ",
      btn("_nvil_chat_close", " ✕ "),
      "%#NvilChatBar# ",
    }), { win = result })
  end

  local input = sidebar.containers.input and sidebar.containers.input.winid
  if valid(input) then
    local model = (require("freebuff.settings.avante_model_dropdown").current_model():gsub("%%", "%%%%"))
    api.nvim_set_option_value("winbar", table.concat({
      btn("_nvil_chat_model", "  " .. model .. " ▾ ", "NvilChatBtnHot"),
      "%#NvilChatBar#%=",
      "%#NvilChatHint#⌘⏎ send (insert) · ⏎ send (normal) ",
    }), { win = input })
  end
end

return M
