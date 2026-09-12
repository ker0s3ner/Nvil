-- Hold <leader> (space) for a moment and a popup shows every keymap
-- registered under it, grouped and labeled. This is the practical answer to
-- "a settings page for keybinds" in Neovim — not a GUI you click through,
-- but a live, always-accurate reference, since it reads real keymaps rather
-- than a hand-maintained list that goes stale.

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 400, -- matches timeoutlen in options.lua
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    -- Group labels so the popup reads like a menu, not a flat keymap dump
    wk.add({
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>g", group = "Git" },
      { "<leader>a", group = "AI (Avante)" },
      { "<leader>b", group = "Buffers / Browser" },
      { "<leader>u", group = "UI" },
      { "<leader>c", group = "Code" },
      { "<leader>x", group = "Diagnostics" },
      { "<leader>m", group = "Markdown" },
    })
  end,
}
