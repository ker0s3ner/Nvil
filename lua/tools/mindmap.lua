-- tools/mindmap.lua
-- Obsidian-style graph view for a folder, rendered to a self-contained HTML
-- file (own force-directed layout, no CDN) and opened in your browser.
--   :MindMap       notes + code graph of the current project
--                  (markdown [[wikilinks]] / links, lua require, python import, js/ts relative imports)
--   :MindMapFile   heading outline of the current markdown file as a mind map
-- Drag nodes, scroll to zoom, drag background to pan, type in the box to filter.

local M = {}

local EXTS = { md = true, markdown = true, lua = true, py = true, js = true, jsx = true, ts = true, tsx = true }
local MAX_FILES = 1500

local function list_files(root)
  local out = vim.fn.systemlist({ "git", "-C", root, "ls-files", "--cached", "--others", "--exclude-standard" })
  if vim.v.shell_error ~= 0 then
    out = vim.fn.systemlist({ "find", root, "-maxdepth", "7", "-type", "f", "-not", "-path", "*/.git/*",
      "-not", "-path", "*/node_modules/*", "-not", "-path", "*/.venv/*" })
    for i, p in ipairs(out) do out[i] = p:sub(#root + 2) end
  end
  local files = {}
  for _, p in ipairs(out) do
    local ext = p:match("%.(%w+)$")
    if ext and EXTS[ext:lower()] then files[#files + 1] = p end
    if #files >= MAX_FILES then break end
  end
  return files
end

local function read(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local s = f:read("*a") or ""
  f:close()
  return s
end

local function norm(p)
  local parts = {}
  for seg in p:gmatch("[^/]+") do
    if seg == ".." then table.remove(parts) elseif seg ~= "." then parts[#parts + 1] = seg end
  end
  return table.concat(parts, "/")
end

function M.build_project(root)
  local files = list_files(root)
  local set, by_base, lua_mod, py_mod = {}, {}, {}, {}
  for _, p in ipairs(files) do
    set[p] = true
    local base = vim.fn.fnamemodify(p, ":t:r"):lower()
    by_base[base] = by_base[base] or p
    if p:match("%.lua$") then
      local m = p:gsub("^.-lua/", ""):gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
      lua_mod[m] = p
    elseif p:match("%.py$") then
      py_mod[(p:gsub("%.py$", ""):gsub("/__init__$", ""):gsub("/", "."))] = p
    end
  end

  local nodes, links, seen = {}, {}, {}
  local function node(id, label, group)
    if not seen[id] then
      seen[id] = true
      nodes[#nodes + 1] = { id = id, label = label, group = group }
    end
  end
  local function link(a, b) if a ~= b then links[#links + 1] = { a, b } end end

  for _, p in ipairs(files) do
    local ext = p:match("%.(%w+)$"):lower()
    local group = p:match("^([^/]+)/") or "."
    node(p, vim.fn.fnamemodify(p, ":t"), group)
    local text = read(root .. "/" .. p)

    if ext == "md" or ext == "markdown" then
      for target in text:gmatch("%[%[([^%]|#]+)") do
        local hit = by_base[vim.trim(target):lower()]
        if hit then link(p, hit) else
          local id = "[[" .. target .. "]]"
          node(id, target, "unresolved"); link(p, id)
        end
      end
      for target in text:gmatch("%]%(([^)#%s]+%.md)") do
        local hit = norm(vim.fn.fnamemodify(p, ":h") .. "/" .. target)
        if set[hit] then link(p, hit) end
      end
    elseif ext == "lua" then
      for m in text:gmatch("require%s*%(?%s*[\"']([%w_%.%-/]+)[\"']") do
        local hit = lua_mod[m:gsub("/", ".")]
        if hit then link(p, hit) end
      end
    elseif ext == "py" then
      for m in text:gmatch("\n%s*from%s+([%w_%.]+)%s+import") do
        local hit = py_mod[m] or py_mod[m:match("([%w_]+)$") or ""]
        if hit then link(p, hit) end
      end
      for m in text:gmatch("\n%s*import%s+([%w_%.]+)") do
        local hit = py_mod[m]
        if hit then link(p, hit) end
      end
    else -- js / ts
      for m in text:gmatch("from%s+[\"'](%.[^\"']+)[\"']") do
        local base = norm(vim.fn.fnamemodify(p, ":h") .. "/" .. m)
        for _, e in ipairs({ "", ".ts", ".tsx", ".js", ".jsx", "/index.ts", "/index.js" }) do
          if set[base .. e] then link(p, base .. e); break end
        end
      end
    end
  end
  return { nodes = nodes, links = links }
end

function M.build_outline(buf)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  local nodes, links = { { id = "root", label = name ~= "" and name or "document", group = "root" } }, {}
  local stack = { { level = 0, id = "root" } }
  local in_code = false
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match("^```") then in_code = not in_code end
    local hashes, title = line:match("^(#+)%s+(.+)$")
    if hashes and not in_code then
      local level = #hashes
      while #stack > 1 and stack[#stack].level >= level do table.remove(stack) end
      local id = "h" .. i
      nodes[#nodes + 1] = { id = id, label = title, group = "h" .. math.min(level, 4) }
      links[#links + 1] = { stack[#stack].id, id }
      stack[#stack + 1] = { level = level, id = id }
    end
  end
  return { nodes = nodes, links = links }
end

local TEMPLATE = [==[<!doctype html><meta charset="utf-8"><title>__TITLE__</title>
<style>
html,body{margin:0;height:100%;background:#090909;color:#f2f2f2;font:13px ui-monospace,Menlo,monospace;overflow:hidden}
canvas{display:block;width:100vw;height:100vh}
#bar{position:fixed;top:12px;left:12px;display:flex;gap:8px;align-items:center}
#q{background:#111;border:1px solid __ACCENT__;color:#f2f2f2;padding:6px 10px;border-radius:6px;outline:none;width:220px}
#info{position:fixed;bottom:12px;left:12px;color:#8a8a8a}
#hov{position:fixed;bottom:12px;right:12px;color:__ACCENT__}
</style>
<div id="bar"><input id="q" placeholder="filter…" autofocus><span id="stat"></span></div>
<canvas id="c"></canvas><div id="info"></div><div id="hov"></div>
<script>
const ACCENT="__ACCENT__",data=__DATA__;
const cv=document.getElementById("c"),cx=cv.getContext("2d");
let W,H,dpr=devicePixelRatio||1;
function size(){W=innerWidth;H=innerHeight;cv.width=W*dpr;cv.height=H*dpr;cx.setTransform(dpr,0,0,dpr,0,0)}size();addEventListener("resize",size);
const N=data.nodes.map(n=>({...n,x:(Math.random()-.5)*500,y:(Math.random()-.5)*400,vx:0,vy:0,deg:0}));
const byId={};N.forEach(n=>byId[n.id]=n);
const L=data.links.map(l=>({s:byId[l[0]],t:byId[l[1]]})).filter(l=>l.s&&l.t);
L.forEach(l=>{l.s.deg++;l.t.deg++});
const groups=[...new Set(N.map(n=>n.group))];
const shade=g=>g==="unresolved"?"#555":g==="root"?"#ffffff":`hsl(${350+groups.indexOf(g)*17%40-10},${60+groups.indexOf(g)*7%35}%,${45+groups.indexOf(g)*9%25}%)`;
document.getElementById("stat").textContent=N.length+" nodes · "+L.length+" links";
document.getElementById("info").textContent="drag nodes · scroll to zoom · drag background to pan";
let cam={x:0,y:0,k:1},drag=null,pan=null,hover=null,filter="",heat=1;
const rad=n=>4+Math.min(14,Math.sqrt(n.deg)*2.4);
function step(){
 const k=heat;
 for(let i=0;i<N.length;i++){const a=N[i];
  for(let j=i+1;j<N.length;j++){const b=N[j];let dx=a.x-b.x,dy=a.y-b.y,d2=dx*dx+dy*dy+.01;
   if(d2<90000){const f=2400/d2*k,d=Math.sqrt(d2);dx/=d;dy/=d;a.vx+=dx*f;a.vy+=dy*f;b.vx-=dx*f;b.vy-=dy*f}}
  a.vx-=a.x*.004*k;a.vy-=a.y*.004*k}
 for(const l of L){const dx=l.t.x-l.s.x,dy=l.t.y-l.s.y,d=Math.sqrt(dx*dx+dy*dy)+.01,f=(d-70)*.02*k;
  const fx=dx/d*f,fy=dy/d*f;l.s.vx+=fx;l.s.vy+=fy;l.t.vx-=fx;l.t.vy-=fy}
 for(const n of N){if(n===drag)continue;n.vx*=.82;n.vy*=.82;n.x+=n.vx;n.y+=n.vy}
 heat=Math.max(.15,heat*.995)}
const sx=x=>(x-cam.x)*cam.k+W/2,sy=y=>(y-cam.y)*cam.k+H/2;
const wx=x=>(x-W/2)/cam.k+cam.x,wy=y=>(y-H/2)/cam.k+cam.y;
const match=n=>!filter||n.label.toLowerCase().includes(filter)||n.id.toLowerCase().includes(filter);
function draw(){
 cx.clearRect(0,0,W,H);
 const nb=new Set();if(hover){nb.add(hover);L.forEach(l=>{if(l.s===hover)nb.add(l.t);if(l.t===hover)nb.add(l.s)})}
 for(const l of L){const hot=hover&&(l.s===hover||l.t===hover);
  cx.strokeStyle=hot?ACCENT:"rgba(255,255,255,.13)";cx.lineWidth=hot?1.6:1;
  cx.beginPath();cx.moveTo(sx(l.s.x),sy(l.s.y));cx.lineTo(sx(l.t.x),sy(l.t.y));cx.stroke()}
 for(const n of N){const dim=(hover&&!nb.has(n))||!match(n);
  cx.globalAlpha=dim?.18:1;cx.fillStyle=n===hover?ACCENT:shade(n.group);
  cx.beginPath();cx.arc(sx(n.x),sy(n.y),rad(n)*cam.k,0,7);cx.fill();
  if(cam.k>.55&&(n.deg>1||cam.k>1.1||n===hover||(filter&&match(n)))){cx.fillStyle="#f2f2f2";cx.font=(11*Math.min(cam.k,1.4))+"px ui-monospace,monospace";
   cx.fillText(n.label,sx(n.x)+rad(n)*cam.k+4,sy(n.y)+3)}}
 cx.globalAlpha=1}
function loop(){step();draw();requestAnimationFrame(loop)}loop();
const pick=(mx,my)=>{let best=null,bd=1e9;for(const n of N){const dx=sx(n.x)-mx,dy=sy(n.y)-my,d=Math.sqrt(dx*dx+dy*dy);if(d<rad(n)*cam.k+5&&d<bd){best=n;bd=d}}return best};
cv.onmousedown=e=>{const n=pick(e.clientX,e.clientY);if(n){drag=n;heat=1}else pan={x:e.clientX,y:e.clientY,cx:cam.x,cy:cam.y}};
addEventListener("mouseup",()=>{drag=null;pan=null});
cv.onmousemove=e=>{if(drag){drag.x=wx(e.clientX);drag.y=wy(e.clientY);drag.vx=drag.vy=0}
 else if(pan){cam.x=pan.cx-(e.clientX-pan.x)/cam.k;cam.y=pan.cy-(e.clientY-pan.y)/cam.k}
 else{hover=pick(e.clientX,e.clientY);document.getElementById("hov").textContent=hover?hover.id+"  ("+hover.deg+" links)":""}};
cv.onwheel=e=>{e.preventDefault();const f=e.deltaY<0?1.1:.9,bx=wx(e.clientX),by=wy(e.clientY);cam.k=Math.max(.15,Math.min(5,cam.k*f));cam.x=bx-(e.clientX-W/2)/cam.k;cam.y=by-(e.clientY-H/2)/cam.k};
document.getElementById("q").oninput=e=>{filter=e.target.value.toLowerCase()};
</script>]==]

local function open_html(graph, title)
  local theme_ok, Theme = pcall(require, "freebuff.theme")
  local accent = theme_ok and Theme.current().accent or "#ff304f"
  local json = vim.json.encode(graph):gsub("</", "<\\/")
  local html = TEMPLATE
    :gsub("__TITLE__", function() return title end)
    :gsub("__ACCENT__", function() return accent end)
    :gsub("__DATA__", function() return json end)
  local path = vim.fn.stdpath("cache") .. "/nvil-mindmap.html"
  local f = assert(io.open(path, "w"))
  f:write(html)
  f:close()
  vim.ui.open(path)
end

function M.project()
  local root = vim.fn.getcwd()
  local g = M.build_project(root)
  if #g.nodes == 0 then return vim.notify("No notes/code found in " .. root, vim.log.levels.WARN, { title = "MindMap" }) end
  open_html(g, "Graph — " .. vim.fn.fnamemodify(root, ":t"))
end

function M.file()
  local buf = vim.api.nvim_get_current_buf()
  local g = M.build_outline(buf)
  if #g.nodes <= 1 then return vim.notify("No markdown headings in this buffer", vim.log.levels.WARN, { title = "MindMap" }) end
  open_html(g, "Outline — " .. vim.fn.expand("%:t"))
end

function M.setup()
  vim.api.nvim_create_user_command("MindMap", M.project, { desc = "Graph view of notes + code in this project" })
  vim.api.nvim_create_user_command("MindMapFile", M.file, { desc = "Mind map of this markdown file's headings" })
end

return M
