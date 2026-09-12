# Your Neovim config

Built on [lazy.nvim](https://github.com/folke/lazy.nvim). Structure:

```
init.lua               entry point — just requires everything else
lua/config/
  lazy.lua             bootstraps the plugin manager
  options.lua           <- "UI settings" — edit this to change editor behavior
  keymaps.lua           <- "keybind settings" — edit this to change core keybinds
  autocmds.lua          small automations (trim whitespace, restore cursor, etc.)
lua/plugins/
  colorscheme.lua       tokyonight / catppuccin / rose-pine, <leader>uc to switch live
  explorer.lua          neo-tree (left sidebar file explorer)
  bufferline.lua        VS Code-style tab row
  statusline.lua        lualine
  telescope.lua         fuzzy finder for files/grep/buffers/keymaps
  treesitter.lua        syntax highlighting
  git.lua               gitsigns (inline) + neogit (full git UI)
  lsp.lua               Mason + language servers (autocomplete/errors/go-to-def)
  completion.lua        the autocomplete popup itself (nvim-cmp)
  formatting.lua        auto-format on save (conform.nvim)
  ai.lua                Avante — the Cursor-style AI sidebar, wired to local Gemma 4
  image.lua             inline image rendering (Kitty graphics protocol)
  browser.lua           real markdown preview + "open in actual browser" keymaps
  which-key.lua         live keybind reference popup
```

## One-time setup

**1. Install the Neovim plugins** — just open `nvim`, lazy.nvim bootstraps
itself and installs everything on first launch.

**2. Set up the local AI (Gemma 4 via Ollama)**

```bash
# install Ollama (Arch)
sudo pacman -S ollama
sudo systemctl enable --now ollama

# pull the model sized for your GTX 1060 (6GB VRAM)
ollama pull gemma4:e4b
```
If you upgrade your GPU later, swap `model = "gemma4:e4b"` for `gemma4:26b`
in `lua/plugins/ai.lua` — stronger reasoning, needs ~16GB VRAM.

**3. System dependencies for image rendering**
```bash
sudo pacman -S imagemagick
```
Image rendering needs a terminal that supports the Kitty graphics protocol.
Ghostty (already in your stack) supports it. If images don't render in
Neovide, that's a known Neovide limitation, not a config bug — test in
Ghostty to confirm.

**4. Formatters/LSPs** — `:Mason` opens a UI to install/remove language
servers, formatters, and linters. The ones listed in `lsp.lua` install
automatically on first launch; add more there anytime.

## Keymap cheatsheet (leader = space)

Hold `<space>` for ~400ms in Neovim and a live popup shows all of these —
this list will drift out of date, that popup won't.

| Key | Action |
|---|---|
| `<leader>e` | Toggle file explorer |
| `<leader>ff` / `fg` / `fb` | Find files / grep / buffers |
| `<S-l>` / `<S-h>` | Next / previous buffer (tab) |
| `<leader>bd` | Close current buffer |
| `<leader>gg` | Open full git UI (Neogit) |
| `]h` / `[h` | Next / previous git change |
| `<leader>gp` | Preview git hunk |
| `<leader>aa` | Ask the AI sidebar |
| `<leader>ae` | Ask AI to edit current selection |
| `<leader>at` | Toggle AI sidebar |
| `gd` / `gr` / `K` | Go to definition / references / hover docs |
| `<leader>rn` | Rename symbol (LSP) |
| `<leader>ca` | Code action |
| `<leader>mp` | Toggle markdown preview (real browser) |
| `<leader>bl` | Open localhost:PORT in browser |
| `gx` | Open URL under cursor in browser |
| `<leader>uc` | Live-switch colorscheme |

## What's real vs. adjusted from your original ask

- **Browser rendering inside Neovim** isn't a thing that exists — no plugin
  embeds an actual web engine. What's here instead: real markdown preview in
  your actual browser, and one-keystroke opening of any URL (including
  localhost) in your system browser.
- **A GUI settings page** isn't standard Neovim practice — configs are Lua
  files by design. `options.lua` + `keymaps.lua` are structured to be easy to
  scan and edit directly, and which-key gives you a live, always-accurate
  popup of every keybind instead of a static reference page.
- **Everything else** — explorer, tabs, git, AI sidebar, images, syntax
  highlighting — is a real, working plugin as configured.
