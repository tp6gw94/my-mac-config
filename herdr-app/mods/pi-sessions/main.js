import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex, InputState, Input, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { exec, focused, theme, props, run, layout, settings, home, openOverlay, closeOverlay, notify } from "herdr";

const PANEL = "pi-sessions-panel";
const POLL_MS = 5000;
const PREVIEW_BYTES = 400000;
const PREVIEW_MESSAGES = 20;
const PREVIEW_LINES = 12;
const PREVIEW_CHARS = 1200;
const ROW_H = 46;
const LIST_MAX = 360;
const LIST_ID = "pi-session-list";
const DOUBLE_CLICK_MS = 400;
const MENU_WIDTH = 220;
const MENU_HEIGHT = 170;

const LIST = `dir="$1"
for f in "$dir"/*.jsonl; do
  [ -f "$f" ] || continue
  printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' "$(stat -f %m "$f")" "$(head -n 1 "$f")" "$(grep -m1 '"message":{"role":"user"' "$f" | sed -E 's/"data":"[^"]*"/"data":""/g')" "$(grep '"type":"session_info"' "$f" | tail -n 1)" "$f" "$(stat -f %z "$f")"
done`;

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const panelShown = () => {
  const node = find(layout(), PANEL);
  return Boolean(node) && !node.hidden;
};
const mono = () => settings().font_family ?? "JetBrains Mono";
const base = (path) => path.slice(path.lastIndexOf("/") + 1);
const sessionFolder = (dir) => `${home()}/.pi/agent/sessions/--${dir.replace(/^[/\\]/, "").replace(/[/\\:]/g, "-")}--`;

function parseLine(line) {
  try {
    return JSON.parse(line);
  } catch {
    return null;
  }
}

const textOf = (content) => {
  if (typeof content === "string") return content;
  return (content ?? []).filter((part) => part.type === "text").map((part) => part.text).join("\n");
};

const SELECTED_SKILLS = /<selected_skills>[\s\S]*?<\/selected_skills>/g;
const SKILL_BLOCK = /<skill\b[^>]*>[\s\S]*?<\/skill>/g;
const SKILL_TAG = /<skill\b[^>]*\bname="([^"]*)"/g;

const skillLabel = (text) => [...text.matchAll(SKILL_TAG)].map((match) => `/skill:${match[1]}`).join(" ");
const userText = (text) => {
  const stripped = text.replace(SELECTED_SKILLS, "").replace(SKILL_BLOCK, "").trim();
  return stripped || skillLabel(text);
};
const firstLine = (text) => text.split("\n")[0].trim();

async function listSessions(dir) {
  const found = await exec("sh", ["-c", LIST, "sh", sessionFolder(dir)]);
  const lines = found.stdout.split("\n").filter(Boolean);
  return lines.map((line) => {
    const [mtime, headLine, userLine, infoLine, file, size] = line.split("\t");
    const meta = parseLine(headLine);
    const info = parseLine(infoLine);
    const prompt = userText(textOf(parseLine(userLine)?.message?.content));
    return {
      id: meta.id,
      file,
      cwd: meta.cwd,
      title: info?.name?.trim() || firstLine(prompt),
      prompt,
      updatedAt: Number(mtime) * 1000,
      version: `${mtime}-${size}`,
    };
  }).filter((session) => session.cwd === dir).sort((a, b) => b.updatedAt - a.updatedAt);
}

async function loadPreview(file) {
  const tail = await exec("tail", ["-c", String(PREVIEW_BYTES), file]);
  const messages = [];
  for (const line of tail.stdout.split("\n")) {
    const record = parseLine(line);
    if (record?.type !== "message") continue;
    const { role, content } = record.message;
    if (role !== "user" && role !== "assistant") continue;
    const body = textOf(content);
    const text = role === "user" ? userText(body) : body.trim();
    if (text) messages.push({ role, text });
  }
  return messages;
}

function ago(at) {
  const seconds = Math.max(0, Math.floor((Date.now() - at) / 1000));
  if (seconds < 60) return "now";
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
  return `${Math.floor(seconds / 86400)}d`;
}

function clock(at) {
  const d = new Date(at);
  const time = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  return d.toDateString() === new Date().toDateString() ? time : `${d.getMonth() + 1}/${d.getDate()} ${time}`;
}

function clip(text, maxLines) {
  const lines = text.split("\n");
  const shown = lines.length > maxLines ? `${lines.slice(0, maxLines).join("\n")}\n…` : text;
  return shown.length > PREVIEW_CHARS ? `${shown.slice(0, PREVIEW_CHARS)}…` : shown;
}

export default class PiSessions extends View {
  init(_props, cx) {
    if (props()?.menu) return;
    this.dir = null;
    this.sessions = null;
    this.selected = null;
    this.preview = null;
    this.listSeq = 0;
    this.shown = false;
    this.inputFocused = false;
    this.scroll = VirtualListScrollHandle.new();
    this.lastClick = null;
    this.input = InputState.new({ placeholder: "Search sessions…" });
    this.input.on("change", (_e, cx) => cx.notify());
    this.input.on("focus", (_e, cx) => { this.inputFocused = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.inputFocused = false; cx.notify(); });
    this.input.on("submit", () => {
      const session = this.selectedSession();
      if (session) this.resume(session);
    });
    this.handle = cx.focus_handle();
    cx.timer.every(POLL_MS, (cx) => this.refresh(cx));
  }

