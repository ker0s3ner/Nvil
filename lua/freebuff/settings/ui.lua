-- freebuff/settings/ui.lua — Settings UI: sidebar + content pages, full TUI.

local api = vim.api
local Data = require("freebuff.settings.data")
local M = {}

local NS = api.nvim_create_namespace("freebuff_settings")

local hl = {
  SidebarActive = "FbSidebarActive", SidebarFg = "FbSidebarFg",
  SectionTitle = "FbSectionTitle", ToggleOn = "FbToggleOn", ToggleOff = "FbToggleOff",
  SettingDesc = "FbSettingDesc", HeaderBg = "FbHeaderBg",
  Heatmap0 = "FbHeatmap0", Heatmap1 = "FbHeatmap1", Heatmap2 = "FbHeatmap2",
  Heatmap3 = "FbHeatmap3", Heatmap4 = "FbHeatmap4",
}

local function setup_highlights()
  local fg = api.nvim_get_hl(0, { name = "Normal" }).fg or "#c0caf5"
  api.nvim_set_hl(0, hl.SidebarActive, { bg = "#24283b", fg = "#7aa2f7", bold = true })
  api.nvim_set_hl(0, hl.SidebarFg, { bg = "#13141c", fg = "#787c99" })
  api.nvim_set_hl(0, hl.SectionTitle, { fg = "#565f89", bold = true })
  api.nvim_set_hl(0, hl.ToggleOn, { fg = "#9ece6a", bold = true })
  api.nvim_set_hl(0, hl.ToggleOff, { fg = "#565f89" })
  api.nvim_set_hl(0, hl.SettingDesc, { fg = "#565f89" })
  api.nvim_set_hl(0, hl.HeaderBg, { fg = fg, bold = true })
  api.nvim_set_hl(0, hl.Heatmap0, { fg = "#3b4261" })
  api.nvim_set_hl(0, hl.Heatmap1, { fg = "#1a5c2e" })
  api.nvim_set_hl(0, hl.Heatmap2, { fg = "#2d8a4e" })
  api.nvim_set_hl(0, hl.Heatmap3, { fg = "#4ade80" })
  api.nvim_set_hl(0, hl.Heatmap4, { fg = "#86efac" })
end

local state = {
  winid = nil, bufnr = nil,
  sidebar_winid = nil, sidebar_bufnr = nil,
  current_page = "appearance",
  row_map = {}, sidebar_items = {},
}

-- ── Pages ───────────────────────────────────────────────────────────────────

local pages = {}

