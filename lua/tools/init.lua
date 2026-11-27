-- tools/init.lua — the "everything in one app" launcher.
local M = {}

local Data = require("freebuff.settings.data")
local function enabled(key) return Data.get_value("tools." .. key) ~= false end

M.items = {
  { icon = "󰆦", label = "LeetCode", key = "leetcode", desc = "Practice problems, run & submit", run = "Leet" },
  { icon = "󰎈", label = "Strudel music", key = "strudel", desc = "New live-coded track from your music pack", run = function() M.strudel_new() end },
  { icon = "", label = "Jupyter kernel", key = "jupyter", desc = "Start the default kernel for this buffer", run = function()
      vim.cmd("MoltenInit " .. (Data.get_value("packs.kernel") or "python3")) end },
  { icon = "󰐱", label = "Live render (LaTeX / Typst / Manim)", key = "latex_live", desc = "Toggle auto-compile for this buffer", run = "NvilLive" },
  { icon = "󰐱", label = "Compile / open PDF", key = "latex_live", desc = "One-shot compile of the current .tex/.typ", run = "NvilCompile" },
  { icon = "󱓧", label = "Project graph", key = "mindmap", desc = "Obsidian-style graph of notes + code", run = "MindMap" },
  { icon = "󱓧", label = "File outline mind map", key = "mindmap", desc = "Headings of this markdown file", run = "MindMapFile" },
  { icon = "", label = "Markdown preview", key = "mindmap", desc = "Live preview in the browser", run = "MarkdownPreviewToggle" },
  { icon = "󰛳", label = "Network: serial console", key = "network", desc = "screen to a Cisco console port", run = "NetConsole" },
  { icon = "󰛳", label = "Network: SSH / telnet", key = "network", desc = "Connect to a device", run = "NetSsh" },
  { icon = "󰛳", label = "Network: subnet calculator", key = "network", desc = "IPv4 network / broadcast / hosts", run = function()
      vim.ui.input({ prompt = "Subnet (ip/prefix): " }, function(v) if v and v ~= "" then vim.cmd("NetSubnet " .. v) end end) end },
  { icon = "󰛳", label = "Network: training lab", key = "network", desc = "Cisco-style VLAN, routing, OSPF or troubleshooting lab", run = function()
      vim.ui.input({ prompt = "Lab (vlan/routing/ospf/troubleshoot): " }, function(v) if v and v ~= "" then vim.cmd("NetLab " .. v) end end) end },
  { icon = "", label = "Gamma: startup artifact", key = "gamma", desc = "Create a pitch, memo or launch-page brief", run = function() require("tools").gamma_new() end },
  { icon = "", label = "Settings", key = "", desc = "Packs, fonts, colors, keybinds…", run = function() require("freebuff.settings.ui").open() end },
  { icon = "", label = "AI chat", key = "", desc = "Toggle the Avante sidebar", run = "AvanteToggle" },
}

function M.launcher()
  local items = vim.tbl_filter(function(i) return i.key == "" or enabled(i.key) end, M.items)
  vim.ui.select(items, {
    prompt = "Tools",
    format_item = function(i) return ("%s  %-34s %s"):format(i.icon, i.label, i.desc) end,
  }, function(choice)
    if not choice then return end
    if type(choice.run) == "function" then choice.run() else vim.cmd(choice.run) end
  end)
end

function M.strudel_new()
  require("freebuff.settings.packs").new_strudel()
  pcall(function() require("lazy").load({ plugins = { "strudel.nvim" } }) end)
end

function M.gamma_new()
  vim.ui.select({ "pitch deck", "strategy memo", "launch webpage" }, { prompt = "Gamma artifact" }, function(choice)
    if not choice then return end
    local slug = ({ ["pitch deck"] = "pitch-deck", ["strategy memo"] = "strategy-memo", ["launch webpage"] = "launch-page" })[choice]
    local templates = {
      ["pitch-deck"] = { "# Startup pitch deck", "", "## Problem", "", "## Customer", "", "## Solution", "", "## Why now", "", "## Business model", "", "## Traction", "", "## Ask" },
      ["strategy-memo"] = { "# Strategy memo", "", "**Decision:** ", "", "## Context", "", "## Options", "", "## Recommendation", "", "## Risks", "", "## Next actions" },
      ["launch-page"] = { "# Launch page brief", "", "## One-line promise", "", "## Who it is for", "", "## The problem", "", "## How it works", "", "## Proof", "", "## Call to action" },
    }
    vim.cmd("enew")
    vim.bo.filetype = "markdown"
    vim.api.nvim_buf_set_name(0, "gamma-" .. slug .. ".md")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, templates[slug])
    vim.notify("Draft ready: preview it with <leader>mp, then paste/import it into Gamma", vim.log.levels.INFO, { title = "Gamma workflow" })
  end)
end

return M
