-- freebuff/settings/data.lua
-- Settings data model with defaults and JSON file persistence.
-- Settings are stored at ~/.config/nvim/freebuff-settings.json

local M = {}

local settings_path = vim.fn.stdpath("config") .. "/freebuff-settings.json"

---@class FreebuffSettings
local defaults = {
  -- ── Appearance ──────────────────────────────────────────────────
  appearance = {
    colorscheme = "tokyonight-storm",
    transparent = false,
    font_size = 14,
    font_family = "",
    show_line_numbers = true,
    show_relative_line_numbers = true,
    show_sign_column = true,
    cursorline = true,
    cursorcolumn = false,
    termguicolors = true,
    statusline = "default",
    winbar = true,
    show_tabline = true,
    anim_duration = 200,
  },

  -- ── Usage / Stats ───────────────────────────────────────────────
  usage = {
    show_heatmap = true,
    session_count = 0,
    total_time_seconds = 0,
    total_ai_tokens = 0,
    total_chats = 0,
    -- Per-day activity for heatmap (YYYY-MM-DD = count)
    daily_activity = {},
  },

  -- ── AI / Avante ─────────────────────────────────────────────────
  ai = {
    provider = "ollama",
    model = "gemma4:e4b",
    system_prompt = [[You are a code assistant. Help with software engineering tasks: fixing bugs, adding functionality, refactoring, and explaining code. Be concise and helpful.]],
    temperature = 0.6,
    context_window = 32768,
    max_tokens = 4096,
    auto_suggestions = false,
    auto_apply_diff = false,
    agentic_mode = true,
    agent_prompt = "You are an autonomous coding agent. Analyze the codebase, make changes, and verify your work.",
    tools = {
      read_file = true,
      write_file = true,
      edit_file = true,
      run_terminal = true,
      search_code = true,
    },
  },

  -- ── Git ─────────────────────────────────────────────────────────
  git = {
    provider = "",       -- "github", "gitlab", ""
    token = "",
    username = "",
    default_branch = "main",
    auto_fetch = false,
    show_status_in_statusline = true,
    sign_commits = true,
  },

  -- ── Browser & Network ──────────────────────────────────────────
  browser = {
    default_browser = "",      -- empty = system default
    localhost_port = 3000,
    auto_open_preview = false,
    markdown_preview_theme = "dark",
    webview_enabled = false,
    webview_width = 80,
    webview_height = 40,
  },

  -- ── General / Keybinds ─────────────────────────────────────────
  general = {
    leader = " ",
    local_leader = "\\",
    timeout_len = 400,
    mouse = "a",
    clipboard = "unnamedplus",
    spell = false,
    wrap = false,
    case_sensitive_search = false,
    -- Custom keybinds: { mode, lhs, rhs, desc }
    custom_keybinds = {},
  },

  -- ── Docs ────────────────────────────────────────────────────────
  docs = {
    last_read_section = "",
    show_welcome = true,
  },
}

--- Merge user settings with defaults (shallow per section)
---@param user? table
---@return FreebuffSettings
function M.load(user)
  local result = vim.deepcopy(defaults)
  if user then
    for section, values in pairs(user) do
      if type(values) == "table" and result[section] then
        result[section] = vim.tbl_deep_extend("force", result[section], values)
      end
    end
  end
  return result
end

--- Read settings from disk
---@return FreebuffSettings
function M.read()
  local f = io.open(settings_path, "r")
  if not f then return M.load() end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then return M.load() end
  local ok, data = pcall(vim.json.decode, content)
  if not ok then return M.load() end
  return M.load(data)
end

--- Write settings to disk
---@param settings FreebuffSettings
function M.write(settings)
  local f = io.open(settings_path, "w")
  if not f then
    vim.notify("Failed to write settings to " .. settings_path, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(settings))
  f:close()
end

--- Get the current settings (cached in module)
M.current = nil

--- Get or load current settings
---@return FreebuffSettings
function M.get()
  if not M.current then M.current = M.read() end
  return M.current
end

--- Save current settings to disk
function M.save()
  if M.current then M.write(M.current) end
end

--- Update a specific setting path like "ai.model" and save
---@param path string Dot-separated path (e.g. "ai.model")
---@param value any
function M.set(path, value)
  local settings = M.get()
  local parts = vim.split(path, ".", { plain = true })
  local obj = settings
  for i = 1, #parts - 1 do
    obj = obj[parts[i]]
    if not obj then return end
  end
  obj[parts[#parts]] = value
  M.save()
end

--- Get a value by dot path
---@param path string
---@return any
function M.get_value(path)
  local settings = M.get()
  local parts = vim.split(path, ".", { plain = true })
  local obj = settings
  for _, part in ipairs(parts) do
    obj = obj[part]
    if obj == nil then return nil end
  end
  return obj
end

--- Record an activity event (call on startup, chat, etc.)
function M.record_activity()
  local settings = M.get()
  local today = os.date("%Y-%m-%d")
  settings.usage.daily_activity[today] = (settings.usage.daily_activity[today] or 0) + 1
  settings.usage.session_count = (settings.usage.session_count or 0) + 1
  M.save()
end

--- Record AI token usage
---@param tokens number
function M.record_tokens(tokens)
  local settings = M.get()
  settings.usage.total_ai_tokens = (settings.usage.total_ai_tokens or 0) + tokens
  M.save()
end

--- Record a chat
function M.record_chat()
  local settings = M.get()
  settings.usage.total_chats = (settings.usage.total_chats or 0) + 1
  M.save()
end

--- Get available colorschemes
---@return string[]
function M.get_colorschemes()
  local schemes = {}
  local seen = {}
  -- Only scan directories that actually exist
  local paths = vim.api.nvim_list_runtime_paths()
  for _, base in ipairs(paths) do
    local colors_dir = base .. "/colors"
    if vim.fn.isdirectory(colors_dir) == 1 then
      local ok, files = pcall(vim.fn.readdir, colors_dir)
      if ok and type(files) == "table" then
        for _, f in ipairs(files) do
          if f and (f:match("%.vim$") or f:match("%.lua$")) then
            local name = f:gsub("%.vim$", ""):gsub("%.lua$", "")
            if name ~= "" and not seen[name] then
              seen[name] = true
              schemes[#schemes + 1] = name
            end
          end
        end
      end
    end
  end
  table.sort(schemes)
  return schemes
end

--- Get installed Ollama models
---@return table[] List of {name, size, parameter_size}
function M.get_ollama_models()
  local models = {}
  local result = vim.fn.system("curl -s http://127.0.0.1:11434/api/tags 2>/dev/null")
  if vim.v.shell_error ~= 0 then return models end
  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data.models then return models end
  for _, m in ipairs(data.models) do
    table.insert(models, {
      name = m.name,
      size = m.size,
      parameter_size = m.details and m.details.parameter_size or "",
      context_length = m.details and m.details.context_length or 0,
    })
  end
  return models
end

return M
