-- tools/render.lua
-- Live, debounced auto-compilation for LaTeX / Typst (-> PDF) and Manim (-> mp4),
-- plus a PDF opener. Works with whatever compiler is installed:
--   LaTeX : latexmk > tectonic > pdflatex
--   Typst : typst
--   Manim : manim (python)
-- Output is opened in the macOS viewer (Skim if installed, else Preview).
-- Inline-in-Neovim PDF needs Ghostscript (`brew install ghostscript`) and the
-- Kitty-graphics support Ghostty already has; Snacks.image will then render it.

local M = {}

local Data = require("freebuff.settings.data")
local log_lines = {}
local live = {}       -- bufnr -> { timer, augroup }
local running = {}    -- file -> true while a compile is in flight
local opened = {}     -- output path -> true once opened in a viewer
local last_scene = {} -- bufnr -> scene name

local function exe(bin) return vim.fn.executable(bin) == 1 end
local function delay() return Data.get_value("tools.autocompile_delay") or 600 end

local function log(msg)
  for _, l in ipairs(vim.split(msg, "\n", { plain = true })) do log_lines[#log_lines + 1] = l end
  if #log_lines > 2000 then
    log_lines = vim.list_slice(log_lines, #log_lines - 1500, #log_lines)
  end
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Render" })
end

function M.show_log()
  vim.cmd("botright 12new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "nofile", "wipe", false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, #log_lines > 0 and log_lines or { "(no render output yet)" })
  vim.cmd("normal! G")
end

--- Open a file (pdf / mp4) in the system viewer; Skim if present for live PDF reload.
function M.open_output(path)
  if vim.fn.filereadable(path) == 0 then return notify("Nothing to open yet: " .. path, vim.log.levels.WARN) end
  if path:match("%.pdf$") and vim.fn.isdirectory("/Applications/Skim.app") == 1 then
    vim.system({ "open", "-g", "-a", "Skim", path })
  else
    vim.system({ "open", "-g", path })
  end
end

-- ── LaTeX / Typst ───────────────────────────────────────────────────────────

local function doc_command(file)
  local ext = file:match("%.(%w+)$")
  local dir = vim.fn.fnamemodify(file, ":h")
  if ext == "tex" then
    if exe("latexmk") then
      return { "latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error", "-file-line-error", file }, dir, "pdf"
    elseif exe("tectonic") then
      return { "tectonic", "-X", "compile", "--keep-logs", file }, dir, "pdf"
    elseif exe("pdflatex") then
      return { "pdflatex", "-interaction=nonstopmode", "-halt-on-error", "-file-line-error", file }, dir, "pdf"
    end
    return nil, "No LaTeX compiler found (install latexmk, tectonic or pdflatex)"
  elseif ext == "typ" then
    if exe("typst") then return { "typst", "compile", file }, dir, "pdf" end
    return nil, "typst not found (brew install typst)"
  end
  return nil, "Not a .tex / .typ file"
end

local function fill_quickfix(out, file)
  local items = {}
  for line in out:gmatch("[^\r\n]+") do
    local f, l, m = line:match("^(%S+%.tex):(%d+): (.+)$")
    if f then items[#items + 1] = { filename = f, lnum = tonumber(l), text = m } end
  end
  if #items > 0 then vim.fn.setqflist({}, "r", { title = "LaTeX errors", items = items }) end
  return #items
end

function M.compile(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then return notify("Save the file first", vim.log.levels.WARN) end
  if running[file] then return end

  if vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent! noautocmd update") end)
  end

  local cmd, cwd, kind = doc_command(file)
  if not cmd then return notify(cwd, vim.log.levels.ERROR) end

  running[file] = true
  log("$ " .. table.concat(cmd, " "))
  vim.system(cmd, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      running[file] = nil
      local out = (res.stdout or "") .. (res.stderr or "")
      log(out)
      local pdf = file:gsub("%.%w+$", "." .. kind)
      if res.code == 0 then
        vim.fn.setqflist({}, "r", { title = "LaTeX errors", items = {} })
        if not opened[pdf] then
          opened[pdf] = true
          M.open_output(pdf)
        end
        vim.api.nvim_echo({ { "  compiled " .. vim.fn.fnamemodify(pdf, ":t"), "DiagnosticOk" } }, false, {})
      else
        local n = fill_quickfix(out, file)
        notify(("Compile failed (%d error%s). :NvilLog for output"):format(n, n == 1 and "" or "s"), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.open_pdf(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  M.open_output((file:gsub("%.%w+$", ".pdf")))
end

-- ── Manim ───────────────────────────────────────────────────────────────────

local QUALITY = { l = "480p15", m = "720p30", h = "1080p60", p = "1440p60", k = "2160p60" }

local function scenes_in(buf)
  local out = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local name = line:match("^class%s+([%w_]+)%s*%(.*Scene.*%)")
    if name then out[#out + 1] = name end
  end
  return out
end

function M.manim_render(buf, quality, scene)
  buf = buf or vim.api.nvim_get_current_buf()
  if not exe("manim") then return notify("manim not found on PATH", vim.log.levels.ERROR) end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then return notify("Save the file first", vim.log.levels.WARN) end
  if vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent! noautocmd update") end)
  end
  quality = quality or "l"
  scene = scene or last_scene[buf]
  if not scene then
    local found = scenes_in(buf)
    if #found == 0 then return notify("No Scene subclass found in this file", vim.log.levels.WARN) end
    if #found > 1 then
      return vim.ui.select(found, { prompt = "Manim scene" }, function(choice)
        if choice then last_scene[buf] = choice; M.manim_render(buf, quality, choice) end
      end)
    end
    scene = found[1]
  end
  last_scene[buf] = scene
  if running[file] then return end
  running[file] = true

  local cwd = vim.fn.fnamemodify(file, ":h")
  local cmd = { "manim", "-q" .. quality, "--disable_caching", file, scene }
  log("$ " .. table.concat(cmd, " "))
  notify("Rendering " .. scene .. " (" .. QUALITY[quality] .. ")…")
  vim.system(cmd, { cwd = cwd, text = true, env = { COLUMNS = "400" } }, function(res)
    vim.schedule(function()
      running[file] = nil
      local out = (res.stdout or "") .. (res.stderr or "")
      log(out)
      if res.code ~= 0 then
        return notify("Manim failed. :NvilLog for output", vim.log.levels.ERROR)
      end
      local stem = vim.fn.fnamemodify(file, ":t:r")
      local mp4 = ("%s/media/videos/%s/%s/%s.mp4"):format(cwd, stem, QUALITY[quality], scene)
      notify("Rendered " .. scene)
      M.open_output(mp4)
    end)
  end)
end

function M.manim_pick_scene(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local found = scenes_in(buf)
  if #found == 0 then return notify("No Scene subclass found", vim.log.levels.WARN) end
  vim.ui.select(found, { prompt = "Manim scene" }, function(choice)
    if choice then last_scene[buf] = choice; notify("Scene: " .. choice) end
  end)
end

-- ── Live mode (debounced) ───────────────────────────────────────────────────

local function is_manim(buf) return vim.bo[buf].filetype == "python" end

function M.toggle_live(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local tool = is_manim(buf) and "manim_live" or "latex_live"
  if Data.get_value("tools." .. tool) == false then
    return notify("Live render is disabled in Settings -> Tools", vim.log.levels.WARN)
  end

  if live[buf] then
    live[buf].timer:stop(); live[buf].timer:close()
    pcall(vim.api.nvim_del_augroup_by_id, live[buf].group)
    live[buf] = nil
    return notify("Live render: off")
  end

  local timer = vim.uv.new_timer()
  local group = vim.api.nvim_create_augroup("nvil_live_" .. buf, { clear = true })
  live[buf] = { timer = timer, group = group }

  local function schedule_run()
    timer:stop()
    timer:start(delay(), 0, vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if is_manim(buf) then M.manim_render(buf, "l") else M.compile(buf) end
    end))
  end

  local events = is_manim(buf) and { "BufWritePost" } or { "TextChanged", "TextChangedI", "BufWritePost" }
  vim.api.nvim_create_autocmd(events, { group = group, buffer = buf, callback = schedule_run })
  vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = buf, callback = function()
    if live[buf] then pcall(function() live[buf].timer:stop(); live[buf].timer:close() end); live[buf] = nil end
  end })
  notify(("Live render: on (%s, %dms debounce)"):format(ft, delay()))
  if is_manim(buf) then M.manim_render(buf, "l") else M.compile(buf) end
end

function M.setup()
  local cmd = vim.api.nvim_create_user_command
  cmd("NvilCompile", function() M.compile() end, { desc = "Compile current LaTeX/Typst file" })
  cmd("NvilLive", function() M.toggle_live() end, { desc = "Toggle live auto-compile for this buffer" })
  cmd("NvilLog", function() M.show_log() end, { desc = "Show render log" })
  cmd("NvilPdf", function() M.open_pdf() end, { desc = "Open compiled PDF" })
  cmd("ManimRender", function(o) M.manim_render(nil, o.args ~= "" and o.args or "l") end,
    { nargs = "?", complete = function() return { "l", "m", "h", "k" } end, desc = "Render a Manim scene (quality l/m/h/k)" })
  cmd("ManimScene", function() M.manim_pick_scene() end, { desc = "Pick the Manim scene to render" })
end

return M
