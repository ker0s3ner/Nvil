-- Avante chat sidebar: layout + clean clickable chrome (see freebuff/avante_chrome.lua).
-- Replaces the old header buttons + inline "Model:" virtual text, which duplicated
-- itself on every keystroke and broke after closing/reopening the sidebar.

return {
  {
    "yetone/avante.nvim",
    opts = function(_, opts)
      opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
        position = "right",
        wrap = true,
        width = 36,
        sidebar_header = { enabled = false }, -- our winbars replace it
        input = { prefix = "❯ ", height = 7 },
        edit = { border = "rounded", start_insert = true },
        ask = { floating = false, start_insert = true, border = "rounded" },
      })

      local existing_post = opts.sidebar_post_render
      opts.sidebar_post_render = function(sidebar)
        if existing_post then existing_post(sidebar) end
        vim.schedule(function()
          require("freebuff.theme").apply()
          require("freebuff.avante_chrome").attach(sidebar)
        end)
      end
    end,
  },
}
