return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      always_show_bufferline = true,
      offsets = {
        { filetype = "neo-tree", text = "File Explorer", highlight = "Directory", separator = true },
        { filetype = "Avante", text = "Chat", highlight = "Directory", separator = true },
      },
    },
  },
}
