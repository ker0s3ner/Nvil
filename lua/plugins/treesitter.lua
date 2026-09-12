return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "css",
      "toml",
      "c",
      "cpp",
      "rust",
      "go",
      "gitcommit",
      "gitignore",
      "diff",
    })
  end,
}
