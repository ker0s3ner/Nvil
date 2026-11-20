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

return M
