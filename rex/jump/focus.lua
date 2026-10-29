local session = assert(rex.args.session)
local kind = assert(rex.args.kind)
local window = assert(rex.args.window)
local block = assert(rex.args.block)
local route = assert(rex.args.route)
local origin = assert(os.getenv("REX_SESSION"))
local origin_block = assert(os.getenv("REX_BLOCK"))

local function app_clients(api)
  return assert(api.call("client.list", { kinds = { "app" } })).clients or {}
end

local function picker_app()
  assert(rex.session.attach{ session_id = origin })

  local owner
  for _, candidate in ipairs(assert(rex.session.list_blocks{ session_id = origin }).blocks or {}) do
    if candidate.block_id == origin_block then
      owner = candidate.owner
      break
    end
  end

  for _, candidate in ipairs(app_clients(rex)) do
    if candidate.client_id == owner and candidate.connection_state ~= "lost" then
      return candidate
    end
  end

  error(("no app client owns the jump layer (owner %s)"):format(tostring(owner)), 0)
end

local function app_on(dest, picker)
  local label = assert(picker.info and picker.info.label)
  local found
  for _, candidate in ipairs(app_clients(dest)) do
    if candidate.connection_state ~= "lost" and candidate.info and candidate.info.label == label then
      if found then error(("more than one %s app on %s"):format(label, route), 0) end
      found = candidate
    end
  end
  if not found then error(("no %s app on %s"):format(label, route), 0) end
  return found
end

local host = route:match("^remote:(.+)$")
local dest = host and rex.server(host) or rex
local picker = picker_app()
local app = host and app_on(dest, picker) or picker

if host or rex.session_id ~= session then
  assert(dest.session.attach{ session_id = session })
end

local view = assert(dest.session.view{ session_id = session })

local function holds_block(candidate, block_id)
  for _, layer in ipairs(candidate.layers or {}) do
    for _, entry in ipairs(layer.blocks or {}) do
      if entry.block_id == block_id then return true end
    end
  end
  return false
end

local function find_window(match)
  for _, candidate in ipairs(view.windows or {}) do
    if match(candidate) then return candidate.window_id end
  end
end

local target, window_id
if kind == "agent" then
  target = block
  window_id = find_window(function(candidate) return holds_block(candidate, block) end)
elseif kind == "tab" then
  target = window
  window_id = find_window(function(candidate) return candidate.window_id == window end)
else
  error("unknown target kind " .. tostring(kind), 0)
end

if not window_id then
  error(("target %s no longer exists"):format(target), 0)
end

assert(dest.call("client.perform", {
  client_id = app.client_id,
  action = "session.select",
  args = { session_id = session, window_id = window_id },
  origin = "cli",
}))

if kind == "agent" then
  assert(dest.session.focus_block{ session_id = session, block_id = block })
end
