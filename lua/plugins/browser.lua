-- There's no real embedded web engine for Neovim — no plugin renders actual
-- Chromium-grade HTML/CSS/JS inside a Neovim window. What you get here is
-- the honest, actually-useful version of "browser rendering":
--
--   1. markdown-preview.nvim: live-renders your markdown in your REAL browser
--      (spins up a localhost server, auto-refreshes on save)
--   2. A keymap that opens any URL — including localhost:PORT — in your
--      actual system browser (Zen Browser, per your setup)
--
-- If you want a true in-editor web view later, "peek.nvim" gets closer for
-- markdown specifically (renders via a Deno-powered webview instead of your
-- browser) — worth trying if the external-browser round-trip bothers you,
-- but even peek.nvim can't load arbitrary websites, only local markdown.

return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    ft = { "markdown" },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Toggle markdown preview" },
    },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_theme = "dark"
    end,
  },
  {
    -- Not a real plugin, just a place to hang the URL-opening keymaps —
    -- kept in its own file so it's easy to find and extend.
    dir = vim.fn.stdpath("config"),
    name = "browser-keymaps",
    keys = {
      {
        "<leader>bl",
        function()
          vim.ui.input({ prompt = "Open localhost port: " }, function(port)
            if port and port ~= "" then
              vim.ui.open("http://localhost:" .. port)
            end
          end)
        end,
        desc = "Open localhost:PORT in browser",
      },
      {
        "gx",
        function()
          local url = vim.fn.expand("<cfile>")
          vim.ui.open(url)
        end,
        desc = "Open URL under cursor in browser",
      },
    },
  },
}
