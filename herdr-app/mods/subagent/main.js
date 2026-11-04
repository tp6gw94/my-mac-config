import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex, TextView } from "gpui-base";
import { hc, focused, theme, props, run, layout, settings, openOverlay } from "herdr";
import { ACTIVE, inside, runningTasks, folderTasks, loadSession, toolSummary, viewerPath } from "./data.js";
import { tabBar } from "./tabs.js";

const ICON = "mods/subagent/layers.svg";
const SPINNER = "mods/subagent/spinner.svg";
const PANEL = "subagent-panel";
const SESSIONS = "pi-sessions-panel";
const SESSIONS_ICON = "mods/pi-sessions/history.svg";
const POLL_MS = 2000;
const ENTRIES_SHOWN = 12;

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const shownFor = (id) => {
  const node = find(layout(), id);
  return Boolean(node) && !node.hidden;
};
const panelShown = () => shownFor(PANEL);
const mono = () => settings().font_family ?? "JetBrains Mono";

function toggle(panel, label, icon, badge = 0) {
  const t = theme();
  const on = shownFor(panel);
  return h_flex().id(`${panel}-toggle`).h(26).px(8).gap(5).flex_none().items_center().rounded(6).text_size(12)
    .bg(on ? t.selected : t.chrome).text_color(on || badge ? t.foreground : t.muted).hover((s) => s.bg(t.hover))
    .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
    .on_click(() => run("layout.toggle", { id: panel }))
    .child(svg(icon).size(14))
    .child(label)
    .when(badge > 0, (el) => el.child(div().px(5).rounded(4).bg(t.raised).text_color(t.working).child(String(badge))));
}

