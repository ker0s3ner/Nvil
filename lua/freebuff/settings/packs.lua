-- freebuff/settings/packs.lua
-- Pack definitions + the code that applies them. A "pack" is a named preset for
-- one category; exactly one is active per category (packs.<category> in the
-- settings JSON). Add a pack by adding an entry here — the Settings -> Packs
-- page picks it up automatically.

local M = {}
local Data = require("freebuff.settings.data")

local function pk(label, desc, extra)
  return vim.tbl_extend("force", { label = label, desc = desc }, extra or {})
end

-- ── Music (Strudel starter packs) ───────────────────────────────────────────
M.music = {
  lofi = pk("Lo-fi", "Dusty drums, warm chords", {
    code = [[// lo-fi pack
setcps(0.55)
$: s("bd ~ ~ bd ~ ~ sd ~").bank("RolandTR808").gain(.8)
$: s("hh*8").bank("RolandTR808").gain(.35).swingBy(1/6, 4)
$: note("<c3 f3 a2 g2>").s("sawtooth").lpf(600).room(.6).gain(.5)
$: n("0 2 4 7 9 7 4 2").scale("c4:minor pentatonic").s("triangle").delay(.4).gain(.35)
]] }),
  techno = pk("Techno", "Four on the floor, acid line", {
    code = [[// techno pack
setcps(130/60/4)
$: s("bd*4").bank("RolandTR909").gain(.9)
$: s("~ cp ~ cp").bank("RolandTR909")
$: s("hh*16").bank("RolandTR909").gain(.4)
$: note("c2 c2 [c2 eb2] c2").s("sawtooth").lpf(sine.range(200,2000).slow(8)).resonance(12).gain(.6)
]] }),
  ambient = pk("Ambient", "Slow pads and long reverb", {
    code = [[// ambient pack
setcps(0.2)
$: note("<[c3,e3,g3,b3] [a2,c3,e3,g3] [f2,a2,c3,e3] [g2,b2,d3,f3]>").s("sawtooth").lpf(900).attack(2).release(4).room(.9).gain(.4)
$: n("0 ~ 4 ~ 7 ~ 11 ~").scale("c5:major").s("sine").delay(.6).delayfeedback(.6).room(.8).gain(.25)
]] }),
  dnb = pk("Drum & bass", "Breakbeat + reese bass", {
    code = [[// drum & bass pack
setcps(174/60/4)
$: s("bd ~ ~ ~ ~ ~ bd ~ ~ ~ bd ~ ~ ~ ~ ~, ~ ~ ~ ~ sd ~ ~ ~ ~ ~ ~ ~ sd ~ ~ ~").bank("RolandTR909")
$: s("hh*16").gain(.3)
$: note("<f1 f1 ab1 g1>").s("sawtooth").lpf(400).distort(.3).gain(.7)
]] }),
  empty = pk("Blank", "Just a clean file", { code = "// strudel\n$: s(\"bd sd\")\n" }),
}
M.music_order = { "lofi", "techno", "ambient", "dnb", "empty" }

-- ── Fonts (GUI: guifont; terminal: install hint) ────────────────────────────
M.fonts = {
  jetbrains = pk("JetBrains Mono", "Default; great ligatures", { gui = "JetBrainsMono Nerd Font", cask = "font-jetbrains-mono-nerd-font" }),
  firacode = pk("Fira Code", "Classic coding ligatures", { gui = "FiraCode Nerd Font", cask = "font-fira-code-nerd-font" }),
  hack = pk("Hack", "Clean and sturdy", { gui = "Hack Nerd Font", cask = "font-hack-nerd-font" }),
  iosevka = pk("Iosevka", "Narrow, fits more columns", { gui = "Iosevka Nerd Font", cask = "font-iosevka-nerd-font" }),
  cascadia = pk("Cascadia Code", "Microsoft's coding font", { gui = "CaskaydiaCove Nerd Font", cask = "font-caskaydia-cove-nerd-font" }),
  meslo = pk("Meslo", "Menlo-like", { gui = "MesloLGS Nerd Font", cask = "font-meslo-lg-nerd-font" }),
}
M.fonts_order = { "jetbrains", "firacode", "hack", "iosevka", "cascadia", "meslo" }

