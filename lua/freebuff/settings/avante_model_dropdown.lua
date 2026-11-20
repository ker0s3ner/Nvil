-- freebuff/settings/avante_model_dropdown.lua
-- Model picker for the Avante chat. The old version stamped an inline virtual-text
-- "Model: …" on every keystroke without ever clearing it (clear_namespace(buf, ns, 0, 0)
-- clears nothing), so the text stacked up, and `attached` stopped it re-attaching after
-- the sidebar was closed. The picker is now a clickable winbar on the input window
-- (see plugins/avante-ui.lua); this module just supplies the model list and switching.

local M = {}

local Data = require("freebuff.settings.data")

--- Installed Ollama models (empty list when Ollama isn't running).
---@return table[]
function M.fetch_models()
  local res = vim.system({ "curl", "-s", "--max-time", "2", "http://127.0.0.1:11434/api/tags" }, { text = true }):wait()
  if res.code ~= 0 or not res.stdout or res.stdout == "" then return {} end
  local ok, data = pcall(vim.json.decode, res.stdout)
  if not ok or type(data) ~= "table" or not data.models then return {} end
  local models = {}
  for _, m in ipairs(data.models) do
    models[#models + 1] = { name = m.name, parameter_size = m.details and m.details.parameter_size or "" }
  end
  return models
end

---@return string
function M.current_model()
  local ok, Config = pcall(require, "avante.config")
  if not ok then return Data.get_value("ai.model") or "model" end
  local provider = Config.providers and Config.providers[Config.provider]
  return provider and provider.model or Data.get_value("ai.model") or "model"
end

--- Open the picker; `on_change` runs after a model was chosen.
function M.open_selector(on_change)
  local models = M.fetch_models()
  if #models == 0 then
    return vim.notify("No Ollama models found — is `ollama serve` running?", vim.log.levels.WARN, { title = "AI" })
  end
  local current = M.current_model()
  vim.ui.select(models, {
    prompt = "Select AI model",
    format_item = function(m)
      local mark = m.name == current and "● " or "  "
      return mark .. m.name .. (m.parameter_size ~= "" and ("  (" .. m.parameter_size .. ")") or "")
    end,
  }, function(choice)
    if not choice then return end
    Data.set("ai.model", choice.name)
    local ok, Config = pcall(require, "avante.config")
    if ok then
      pcall(Config.override, { providers = { ollama = { model = choice.name } } })
    end
    vim.notify("Model: " .. choice.name, vim.log.levels.INFO, { title = "AI" })
    if on_change then on_change() end
  end)
end

return M
