local terminal = "com.superlogical.terminal"

local GROUP_RANK = { attention = 1, working = 2, idle = 3 }

local STATE = {
  blocked = { group = "attention", color = "\27[31m", label = "blocked" },
  done = { group = "attention", color = "\27[32m", label = "done" },
  error = { group = "attention", color = "\27[35m", label = "error" },
  working = { group = "working", color = "\27[33m", label = "working" },
  idle = { group = "idle", color = "\27[2m", label = "idle" },
}

local function clean(value)
  return ((tostring(value or "")):gsub("[%c]+", " "))
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

local function sessions()
  return assert(rex.call("session.list")).sessions or {}
end

local function view_for(session_id)
  local view = rex.session.view{ session_id = session_id }
  if not view or not view.windows then
    assert(rex.session.attach{ session_id = session_id })
    view = assert(rex.session.view{ session_id = session_id })
  end
  return view
end

local function session_label(view, session)
  return clean(view.label or session.label or session.session_id)
end

local function window_label(window)
  return clean(window.label or window.window_id)
end

local function holds_block(window, block_id)
  for _, layer in ipairs(window.layers or {}) do
    for _, block in ipairs(layer.blocks or {}) do
      if block.block_id == block_id then return true end
    end
  end
  return false
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

local function block_title(session_id, block_id)
  local title = rex.call(terminal .. ".title", { session_id = session_id, block_id = block_id })
  return clean(title and title.title)
end

local function agent_state(session_id, block_id)
  local status = rex.call(terminal .. ".program_status", {
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

local function agent_row(session, label, window, block, excluded_block, now)
  if block.block_id == excluded_block or block.creator_name ~= terminal then return nil end
  local chosen = agent_state(session.session_id, block.block_id)
  if not chosen then return nil end

  local record = chosen.record
  local app = clean(record.effective_app or record.app or "-")
  local display = ("%s%-7s\27[0m %4s  %s  %s / %s  %s"):format(
    chosen.presentation.color,
    chosen.presentation.label,
    age(chosen.updated, now),
    app,
    label,
    window_label(window),
    block_title(session.session_id, block.block_id))

  return {
    group = chosen.presentation.group,
    rank = chosen.rank,
    updated = chosen.updated,
    line = table.concat({
      session.session_id,
      window.window_id,
      block.block_id,
      "agent",
      display,
    }, "\t"),
  }
end

local function agent_lines(block_id, filter)
  local now = os.time()
  local rows = {}
  for _, session in ipairs(sessions()) do
    local view = view_for(session.session_id)
    local label = session_label(view, session)
    for _, entry in ipairs(view_blocks(view)) do
      local row = agent_row(session, label, entry.window, entry.block, block_id, now)
      if row and (not filter or row.group == filter) then table.insert(rows, row) end
    end
  end

  table.sort(rows, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    if a.updated ~= b.updated then return a.updated > b.updated end
    return a.line < b.line
  end)

  local lines = {}
  for _, row in ipairs(rows) do table.insert(lines, row.line) end
  return lines
end

local function target_block(blocks, focused_id)
  for _, block in ipairs(blocks) do
    if block.block_id == focused_id then return block.block_id end
  end
  return blocks[1] and blocks[1].block_id
end

local function window_target(window)
  for _, layer in ipairs(window.layers or {}) do
    if layer.kind ~= "floating" then
      return target_block(layer.blocks or {}, window.focused_block_id)
    end
  end
  return window.focused_block_id
end

local function tab_lines(block_id)
  local lines = {}
  for _, session in ipairs(sessions()) do
    local view = view_for(session.session_id)
    local label = session_label(view, session)
    for _, window in ipairs(view.windows or {}) do
      local marker = ""
      if holds_block(window, block_id) then marker = "  (current)" end
      table.insert(lines, table.concat({
        session.session_id,
        window.window_id,
        window_target(window),
        "tab",
        label .. " / " .. window_label(window) .. marker,
      }, "\t"))
    end
  end
  return lines
end

local MODES = { agents = agent_lines, tabs = tab_lines }

local mode = rex.args.mode or "agents"
local filter = rex.args.filter
if filter == "all" then filter = nil end

local render = assert(MODES[mode], "unknown mode " .. mode)
for _, line in ipairs(render(rex.args.block, filter)) do
  print(line)
end
