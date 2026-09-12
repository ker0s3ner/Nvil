-- Three dark, minimal themes are installed so you can pick your favorite —
-- tokyonight (default) is closest to Linear's near-black + purple accent look.
-- Switch anytime with <leader>uc (Telescope colorscheme picker, live preview)
-- and it'll actually apply for the session; edit `vim.cmd.colorscheme` below
-- to make a choice permanent.

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- load before other plugins so UI elements theme correctly
    opts = {
      style = "storm",         -- "storm" | "night" | "moon" | "day"
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },

  -- Load-order hook: this plugin has no real logic, it just guarantees the
  -- colorscheme is applied once everything else is set up.
  {
    "folke/tokyonight.nvim",
    config = function()
      vim.cmd.colorscheme("tokyonight-storm")
    end,
  },
}