  filtered() {
    const sessions = this.sessions ?? [];
    const query = this.input.value().trim().toLowerCase();
    if (!query) return sessions;
    return sessions.filter((session) =>
      [session.title, session.prompt, session.id].join(" ").toLowerCase().includes(query));
  }

  selectedSession() {
    const sessions = this.filtered();
    return sessions.find((session) => session.id === this.selected) ?? sessions[0] ?? null;
  }

  refresh(cx) {
    const dir = this.dir;
    if (!dir || !panelShown()) return;
    const seq = ++this.listSeq;
    cx.spawn(async (cx) => {
      const sessions = await listSessions(dir);
      if (seq !== this.listSeq || dir !== this.dir) return;
      this.sessions = sessions;
      cx.notify();
    });
  }

  ensurePreview(cx) {
    const session = this.selectedSession();
    if (!session) {
      this.preview = null;
      return;
    }
    if (this.preview?.id === session.id && this.preview.version === session.version) return;
    const messages = this.preview?.id === session.id ? this.preview.messages : null;
    this.preview = { id: session.id, version: session.version, messages };
    cx.spawn(async (cx) => {
      const loaded = await loadPreview(session.file);
      if (this.preview?.id !== session.id || this.preview.version !== session.version) return;
      this.preview = { id: session.id, version: session.version, messages: loaded };
      cx.notify();
    });
  }

  select(session, cx) {
    if (this.selected === session.id) return;
    this.selected = session.id;
    cx.notify();
  }

  move(step, cx) {
    const sessions = this.filtered();
    if (sessions.length === 0) return;
    const current = sessions.findIndex((session) => session.id === this.selected);
    const next = Math.min(Math.max(current + step, 0), sessions.length - 1);
    this.select(sessions[next], cx);
    this.scroll.scroll_to_item(next, "center");
  }

  click(key, cx) {
    const now = Date.now();
    const last = this.lastClick;
    this.lastClick = { key, at: now };
    const session = this.filtered().find((entry) => entry.id === key);
    if (!session) return;
    if (last?.key === key && now - last.at < DOUBLE_CLICK_MS) {
      this.lastClick = null;
      this.resume(session);
      return;
    }
    this.select(session, cx);
  }

  key(e, cx) {
    if (e.key === "up") this.move(-1, cx);
    else if (e.key === "down") this.move(1, cx);
    else if (e.key === "escape") run("layout.hide", { id: PANEL });
    else return;
    cx.stop_propagation();
  }

  resume(session) {
    run("tab.new", { folder: session.cwd, argv: ["safe-pi", "--session", session.file] });
  }

  fork(session) {
    run("tab.new", { folder: session.cwd, argv: ["safe-pi", "--fork", session.file] });
  }

  split(session) {
    run("terminal.open", { argv: ["safe-pi", "--session", session.file], folder: session.cwd, place: "right" });
  }

  menu(session) {
    openOverlay({ mod: "pi-sessions", kind: "popup", width: MENU_WIDTH, height: MENU_HEIGHT, props: { menu: true, session } });
  }

