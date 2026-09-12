return {
  -- Mason gives you a real UI (:Mason) for installing/removing language
  -- servers, formatters, and linters — the closest thing Neovim has to a
  -- graphical "extensions/tools" settings panel.
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = { ui = { border = "rounded" } },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- Add a language server name here and Mason auto-installs it on
      -- startup. Find server names with :Mason or the lspconfig docs.
      ensure_installed = {
        "lua_ls",       -- Lua
        "pyright",      -- Python
        "ts_ls",        -- TypeScript / JavaScript
        "html",
        "cssls",
        "jsonls",
        "clangd",       -- C / C++
        "bashls",
      },
      automatic_installation = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")

      -- Keymaps that apply once an LSP attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(event)
          local map = function(mode, keys, func, desc)
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "Goto definition")
          map("n", "gr", vim.lsp.buf.references, "Goto references")
          map("n", "gI", vim.lsp.buf.implementation, "Goto implementation")
          map("n", "K", vim.lsp.buf.hover, "Hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })

      local servers = { "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "clangd", "bashls" }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({ capabilities = capabilities })
      end

      -- lua_ls needs to know about the Neovim runtime so it stops
      -- warning about `vim` being an undefined global in your own config
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })
    end,
  },
}
