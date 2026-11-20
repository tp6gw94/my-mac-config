import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, commands, focused, keys, props, run, shared, theme } from "herdr";

const PREFIX = "ctrl-a";
const GROUP_LABELS = { f: "Find", g: "Git", n: "Notes and inbox" };
const ACTION_LABELS = {
  "app.help": "All shortcuts",
  "app.settings": "Settings",
  "layout.toggle:sidebar": "Toggle sidebar",
  "mod.open:hunk-diff": "Hunk Diff",
  "mod.open:inbox-popup": "Inbox",
  "mod.open:lazygit-popup": "Lazygit",
  "mod.open:picker": "Open picker",
  "mod.open:quicknote": "Quick note",
  "mod.open:space-jump": "Jump to space",
  "mod.open:worktree-new": "New worktree",
  "mod.open:worktree-open": "Open worktree",
  "pane.split:right": "Split right",
  "pane.split:down": "Split down",
};
const KEY_LABELS = { cmd: "⌘", ctrl: "Ctrl", alt: "Alt", shift: "Shift", escape: "Esc", backspace: "⌫" };
const SHIFTED = Object.fromEntries([..."!@#$%^&*()?"].map((key, i) => [key, "1234567890/"[i]]));

function keyId(keystroke) {
  const chord = keystroke.toLowerCase();
  const modifiers = chord.match(/^(?:(?:alt|cmd|ctrl|fn|shift)-)+/)?.[0] ?? "";
  const parts = modifiers ? modifiers.slice(0, -1).split("-") : [];
  let key = chord.slice(modifiers.length);
  if (SHIFTED[key]) {
    key = SHIFTED[key];
    if (!parts.includes("shift")) parts.push("shift");
  }
  return [...parts.sort(), key].join("-");
}

function keyLabel(key) {
  if (key === "shift-/") return "?";
  const modifiers = key.match(/^(?:(?:alt|cmd|ctrl|fn|shift)-)+/)?.[0] ?? "";
  const base = key.slice(modifiers.length);
  if (!modifiers) return KEY_LABELS[base] ?? base;
  return [...modifiers.slice(0, -1).split("-").map((part) => KEY_LABELS[part] ?? part), base.toUpperCase()].join("+");
}

function commandFor(action, catalog) {
  const separator = action.indexOf(":");
  const name = separator < 0 ? action : action.slice(0, separator);
  const value = separator < 0 ? null : action.slice(separator + 1);
  const spec = catalog.get(name);
  if (value === null) return name.includes(".") ? { name, args: {} } : null;
  const first = spec?.args[0]?.name;
  if (!first) return null;
  return { name, args: { [first]: first === "index" ? Number(value) : value } };
}

function labelFor(action, name) {
  if (ACTION_LABELS[action]) return ACTION_LABELS[action];
  const [subject, verb] = name.split(".");
  const argument = action.slice(name.length + 1);
  const words = verb === "prev" ? "Previous" : verb.replace(/_/g, " ");
  const label = words[0].toUpperCase() + words.slice(1);
  if (verb === "select" && argument) {
    return subject[0].toUpperCase() + subject.slice(1) + " " + argument;
  }
  return [label, subject, argument].filter(Boolean).join(" ");
}

function readBindings() {
  const catalog = new Map(commands().map((command) => [command.name, command]));
  const sections = ["global", `layout:${shared("layout")}`];
  if (focused()?.terminal) sections.push("terminal");
  const bindings = new Map();
  for (const { section, keys: sequence, action } of keys()) {
    const priority = sections.indexOf(section);
    const [prefix, ...tail] = sequence.trim().split(/\s+/).map(keyId);
    if (priority < 0 || prefix !== PREFIX || !tail.length) continue;
    const id = tail.join(" ");
    if ((bindings.get(id)?.priority ?? -1) > priority) continue;
    const command = commandFor(action, catalog);
    bindings.set(id, { tail, priority, command, label: command && labelFor(action, command.name) });
  }
  return [...bindings.values()].filter((entry) => entry.command);
}

function rowOrder(row) {
  if (row.group) return 0;
  if (/^shift-\d$/.test(row.key)) return 3;
  return row.key.includes("-") ? 2 : 1;
}

function keycap(key, t, accent = false) {
  return h_flex().h(22).min_w(24).px(5).flex_none().items_center().justify_center()
    .rounded(5).border_1().border_color(t.border).bg(t.raised)
    .font_family("monospace").text_size(11).text_color(accent ? t.accent : t.foreground)
    .child(keyLabel(key));
}