function duration(ms) {
  const s = Math.max(0, Math.floor(ms / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m ${s % 60}s`;
  return `${Math.floor(s / 3600)}h ${Math.floor((s % 3600) / 60)}m`;
}

function clock(at) {
  const d = new Date(at);
  const time = `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  return d.toDateString() === new Date().toDateString() ? time : `${d.getMonth() + 1}/${d.getDate()} ${time}`;
}

function clip(text, maxLines, fromEnd = false) {
  const all = text.split("\n");
  let shown = all.length > maxLines ? (fromEnd ? all.slice(-maxLines) : all.slice(0, maxLines)).join("\n") : text;
  if (shown.length > 2000) shown = fromEnd ? shown.slice(-2000) : shown.slice(0, 2000);
  if (shown === text) return text;
  return fromEnd ? `…\n${shown}` : `${shown}\n…`;
}

const started = (task) => task.startedAt ?? task.createdAt;
const runTime = (task) => (task.finishedAt ?? Date.now()) - started(task);
const statusLabel = (status) => status.replace("_", " ");

function statusMark(task, t) {
  if (task.status === "running") return svg(SPINNER).size(12).flex_none().text_color(t.working).spin(900);
  if (task.status === "completed") return svg("mods/subagent/circle-check.svg").size(12).flex_none().text_color(t.ansi2);
  const color = { waiting_input: t.blocked, failed: t.ansi1, queued: t.idle, starting: t.idle }[task.status] ?? t.dim;
  return div().size(7).mx(2.5).flex_none().rounded(4).bg(color);
}

async function openViewer(task) {
  const script = 'node "$1" --events "$2"; printf "\\n[Press Enter to close]"; read -r _';
  const result = await hc(["run", "--bg", "--json", "--rm", "--no-parent", "--cwd", task.cwd, "--", "zsh", "-lc", script, "zsh", viewerPath(), task.eventFile]);
  const { address } = JSON.parse(result.stdout);
  openOverlay({
    kind: "dialog", modal: true, width: 0.8, height: 0.8,
    layout: {
      type: "column",
      children: [
        { type: "block", size: { px: 34 }, content: { mod: "subagent", props: { bar: true, terminal: address, name: task.name, model: task.model?.id } } },
        { type: "block", content: { terminal: address } },
      ],
    },
  });
}

const textButton = (id, label, t, action) => div().id(id).flex_none().px(6).py(2).rounded(5).text_size(11.5).text_color(t.muted)
  .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(action).child(label);

export default class Subagent extends View {
  init(_props, cx) {
    const role = props() ?? {};
    if (role.bar) return;
    this.running = [];
    this.recent = [];
    this.count = 0;
    this.dir = undefined;
    this.open = new Set();
    this.promptOpen = new Set();
    this.allEntries = new Set();
    this.sessions = {};
    this.busy = false;
    this.pressed = null;
    cx.timer.every(POLL_MS, (cx) => this.refresh(cx));
    this.refresh(cx);
  }

  refresh(cx) {
    const role = props() ?? {};
    if (this.busy || (role.panel && !panelShown())) return;
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        if (role.panel) await this.refreshPanel();
        else this.running = await runningTasks();
      } finally {
        this.busy = false;
      }
      cx.notify();
    });
  }

  async refreshPanel() {
    const dir = this.dir;
    if (!dir) { this.running = []; this.recent = []; return; }
    const { running, recent } = await folderTasks(dir);
    if (dir !== this.dir) return;
    this.running = running;
    this.recent = recent;
    const stale = [...running, ...recent].filter((task) => this.open.has(task.taskId)
      && (!this.sessions[task.taskId] || this.sessions[task.taskId].status !== task.status || ACTIVE.includes(task.status)));
    await Promise.all(stale.map(async (task) => {
      this.sessions[task.taskId] = { ...(await loadSession(task)), status: task.status };
    }));
  }

  toggle(task, cx) {
    if (this.open.has(task.taskId)) { this.open.delete(task.taskId); cx.notify(); return; }
    this.open.add(task.taskId);
    cx.notify();
    cx.spawn(async (cx) => {
      this.sessions[task.taskId] = { ...(await loadSession(task)), status: task.status };
      cx.notify();
    });
  }

  render(cx) {
    const role = props() ?? {};
    if (role.bar) return this.renderBar(role);
    if (role.panel) return this.renderPanel(cx);
    return this.renderTopbar();
  }

  renderTopbar() {
    const t = theme();
    const count = this.running.filter((task) => inside(task.cwd, focused()?.cwd)).length;
    return tabBar(this, t, h_flex().gap(3).items_center()
      .child(toggle(SESSIONS, "Sessions", SESSIONS_ICON))
      .child(toggle(PANEL, "Subagent", ICON, count)));
  }

  renderPanel(cx) {
    const t = theme();
    const dir = focused()?.cwd ?? null;
    if (dir !== this.dir) {
      this.dir = dir;
      this.running = [];
      this.recent = [];
      this.refresh(cx);
    }
    const section = (label, tasks) => v_flex().flex_none().gap(6)
      .child(div().px(2).text_size(11.5).font_semibold().text_color(t.muted).child(label))
      .children(tasks.map((task) => this.card(task, t)));
    return v_flex().id("subagent-panel").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Subagents"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${this.running.length} running`))
        .child(div().flex_1().min_w(0).text_size(11.5).text_color(t.dim).text_ellipsis_start().whitespace_nowrap().overflow_hidden().child(dir ?? "")))
      .child(v_flex().id("subagent-scroll").flex_1().min_h(0).overflow_y_scrollbar().p(10).gap(16)
        .child(section("Running", this.running)
          .when(this.running.length === 0, (el) => el.child(div().px(2).text_size(12.5).text_color(t.dim).child(dir ? "No subagents running in this folder." : "Focus a terminal to see its folder's subagents."))))
        .when(this.recent.length > 0, (el) => el.child(section("Recent", this.recent))));
  }

  card(task, t) {
    const id = task.taskId;
    const open = this.open.has(id);
    const time = ACTIVE.includes(task.status) ? duration(runTime(task)) : clock(task.finishedAt ?? started(task));
    return v_flex().id(`card-${id}`).flex_none().rounded(8).border_1().border_color(open ? t.input : t.border).bg(open ? t.surface : t.background)
      .child(h_flex().id(`toggle-${id}`).px(10).py(8).gap(8).items_start().rounded(8).hover((s) => s.bg(t.hover))
        .on_click((_e, cx) => this.toggle(task, cx))
        .child(svg(`mods/subagent/${open ? "chevron-down" : "chevron-right"}.svg`).size(12).mt(3).flex_none().text_color(t.dim))
        .child(v_flex().flex_1().min_w(0).gap(3)
          .child(h_flex().gap(7).items_center()
            .child(statusMark(task, t))
            .child(div().flex_1().min_w(0).truncate().child(task.name || id))
            .child(div().flex_none().text_size(11.5).text_color(t.dim).child(time)))
          .child(div().pl(19).truncate().text_size(11.5).text_color(t.muted)
            .child([statusLabel(task.status), task.model?.id, task.thinking].filter(Boolean).join(" · ")))))
      .when(open, (el) => el.child(this.details(task, t)));
  }

  details(task, t) {
    const id = task.taskId;
    const session = this.sessions[id];
    const tools = task.capabilities?.callable ?? task.capabilities?.requested ?? [];
    const meta = [
      ["Status", statusLabel(task.status)],
      ["Model", task.model ? `${task.model.provider}/${task.model.id}` : ""],
      ["Thinking", task.thinking ?? "inherited"],
      ["Tools", tools.join(", ")],
      ["Web", task.webAccess ? "on" : "off"],
      ["Folder", task.cwd],
      ["Started", `${clock(started(task))}`],
      [ACTIVE.includes(task.status) ? "Elapsed" : "Duration", duration(runTime(task))],
      ["Timeout", task.timeoutMs ? duration(task.timeoutMs) : ""],
      ["Speed", task.tps ? `${task.tps.toFixed(1)} tok/s` : ""],
      ["Task", id],
    ].filter(([, value]) => value);
    return v_flex().px(12).pt(10).pb(12).gap(14).border_t(1).border_color(t.border)
      .child(v_flex().gap(4).text_size(12)
        .children(meta.map(([label, value]) => h_flex().gap(10).items_start()
          .child(div().w(64).flex_none().text_color(t.dim).child(label))
          .child(div().flex_1().min_w(0).text_color(t.foreground).child(value))))
        .when(Boolean(task.error), (el) => el.child(h_flex().gap(10).items_start()
          .child(div().w(64).flex_none().text_color(t.dim).child("Error"))
          .child(div().flex_1().min_w(0).text_color(t.ansi1).child(task.error)))))
      .child(session ? this.promptBlock(task, session, t) : div().text_size(12).text_color(t.dim).child("Loading session…"))
      .when(Boolean(session), (el) => el.child(this.output(task, session, t)))
      .child(h_flex().gap(6)
        .child(textButton(`viewer-${id}`, "Open live log", t, (_e, cx) => cx.spawn(async () => openViewer(task)))));
  }

  promptBlock(task, session, t) {
    const id = task.taskId;
    const full = this.promptOpen.has(id);
    const short = clip(session.prompt, 8);
    const long = short !== session.prompt;
    return v_flex().gap(6)
      .child(h_flex().items_center().gap(6)
        .child(div().flex_1().text_size(11.5).font_semibold().text_color(t.muted).child("Prompt"))
        .when(long, (el) => el.child(textButton(`prompt-toggle-${id}`, full ? "Show less" : "Show all", t, (_e, cx) => {
          if (full) this.promptOpen.delete(id); else this.promptOpen.add(id);
          cx.notify();
        }))))
      .child(div().p(10).rounded(6).border_1().border_color(t.border).bg(t.background).text_size(12.5)
        .child(session.prompt ? TextView.markdown(`prompt-${id}-${full}`, full ? session.prompt : short).selectable(true) : div().text_color(t.dim).child("No prompt recorded.")));
  }

  output(task, session, t) {
    const id = task.taskId;
    const all = this.allEntries.has(id);
    const entries = all ? session.entries : session.entries.slice(-ENTRIES_SHOWN);
    const hidden = session.entries.length - entries.length;
    const last = session.entries[session.entries.length - 1];
    const waiting = ACTIVE.includes(task.status) && !(last?.kind === "tool" && !last.result);
    return v_flex().gap(8)
      .child(h_flex().items_center().gap(6)
        .child(div().flex_1().text_size(11.5).font_semibold().text_color(t.muted).child("Output"))
        .when(hidden > 0, (el) => el.child(textButton(`entries-toggle-${id}`, `Show ${hidden} earlier`, t, (_e, cx) => {
          this.allEntries.add(id);
          cx.notify();
        })))
        .when(hidden === 0 && session.clipped, (el) => el.child(div().text_size(11.5).text_color(t.dim).child("Earlier output is in the live log"))))
      .when(session.entries.length === 0 && !waiting, (el) => el.child(div().text_size(12).text_color(t.dim).child("No output yet.")))
      .children(entries.map((entry, i) => this.entry(task, entry, `${id}-${hidden + i}`, t)))
      .when(waiting, (el) => el.child(h_flex().gap(7).items_center().text_size(12).text_color(t.muted)
        .child(svg(SPINNER).size(12).text_color(t.working).spin(900))
        .child(task.status === "waiting_input" ? "Waiting for input" : "Working…")));
  }

  entry(task, entry, key, t) {
    if (entry.kind === "thinking") {
      return div().pl(10).border_l(2).border_color(t.border).text_size(12).italic().text_color(t.dim).child(clip(entry.text, 4));
    }
    if (entry.kind === "text") {
      return div().text_size(13).text_color(t.foreground).child(TextView.markdown(`md-${key}`, entry.text).selectable(true));
    }
    if (entry.kind === "user") {
      return v_flex().gap(4).p(8).rounded(6).bg(t.raised).text_size(12.5)
        .child(div().text_size(11).text_color(t.muted).child("Message"))
        .child(div().text_color(t.foreground).child(clip(entry.text, 10)));
    }
    const summary = toolSummary(entry.args);
    const result = entry.result;
    const pending = !result && ACTIVE.includes(task.status);
    return v_flex().rounded(6).border_1().border_color(result?.error ? t.ansi1 : t.border).bg(t.background).font_family(mono()).text_size(11.5)
      .child(h_flex().px(8).py(5).gap(6).items_center()
        .child(pending ? svg(SPINNER).size(11).flex_none().text_color(t.working).spin(900)
          : div().size(6).mx(2.5).flex_none().rounded(3).bg(result?.error ? t.ansi1 : t.dim))
        .child(div().flex_1().min_w(0).font_semibold().text_color(t.accent).child(entry.name))
        .when(Boolean(result?.durationMs), (el) => el.child(div().flex_none().text_color(t.dim).child(duration(result.durationMs)))))
      .when(Boolean(summary), (el) => el.child(div().px(8).pb(6).text_color(t.foreground).child(clip(summary, 6))))
      .when(Boolean(result?.text), (el) => el.child(div().px(8).py(5).border_t(1).border_color(t.border)
        .text_color(result.error ? t.ansi1 : t.muted).child(clip(result.text, 6, true))));
  }

  renderBar({ terminal, name, model }) {
    const t = theme();
    return h_flex().size_full().px(12).gap(8).items_center().bg(t.chrome).border_b(1).border_color(t.border).text_size(12.5)
      .child(svg(ICON).size(14).text_color(t.muted))
      .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(name ?? terminal))
      .child(div().flex_none().text_color(t.dim).child(model ?? ""))
      .child(div().id("viewer-close").size(22).flex_none().flex().items_center().justify_center().rounded(5).text_color(t.dim)
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click(() => run("terminal.kill", { terminal }))
        .child(svg("mods/pane/close.svg").size(12)));
  }
}