pages[#pages + 1] = {
  id = "appearance", icon = "", label = "Appearance",
  build = function()
    local opts = {}
    for _, name in ipairs(Data.get_colorschemes()) do
      opts[#opts + 1] = { label = name, value = name }
    end
    if #opts == 0 then
      opts = { { label = "tokyonight-storm", value = "tokyonight-storm" },
               { label = "catppuccin-mocha", value = "catppuccin-mocha" },
               { label = "rose-pine", value = "rose-pine" } }
    end
    return {
      { "section", "Theme" },
      { "dropdown", "appearance.colorscheme", "Color Scheme", "Colorscheme for the editor", opts },
      { "toggle", "appearance.transparent", "Transparent Background", "Remove background for terminal transparency" },
      { "section", "Font" },
      { "slider", "appearance.font_size", "Font Size", "Editor font size", 8, 32, 1, "%dpx" },
      { "input", "appearance.font_family", "Font Family", "Custom font name (empty = default)" },
      { "section", "Editor" },
      { "toggle", "appearance.show_line_numbers", "Line Numbers", "Show line numbers" },
      { "toggle", "appearance.show_relative_line_numbers", "Relative Numbers", "Show relative line numbers" },
      { "toggle", "appearance.show_sign_column", "Sign Column", "Always show sign column" },
      { "toggle", "appearance.cursorline", "Cursor Line", "Highlight current line" },
      { "toggle", "appearance.cursorcolumn", "Cursor Column", "Highlight current column" },
      { "toggle", "appearance.termguicolors", "True Color", "Enable 24-bit RGB colors" },
      { "toggle", "appearance.winbar", "Winbar", "Show window bar" },
      { "toggle", "appearance.show_tabline", "Tab Line", "Show buffer tab line" },
      { "slider", "appearance.anim_duration", "Animation Duration", "UI animation duration (ms)", 0, 1000, 50, "%dms" },
    }
  end,
}

-- ── Usage page with real heatmap ────────────────────────────────────────────

local function build_heatmap_lines(daily_activity)
  local lines = {}  -- each element is a table of {text, hl} segments for one line
  local today = os.date("*t")
  local today_epoch = os.time(today)
  local blocks = { " ", " ", " ", " ", " " }
  local hls = { hl.Heatmap0, hl.Heatmap1, hl.Heatmap2, hl.Heatmap3, hl.Heatmap4 }

  -- Build 7 rows (Mon-Sun), 52 columns (weeks)
  local grid = {}
  for d = 1, 7 do grid[d] = {} end
  local max_count = 1
  for day_offset = 364, 0, -1 do
    local d = os.date("*t", today_epoch - day_offset * 86400)
    local key = os.date("%Y-%m-%d", os.time(d))
    local count = daily_activity[key] or 0
    if count > max_count then max_count = count end
    local week = math.floor((364 - day_offset) / 7) + 1
    grid[d.wday][week] = count
  end

  -- Day labels
  local day_labels = { "Mon", "", "Wed", "", "Fri", "", "" }
  for row = 1, 7 do
    local segs = {}
    segs[#segs + 1] = { string.format("%-3s", day_labels[row]), hl.SidebarFg }
    segs[#segs + 1] = { "  ", "" }
    for col = 1, 52 do
      local count = grid[row][col] or 0
      local level = 0
      if count > 0 then
        local ratio = count / max_count
        if ratio < 0.25 then level = 1
        elseif ratio < 0.5 then level = 2
        elseif ratio < 0.75 then level = 3
        else level = 4 end
      end
      segs[#segs + 1] = { blocks[level + 1], hls[level + 1] }
    end
    lines[#lines + 1] = segs
  end
  return lines
end

pages[#pages + 1] = {
  id = "usage", icon = "", label = "Usage",
  build = function()
    local u = Data.get().usage or {}
    local items = {
      { "section", "Overview" },
      { "display", "Sessions", tostring(u.session_count or 0) .. " total sessions" },
      { "display", "AI Chats", tostring(u.total_chats or 0) .. " conversations" },
      { "display", "AI Tokens Used", tostring(u.total_ai_tokens or 0) .. " tokens" },
    }
    local hrs = math.floor((u.total_time_seconds or 0) / 3600)
    local mins = math.floor(((u.total_time_seconds or 0) % 3600) / 60)
    items[#items + 1] = { "display", "Time in Editor", hrs .. "h " .. mins .. "m" }
    items[#items + 1] = { "section", "Activity (Last 52 Weeks)" }
    local total = 0
    for _, c in pairs(u.daily_activity or {}) do total = total + c end
    items[#items + 1] = { "heatmap", total }
    items[#items + 1] = { "toggle", "usage.show_heatmap", "Show on Dashboard", "Display heatmap on start screen" }
    return items
  end,
}

-- ── AI page with multiple prompts ───────────────────────────────────────────

pages[#pages + 1] = {
  id = "ai", icon = "", label = "AI",
  build = function()
    local models = Data.get_ollama_models()
    local model_opts = {}
    for _, m in ipairs(models) do
      model_opts[#model_opts + 1] = { label = m.name .. " (" .. m.parameter_size .. ")", value = m.name }
    end
    if #model_opts == 0 then
      model_opts = { { label = "No Ollama models found", value = "" } }
    end
    local items = {
      { "section", "Provider" },
      { "dropdown", "ai.provider", "Provider", "AI provider backend", {
        { label = "Ollama (Local)", value = "ollama" },
        { label = "OpenAI", value = "openai" },
        { label = "Anthropic", value = "anthropic" },
        { label = "Copilot", value = "copilot" },
      }},
      { "dropdown", "ai.model", "Model", "AI model for chat and code", model_opts },
      { "section", "Behavior" },
      { "toggle", "ai.agentic_mode", "Agentic Mode", "Allow AI to read/edit files and run commands" },
      { "toggle", "ai.auto_suggestions", "Auto Suggestions", "Ghost-text as you type" },
      { "toggle", "ai.auto_apply_diff", "Auto Apply Diffs", "Apply diffs without review" },
      { "section", "Generation" },
      { "slider", "ai.temperature", "Temperature", "Creativity (0=deterministic, 1=creative)", 0, 2, 0.1, "%.1f" },
      { "slider", "ai.context_window", "Context Window", "Max context tokens", 4096, 131072, 4096, "%d" },
      { "slider", "ai.max_tokens", "Max Output", "Max response tokens", 256, 16384, 256, "%d" },
    }

    -- Master prompts (multiple, user selects active)
    items[#items + 1] = { "section", "Master Prompts" }
    local prompts = Data.get_value("ai.master_prompts") or {}
    if #prompts == 0 then
      -- Initialize with default
      prompts = { { name = "Default", text = Data.get_value("ai.system_prompt") or "You are a helpful code assistant.", active = true } }
      Data.set("ai.master_prompts", prompts)
    end
    for i, p in ipairs(prompts) do
      local mark = p.active and "● " or "○ "
      items[#items + 1] = { "prompt_item", "ai.master_prompts", i, mark .. p.name, p.text }
    end
    items[#items + 1] = { "button", nil, "+ Add Master Prompt", "Create a new system prompt preset",
      function() M._add_prompt("ai.master_prompts", "Master Prompt") end }

    -- Agent prompts (multiple, user selects active)
    items[#items + 1] = { "section", "Agent Prompts" }
    local agent_prompts = Data.get_value("ai.agent_prompts") or {}
    if #agent_prompts == 0 then
      agent_prompts = { { name = "Default", text = Data.get_value("ai.agent_prompt") or "You are an autonomous coding agent.", active = true } }
      Data.set("ai.agent_prompts", agent_prompts)
    end
    for i, p in ipairs(agent_prompts) do
      local mark = p.active and "● " or "○ "
      items[#items + 1] = { "prompt_item", "ai.agent_prompts", i, mark .. p.name, p.text }
    end
    items[#items + 1] = { "button", nil, "+ Add Agent Prompt", "Create a new agent prompt preset",
      function() M._add_prompt("ai.agent_prompts", "Agent Prompt") end }

    -- Tools
    items[#items + 1] = { "section", "Tools" }
    items[#items + 1] = { "toggle", "ai.tools.read_file", "Read Files", "Allow reading file contents" }
    items[#items + 1] = { "toggle", "ai.tools.write_file", "Write Files", "Allow creating/overwriting files" }
    items[#items + 1] = { "toggle", "ai.tools.edit_file", "Edit Files", "Allow editing existing files" }
    items[#items + 1] = { "toggle", "ai.tools.run_terminal", "Terminal Commands", "Allow executing shell commands" }
    items[#items + 1] = { "toggle", "ai.tools.search_code", "Search Code", "Allow searching the codebase" }
    return items
  end,
}

-- ── Git page ────────────────────────────────────────────────────────────────

pages[#pages + 1] = {
  id = "git", icon = "", label = "Git",
  build = function()
    return {
      { "section", "Account" },
      { "dropdown", "git.provider", "Provider", "Git hosting platform", {
        { label = "None", value = "" }, { label = "GitHub", value = "github" }, { label = "GitLab", value = "gitlab" },
      }},
      { "input", "git.username", "Username", "Your Git hosting username" },
      { "input", "git.token", "Access Token", "Personal access token (stored locally)" },
      { "section", "Behavior" },
      { "input", "git.default_branch", "Default Branch", "Branch for new repos" },
      { "toggle", "git.auto_fetch", "Auto Fetch", "Fetch on startup" },
      { "toggle", "git.show_status_in_statusline", "Status in Statusline", "Show branch/diff stats" },
      { "toggle", "git.sign_commits", "GPG Sign Commits", "Sign commits with GPG" },
    }
  end,
}

-- ── Browser & Network page ──────────────────────────────────────────────────

pages[#pages + 1] = {
  id = "browser", icon = "", label = "Browser & Network",
  build = function()
    return {
      { "section", "Browser" },
      { "input", "browser.default_browser", "Default Browser", "Browser command (empty = system default)" },
      { "toggle", "browser.auto_open_preview", "Auto Open Preview", "Open markdown preview on open" },
      { "dropdown", "browser.markdown_preview_theme", "Preview Theme", "Markdown preview theme", {
        { label = "Dark", value = "dark" }, { label = "Light", value = "light" },
      }},
      { "section", "Web Rendering" },
      { "display", "Note", "Full Chromium rendering is not available in Neovim. Options: open in system browser (recommended), or w3m text browser." },
      { "toggle", "browser.webview_enabled", "Enable w3m Text Browser", "Render pages as text inside Neovim (requires w3m installed)" },
      { "section", "Dev Server" },
      { "slider", "browser.localhost_port", "Default Port", "Default localhost port", 1000, 65535, 1, ":%d" },
    }
  end,
}

-- ── General page with grouped keybinds ──────────────────────────────────────

pages[#pages + 1] = {
  id = "general", icon = "", label = "General",
  build = function()
    local items = {
      { "section", "Core" },
      { "input", "general.leader", "Leader Key", "Global leader key" },
      { "input", "general.local_leader", "Local Leader", "Buffer-local leader key" },
      { "slider", "general.timeout_len", "Timeout Length", "Wait for mapped sequence (ms)", 100, 3000, 100, "%dms" },
      { "section", "Input" },
      { "dropdown", "general.mouse", "Mouse", "Mouse support", {
        { label = "All Modes", value = "a" }, { label = "Normal Only", value = "n" },
        { label = "Disabled", value = "" },
      }},
      { "input", "general.clipboard", "Clipboard", "System clipboard" },
      { "toggle", "general.spell", "Spell Check", "Enable spell checking" },
      { "toggle", "general.wrap", "Line Wrap", "Wrap long lines" },
    }

    -- Keybinds grouped by category
    local kb_groups = {
      { name = "File & Navigation", binds = {
        { "n", "<leader>e", "File Explorer", "Neo-tree" },
        { "n", "<leader>fi", "Find Item", "Files & folders" },
        { "n", "<leader>sg", "Search Text", "Live grep" },
        { "n", "<leader>fr", "Recent Files", "Old files" },
        { "n", "<leader>fw", "Settings", "Open settings" },
      }},
      { name = "AI / Avante", binds = {
        { "n", "<leader>aa", "AI Chat", "Open sidebar" },
        { "n", "<leader>ar", "AI Refresh", "Refresh sidebar" },
        { "n", "<leader>at", "Toggle AI", "Toggle sidebar" },
        { "n", "<leader>a?", "Select Model", "Switch AI model" },
        { "n", "<leader>ah", "Chat History", "Browse past chats" },
      }},
      { name = "Git", binds = {
        { "n", "<leader>gn", "Neogit", "Open Neogit" },
      }},
      { name = "Window & Buffer", binds = {
        { "n", "<leader>bd", "Close Buffer", "Delete buffer" },
        { "n", "<leader>bp", "Toggle Pin", "Pin buffer" },
        { "n", "<leader>ft", "Terminal", "Floating terminal" },
        { "n", "<leader>mp", "Markdown Preview", "Live preview in browser" },
        { "n", "<leader>l", "Lazy", "Package manager" },
        { "n", "<leader>qs", "Restore Session", "Restore session" },
      }},
    }

    items[#items + 1] = { "section", "Keybindings" }
    for _, group in ipairs(kb_groups) do
      items[#items + 1] = { "keybind_group", group.name, group.binds }
    end
    items[#items + 1] = { "button", nil, "+ Add Custom Keybind", "Create a new keybind",
      function() M._add_keybind() end }

    -- Show user custom keybinds
    local kb = Data.get_value("general.custom_keybinds") or {}
    if #kb > 0 then
      items[#items + 1] = { "section", "Custom Keybinds" }
      for i, bind in ipairs(kb) do
        items[#items + 1] = { "button", nil,
          (bind.mode or "n") .. " " .. (bind.lhs or "?") .. " → " .. (bind.desc or bind.rhs or ""),
          "Click to remove",
          function()
            local new_kb = {}
            for j, b in ipairs(kb) do if j ~= i then new_kb[#new_kb + 1] = b end end
            Data.set("general.custom_keybinds", new_kb)
            render_content()
          end,
        }
      end
    end
    return items
  end,
}

-- ── Docs page ───────────────────────────────────────────────────────────────

pages[#pages + 1] = {
  id = "docs", icon = "", label = "Docs",
  build = function()
    return {
      { "header", "Welcome to Freebuff" },
      { "section", "Quick Start" },
      { "display", "Navigation", "<Space>e explorer, <Space>fi find, <Space>sg search" },
      { "display", "AI Chat", "<Space>aa sidebar, <D-cr> send" },
      { "display", "Terminal", "<Space>ft floating terminal" },
      { "display", "Git", "<Space>gn Neogit" },
      { "display", "Sessions", "<Space>qs restore, <Space>ql last" },
      { "section", "Shortcuts" },
      { "display", "<Space> fi", "Find Item (files & folders)" },
      { "display", "<Space> sg", "Search text" },
      { "display", "<Space> e",  "File Explorer" },
      { "display", "<Space> aa", "AI Chat" },
      { "display", "<Space> fw", "Settings" },
      { "display", "<Space> l",  "Lazy" },
      { "section", "About" },
      { "display", "Freebuff", "Neovim config — Cursor-like AI, full local control" },
      { "display", "Provider", "Ollama + Gemma 4 — no API keys" },
      { "toggle", "docs.show_welcome", "Show Welcome on Startup", "Welcome message on launch" },
    }
  end,
}

-- ── Rendering helpers ───────────────────────────────────────────────────────

local function parse_item(raw) return raw[1], raw[2], raw[3], raw[4], unpack(raw, 5) end

local heatmap_lines_cache = nil  -- cached heatmap {text, hl} segments per line

function render_content()
  if not state.bufnr or not api.nvim_buf_is_valid(state.bufnr) then return end

  local page_def
  for _, p in ipairs(pages) do if p.id == state.current_page then page_def = p; break end end
  if not page_def then return end

  local items = page_def.build()
  local lines = {}
  local line_hls = {}  -- line_hls[line_idx] = { {hl, col_start, col_end}, ... }
  state.row_map = {}
  heatmap_lines_cache = nil

  -- Row 1: header
  lines[#lines + 1] = "  ← Back      " .. page_def.icon .. "  " .. page_def.label
  line_hls[1] = {}
  lines[#lines + 1] = ""
  line_hls[2] = {}

  local row = 3

  for _, raw in ipairs(items) do
    local tp, key, name, desc = parse_item(raw)

    if tp == "header" then
      lines[#lines + 1] = ""; line_hls[#lines] = {}
      lines[#lines + 1] = "  " .. (name or ""); line_hls[#lines] = {}
      lines[#lines + 1] = ""; line_hls[#lines] = {}
      row = row + 3

    elseif tp == "section" then
      lines[#lines + 1] = ""; line_hls[#lines] = {}
      lines[#lines + 1] = "  " .. string.upper(name or ""); line_hls[#lines] = {}
      lines[#lines + 1] = ""; line_hls[#lines] = {}
      row = row + 3

    elseif tp == "toggle" then
      local on = Data.get_value(key) == true
      lines[#lines + 1] = "  " .. (on and "●" or "○") .. "  " .. (name or "")
      state.row_map[row] = { type = "toggle", key = key, item = raw }
      row = row + 1
      if desc and #desc > 0 then lines[#lines + 1] = "    " .. desc; row = row + 1 end
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "slider" then
      local val = Data.get_value(key) or raw[5] or 0
      local smin, smax, sstep, sfmt = raw[5], raw[6], raw[7], raw[8]
      local ratio = (smax and smin) and math.max(0, math.min(1, (val - smin) / (smax - smin))) or 0
      local bw, fill = 20, math.floor(ratio * 20)
      local bar = ""
      for i = 1, bw do
        if i <= fill then bar = bar .. "━"
        elseif i == fill + 1 then bar = bar .. "●"
        else bar = bar .. "─" end
      end
      local label = sfmt and string.format(sfmt, val) or tostring(val)
      lines[#lines + 1] = "  " .. bar .. "  " .. (name or "") .. ": " .. label
      state.row_map[row] = { type = "slider", key = key, item = raw }
      row = row + 1
      if desc and #desc > 0 then lines[#lines + 1] = "    " .. desc; row = row + 1 end
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "dropdown" then
      local val = Data.get_value(key)
      local display = val or "None"
      local opts = raw[5]
      if opts then for _, o in ipairs(opts) do if o.value == val then display = o.label; break end end end
      lines[#lines + 1] = "  " .. (name or "") .. ":  " .. display .. "  ▾"
      state.row_map[row] = { type = "dropdown", key = key, item = raw }
      row = row + 1
      if desc and #desc > 0 then lines[#lines + 1] = "    " .. desc; row = row + 1 end
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "input" then
      local val = Data.get_value(key) or ""
      local display = #val > 50 and val:sub(1, 47) .. "..." or val
      if #display == 0 then display = "(empty)" end
      lines[#lines + 1] = "  " .. (name or "") .. ":  " .. display
      state.row_map[row] = { type = "input", key = key, item = raw }
      row = row + 1
      if desc and #desc > 0 then lines[#lines + 1] = "    " .. desc; row = row + 1 end
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "button" then
      local action_fn = raw[5]
      lines[#lines + 1] = "  [ " .. (name or "?") .. " ]"
      state.row_map[row] = { type = "button", key = key, item = raw, action_fn = action_fn }
      row = row + 1
      if desc and #desc > 0 then lines[#lines + 1] = "    " .. desc; row = row + 1 end
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "display" then
      local d = name or ""
      if desc and #desc > 0 then d = d .. "  —  " .. desc end
      lines[#lines + 1] = "  " .. d
      row = row + 1
      lines[#lines + 1] = ""; row = row + 1

    elseif tp == "heatmap" then
      -- Add heatmap legend line
      local total = name or 0
      lines[#lines + 1] = "  " .. total .. " contributions in the last year"
      row = row + 1
      lines[#lines + 1] = ""
      row = row + 1
      -- Build heatmap
      local hm = build_heatmap_lines(Data.get().usage.daily_activity or {})
      heatmap_lines_cache = hm
      for _, segs in ipairs(hm) do
        local line_text = "  "
        for _, s in ipairs(segs) do line_text = line_text .. s[1] end
        lines[#lines + 1] = line_text
        row = row + 1
      end
      -- Legend
      lines[#lines + 1] = "          Less  " .. " " .. " " .. " " .. " " .. "  More"
      row = row + 1
      lines[#lines + 1] = ""
      row = row + 1

    elseif tp == "prompt_item" then
      -- Master/agent prompt: "● Name" with description
      local ppath, pidx = raw[2], raw[3]
      local pname, ptext = raw[4], raw[5]
      lines[#lines + 1] = "  " .. (pname or "?")
      state.row_map[row] = { type = "prompt_item", key = ppath, idx = pidx, item = raw }
      row = row + 1
      -- Show truncated preview
      local preview = ptext and (#ptext > 60 and ptext:sub(1, 57) .. "..." or ptext) or ""
      if #preview > 0 then
        lines[#lines + 1] = "    " .. preview
        row = row + 1
      end
      lines[#lines + 1] = ""
      row = row + 1

    elseif tp == "keybind_group" then
      -- Group header
      lines[#lines + 1] = "  " .. string.upper(name or "")
      row = row + 1
      -- Each keybind as a row
      local binds = raw[3] or {}
      for _, bind in ipairs(binds) do
        local mode, lhs, desc, cmd = bind[1], bind[2], bind[3], bind[4]
        lines[#lines + 1] = "    <leader>" .. lhs:gsub("^<leader>", "") .. "  " .. (desc or "")
        state.row_map[row] = { type = "keybind_display", item = bind }
        row = row + 1
      end
      lines[#lines + 1] = ""
      row = row + 1
    end
  end

  -- Write buffer
  api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
  api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = state.bufnr })

  -- Apply extmarks
  local erow = 0
  local lc = #lines
  for _, raw in ipairs(items) do
    local tp, key, name = parse_item(raw)
    if erow >= lc then break end

    if tp == "header" then erow = erow + 3
    elseif tp == "section" then
      pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 2, {
        end_col = 2 + #(name or ""), hl_group = hl.SectionTitle })
      erow = erow + 3
    elseif tp == "toggle" then
      local on = Data.get_value(key) == true
      pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 2, {
        end_col = 4, hl_group = on and hl.ToggleOn or hl.ToggleOff })
      erow = erow + 1
      if raw[4] and #raw[4] > 0 and erow < lc then
        pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 4, {
          end_col = math.min(4 + #raw[4], #lines[erow + 1] or 0), hl_group = hl.SettingDesc })
        erow = erow + 1
      end
      erow = erow + 1
    elseif tp == "slider" then
      erow = erow + 1
      if raw[4] and #raw[4] > 0 and erow < lc then
        pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 4, {
          end_col = math.min(4 + #raw[4], #lines[erow + 1] or 0), hl_group = hl.SettingDesc })
        erow = erow + 1
      end
      erow = erow + 1
    elseif tp == "dropdown" then
      erow = erow + 1
      if raw[4] and #raw[4] > 0 and erow < lc then
        pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 4, {
          end_col = math.min(4 + #raw[4], #lines[erow + 1] or 0), hl_group = hl.SettingDesc })
        erow = erow + 1
      end
      erow = erow + 1
    elseif tp == "input" then
      erow = erow + 1
      if raw[4] and #raw[4] > 0 and erow < lc then
        pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 4, {
          end_col = math.min(4 + #raw[4], #lines[erow + 1] or 0), hl_group = hl.SettingDesc })
        erow = erow + 1
      end
      erow = erow + 1
    elseif tp == "button" then
      erow = erow + 1
      if raw[4] and #raw[4] > 0 and erow < lc then
        pcall(api.nvim_buf_set_extmark, state.bufnr, NS, erow, 4, {
          end_col = math.min(4 + #raw[4], #lines[erow + 1] or 0), hl_group = hl.SettingDesc })
        erow = erow + 1
      end
      erow = erow + 1
    elseif tp == "display" then erow = erow + 2
    elseif tp == "heatmap" then
      erow = erow + 2  -- header + blank
      local hm_count = heatmap_lines_cache and #heatmap_lines_cache or 0
      erow = erow + hm_count + 3  -- heatmap lines + legend + blank
    elseif tp == "prompt_item" then
      erow = erow + 1
      if raw[5] and #raw[5] > 0 then erow = erow + 1 end
      erow = erow + 1
    elseif tp == "keybind_group" then
      erow = erow + 1  -- group header
      local binds = raw[3] or {}
      erow = erow + #binds + 1  -- binds + blank
    end
  end

  -- Header highlight
  if #lines > 0 then
    pcall(api.nvim_buf_set_extmark, state.bufnr, NS, 0, 0, {
      end_line = 1, hl_group = hl.HeaderBg })
  end

  -- Apply heatmap highlights
  if heatmap_lines_cache and state.current_page == "usage" then
    -- Find where heatmap lines start (after the header + overview + section header)
    local hm_start = 0
    local line_idx = 0
    for _, raw in ipairs(items) do
      local tp = raw[1]
      if tp == "heatmap" then
        -- Skip legend + blank above heatmap
        hm_start = line_idx + 2  -- after "X contributions..." + blank
        break
      end
      -- Count lines this item produces
      if tp == "section" then line_idx = line_idx + 3
      elseif tp == "display" then line_idx = line_idx + 2
      elseif tp == "toggle" then line_idx = line_idx + 3
      else line_idx = line_idx + 2 end
    end

    for i, segs in ipairs(heatmap_lines_cache) do
      local line_num = hm_start + i - 1  -- 0-indexed
      if line_num >= 0 and line_num < lc then
        local col = 2  -- after "  " prefix
        for _, s in ipairs(segs) do
          local text, hl_name = s[1], s[2]
          if hl_name and hl_name ~= "" then
            pcall(api.nvim_buf_set_extmark, state.bufnr, NS, line_num, col, {
              end_col = col + #text, hl_group = hl_name })
          end
          col = col + #text
        end
      end
    end
  end
end

function render_sidebar()
  if not state.sidebar_bufnr or not api.nvim_buf_is_valid(state.sidebar_bufnr) then return end
  api.nvim_buf_clear_namespace(state.sidebar_bufnr, NS, 0, -1)

  local lines = { "  Search Settings", "" }
  local items = { { type = "search" } }

  for i, page in ipairs(pages) do
    local active = page.id == state.current_page
    lines[#lines + 1] = (active and "▸" or " ") .. " " .. i .. ". " .. page.icon .. "  " .. page.label
    items[#items + 1] = { type = "page", id = page.id }
  end

  lines[#lines + 1] = ""; lines[#lines + 1] = ""; lines[#lines + 1] = ""
  items[#items + 1] = { type = "spacer" }
  lines[#lines + 1] = "   v1.0.0"
  items[#items + 1] = { type = "version" }

  api.nvim_set_option_value("modifiable", true, { buf = state.sidebar_bufnr })
  api.nvim_buf_set_lines(state.sidebar_bufnr, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = state.sidebar_bufnr })

  for i, item in ipairs(items) do
    local li = i - 1  -- 0-indexed
    if item.type == "page" then
      local hl_name = item.id == state.current_page and hl.SidebarActive or hl.SidebarFg
      api.nvim_buf_set_extmark(state.sidebar_bufnr, NS, li, 0, { end_line = li + 1, hl_group = hl_name })
    end
  end

  state.sidebar_items = items
end

-- ── Actions ─────────────────────────────────────────────────────────────────

function M._activate_row(row_1based)
  if row_1based == 1 then M.close(); return end

  local entry = state.row_map[row_1based]
  if not entry then return end

  if entry.type == "toggle" then
    local cur = Data.get_value(entry.key)
    local new = not cur
    Data.set(entry.key, new)
    render_content()
    M._apply_setting(entry.key, new)

  elseif entry.type == "slider" then
    local raw = entry.item
    local cur = Data.get_value(entry.key) or raw[5] or 0
    local step = raw[7] or 1
    cur = cur + step
    if cur > (raw[6] or 100) then cur = raw[5] or 0 end
    Data.set(entry.key, cur)
    render_content()
    M._apply_setting(entry.key, cur)

  elseif entry.type == "dropdown" then M._dropdown_select(entry)
  elseif entry.type == "input" then M._input_edit(entry)
  elseif entry.type == "button" then
    local name = entry.item[3]
    if name == "+ Add Keybind" or name == "+ Add Custom Keybind" then
      M._add_keybind()
    elseif name == "+ Add Master Prompt" or name == "+ Add Agent Prompt" then
      if entry.action_fn then entry.action_fn() end
    elseif entry.action_fn then
      entry.action_fn()
    end

  elseif entry.type == "prompt_item" then
    -- Toggle active state of this prompt, deactivate others
    local prompts = Data.get_value(entry.key) or {}
    for i, p in ipairs(prompts) do p.active = (i == entry.idx) end
    Data.set(entry.key, prompts)
    -- Apply the active prompt
    local active = prompts[entry.idx]
    if active then
      local setting_key = entry.key == "ai.master_prompts" and "ai.system_prompt" or "ai.agent_prompt"
      Data.set(setting_key, active.text)
    end
    render_content()
  end
end

function M._dropdown_select(entry)
  local raw = entry.item
  local opts = raw[5] or {}
  if #opts == 0 then return end
  local labels = {}
  for _, o in ipairs(opts) do labels[#labels + 1] = o.label end
  vim.ui.select(labels, { prompt = raw[3] .. ": " }, function(_, idx)
    if idx and opts[idx] then
      Data.set(entry.key, opts[idx].value)
      render_content()
      M._apply_setting(entry.key, opts[idx].value)
    end
  end)
end

function M._input_edit(entry)
  local raw, key = entry.item, entry.key
  local cur = Data.get_value(key) or ""
  local name = raw[3] or "Value"
  if key == "ai.system_prompt" or key == "ai.agent_prompt" then
    M._multiline_edit(entry); return
  end
  vim.ui.input({ prompt = name .. ": ", default = cur }, function(choice)
    if choice ~= nil then Data.set(key, choice); render_content(); M._apply_setting(key, choice) end
  end)
end

function M._multiline_edit(entry)
  local key, name = entry.key, entry.item[3] or "Value"
  local cur = Data.get_value(key) or ""
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(cur, "\n", { plain = true }))
  api.nvim_set_option_value("modifiable", true, { buf = buf })
  local w = math.min(80, vim.o.columns - 10)
  local h = math.min(20, vim.o.lines - 10)
  local win = api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h, row = 2, col = 4,
    style = "minimal", border = "rounded", title = " " .. name .. " ", title_pos = "center",
  })
  local function save()
    Data.set(key, table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    pcall(api.nvim_win_close, win, true); pcall(api.nvim_buf_delete, buf, { force = true })
    render_content()
  end
  for _, m in ipairs({ "n", "i" }) do
    api.nvim_buf_set_keymap(buf, m, "<D-cr>", "", { callback = save, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, m, "<C-s>", "", { callback = save, noremap = true, silent = true })
  end
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", { callback = function()
    pcall(api.nvim_win_close, win, true); pcall(api.nvim_buf_delete, buf, { force = true })
  end, noremap = true, silent = true })
end

function M._add_prompt(path, label)
  vim.ui.input({ prompt = label .. " Name: " }, function(name)
    if not name or name == "" then return end
    vim.ui.input({ prompt = label .. " Text: " }, function(text)
      if not text then return end
      local prompts = Data.get_value(path) or {}
      -- Deactivate all others
      for _, p in ipairs(prompts) do p.active = false end
      prompts[#prompts + 1] = { name = name, text = text or "", active = true }
      Data.set(path, prompts)
      -- Apply as active
      local setting_key = path == "ai.master_prompts" and "ai.system_prompt" or "ai.agent_prompt"
      Data.set(setting_key, text or "")
      render_content()
    end)
  end)
end

function M._add_keybind()
  local modes = { "n", "i", "v", "x", "t" }
  vim.ui.select(modes, { prompt = "Mode" }, function(mode)
    if not mode then return end
    vim.ui.input({ prompt = "Key (e.g. <leader>ff): " }, function(lhs)
      if not lhs or lhs == "" then return end
      vim.ui.input({ prompt = "Command: " }, function(rhs)
        if not rhs or rhs == "" then return end
        vim.ui.input({ prompt = "Description: " }, function(desc)
          local kb = Data.get_value("general.custom_keybinds") or {}
          kb[#kb + 1] = { mode = mode, lhs = lhs, rhs = rhs, desc = desc or "" }
          Data.set("general.custom_keybinds", kb)
          pcall(vim.keymap.set, mode, lhs, rhs, { desc = desc, silent = true })
          render_content()
        end)
      end)
    end)
  end)
end

-- ── Apply settings ──────────────────────────────────────────────────────────

function M._apply_setting(key, value)
  local parts = vim.split(key, ".", { plain = true })
  local sec, sub = parts[1], parts[2]
  if sec == "appearance" then
    if sub == "colorscheme" then pcall(vim.cmd.colorscheme, value)
    elseif sub == "transparent" then vim.notify("Restart to apply", vim.log.levels.INFO)
    elseif sub == "font_size" or sub == "font_family" then
      local ff = Data.get_value("appearance.font_family") or ""
      local fs = Data.get_value("appearance.font_size") or 14
      local font = (ff ~= "" and ff or "JetBrainsMono Nerd Font") .. ":h" .. fs
      pcall(function() vim.o.guifont = font end)
    elseif sub == "show_line_numbers" then vim.opt.number = value
    elseif sub == "show_relative_line_numbers" then vim.opt.relativenumber = value
    elseif sub == "show_sign_column" then vim.opt.signcolumn = value and "yes" or "no"
    elseif sub == "cursorline" then vim.opt.cursorline = value
    elseif sub == "cursorcolumn" then vim.opt.cursorcolumn = value
    elseif sub == "termguicolors" then vim.opt.termguicolors = value
    elseif sub == "winbar" then vim.opt.winbar = value and "%f" or ""
    elseif sub == "show_tabline" then vim.opt.showtabline = value and 2 or 0
    end
  elseif sec == "general" then
    if sub == "mouse" then vim.opt.mouse = value
    elseif sub == "spell" then vim.opt.spell = value
    elseif sub == "wrap" then vim.opt.wrap = value
    elseif sub == "timeout_len" then vim.opt.timeoutlen = value
    elseif sub == "clipboard" then vim.opt.clipboard = value
    elseif sub == "leader" then vim.g.mapleader = value
    elseif sub == "local_leader" then vim.g.maplocalleader = value
    end
  elseif sec == "ai" then
    local ok, ac = pcall(require, "avante.config")
    if ok then
      if sub == "model" then
        pcall(function() ac.override({ providers = { ollama = { model = value } } }) end)
        vim.notify("Model: " .. value, vim.log.levels.INFO)
      elseif sub == "provider" then
        pcall(function() require("avante.providers").refresh(value) end)
      end
    end
  end
end

-- ── Windows ─────────────────────────────────────────────────────────────────

local function create_windows()
  setup_highlights()
  local tw, th = vim.o.columns, vim.o.lines - vim.o.cmdheight
  local side_w, h = 28, th - 4
  local content_w = tw - side_w - 3

  state.sidebar_bufnr = api.nvim_create_buf(false, true)
  api.nvim_set_option_value("modifiable", false, { buf = state.sidebar_bufnr })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = state.sidebar_bufnr })

  state.bufnr = api.nvim_create_buf(false, true)
  api.nvim_set_option_value("modifiable", false, { buf = state.bufnr })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = state.bufnr })

  state.sidebar_winid = api.nvim_open_win(state.sidebar_bufnr, false, {
    relative = "editor", width = side_w, height = h,
    row = 2, col = 1, style = "minimal",
    border = { "", "", "", "", "", "", "", "" },
    focusable = true,
  })
  -- NO cursorline on sidebar — only extmark highlight shows active page
  api.nvim_set_option_value("wrap", false, { win = state.sidebar_winid })

  state.winid = api.nvim_open_win(state.bufnr, true, {
    relative = "editor", width = content_w, height = h,
    row = 2, col = side_w + 2, style = "minimal",
    border = "rounded", title = "  Settings  ", title_pos = "center",
  })
  api.nvim_set_option_value("wrap", true, { win = state.winid })
  api.nvim_set_option_value("linebreak", true, { win = state.winid })
  api.nvim_set_option_value("breakindent", true, { win = state.winid })
  api.nvim_set_option_value("scrolloff", 3, { win = state.winid })
  api.nvim_set_option_value("cursorline", true, { win = state.winid })
  local cline = api.nvim_get_hl(0, { name = "CursorLine" })
  api.nvim_set_hl(0, "FbCL", { bg = cline.bg or "#24283b" })
  api.nvim_set_option_value("winhighlight", "CursorLine:FbCL", { win = state.winid })

  -- ── Sidebar keymaps ──
  local function sidebar_nav()
    local pos = api.nvim_win_get_cursor(state.sidebar_winid)
    local item = state.sidebar_items[pos[1]]
    if item and item.type == "page" then
      state.current_page = item.id
      render_sidebar(); render_content()
      api.nvim_set_current_win(state.winid)
    end
  end

  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "<CR>", "", { callback = sidebar_nav, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "<2-LeftMouse>", "", { callback = sidebar_nav, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "<LeftMouse>", "", {
    callback = function()
      local pos = vim.fn.getmousepos()
      if pos.winid ~= state.sidebar_winid then return end
      vim.defer_fn(function()
        if not state.sidebar_winid or not api.nvim_win_is_valid(state.sidebar_winid) then return end
        local item = state.sidebar_items[pos.line]
        if item and item.type == "page" then
          state.current_page = item.id
          render_sidebar(); render_content()
          api.nvim_set_current_win(state.winid)
        end
      end, 150)
    end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "q", "", { callback = function() M.close() end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "<Tab>", "", {
    callback = function()
      if state.winid and api.nvim_win_is_valid(state.winid) then api.nvim_set_current_win(state.winid) end
    end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", "<C-w>l", "", {
    callback = function()
      if state.winid and api.nvim_win_is_valid(state.winid) then api.nvim_set_current_win(state.winid) end
    end, noremap = true, silent = true })

  -- ── Page-jump shortcuts ──
  local shortcuts = { "1", "2", "3", "4", "5", "6", "7" }
  for i, key in ipairs(shortcuts) do
    if pages[i] then
      local pid = pages[i].id
      -- From content
      api.nvim_buf_set_keymap(state.bufnr, "n", key, "", {
        callback = function()
          state.current_page = pid; render_sidebar(); render_content()
        end, noremap = true, silent = true })
      -- From sidebar
      api.nvim_buf_set_keymap(state.sidebar_bufnr, "n", key, "", {
        callback = function()
          state.current_page = pid; render_sidebar(); render_content()
          api.nvim_set_current_win(state.winid)
        end, noremap = true, silent = true })
    end
  end

  -- ── Content keymaps ──
  api.nvim_buf_set_keymap(state.bufnr, "n", "<CR>", "", {
    callback = function() M._activate_row(api.nvim_win_get_cursor(state.winid)[1]) end,
    noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "<Space>", "", {
    callback = function() M._activate_row(api.nvim_win_get_cursor(state.winid)[1]) end,
    noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "o", "", {
    callback = function() M._activate_row(api.nvim_win_get_cursor(state.winid)[1]) end,
    noremap = true, silent = true })

  -- Mouse on content
  api.nvim_buf_set_keymap(state.bufnr, "n", "<LeftMouse>", "", {
    callback = function()
      local pos = vim.fn.getmousepos()
      if pos.winid ~= state.winid then return end
      vim.defer_fn(function()
        if state.winid and api.nvim_win_is_valid(state.winid) then M._activate_row(pos.line) end
      end, 200)
    end, noremap = true, silent = true })

  -- Arrow keys for sliders
  api.nvim_buf_set_keymap(state.bufnr, "n", "<Left>", "", {
    callback = function()
      local e = state.row_map[api.nvim_win_get_cursor(state.winid)[1]]
      if e and e.type == "slider" then
        local raw, cur = e.item, Data.get_value(e.key) or e.item[5] or 0
        local new = math.max(raw[5] or 0, cur - (raw[7] or 1))
        Data.set(e.key, new); render_content(); M._apply_setting(e.key, new)
      end
    end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "<Right>", "", {
    callback = function()
      local e = state.row_map[api.nvim_win_get_cursor(state.winid)[1]]
      if e and e.type == "slider" then
        local raw, cur = e.item, Data.get_value(e.key) or e.item[5] or 0
        local new = math.min(raw[6] or 100, cur + (raw[7] or 1))
        Data.set(e.key, new); render_content(); M._apply_setting(e.key, new)
      end
    end, noremap = true, silent = true })

  -- Smart j/k
  api.nvim_buf_set_keymap(state.bufnr, "n", "j", "", {
    callback = function()
      local row = api.nvim_win_get_cursor(state.winid)[1]
      for r = row + 1, api.nvim_buf_line_count(state.bufnr) do
        if state.row_map[r] then pcall(api.nvim_win_set_cursor, state.winid, { r, 0 }); return end
      end
    end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "k", "", {
    callback = function()
      local row = api.nvim_win_get_cursor(state.winid)[1]
      for r = row - 1, 1, -1 do
        if state.row_map[r] then pcall(api.nvim_win_set_cursor, state.winid, { r, 0 }); return end
      end
    end, noremap = true, silent = true })

  -- Close & navigate
  api.nvim_buf_set_keymap(state.bufnr, "n", "q", "", { callback = function() M.close() end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "<Esc>", "", { callback = function() M.close() end, noremap = true, silent = true })
  api.nvim_buf_set_keymap(state.bufnr, "n", "<C-w>h", "", {
    callback = function()
      if state.sidebar_winid and api.nvim_win_is_valid(state.sidebar_winid) then
        api.nvim_set_current_win(state.sidebar_winid)
      end
    end, noremap = true, silent = true })

  api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      local c = tonumber(args.match)
      if c == state.winid or c == state.sidebar_winid then M.close() end
    end,
  })
end

-- ── Public API ──────────────────────────────────────────────────────────────

function M.refresh() render_content() end

function M.open(page)
  if state.winid and api.nvim_win_is_valid(state.winid) then
    if page then
      state.current_page = page
      render_sidebar(); render_content()
      api.nvim_set_current_win(state.winid)
    end
    return
  end
  state.current_page = page or "appearance"
  create_windows()
  render_sidebar()
  render_content()
end

function M.close()
  for _, w in ipairs({ state.sidebar_winid, state.winid }) do
    if w and api.nvim_win_is_valid(w) then pcall(api.nvim_win_close, w, true) end
  end
  for _, b in ipairs({ state.bufnr, state.sidebar_bufnr }) do
    if b and api.nvim_buf_is_valid(b) then pcall(api.nvim_buf_delete, b, { force = true }) end
  end
  state.winid = nil; state.bufnr = nil
  state.sidebar_winid = nil; state.sidebar_bufnr = nil
  state.row_map = {}; state.sidebar_items = {}
end

return M
