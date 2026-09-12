-- Session persistence: auto-save and auto-restore Neovim sessions per project.
-- Keymaps (LazyVim defaults):
--   <leader>qs  — restore session for the current directory
--   <leader>ql  — restore the last session
--   <leader>qd  — destroy session (don't save, just quit)

return {
  "folke/persistence.nvim",
  event = "VeryLazy",
  opts = {},
}
