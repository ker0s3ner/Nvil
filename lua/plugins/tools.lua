-- All-in-one tools: LeetCode, Strudel (music), Jupyter, LaTeX/PDF/Manim live
-- render, mind-map graph, Cisco networking, markdown. Each tool can be switched
-- off in Settings -> Tools (takes effect on next start).
--
-- Leader groups:  <leader>L leetcode   <leader>M music     <leader>J jupyter
--                 <leader>R render     <leader>N network    <leader>O notes/mind map
--                 <leader>;  tool launcher

local function on(key)
  local ok, Data = pcall(require, "freebuff.settings.data")
  return not ok or Data.get_value("tools." .. key) ~= false
end

local function pack(key, default)
  local ok, Data = pcall(require, "freebuff.settings.data")
  return ok and Data.get_value("packs." .. key) or default
end

return {
  -- ── Tool launcher + render/network/mindmap modules ───────────────────
  {
    dir = vim.fn.stdpath("config"),
    name = "nvil-tools",
    event = "VeryLazy",
    keys = {
      { "<leader>;", function() require("tools").launcher() end, desc = "Tools launcher" },
      { "<leader>Rc", "<cmd>NvilCompile<cr>", desc = "Compile TeX/Typst" },
      { "<leader>Rl", "<cmd>NvilLive<cr>", desc = "Toggle live render" },
      { "<leader>Rp", "<cmd>NvilPdf<cr>", desc = "Open PDF" },
      { "<leader>Rm", "<cmd>ManimRender<cr>", desc = "Manim render (low quality)" },
      { "<leader>RM", "<cmd>ManimRender h<cr>", desc = "Manim render (1080p)" },
      { "<leader>Rs", "<cmd>ManimScene<cr>", desc = "Pick Manim scene" },
      { "<leader>Rg", "<cmd>NvilLog<cr>", desc = "Render log" },
      { "<leader>Og", "<cmd>MindMap<cr>", desc = "Project graph (mind map)" },
      { "<leader>Oo", "<cmd>MindMapFile<cr>", desc = "Outline mind map of this file" },
      { "<leader>Nc", "<cmd>NetConsole<cr>", desc = "Serial console" },
      { "<leader>Ns", "<cmd>NetSsh<cr>", desc = "SSH / telnet" },
      { "<leader>Np", "<cmd>NetPing<cr>", desc = "Ping" },
      { "<leader>Nt", "<cmd>NetTrace<cr>", desc = "Traceroute" },
      { "<leader>Ni", "<cmd>NetInterfaces<cr>", desc = "IOS interface table" },
      { "<leader>Nn", function()
          vim.ui.input({ prompt = "Subnet (ip/prefix): " }, function(v) if v and v ~= "" then vim.cmd("NetSubnet " .. v) end end)
        end, desc = "Subnet calculator" },
    },
    config = function()
      require("tools.render").setup()
      require("tools.network").setup()
      require("tools.mindmap").setup()
    end,
  },

  -- ── LeetCode ─────────────────────────────────────────────────────────
  {
    "kawre/leetcode.nvim",
    enabled = on("leetcode"),
    cmd = "Leet",
    build = ":TSUpdate html",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>Ll", "<cmd>Leet<cr>", desc = "LeetCode menu" },
      { "<leader>Lr", "<cmd>Leet run<cr>", desc = "Run" },
      { "<leader>Ls", "<cmd>Leet submit<cr>", desc = "Submit" },
      { "<leader>Ld", "<cmd>Leet daily<cr>", desc = "Daily problem" },
      { "<leader>Lp", "<cmd>Leet list<cr>", desc = "Problem list" },
      { "<leader>Li", "<cmd>Leet info<cr>", desc = "Problem info" },
      { "<leader>Lc", "<cmd>Leet console<cr>", desc = "Console" },
      { "<leader>Lo", "<cmd>Leet open<cr>", desc = "Open in browser" },
    },
    opts = function()
      return {
        lang = pack("leetcode_lang", "python3"),
        picker = { provider = "snacks-picker" },
        storage = { home = vim.fn.expand("~/leetcode"), cache = vim.fn.stdpath("cache") .. "/leetcode" },
        description = { position = "left", width = "40%", show_stats = true },
        console = { open_on_runcode = true },
      }
    end,
  },

  -- ── Strudel live-coding music ────────────────────────────────────────
  {
    "gruvw/strudel.nvim",
    enabled = on("strudel"),
    build = "npm install",
    event = { "BufReadPre *.str", "BufNewFile *.str", "BufReadPre *.std" },
    cmd = { "StrudelLaunch" },
    keys = {
      { "<leader>Ml", function() require("strudel").launch() end, desc = "Strudel: launch" },
      { "<leader>Mq", function() require("strudel").quit() end, desc = "Strudel: quit" },
      { "<leader>Mt", function() require("strudel").toggle() end, desc = "Strudel: play/pause" },
      { "<leader>Mu", function() require("strudel").update() end, desc = "Strudel: update code" },
      { "<leader>Ms", function() require("strudel").stop() end, desc = "Strudel: stop" },
      { "<leader>Mb", function() require("strudel").set_buffer() end, desc = "Strudel: use this buffer" },
      { "<leader>Me", function() require("strudel").execute() end, desc = "Strudel: execute" },
      { "<leader>Mn", function() require("tools").strudel_new() end, desc = "Strudel: new from music pack" },
    },
    opts = {
      ui = { maximise_menu_panel = true, hide_menu_panel = false, hide_top_bar = false, hide_code_editor = true, hide_error_display = false },
      update_on_save = true,
      sync_cursor = true,
      report_eval_errors = true,
    },
  },

  -- ── Jupyter notebooks ────────────────────────────────────────────────
  -- .ipynb opens as plain text via jupytext (pip install jupytext); Molten runs
  -- cells against a real kernel and shows output inline (images via image.nvim).
  {
    "GCBallesteros/jupytext.nvim",
    enabled = on("jupyter"),
    lazy = false,
    opts = {
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
    },
  },
  {
    "benlubas/molten-nvim",
    enabled = on("jupyter"),
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    cmd = { "MoltenInit", "MoltenEvaluateOperator", "MoltenEvaluateLine" },
    ft = { "python", "markdown", "quarto", "julia" },
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_use_border_highlights = true
    end,
    keys = {
      { "<leader>Ji", function()
          local k = pack("kernel", "python3")
          vim.cmd("MoltenInit " .. k)
        end, desc = "Jupyter: init kernel (pack default)" },
      { "<leader>JI", "<cmd>MoltenInit<cr>", desc = "Jupyter: pick kernel" },
      { "<leader>Je", "<cmd>MoltenEvaluateOperator<cr>", desc = "Jupyter: run operator" },
      { "<leader>Jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Jupyter: run line" },
      { "<leader>Jr", "<cmd>MoltenReevaluateCell<cr>", desc = "Jupyter: re-run cell" },
      { "<leader>Jv", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Jupyter: run selection" },
      { "<leader>Jo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Jupyter: show output" },
      { "<leader>Jh", "<cmd>MoltenHideOutput<cr>", desc = "Jupyter: hide output" },
      { "<leader>Jd", "<cmd>MoltenDelete<cr>", desc = "Jupyter: delete cell" },
      { "<leader>Jx", "<cmd>MoltenInterrupt<cr>", desc = "Jupyter: interrupt" },
      { "<leader>Jk", "<cmd>MoltenRestart!<cr>", desc = "Jupyter: restart kernel" },
    },
  },

  -- ── Cisco IOS syntax ─────────────────────────────────────────────────
  {
    "momota/cisco.vim",
    enabled = on("network"),
    ft = { "cisco" },
  },

  -- ── which-key group labels ───────────────────────────────────────────
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>L", group = "leetcode", icon = "󰆦" },
        { "<leader>M", group = "music (strudel)", icon = "󰎈" },
        { "<leader>J", group = "jupyter", icon = "" },
        { "<leader>R", group = "render (tex/manim)", icon = "󰐱" },
        { "<leader>N", group = "network (cisco)", icon = "󰛳" },
        { "<leader>O", group = "notes / mind map", icon = "󱓧" },
      },
    },
  },
}
