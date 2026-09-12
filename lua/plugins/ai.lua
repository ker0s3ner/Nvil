-- Avante.nvim clones Cursor's AI UX inside Neovim: a right-side chat sidebar,
-- inline diffs, and one-keystroke "apply this edit to the file" — which is
-- specifically the "auto input text like Cursor" behavior you asked for.
--
-- Configured here to run 100% locally against Ollama + Gemma 4 (gemma4:e4b).
-- Setup required on the Ollama side, once:
--   1. Install Ollama:            https://ollama.com
--   2. Pull the model:            ollama pull gemma4:e4b
--   3. Make sure it's running:    ollama serve   (usually auto-starts as a service)
--
-- Why e4b and not the bigger 26b/31b: a GTX 1060 has 6GB VRAM. e4b needs
-- ~5.5GB and fits; 26b needs ~16GB and won't. If you upgrade the GPU later,
-- just change `model = "gemma4:e4b"` below to "gemma4:26b" for meaningfully
-- stronger reasoning/coding, no other change needed.
--
-- Ollama silently caps context at 4096 tokens by default regardless of the
-- model's real window, which will truncate large files — num_ctx below
-- overrides that explicitly.

return {
  "yetone/avante.nvim",
  build = "make",
  event = "VeryLazy",
  version = false, -- always track latest, this plugin moves fast
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope.nvim", -- powers @file mentions / file selector
    { "MeanderingProgrammer/render-markdown.nvim", opts = { file_types = { "markdown", "Avante" } } },
  },
  opts = {
    provider = "ollama",
    mode = "agentic", -- lets it use tools (read/edit files, run commands) rather
                       -- than just chat — this is the "code insanely well,
                       -- autonomously" behavior
    providers = {
      ollama = {
        endpoint = "http://127.0.0.1:11434",
        model = "gemma4:e4b",
        timeout = 60000,
        extra_request_body = {
          options = {
            temperature = 0.6,
            num_ctx = 32768, -- override Ollama's default 4K cap
            keep_alive = "10m",
          },
        },
      },
    },
    behaviour = {
      auto_suggestions = false, -- ghost-text-as-you-type is expensive for a
                                 -- local 4B model; turn on if your GPU keeps up
      auto_apply_diff_after_generation = false, -- review before it touches files
      support_paste_from_clipboard = true,
      minimize_diff = true,
      auto_focus_sidebar = false, -- keep the file focused when the chat opens
    },
    windows = {
      position = "right",
      width = 34, -- percent of screen width
      sidebar_header = {
        align = "center",
        rounded = true,
        enabled = true,
        include_model = true, -- show current model in the header
      },
    },
    mappings = {
      ask = "<leader>aa",
      edit = "<leader>ae",
      refresh = "<leader>ar",
      toggle = { default = "<leader>at" },
      select_model = "<leader>a?",
      select_history = "<leader>ah",
      submit = {
        normal = "<CR>",
        insert = "<D-cr>", -- Cmd+Enter on macOS
      },
    },
  },
}
