return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter.configs",
  opts = {
    -- Add/remove languages here as you need them — this list covers
    -- general scripting, web, and systems work.
    ensure_installed = {
      "lua", "vim", "vimdoc", "query",
      "python", "javascript", "typescript", "tsx",
      "html", "css", "json", "yaml", "toml",
      "c", "cpp", "rust", "go",
      "bash", "markdown", "markdown_inline",
      "regex", "gitcommit", "gitignore", "diff",
    },
    auto_install = true,       -- install a parser automatically when you open
                                -- a filetype it doesn't have yet
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
}
