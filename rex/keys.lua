rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>shift+s", "session.switch")
rex.bind("ctrl+a>ctrl+f", "session.next")
rex.bind("ctrl+a>ctrl+b", "session.previous")
rex.bind("ctrl+a>shift+n", "session.new")
rex.bind("ctrl+a>shift+d", "session.close")
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>r", "client.config.reload")
rex.bind("ctrl+a>x", "pane.close")
rex.bind("ctrl+a>shift+x", "client.tab.close")
rex.bind("ctrl+a>shift+r", "session.rename")
rex.bind("ctrl+a>shift+t", "client.tab.rename")
rex.bind("ctrl+a>b", "client.sidebar.toggle")
rex.bind("ctrl+a>g>g", "lazygit_float")
rex.bind("ctrl+a>g>h", "hunk_diff")
rex.bind("ctrl+a>n>o", "obsidian_inbox_float")
rex.bind("ctrl+a>n>q", "quicknote_float")

rex.bind("ctrl+a>f", "pane.float")
local focus_directions = {
  h = "left",
  j = "down",
  k = "up",
  l = "right",
}

local function focus_pane(request, forward_nvim)
  local view, view_err = rex.session.view({ session_id = request.session_id })
  if not view then
    error(view_err)
  end
  local focused_block_id
  for _, window in ipairs(view.windows) do
    if window.window_id == view.active_window_id then
      focused_block_id = window.focused_block_id
      break
    end
  end
  if focused_block_id ~= request.source_block_id then
    return true
  end
  if forward_nvim then
    local process, process_err =
      rex.block.call("com.superlogical.terminal", "process", { block_id = request.source_block_id })
    if not process then
      error(process_err)
    end
    if process.foreground and process.foreground.name == "nvim" then
      return false
    end
  end
  local _, focus_err = rex.session.focus_direction({
    session_id = request.session_id,
    direction = request.direction,
    wrap = false,
  })
  if focus_err then
    error(focus_err)
  end
  return true
end

rex.action({
  name = "focus_from_source",
  title = "Focus From Source",
  args = { direction = "string" },
  run = function(ctx, args)
    return focus_pane({
      session_id = ctx.session_id,
      source_block_id = ctx.block_id,
      direction = args.direction,
    }, false)
  end,
})

for key, direction in pairs(focus_directions) do
  rex.bind("ctrl+" .. key, function(ctx)
    return focus_pane({
      session_id = ctx.session_id,
      source_block_id = ctx.block_id,
      direction = direction,
    }, true)
  end)
end
rex.bind("alt+n", "client.tab.next")
rex.bind("alt+p", "client.tab.previous")

rex.bind("ctrl+shift+h", "pane.move", { direction = "left" })
rex.bind("ctrl+shift+j", "pane.move", { direction = "down" })
rex.bind("ctrl+shift+k", "pane.move", { direction = "up" })
rex.bind("ctrl+shift+l", "pane.move", { direction = "right" })

rex.bind("alt+left", "pane.resize", { direction = "left" })
rex.bind("alt+down", "pane.resize", { direction = "down" })
rex.bind("alt+up", "pane.resize", { direction = "up" })
rex.bind("alt+right", "pane.resize", { direction = "right" })

rex.bind("ctrl+a>a", "jump")