export default class WhichKey extends View {
  init(_props, cx) {
    this.bindings = readBindings();
    this.path = [];
    this.missed = null;
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  rows() {
    const rows = new Map();
    for (const entry of this.bindings) {
      if (!this.path.every((key, i) => key === entry.tail[i])) continue;
      const key = entry.tail[this.path.length];
      if (!key) continue;
      const row = rows.get(key) ?? { key, group: false };
      if (entry.tail.length > this.path.length + 1) row.group = true;
      else row.entry = entry;
      rows.set(key, row);
    }
    return [...rows.values()].sort((a, b) => rowOrder(a) - rowOrder(b) || a.key.localeCompare(b.key));
  }

  back(cx) {
    this.path.pop();
    this.missed = null;
    cx.notify();
  }

  choose(row, cx) {
    if (row.group) {
      this.path.push(row.key);
      this.missed = null;
      cx.notify();
    } else {
      this.execute(row.entry);
    }
  }

  execute({ command }) {
    this.dismiss();
    run(command.name, command.args);
  }

  keyDown(event, cx) {
    cx.stop_propagation();
    if (event.is_held) return;
    const key = keyId(event.keystroke);
    if (key === "escape") return this.dismiss();
    if (key === "backspace") return this.back(cx);
    if (["alt", "control", "ctrl", "meta", "shift", "super"].includes(key)) return;
    const row = this.rows().find((row) => row.key === key);
    if (row) this.choose(row, cx);
    else {
      this.missed = key;
      cx.notify();
    }
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const title = this.path.length ? GROUP_LABELS[this.path[0]] ?? "Shortcuts" : "Which key";
    const columns = rows.length > 18 ? 3 : rows.length > 6 ? 2 : 1;
    const lines = [];
    for (let start = 0; start < rows.length; start += columns) {
      const line = h_flex().gap(8).flex_none();
      for (let col = 0; col < columns; col++) {
        const row = rows[start + col];
        const cell = h_flex().flex_1().min_w(0);
        if (!row) {
          line.child(cell);
          continue;
        }
        line.child(cell.id(`which-key-row-${row.key}`)
          .h(34).px(6).gap(8).items_center().rounded(6)
          .cursor_pointer().hover((s) => s.bg(t.hover)).active((s) => s.bg(t.selected))
          .on_click((_event, cx) => this.choose(row, cx))
          .child(h_flex().w(61).flex_none().child(keycap(row.key, t, row.group)))
          .child(div().flex_1().min_w(0).truncate().font_medium()
            .child(row.group ? (this.path.length ? "More shortcuts" : GROUP_LABELS[row.key] ?? "More shortcuts") : row.entry.label))
          .when(row.group, (item) => item.child(div().text_color(t.muted).child("›"))));
      }
      lines.push(line);
    }

    return v_flex().id("which-key").track_focus(this.handle)
      .on_key_down((event, cx) => this.keyDown(event, cx))
      .w_full().min_h(0).max_h(510).p(16).gap(10)
      .bg(t.popover).text_color(t.foreground).text_size(13)
      .child(h_flex().h(32).flex_none().items_center().justify_between().gap(12)
        .child(div().text_size(17).font_semibold().child(title))
        .child(h_flex().items_center().gap(6)
          .children([PREFIX, ...this.path].map((key) => keycap(key, t)))))
      .child(v_flex().id(`which-key-list-${this.path.join(" ")}`)
        .min_h(0).h(Math.min(374, Math.max(44, lines.length * 34))).overflow_y_scrollbar()
        .children(lines)
        .when(!rows.length, (list) => list.child(div().p(8).text_color(t.muted).child("No Ctrl+A shortcuts in this context."))))
      .child(h_flex().h(36).flex_none().border_t_1().border_color(t.border)
        .pt(4).items_center().justify_between().gap(8).text_size(12).text_color(t.muted)
        .child(div().truncate().child(this.missed ? "No shortcut for " + keyLabel(this.missed) : "Press a key or click a shortcut"))
        .child(h_flex().gap(12).flex_none()
          .when(this.path.length > 0, (actions) => actions.child(
            h_flex().id("which-key-back").h(32).px(4).gap(5).items_center().rounded(5)
              .cursor_pointer().hover((s) => s.bg(t.hover)).on_click((_event, cx) => this.back(cx))
              .child(keycap("backspace", t)).child("Back")))
          .child(h_flex().id("which-key-close").h(32).px(4).gap(5).items_center().rounded(5)
            .cursor_pointer().hover((s) => s.bg(t.hover)).on_click(() => this.dismiss())
            .child(keycap("escape", t)).child("Close"))));
  }
}
