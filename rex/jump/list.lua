local terminal = "com.superlogical.terminal"
local HELP = "enter focus · ctrl-space jump · ctrl-t switch · ctrl-s filter · ctrl-/ hosts · esc close"

local GROUP_RANK = { attention = 1, working = 2, idle = 3 }

local STATE = {
  blocked = { group = "attention", color = "\27[31m", icon = "󰌾" },
  done = { group = "attention", color = "\27[32m", icon = "󰄬" },
  error = { group = "attention", color = "\27[35m", icon = "󰅚" },
  working = { group = "working", color = "\27[33m", icon = "󰔟" },
  idle = { group = "idle", color = "\27[2m", icon = "󰏤" },
}

local function clean(value)
  return (tostring(value or ""):gsub("[%c]+", " "))
end

local function display_width(value)
  local width, index = 0, 1
  while index <= #value do
    local lead = value:byte(index)
    local codepoint
    if lead < 0x80 then
      codepoint = lead
      index = index + 1
    elseif lead < 0xE0 then
      codepoint = (lead - 0xC0) * 0x40 + value:byte(index + 1) - 0x80
      index = index + 2
    elseif lead < 0xF0 then
      codepoint = (lead - 0xE0) * 0x1000
        + (value:byte(index + 1) - 0x80) * 0x40
        + value:byte(index + 2) - 0x80
      index = index + 3
    else
      codepoint = (lead - 0xF0) * 0x40000
        + (value:byte(index + 1) - 0x80) * 0x1000
        + (value:byte(index + 2) - 0x80) * 0x40
        + value:byte(index + 3) - 0x80
      index = index + 4
    end

    local zero = codepoint >= 0x0300 and codepoint <= 0x036F
      or codepoint >= 0x200B and codepoint <= 0x200F
      or codepoint >= 0xFE00 and codepoint <= 0xFE0F
    local wide = codepoint >= 0x1100 and codepoint <= 0x115F
      or codepoint >= 0x2E80 and codepoint <= 0xA4CF
      or codepoint >= 0xAC00 and codepoint <= 0xD7A3
      or codepoint >= 0xF900 and codepoint <= 0xFAFF
      or codepoint >= 0xFE10 and codepoint <= 0xFE19
      or codepoint >= 0xFE30 and codepoint <= 0xFE4F
      or codepoint >= 0xFF00 and codepoint <= 0xFF60
      or codepoint >= 0xFFE0 and codepoint <= 0xFFE6
      or codepoint >= 0x1F300 and codepoint <= 0x1F64F
      or codepoint >= 0x1F680 and codepoint <= 0x1F6FF
      or codepoint >= 0x1F900 and codepoint <= 0x1F9FF
      or codepoint >= 0x20000 and codepoint <= 0x3FFFD
    if not zero then width = width + (wide and 2 or 1) end
  end
  return width
end

local function days_from_civil(year, month, day)
  if month <= 2 then year = year - 1 end
  local era = math.floor(year / 400)
  local yoe = year - era * 400
  local shifted = month > 2 and month - 3 or month + 9
  local doy = math.floor((153 * shifted + 2) / 5) + day - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

local function epoch(rfc3339)
  local year, month, day, hour, min, sec, sign, hours, minutes =
    tostring(rfc3339):match(
      "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)[^+-]*([+-])(%d%d):(%d%d)$")
  if not year then return nil end
  local wall = days_from_civil(tonumber(year), tonumber(month), tonumber(day)) * 86400
    + tonumber(hour) * 3600 + tonumber(min) * 60 + tonumber(sec)
  local offset = tonumber(hours) * 3600 + tonumber(minutes) * 60
  return wall - (sign == "-" and -offset or offset)
end

local function age(rfc3339, now)
  local stamp = epoch(rfc3339)
  if not stamp then return "-" end
  local elapsed = now - stamp
  if elapsed < 60 then return "now" end
  if elapsed < 3600 then return math.floor(elapsed / 60) .. "m" end
  if elapsed < 86400 then return math.floor(elapsed / 3600) .. "h" end
  return math.floor(elapsed / 86400) .. "d"
