return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = {
    { "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Pin buffer" },
    { "<leader>bc", "<cmd>BufferLineCloseOthers<CR>", desc = "Close other buffers" },
  },
  opts = {
    options = {
      mode = "buffers",             -- one "tab" per open buffer, like VS Code
      separator_style = "thin",
      always_show_bufferline = true,
      show_buffer_close_icons = true,
      show_close_icon = false,
      indicator = { style = "underline" },
      diagnostics = "nvim_lsp",     -- show LSP error/warning counts on tabs
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          highlight = "Directory",
          separator = true,
        },
      },
    },
  },
}
