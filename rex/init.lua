local function open_float(command)
  local process = assert(rex.block.call("com.superlogical.terminal", "process", {}))
  return assert(rex.session.new_layer{
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      options = {
        command = command,
        cwd = process.foreground.cwd,
      },
    },
  })
end

rex.action{
  name = "lazygit_float",
  title = "Open Lazygit in Floating Pane",
  run = function()
    return open_float{ "lazygit" }
  end,
}

rex.action{
  name = "obsidian_inbox_float",
  title = "Open Obsidian Inbox in Floating Pane",
  run = function()
    return open_float{ "sh", "-c", [[exec nvim "${OBSIDIAN:?OBSIDIAN is not set}/inbox.md"]] }
  end,
}

rex.action{
  name = "quicknote_float",
  title = "Open Daily Quicknote in Floating Pane",
  run = function()
    return open_float{ "sh", "-c", [[exec nvim "${ICLOUD:?ICLOUD is not set}/quicknotes/$(date +%F).md"]] }
  end,
}

rex.action{
  name = "hunk_diff",
  title = "Open or Focus Hunk Diff Tab",
  run = function(ctx)
    local view = assert(rex.session.view{})
    local window_id
    for _, window in ipairs(view.windows) do
      if window.label == "Hunk Diff" then
        window_id = window.window_id
        break
      end
    end
    if not window_id then
      local process = assert(rex.block.call("com.superlogical.terminal", "process", {}))
      local window = assert(rex.session.new_window{
        window_label = "Hunk Diff",
        focus = true,
        layout = rex.layout.block{
          flavor = "com.superlogical.terminal.shell",
          options = {
            command = { "hunk", "diff" },
            cwd = process.foreground.cwd,
          },
        },
      })
      window_id = window.window_id
    end
    rex.client.queue("session.select", {
      session_id = ctx.session_id,
      window_id = window_id,
    })
    return { window_id = window_id }
  end,
}

rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>shift+s", "session.switch")
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

rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })
rex.bind("alt+l", "pane.focus", { direction = "right" })

rex.bind("alt+shift+h", "pane.move", { direction = "left" })
rex.bind("alt+shift+j", "pane.move", { direction = "down" })
rex.bind("alt+shift+k", "pane.move", { direction = "up" })
rex.bind("alt+shift+l", "pane.move", { direction = "right" })

rex.bind("alt+left", "pane.resize", { direction = "left" })
rex.bind("alt+down", "pane.resize", { direction = "down" })
rex.bind("alt+up", "pane.resize", { direction = "up" })
rex.bind("alt+right", "pane.resize", { direction = "right" })