  render(cx) {
    if (props()?.menu) return this.renderMenu();
    const t = theme();
    const dir = focused()?.cwd ?? null;
    if (dir !== this.dir) {
      this.dir = dir;
      this.sessions = null;
      this.selected = null;
      this.preview = null;
      if (dir) this.refresh(cx);
    }
    const shown = panelShown();
    if (shown !== this.shown) {
      this.shown = shown;
      if (shown) {
        cx.timer.after(60, () => this.input.focus());
        this.refresh(cx);
      }
    }
    const sessions = this.filtered();
    const session = this.selectedSession();
    if (session?.id !== this.selected) this.selected = session?.id ?? null;
    this.ensurePreview(cx);
    return v_flex().id("pi-sessions").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border)
      .text_color(t.foreground).text_size(13).track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .child(this.header(t))
      .child(this.search(t))
      .when(!dir, (el) => el.child(div().p(14).text_size(12.5).text_color(t.muted).child("Focus a terminal to see its pi sessions")))
      .when(dir && this.sessions === null, (el) => el.child(div().p(14).text_size(12).text_color(t.dim).child("Loading…")))
      .when(dir && this.sessions?.length === 0, (el) => el.child(v_flex().flex_1().min_h(0).p(14).gap(5).text_size(12.5)
        .child(div().text_color(t.muted).child(`No pi sessions in ${base(dir)} yet`))
        .child(div().text_size(11.5).text_color(t.dim).child("Run safe-pi here to start one."))))
      .when(dir && sessions.length === 0 && this.sessions?.length > 0, (el) => el.child(div().p(14).text_size(12.5).text_color(t.muted)
        .child(`No sessions match “${this.input.value().trim()}”`)))
      .when(sessions.length > 0, (el) => el.child(this.list(sessions, session, t)).child(this.detail(session, t)));
  }

  header(t) {
    return h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
      .child(div().font_semibold().child("Sessions"))
      .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(String(this.sessions?.length ?? 0)))
      .child(div().flex_1().min_w(0).text_size(11.5).text_color(t.dim).text_ellipsis_start().whitespace_nowrap().overflow_hidden().child(this.dir ? base(this.dir) : ""));
  }

  search(t) {
    return h_flex().flex_none().px(10).pt(10).pb(6)
      .child(h_flex().h(30).flex_1().min_w(0).px(8).gap(6).items_center().rounded(7).border_1().border_color(this.inputFocused ? t.accent : t.border).bg(t.background)
        .child(svg("mods/workspace-chrome/search.svg").size(13).flex_none().text_color(t.dim))
        .child(Input.new(this.input).flex_1().min_w(0).h_full().text_size(12.5).text_color(t.foreground)));
  }

  list(sessions, session, t) {
    return div().relative().flex_none().h(Math.min(LIST_MAX, sessions.length * ROW_H)).border_b(1).border_color(t.border)
      .child(v_virtual_list(LIST_ID, sessions.length, ROW_H, (index) => sessions[index].id,
        (range) => sessions.slice(range.start, range.end).map((s) => this.row(s, s.id === session?.id, t)))
        .size_full()
        .track_scroll(this.scroll)
        .on_item_click((key, cx) => this.click(key, cx))
        .on_item_secondary_click((key, _event, cx) => {
          cx.stop_propagation();
          const entry = sessions.find((s) => s.id === key);
          if (entry) this.menu(entry);
        }))
      .child(Scrollbar.vertical(LIST_ID).absolute().inset_0());
  }

  row(session, selected, t) {
    return h_flex().w_full().h(ROW_H).flex_none().px(6).py(2).cursor_pointer()
      .child(h_flex().size_full().px(8).gap(8).items_center().rounded(7)
        .when(selected, (el) => el.bg(t.selected)).hover((el) => el.bg(t.hover))
        .child(v_flex().flex_1().min_w(0).gap(3)
          .child(h_flex().gap(8).items_center()
            .child(div().flex_1().min_w(0).truncate().child(session.title))
            .child(div().flex_none().text_size(11).text_color(t.dim).child(ago(session.updatedAt))))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.dim).child(session.id.slice(0, 8)))));
  }

  detail(session, t) {
    const messages = this.preview?.id === session.id ? this.preview.messages : null;
    return v_flex().id("pi-session-detail").flex_1().min_h(0).overflow_y_scrollbar().p(12).gap(10)
      .child(h_flex().flex_none().gap(8).items_start()
        .child(div().flex_1().min_w(0).font_semibold().child(clip(session.title, 2)))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(clock(session.updatedAt))))
      .child(v_flex().flex_none().gap(2).text_size(11).text_color(t.dim)
        .child(div().font_family(mono()).child(session.id))
        .child(div().truncate().child(session.cwd)))
      .child(h_flex().flex_none()
        .child(h_flex().id("pi-session-resume").h(27).flex_none().px(11).items_center().rounded(6).bg(t.solid).text_color(t.solid_foreground)
          .text_size(12).font_medium().cursor_pointer().hover((el) => el.opacity(0.88))
          .on_click(() => this.resume(session))
          .child("Resume")))
      .child(messages
        ? v_flex().flex_none().gap(12).children(messages.slice(-PREVIEW_MESSAGES).map((message) => this.message(message, t)))
        : div().text_size(12).text_color(t.dim).child("Loading conversation…"));
  }

  message(message, t) {
    const user = message.role === "user";
    return v_flex().flex_none().gap(3)
      .child(div().text_size(10.5).font_semibold().text_color(user ? t.muted : t.accent)
        .child(user ? "You" : "Pi"))
      .child(div().text_size(12.5).text_color(t.foreground).child(clip(message.text, PREVIEW_LINES)));
  }

  renderMenu() {
    const t = theme();
    const session = props().session;
    const item = (id, label, action) => h_flex().id(id).h(30).flex_none().px(8).rounded(7).items_center().text_color(t.foreground)
      .hover((el) => el.bg(t.hover)).on_click(action).child(label);
    const choose = (action) => () => {
      closeOverlay(props().overlay);
      action();
    };
    const copy = (text, title) => (_e, cx) => {
      cx.write_to_clipboard(text);
      closeOverlay(props().overlay);
      notify({ title });
    };
    return v_flex().id("pi-session-menu").size_full().p(5).bg(t.popover).text_color(t.foreground).text_size(12.8)
      .child(item("pi-menu-tab", "Open in new tab", choose(() => this.resume(session))))
      .child(item("pi-menu-split", "Open in split right", choose(() => this.split(session))))
      .child(item("pi-menu-fork", "Fork to new session", choose(() => this.fork(session))))
      .child(div().mx(7).my(4).h(1).bg(t.border))
      .child(item("pi-menu-id", "Copy session ID", copy(session.id, "Session ID copied")))
      .child(item("pi-menu-path", "Copy file path", copy(session.file, "File path copied")));
  }
}
