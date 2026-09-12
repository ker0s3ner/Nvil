-- freebuff/settings/avante_model_dropdown.lua
-- Adds a clickable model selector row above the Avante input area.
-- Fetches available Ollama models via the API and lets users switch
-- by clicking or pressing Enter on the selector line.

local api = vim.api
local Data = require("freebuff.settings.data")

local M = {}

local NS = api.nvim_create_namespace("freebuff_model_dropdown")
local attached = false

--- Fetch Ollama models from the API
---@return table[] List of {name, parameter_size, context_length}
local function fetch_models()
  local result = vim.fn.system("curl -s http://127.0.0.1:11434/api/tags 2>/dev/null")
  if vim.v.shell_error ~= 0 then return {} end
  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data.models then return {} end
  local models = {}
  for _, m in ipairs(data.models) do
    table.insert(models, {
      name = m.name,
      parameter_size = m.details and m.details.parameter_size or "",
      context_length = m.details and m.details.context_length or 0,
    })
  end
  return models
end

--- Get the current model name from Avante config
---@return string
local function get_current_model()
  local ok, Config = pcall(require, "avante.config")
  if not ok then return "unknown" end
  local provider = Config.providers[Config.provider]
  if not provider then return "unknown" end
  return provider.model or "unknown"
end

--- Render the model selector line as virtual text above the input
---@param sidebar table
local function render_model_selector(sidebar)
  if not sidebar or not sidebar.containers.input then return end
  local input = sidebar.containers.input
  if not input.bufnr or not api.nvim_buf_is_valid(input.bufnr) then return end

  -- Clear previous extmarks
  api.nvim_buf_clear_namespace(input.bufnr, NS, 0, 0)

  -- Show the current model with a dropdown indicator
  local model_name = get_current_model()
  local line = "  Model:  " .. model_name .. "  ▾"

  api.nvim_buf_set_extmark(input.bufnr, NS, 0, 0, {
    virt_text = { { line, "AvanteTitle" } },
    virt_text_pos = "inline",
    virt_text_win_hl = true,
  })
end

--- Open a model selection popup
local function open_model_selector()
  local models = fetch_models()

  if #models == 0 then
    vim.notify("No Ollama models found. Make sure Ollama is running.", vim.log.levels.WARN)
    return
  end

  local items = {}
  local values = {}
  for _, m in ipairs(models) do
    local label = m.name
    if m.parameter_size ~= "" then
      label = label .. "  (" .. m.parameter_size .. ")"
    end
    table.insert(items, label)
    table.insert(values, m.name)
  end

  vim.ui.select(items, {
    prompt = "Select AI Model",
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and idx then
      local model_name = values[idx]

      -- Update Freebuff settings
      Data.set("ai.model", model_name)

      -- Update Avante config
      local ok, Config = pcall(require, "avante.config")
      if ok then
        pcall(function()
          Config.override({
            providers = {
              ollama = { model = model_name },
            },
          })
        end)
      end

      -- Update sidebar header if it shows the model
      local sidebar_ok, avante = pcall(require, "avante")
      if sidebar_ok then
        local sidebar = avante.get()
        if sidebar and sidebar:is_open() then
          sidebar:render_result()
        end
      end

      vim.notify("Switched to model: " .. model_name, vim.log.levels.INFO)
    end
  end)
end

--- Attach the model selector to the Avante sidebar
---@param sidebar table
function M.attach(sidebar)
  if not sidebar then return end
  if attached then return end
  attached = true

  -- Render the model selector after sidebar opens
  vim.schedule(function()
    render_model_selector(sidebar)
  end)

  -- Re-render on content changes
  if sidebar.containers.input and sidebar.containers.input.bufnr then
    api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
      group = api.nvim_create_augroup("freebuff_model_dropdown", { clear = true }),
      buffer = sidebar.containers.input.bufnr,
      callback = function()
        vim.schedule(function()
          render_model_selector(sidebar)
        end)
      end,
    })

    -- Keymap: <leader>m on the input buffer opens the model selector
    api.nvim_buf_set_keymap(sidebar.containers.input.bufnr, "n", "<leader>m", "", {
      callback = function() open_model_selector() end,
      desc = "Switch AI Model",
      noremap = true,
      silent = true,
    })

    -- Mouse click on the model line opens the selector
    api.nvim_buf_set_keymap(sidebar.containers.input.bufnr, "n", "<LeftMouse>", "", {
      callback = function()
        local pos = vim.fn.getmousepos()
        -- Only trigger if clicking near the start of line 0 (where model text is)
        if pos.line == 1 and pos.column <= 40 then
          vim.schedule(function() open_model_selector() end)
        end
      end,
      desc = "Click model selector",
      noremap = true,
      silent = true,
    })
  end
end

--- Detach from sidebar (called on close)
function M.detach()
  attached = false
end

return M
