return {
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    cmd = "Neogit",
    keys = {
      { "<leader>gn", "<cmd>Neogit<CR>", desc = "Neogit" },
    },
    opts = {
      integrations = { diffview = true },
    },
  },
}