end

local function remote_api(server)
  return {
    session = server.session,
    call = function(method, params)
      local result, err = server.call(method, params)
      if not result then error(err, 0) end
      return result
    end,
  }
end

local function host_name(name)
  return name:match("^[^.]+")
end

local function sources(hosts, block_id)
  local list = { { api = rex, route = "local", tag = "", excluded_block = block_id } }
  if not hosts then return list end

  local status = rex.call("server.status")
  local dns = status and status.tailscale and status.tailscale.dns_name
  list[1].tag = "[" .. host_name(dns or "local") .. "]"
  for _, label in ipairs(rex.servers()) do
    table.insert(list, {
      api = remote_api(rex.server(label)),
      route = "remote:" .. label,
      tag = "[" .. host_name(label) .. "]",
    })
  end
  return list
end

local function sessions(api)
  local result, err = api.call("session.list")
  if not result then error(err, 0) end
  return result.sessions or {}
end

local function view_for(api, session_id)
  local view = api.session.view{ session_id = session_id }
  if not view or not view.windows then
    assert(api.session.attach{ session_id = session_id })
    view = assert(api.session.view{ session_id = session_id })
  end
  return view
end

local function session_label(view, session)
  return clean(view.label or session.label or session.session_id)
end

local function window_name(window)
  local label = clean(window.label)
  if label == "" or label == "Window " .. window.window_id:sub(-8) then return "" end
  return "(" .. label .. ")"
end

local function segments(parts)
  local kept = {}
  for _, part in ipairs(parts) do
    if part ~= "" then table.insert(kept, part) end
  end
  return table.concat(kept, "  ")
end

local function find_block(window, block_id)
  for _, layer in ipairs(window.layers or {}) do
    for _, block in ipairs(layer.blocks or {}) do
      if block.block_id == block_id then return block end
    end
  end
  return nil
end

local function view_blocks(view)
  local entries = {}
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        table.insert(entries, { window = window, block = block })
      end
    end
  end
  return entries
end

local function block_title(api, session_id, block_id)
  local title = api.call(terminal .. ".title", { session_id = session_id, block_id = block_id })
  return clean(title and title.title)
end