-- ── Kernels (Molten / Jupyter) ──────────────────────────────────────────────
M.kernels = {
  python3 = pk("Python 3", "ipykernel", { install = "python3 -m pip install ipykernel && python3 -m ipykernel install --user" }),
  julia = pk("Julia", "IJulia", { install = [[julia -e 'using Pkg; Pkg.add("IJulia")']] }),
  r = pk("R", "IRkernel", { install = [[Rscript -e 'install.packages("IRkernel"); IRkernel::installspec()']] }),
  bash = pk("Bash", "bash_kernel", { install = "python3 -m pip install bash_kernel && python3 -m bash_kernel.install" }),
  javascript = pk("JavaScript / TS", "tslab", { install = "npm install -g tslab && tslab install" }),
}
M.kernels_order = { "python3", "julia", "r", "bash", "javascript" }

-- ── Keybind packs ───────────────────────────────────────────────────────────
-- { mode, lhs, rhs, desc }
M.keybinds = {
  default = pk("LazyVim default", "Nothing extra", { binds = {} }),
  vscode = pk("VS Code-like", "Ctrl-P, Ctrl-B, Alt-j/k, Cmd/Ctrl-S…", {
    binds = {
      { "n", "<C-p>", function() Snacks.picker.files() end, "Quick open" },
      { "n", "<C-S-p>", function() Snacks.picker.commands() end, "Command palette" },
      { "n", "<C-S-f>", function() Snacks.picker.grep() end, "Search in files" },
      { "n", "<C-b>", "<cmd>Neotree toggle<cr>", "Toggle sidebar" },
      { "n", "<C-`>", function() Snacks.terminal() end, "Toggle terminal" },
      { { "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", "Save" },
      { "n", "<A-j>", "<cmd>m .+1<cr>==", "Move line down" },
      { "n", "<A-k>", "<cmd>m .-2<cr>==", "Move line up" },
      { "v", "<A-j>", ":m '>+1<cr>gv=gv", "Move selection down" },
      { "v", "<A-k>", ":m '<-2<cr>gv=gv", "Move selection up" },
      { "n", "<C-/>", "gcc", "Toggle comment", { remap = true } },
      { "v", "<C-/>", "gc", "Toggle comment", { remap = true } },
      { "n", "<C-w>", "<cmd>bd<cr>", "Close tab" },
    },
  }),
  ["helix-lite"] = pk("Helix-lite", "gh/gl line start/end, ge file end, space-f files", {
    binds = {
      { { "n", "v" }, "gh", "0", "Line start" },
      { { "n", "v" }, "gl", "$", "Line end" },
      { { "n", "v" }, "ge", "G", "File end" },
      { "n", "<space>f", function() Snacks.picker.files() end, "Files" },
      { "n", "<space>/", function() Snacks.picker.grep() end, "Grep" },
      { "n", "x", "V", "Select line" },
    },
  }),
  ["emacs-lite"] = pk("Emacs-lite (insert mode)", "Ctrl-a/e/f/b/n/p/k in insert mode", {
    binds = {
      { "i", "<C-a>", "<Home>", "Line start" },
      { "i", "<C-e>", "<End>", "Line end" },
      { "i", "<C-f>", "<Right>", "Forward" },
      { "i", "<C-b>", "<Left>", "Back" },
      { "i", "<C-n>", "<Down>", "Next line" },
      { "i", "<C-p>", "<Up>", "Previous line" },
      { "i", "<C-k>", "<C-o>D", "Kill line" },
    },
  }),
}
M.keybinds_order = { "default", "vscode", "helix-lite", "emacs-lite" }

-- ── Editor packs ────────────────────────────────────────────────────────────
M.editor = {
  default = pk("Default", "2-space indent, no wrap", { opts = { shiftwidth = 2, tabstop = 2, wrap = false, scrolloff = 8, colorcolumn = "" } }),
  compact = pk("Compact", "4-space, ruler at 100", { opts = { shiftwidth = 4, tabstop = 4, wrap = false, scrolloff = 4, colorcolumn = "100" } }),
  spacious = pk("Spacious", "Roomy, 120 ruler", { opts = { shiftwidth = 2, tabstop = 2, wrap = false, scrolloff = 12, colorcolumn = "120" } }),
  writer = pk("Writer", "Soft wrap + spell, for prose/LaTeX", { opts = { shiftwidth = 2, tabstop = 2, wrap = true, linebreak = true, scrolloff = 6, spell = true, colorcolumn = "" } }),
}
M.editor_order = { "default", "compact", "spacious", "writer" }

-- ── Network presets ─────────────────────────────────────────────────────────
M.network = {
  ios = pk("Cisco IOS", "Console 9600 8N1, *.ios/*.cisco syntax", { baud = 9600 }),
  nxos = pk("Cisco NX-OS", "Console 9600, same syntax", { baud = 9600 }),
  generic = pk("Generic (ssh only)", "No serial helpers", { baud = 115200 }),
}
M.network_order = { "ios", "nxos", "generic" }

-- ── LeetCode languages ──────────────────────────────────────────────────────
M.leetcode_langs = { "python3", "cpp", "java", "rust", "golang", "javascript", "typescript", "c", "kotlin", "swift" }

-- ── Applying ────────────────────────────────────────────────────────────────

local applied_keybinds = {}

function M.apply_keybinds(name)
  for _, b in ipairs(applied_keybinds) do pcall(vim.keymap.del, b[1], b[2]) end
  applied_keybinds = {}
  local pack = M.keybinds[name or "default"]
  if not pack then return end
  for _, b in ipairs(pack.binds) do
    local modes, lhs, rhs, desc, extra = b[1], b[2], b[3], b[4], b[5] or {}
    local o = vim.tbl_extend("force", { desc = "[pack] " .. desc, silent = true }, extra)
    if pcall(vim.keymap.set, modes, lhs, rhs, o) then
      for _, m in ipairs(type(modes) == "table" and modes or { modes }) do
        applied_keybinds[#applied_keybinds + 1] = { m, lhs }
      end
    end
  end
end

function M.apply_font(name)
  local f = M.fonts[name or "jetbrains"]
  if not f then return end
  local size = Data.get_value("appearance.font_size") or 14
  local custom = Data.get_value("appearance.font_family") or ""
  pcall(function() vim.o.guifont = (custom ~= "" and custom or f.gui) .. ":h" .. size end)
end

function M.apply_editor(name)
  local p = M.editor[name or "default"]
  if not p then return end
  for k, v in pairs(p.opts) do pcall(function() vim.opt[k] = v end) end
end

function M.apply_color()
  require("freebuff.theme").apply()
end

--- Insert/open a new Strudel file from the active music pack.
function M.new_strudel(pack_name)
  local pack = M.music[pack_name or Data.get_value("packs.music") or "lofi"] or M.music.lofi
  local dir = vim.fn.expand("~/strudel")
  vim.fn.mkdir(dir, "p")
  local path = ("%s/%s-%s.str"):format(dir, pack_name or Data.get_value("packs.music") or "lofi", os.date("%m%d-%H%M"))
  vim.fn.writefile(vim.split(pack.code, "\n", { plain = true }), path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

--- Apply everything that is saved. Called once at startup (VeryLazy) and by the UI.
function M.apply_all()
  M.apply_color()
  M.apply_font(Data.get_value("packs.font"))
  M.apply_editor(Data.get_value("packs.editor"))
  M.apply_keybinds(Data.get_value("packs.keybinds"))
end

--- Python used by Molten/jupytext: a private venv so we never touch system Python.
function M.venv_dir() return vim.fn.stdpath("data") .. "/nvil-venv" end
function M.venv_python() return M.venv_dir() .. "/bin/python" end

function M.python_env_cmd()
  -- Molten needs Python >= 3.10 (macOS system python is 3.9), so prefer uv's 3.12.
  local v = vim.fn.shellescape(M.venv_dir())
  local deps = "pynvim jupyter_client ipykernel jupytext nbformat cairosvg pnglatex plotly kaleido pyperclip"
  if vim.fn.executable("uv") == 1 then
    return ("uv venv --python 3.12 %s && uv pip install --python %s/bin/python %s && %s/bin/python -m ipykernel install --user --name python3 && nvim --headless '+Lazy! load molten-nvim' +UpdateRemotePlugins +qa")
      :format(v, v, deps, v)
  end
  return ("python3 -m venv %s && %s/bin/pip install %s && %s/bin/python -m ipykernel install --user --name python3")
    :format(v, v, deps, v)
end

function M.kernel_install_cmd(k)
  if k == "python3" then return M.python_env_cmd() end
  return M.kernels[k].install
end

--- Install a Homebrew cask / run an install command in a terminal split.
function M.run_in_terminal(cmd)
  vim.cmd("botright 12split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

return M
