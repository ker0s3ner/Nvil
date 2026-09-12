-- Neo-tree extra is enabled in lazyvim.json. These opts merge with LazyVim's.

return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    { "<leader>o", "<cmd>Neotree focus<CR>", desc = "Focus file explorer" },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = "rounded",
    window = {
      position = "left",
      width = 32,
      mappings = {
        ["<space>"] = "none",
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
}
