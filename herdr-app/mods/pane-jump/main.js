import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { closeOverlay, focused, home, layout, notify, panes, props, run, setShared, shared, theme } from "herdr";

const HINT_KEYS = "asdfghjklqwertyuiopzxcvbnm";
const JUMP_KEY = "pane-jump.active";

function labelPanes(items) {
  let width = 1;
  while (HINT_KEYS.length ** width < items.length) width++;
  return Object.fromEntries(items.map(({ pane }, index) => {
    let hint = "";
    for (let digit = 0; digit < width; digit++) {
      hint = HINT_KEYS[index % HINT_KEYS.length] + hint;
      index = Math.floor(index / HINT_KEYS.length);
    }
    return [pane, hint];
  }));
}

function paneFrame(node) {
  if (!node || node.hidden) return null;
  if (node.content?.tab && node.content.pane) return node.content.pane;
  let children = node.children ?? [];
  if (node.type === "stack") {
    const visible = children.filter(child => !child.hidden);
    children = [visible.find(child => child.id === node.active) ?? visible[0]];
  }
  for (const child of children) {
    const frame = paneFrame(child);
    if (frame) return frame;
  }
  return null;
}

function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

function folder(cwd) {
  if (!cwd) return "";
  const h = home();
  return cwd === h ? "~" : cwd.startsWith(h + "/") ? "~" + cwd.slice(h.length) : cwd;
}

export default class PaneJump extends View {
  init(_props, cx) {
    this.hovered = false;
    this.overlay = props()?.overlay;
    if (!this.overlay) return;

    this.tab = focused()?.tab;
    const items = panes().filter((pane) => pane.tab === this.tab);
    const zoomed = items.some((pane) => pane.zoomed);
    if (items.length < 2 || zoomed) {
      closeOverlay(this.overlay);
      notify({
        title: "Pane jump",
        body: items.length < 2 ? "No other panes in this tab" : "Unzoom to jump between panes",
      });
      return;
    }

    this.handle = cx.focus_handle();
    this.handle.focus();
    this.jump = { overlay: this.overlay, hints: labelPanes(items), prefix: "" };
    setShared(JUMP_KEY, this.jump);
  }

  close() {
    if (this.overlay && shared(JUMP_KEY)?.overlay === this.overlay) setShared(JUMP_KEY, null);
  }

  keyDown(event, cx) {
    cx.stop_propagation();
    if (event.keystroke === "escape") {
      closeOverlay(this.overlay);
      return;
    }
    if (!this.jump || event.is_held) return;
    const { control, alt, platform } = event.modifiers;
    if (control || alt || platform) return;
    const key = event.key.toLowerCase();
    if (key === "backspace" && this.jump.prefix) {
      this.jump.prefix = this.jump.prefix.slice(0, -1);
      setShared(JUMP_KEY, this.jump);
      return;
    }
    if (key.length !== 1 || !HINT_KEYS.includes(key)) return;

    const prefix = this.jump.prefix + key;
    const match = Object.entries(this.jump.hints).find(([, hint]) => hint.startsWith(prefix));
    if (!match) return;
    const [pane, hint] = match;
    if (hint === prefix) {
      closeOverlay(this.overlay);
      if (focused()?.tab === this.tab && panes().some((item) => item.pane === pane)) {
        run("pane.focus", { pane });
      }
    } else {
      this.jump.prefix = prefix;
      setShared(JUMP_KEY, this.jump);
    }
  }

  renderOverlay() {
    if (!this.handle) return div();
    return div().id("pane-jump-overlay").size_full().track_focus(this.handle)
      .on_key_down((event, cx) => this.keyDown(event, cx));
  }

  button(t, id, icon, command, args) {
    return div()
      .id(id)
      .p(3)
      .rounded(4)
      .text_color(t.dim)
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_click((_e, cx) => {
        cx.stop_propagation();
        run(command, args);
      })
      .child(svg(`mods/pane-jump/${icon}.svg`).size(14));
  }

  render() {
    if (this.overlay) return this.renderOverlay();
    const t = theme();
    const p = panes().find((item) => item.pane === props()?.pane);
    if (!p) return div();
    const jump = shared(JUMP_KEY);
    const hint = jump?.hints[p.pane];
    const matches = hint?.startsWith(jump.prefix);
    const name = p.name || ((p.program?.agent || p.program?.shell) && p.program.name) || p.title || p.program?.name || "shell";
    const pic = icon(p.program, 14, t.dim);
    const st = p.status;
    const pane = p.pane;
    const bottom = paneFrame(layout())?.header?.position === "bottom";
    return h_flex()
      .id(`pane-head-${pane}`)
      .size_full()
      .px(10)
      .gap(8)
      .items_center()
      .bg(t.background)
      .when(bottom, el => el.border_t(1))
      .when(!bottom, el => el.border_b(1))
      .border_color(t.border)
      .text_size(12)
      .on_hover((hovered, cx) => { this.hovered = hovered; cx.notify(); })
      .on_click(() => run("pane.focus", { pane }))
      .when(hint, (el) => el.child(
        h_flex().h(20).min_w(24).px(5).flex_none().items_center().justify_center()
          .rounded(4).bg(matches ? t.accent : t.raised)
          .text_color(matches ? t.accent_foreground : t.muted)
          .id(`pane-jump-hint-${pane}`).font_family("monospace").font_semibold().child(hint),
      ))
      .when(Boolean(pic), (el) => el.child(pic))
      .child(div().flex_none().truncate().max_w(260).font_medium().text_color(t.foreground).child(name))
      .child(div().flex_1().truncate().text_color(t.dim).child(folder(p.cwd)))
      .when(st === "working", el => el.child(svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900)))
      .when(st === "blocked", el => el.child(div().flex_none().px(6).h(18).flex().items_center().rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).child("Needs you")))
      .when(st === "done", el => el.child(div().size(7).flex_none().rounded(4).bg(t.done)))
      .when(this.hovered, el => el
        .child(this.button(t, `ph-r-${pane}`, "split-right", "pane.split", { direction: "right", pane }))
        .child(this.button(t, `ph-d-${pane}`, "split-down", "pane.split", { direction: "down", pane }))
        .child(this.button(t, `ph-z-${pane}`, p.zoomed ? "unzoom" : "zoom", "pane.zoom", { pane }))
        .child(this.button(t, `ph-x-${pane}`, "close", "pane.close", { pane })));
  }
}
