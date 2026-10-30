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

rex.action{
  name = "jump",
  title = "Jump To Agent, Tab, Or Pane",
  args = { mode = "string" },
  run = function(ctx, args)
    return open_float{ "sh", "-c", [[exec "$HOME/.config/rex/jump/jump.sh" "$1" "$2"]], "jump", args.mode, ctx.block_id }
  end,
}
