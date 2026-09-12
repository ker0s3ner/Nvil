-- Settings plugin spec: wires up the Freebuff Settings UI, keymaps, dashboard integration,
-- model dropdown in Avante input, and activity tracking.

local api = vim.api

-- Custom dashboard picker: shows files AND directories, lets you filter.
-- Selecting a directory sets the explorer root; selecting a file opens it.
local function find_item()
  Snacks.picker({
    finder = function()
      local items = {}
      -- Find all files and directories (not .git etc)
      local handle = vim.fn.systemlist({
        "find", ".", "-maxdepth", "4",
        "-not", "-path", "*/.git/*",
        "-not", "-path", "*/node_modules/*",
        "-not", "-path", "*/.venv/*",
        "-not", "-path", "*/__pycache__/*",
        "-type", "f", "-o", "-type", "d",
      })
      for _, path in ipairs(handle) do
        if path ~= "." then
          local name = path:gsub("^%./", "")
          local is_dir = vim.fn.isdirectory(path) == 1
          items[#items + 1] = {
            text = (is_dir and " " or " ") .. " " .. name,
            file = path,
            dir = is_dir and path or nil,
          }
        end
      end
      return items
    end,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      if item.dir then
        -- Open file explorer rooted at this directory
        require("neo-tree.sources.filesystem").open({
          source = "filesystem",
          path = item.dir,
        })
        -- Also cd the working directory
        vim.cmd("cd " .. vim.fn.fnameescape(item.dir))
        vim.notify("Rooted at: " .. item.dir, vim.log.levels.INFO)
      elseif item.file then
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
    title = "Find Item (files & folders)",
  })
end

return {
  -- ── Settings UI ─────────────────────────────────────────────────────
  {
    dir = vim.fn.stdpath("config"),
    name = "freebuff-settings",
    cmd = "FreebuffSettings",
    keys = {
      { "<leader>fw", function() require("freebuff.settings.ui").open() end, desc = "Open Settings" },
      { "<leader>sa", function() require("freebuff.settings.ui").open("appearance") end, desc = "Settings: Appearance" },
      { "<leader>su", function() require("freebuff.settings.ui").open("usage") end, desc = "Settings: Usage" },
      { "<leader>si", function() require("freebuff.settings.ui").open("ai") end, desc = "Settings: AI" },
      { "<leader>sg", function() require("freebuff.settings.ui").open("git") end, desc = "Settings: Git" },
      { "<leader>sb", function() require("freebuff.settings.ui").open("browser") end, desc = "Settings: Browser" },
      { "<leader>sG", function() require("freebuff.settings.ui").open("general") end, desc = "Settings: General" },
      { "<leader>sd", function() require("freebuff.settings.ui").open("docs") end, desc = "Settings: Docs" },
      { "<leader>fi", find_item, desc = "Find Item (files & folders)" },
    },
    init = function()
      vim.api.nvim_create_user_command("FreebuffSettings", function(opts)
        local page = opts.args ~= "" and opts.args or nil
        require("freebuff.settings.ui").open(page)
      end, { nargs = "?", complete = function()
        return { "appearance", "usage", "ai", "git", "browser", "general", "docs" }
      end })
    end,
  },

  -- ── Dashboard ──────────────────────────────────────────────────────
  {
    "snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.keys = {
        { icon = " ", key = "f", desc = "Find Item", action = function() find_item() end },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = " ", key = "c", desc = "Settings", action = ":lua require('freebuff.settings.ui').open()" },
        { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      }
      return opts
    end,
  },

  -- ── Model dropdown in Avante input area ─────────────────────────────
  {
    "yetone/avante.nvim",
    opts = function(_, opts)
      local existing_post = opts.sidebar_post_render
      opts.sidebar_post_render = function(sidebar)
        if existing_post then existing_post(sidebar) end
        pcall(function() require("freebuff.settings.avante_model_dropdown").attach(sidebar) end)
      end
    end,
  },

  -- ── Activity tracking on startup ───────────────────────────────────
  {
    dir = vim.fn.stdpath("config"),
    name = "freebuff-activity",
    event = "VeryLazy",
    config = function()
      local ok, data = pcall(require, "freebuff.settings.data")
      if ok then
        data.record_activity()
        api.nvim_create_autocmd("VimLeavePre", {
          callback = function()
            local settings = data.get()
            local start_time = vim.g.freebuff_session_start or os.time()
            settings.usage.total_time_seconds = (settings.usage.total_time_seconds or 0) + (os.time() - start_time)
            data.save()
          end,
        })
        vim.g.freebuff_session_start = os.time()
      end
    end,
  },
}