local function block_dir_display(api, session_id, block_id)
  local process = api.call(terminal .. ".process", { session_id = session_id, block_id = block_id })
  local cwd = process and process.foreground and process.foreground.cwd
  if not cwd then return "" end

  local home = process.home
  local display = cwd
  if home and (cwd == home or cwd:sub(1, #home + 1) == home .. "/") then
    display = "~" .. cwd:sub(#home + 1)
  end
  return "\27[2m" .. clean(display) .. "\27[0m"
end

local function agent_state(api, session_id, block_id)
  local status = api.call(terminal .. ".program_status", {
    session_id = session_id,
    block_id = block_id,
  })

  local chosen
  for _, record in ipairs((status and status.records) or {}) do
    local presentation = STATE[record.state] or STATE.idle
    local rank = GROUP_RANK[presentation.group]
    local updated = tostring(record.updated_at or "")
    local preferred = not chosen
      or rank < chosen.rank
      or (rank == chosen.rank and updated > chosen.updated)
    if preferred then
      chosen = { presentation = presentation, rank = rank, updated = updated, record = record }
    end
  end
  return chosen
end

local function row_line(row, display)
  return table.concat({
    row.session_id,
    row.window_id,
    row.block_id,
    row.kind,
    row.route,
    display,
  }, "\t")
end

local function agent_row(source, session, label, window, block, now)
  if block.block_id == source.excluded_block or block.creator_name ~= terminal then return nil end
  local chosen = agent_state(source.api, session.session_id, block.block_id)
  if not chosen then return nil end

  local record = chosen.record
  local presentation = chosen.presentation
  local app = clean(record.effective_app or record.app or "-")
  local app_prefix = ("%s%s\27[0m %4s "):format(
    presentation.color, presentation.icon, age(chosen.updated, now))
  local tail = segments{
    block_dir_display(source.api, session.session_id, block.block_id),
    window_name(window),
    source.tag,
    block_title(source.api, session.session_id, block.block_id),
  }

  local row = {
    session_id = session.session_id,
    window_id = window.window_id,
    block_id = block.block_id,
    kind = "agent",
    route = source.route,
    group = presentation.group,
    rank = chosen.rank,
    stamp = epoch(chosen.updated) or 0,
    updated = chosen.updated,
    app_prefix = app_prefix,
    app = app,
    session = label,
    tail = tail,
  }
  row.sort_key = row_line(row, "")
  return row
end

local function agent_rows(source, filter, now)
  local rows = {}
  for _, session in ipairs(sessions(source.api)) do
    local view = view_for(source.api, session.session_id)
    local label = session_label(view, session)
    for _, entry in ipairs(view_blocks(view)) do
      local row = agent_row(source, session, label, entry.window, entry.block, now)
      if row and (not filter or row.group == filter) then table.insert(rows, row) end
    end
  end
  return rows
end

local function target_block(blocks, focused_id)
  for _, block in ipairs(blocks) do
    if block.block_id == focused_id then return block end
  end
  return blocks[1]
end

local function window_target(window)
  for _, layer in ipairs(window.layers or {}) do
    if layer.kind ~= "floating" then
      return target_block(layer.blocks or {}, window.focused_block_id)
    end
  end
  return find_block(window, window.focused_block_id)
end

local function tab_rows(source)
  local rows = {}
  for _, session in ipairs(sessions(source.api)) do
    local view = view_for(source.api, session.session_id)
    local label = session_label(view, session)
    for _, window in ipairs(view.windows or {}) do
      local target = window_target(window)
      local dir_display = ""
      if target.creator_name == terminal then
        dir_display = block_dir_display(source.api, session.session_id, target.block_id)
      end
      local current = find_block(window, source.excluded_block)
      local tail = segments{ dir_display, window_name(window), source.tag }
      table.insert(rows, {
        session_id = session.session_id,
        window_id = window.window_id,
        block_id = target.block_id,
        kind = "tab",
        route = source.route,
        session = label,
        current = current ~= nil,
        tail = tail,
      })
    end
  end
  return rows
end

local MODES = { agents = agent_rows, tabs = tab_rows }

local mode = rex.args.mode or "agents"
local filter = rex.args.filter
if filter == "all" then filter = nil end

local render = assert(MODES[mode], "unknown mode " .. mode)
local now = os.time()
local down, rows = {}, {}
for _, source in ipairs(sources(rex.args.hosts == "on", rex.args.block)) do
  local ok, result
  if source.route == "local" then
    ok, result = true, render(source, filter, now)
  else
    ok, result = pcall(render, source, filter, now)
  end
  if ok then
    for _, row in ipairs(result) do table.insert(rows, row) end
  else
    table.insert(down, source.tag .. " unreachable")
  end
end

if mode == "agents" then
  table.sort(rows, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    if a.stamp ~= b.stamp then return a.stamp > b.stamp end
    if a.updated ~= b.updated then return a.updated > b.updated end
    return a.sort_key < b.sort_key
  end)
end

local app_width, session_width = 0, 0
for _, row in ipairs(rows) do
  if row.app then app_width = math.max(app_width, display_width(row.app)) end
  session_width = math.max(session_width, display_width(row.session))
end

local header = HELP
if #down > 0 then header = header .. " · " .. table.concat(down, ", ") end
print(table.concat({ "-", "-", "-", "header", "-", header }, "\t"))
for _, row in ipairs(rows) do
  local display
  if mode == "agents" then
    display = row.app_prefix .. row.app
      .. string.rep(" ", app_width - display_width(row.app))
      .. "  " .. row.session
      .. string.rep(" ", session_width - display_width(row.session))
  else
    display = row.session
    if row.current then display = "\27[1;36m" .. display .. "\27[0m" end
    display = display .. string.rep(" ", session_width - display_width(row.session))
  end
  if row.tail ~= "" then display = display .. "  " .. row.tail end
  print(row_line(row, display))
end
