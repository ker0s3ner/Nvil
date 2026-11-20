-- Base colorscheme is tokyonight-night; freebuff/theme.lua repaints the accent
-- (red by default, switchable in Settings -> Packs) after every ColorScheme event.
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
      on_highlights = function(hl)
        hl.StatusLine = { fg = "#f2f2f2", bg = "#111111" }
        hl.StatusLineNC = { fg = "#666666", bg = "#0d0d0d" }
      end,
    },
  },
  { "catppuccin/nvim", name = "catppuccin" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "rebelot/kanagawa.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
    init = function()
      require("freebuff.theme").setup()
    end,
  },
}
