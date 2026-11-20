-- tools/network.lua
-- Cisco / networking helpers. This is NOT a packet simulator (Packet Tracer,
-- GNS3 and containerlab do that); it covers the editor side of the workflow:
--   :NetConsole   serial console to a switch/router (screen, 9600 8N1)
--   :NetSsh       ssh / telnet to a device (hosts from ~/.ssh/config)
--   :NetPing / :NetTrace
--   :NetSubnet 10.0.0.77/26   network, mask, wildcard, broadcast, host range
--   :NetInterfaces            table of interfaces from the open IOS config
-- Cisco IOS syntax highlighting comes from momota/cisco.vim (*.ios, *.cisco, *.cfg).

local M = {}

local function term(cmd, title)
  vim.cmd("botright 14split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
  vim.b.nvil_term_title = title
end

local function ssh_hosts()
  local hosts = {}
  local f = io.open(vim.fn.expand("~/.ssh/config"), "r")
  if f then
    for line in f:lines() do
      local h = line:match("^%s*[Hh]ost%s+(%S+)")
      if h and not h:find("[*?]") then hosts[#hosts + 1] = h end
    end
    f:close()
  end
  return hosts
end

function M.console()
  local devs = vim.fn.glob("/dev/tty.usb*", false, true)
  vim.list_extend(devs, vim.fn.glob("/dev/cu.usb*", false, true))
  if #devs == 0 then return vim.notify("No USB serial device found", vim.log.levels.WARN, { title = "Network" }) end
  vim.ui.select(devs, { prompt = "Console port" }, function(dev)
    if dev then term(("screen %s 9600"):format(dev), "console") end
  end)
end

function M.connect()
  local hosts = ssh_hosts()
  vim.ui.select({ "ssh", "telnet" }, { prompt = "Protocol" }, function(proto)
    if not proto then return end
    local function go(host)
      if host and host ~= "" then term(("%s %s"):format(proto, host), proto .. " " .. host) end
    end
    if #hosts > 0 and proto == "ssh" then
      vim.list_extend(hosts, { "(type a host…)" })
      vim.ui.select(hosts, { prompt = "Host" }, function(h)
        if h == "(type a host…)" then vim.ui.input({ prompt = "Host: " }, go) else go(h) end
      end)
    else
      vim.ui.input({ prompt = "Host: " }, go)
    end
  end)
end

function M.ping(host)
  local function go(h) if h and h ~= "" then term("ping -c 5 " .. vim.fn.shellescape(h), "ping") end end
  if host and host ~= "" then go(host) else vim.ui.input({ prompt = "Ping: " }, go) end
end

function M.trace(host)
  local function go(h) if h and h ~= "" then term("traceroute " .. vim.fn.shellescape(h), "trace") end end
  if host and host ~= "" then go(host) else vim.ui.input({ prompt = "Traceroute: " }, go) end
end

-- ── Subnet calculator (IPv4) ────────────────────────────────────────────────

local function ip2n(ip)
  local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  if not a then return nil end
  a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
  if a > 255 or b > 255 or c > 255 or d > 255 then return nil end
  return ((a * 256 + b) * 256 + c) * 256 + d
end

local function n2ip(n)
  return ("%d.%d.%d.%d"):format(math.floor(n / 16777216) % 256, math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

function M.subnet(arg)
  local ip, bits = (arg or ""):match("^(%d+%.%d+%.%d+%.%d+)/(%d+)$")
  local n = ip and ip2n(ip)
  bits = tonumber(bits)
  if not n or not bits or bits > 32 then
    return vim.notify("Usage: :NetSubnet 192.168.1.10/24", vim.log.levels.WARN, { title = "Network" })
  end
  local size = 2 ^ (32 - bits)
  local mask = 4294967296 - size
  local net = math.floor(n / size) * size
  local bcast = net + size - 1
  local hosts = bits >= 31 and size or size - 2
  local first = bits >= 31 and net or net + 1
  local last = bits >= 31 and bcast or bcast - 1
  local lines = {
    ("Address   : %s/%d"):format(ip, bits),
    ("Netmask   : %s"):format(n2ip(mask)),
    ("Wildcard  : %s"):format(n2ip(4294967295 - mask)),
    ("Network   : %s/%d"):format(n2ip(net), bits),
    ("Broadcast : %s"):format(n2ip(bcast)),
    ("Hosts     : %s – %s  (%d usable)"):format(n2ip(first), n2ip(last), hosts),
  }
  M.float(lines, " Subnet ")
end

function M.float(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local w = 20
  for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l) + 2) end
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = math.min(w, vim.o.columns - 4), height = math.min(#lines, vim.o.lines - 6),
    row = math.floor((vim.o.lines - #lines) / 3), col = math.floor((vim.o.columns - w) / 2),
    style = "minimal", border = "rounded", title = title, title_pos = "center",
  })
  vim.bo[buf].bufhidden = "wipe"
  for _, k in ipairs({ "q", "<Esc>" }) do vim.keymap.set("n", k, "<cmd>close<cr>", { buffer = buf, nowait = true }) end
  return win
end

-- ── Interface table from a Cisco IOS config ─────────────────────────────────

function M.interfaces(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local rows, cur = {}, nil
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local name = line:match("^interface%s+(%S+)")
    if name then
      cur = { name = name, ip = "", desc = "", vlan = "", state = "up" }
      rows[#rows + 1] = cur
    elseif cur and line:match("^%S") then
      cur = nil
    elseif cur then
      cur.desc = line:match("^%s*description%s+(.+)") or cur.desc
      local ip, mask = line:match("^%s*ip address%s+(%S+)%s+(%S+)")
      if ip then cur.ip = ip .. " " .. mask end
      cur.vlan = line:match("switchport access vlan%s+(%d+)") or cur.vlan
      if line:match("^%s*shutdown") then cur.state = "down" end
    end
  end
  if #rows == 0 then return vim.notify("No `interface` blocks in this buffer", vim.log.levels.WARN, { title = "Network" }) end
  local out = { ("%-22s %-6s %-6s %-30s %s"):format("INTERFACE", "STATE", "VLAN", "IP", "DESCRIPTION") }
  for _, r in ipairs(rows) do
    out[#out + 1] = ("%-22s %-6s %-6s %-30s %s"):format(r.name, r.state, r.vlan, r.ip, r.desc)
  end
  M.float(out, " Interfaces ")
end

function M.setup()
  local cmd = vim.api.nvim_create_user_command
  cmd("NetConsole", M.console, { desc = "Serial console to a Cisco device" })
  cmd("NetSsh", M.connect, { desc = "SSH / telnet to a device" })
  cmd("NetPing", function(o) M.ping(o.args) end, { nargs = "?" })
  cmd("NetTrace", function(o) M.trace(o.args) end, { nargs = "?" })
  cmd("NetSubnet", function(o) M.subnet(o.args) end, { nargs = 1, desc = "IPv4 subnet calculator" })
  cmd("NetInterfaces", function() M.interfaces() end, { desc = "Interface table from IOS config" })

  vim.filetype.add({ extension = { ios = "cisco", cisco = "cisco" } })
end

return M
