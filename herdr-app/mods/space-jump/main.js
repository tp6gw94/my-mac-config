import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, home, props, run, setShared, shared, spaces, theme } from "herdr";

const SIDEBAR_KEY = "space-jump.sidebar";
const HINT_KEYS = "asdfghjklqwertyuiopzxcvbnm";
const ROW_HEIGHT = 44;
const ROW_GAP = 4;
const ROWS_PER_PAGE = 7;
const MIN_TWO_COLUMN_WIDTH = 520;
const WHEEL_PAUSE_MS = 150;
const TRACKPAD_THRESHOLD_PX = 24;

function labelSpaces(items) {
  let width = 1;
  while (HINT_KEYS.length ** width < items.length) width++;
  return items.map((space, index) => {
    let hint = "";
    for (let digit = 0; digit < width; digit++) {
      hint = HINT_KEYS[index % HINT_KEYS.length] + hint;
      index = Math.floor(index / HINT_KEYS.length);
    }
    return { id: space.id, hint };
  });
}

export default class SpaceJump extends View {
  init(_props, cx) {
    const { overlay, sidebar } = props() ?? {};
    this.overlay = overlay;
    this.sidebar = sidebar;
    this.targets = labelSpaces(spaces());
    this.prefix = "";
    this.page = 0;
    this.wide = true;
    this.lastWheelAt = -Infinity;
    this.wheelTravel = 0;
    this.wheelTurned = false;
    this.handle = cx.focus_handle();
    this.handle.focus();
    if (this.sidebar) {
      this.hints = Object.fromEntries(this.targets.map(({ id, hint }) => [id, hint]));
      this.showHints();
    }
  }

  showHints() {
    setShared(SIDEBAR_KEY, { overlay: this.overlay, hints: this.hints, prefix: this.prefix });
  }

  close() {
    if (this.sidebar && shared(SIDEBAR_KEY)?.overlay === this.overlay) setShared(SIDEBAR_KEY, null);
  }

  dismiss() {
    closeOverlay(this.overlay);
  }

  select(id) {
    this.dismiss();
    run("space.select", { id });
  }

  rows(prefix = this.prefix) {
    const live = new Map(spaces().map((space) => [space.id, space]));
    return this.targets
      .filter((target) => live.has(target.id) && target.hint.startsWith(prefix))
      .map((target) => ({ ...live.get(target.id), hint: target.hint }));
  }

  pagination(count) {
    const columns = this.wide && count >= ROWS_PER_PAGE ? 2 : 1;
    const pageSize = ROWS_PER_PAGE * columns;
    const pageCount = Math.max(1, Math.ceil(count / pageSize));
    return { columns, pageSize, pageCount, page: Math.min(this.page, pageCount - 1) };
  }

  turnPage(step, cx) {
    const { page, pageCount } = this.pagination(this.rows().length);
    const next = Math.max(0, Math.min(page + step, pageCount - 1));
    if (next === page) return;
    this.page = next;
    cx.notify();
  }

  wheel(event, cx) {
    const { x, y } = event.delta_lines ?? event.delta;
    if (event.modifiers.control || Math.abs(x) >= Math.abs(y)) return;
    cx.stop_propagation();
    if (event.delta_lines) {
      this.turnPage(y > 0 ? -1 : 1, cx);
      return;
    }
    const now = Date.now();
    if (now - this.lastWheelAt >= WHEEL_PAUSE_MS) {
      this.wheelTravel = 0;
      this.wheelTurned = false;
    }
    this.lastWheelAt = now;
    if (this.wheelTurned) return;
    this.wheelTravel += y;
    if (Math.abs(this.wheelTravel) < TRACKPAD_THRESHOLD_PX) return;
    this.wheelTurned = true;
    this.turnPage(this.wheelTravel > 0 ? -1 : 1, cx);
  }

  keyDown(event, cx) {
    cx.stop_propagation();
    if (event.keystroke === "escape") {
      this.dismiss();
      return;
    }
    const { control, alt, platform } = event.modifiers;
    if (control || alt || platform) return;
    const key = event.key.toLowerCase();
    if (!this.sidebar && (key === "up" || key === "pageup")) {
      this.turnPage(-1, cx);
      return;
    }
    if (!this.sidebar && (key === "down" || key === "pagedown")) {
      this.turnPage(1, cx);
      return;
    }
    let prefix;
    if (event.keystroke === "backspace" && this.prefix) prefix = this.prefix.slice(0, -1);
    else if (!event.is_held && key.length === 1 && HINT_KEYS.includes(key)) prefix = this.prefix + key;
    else return;

    const rows = this.rows(prefix);
    if (this.sidebar && !rows.length) return;
    this.prefix = prefix;
    const match = rows.find((space) => space.hint === prefix);
    if (match) {
      this.select(match.id);
      return;
    }
    if (this.sidebar) {
      this.showHints();
    } else {
      this.page = 0;
      cx.notify();
    }
  }

  entry(space, localHome, t) {
    const folder = space.folder === localHome ? "~"
      : space.folder.startsWith(localHome + "/") ? "~" + space.folder.slice(localHome.length)
      : space.folder;
    const detail = [space.active && "Current", space.machine, folder, space.branch].filter(Boolean).join(" · ");
    return h_flex().id(`space-jump-${space.id}`).flex_1().min_w(0).h_full()
      .px(8).gap(8).items_center().rounded(6).bg(space.active ? t.selected : t.popover)
      .cursor_pointer().hover((style) => style.bg(t.hover)).active((style) => style.bg(t.selected))
      .on_click(() => this.select(space.id))
      .child(
        h_flex().min_w(32).h(28).px(6).flex_none().items_center().justify_center()
          .rounded(4).border_1().border_color(t.input).bg(t.raised)
          .font_family("monospace").font_semibold().text_color(t.accent)
          .child(div().text_color(t.muted).child(space.hint.slice(0, this.prefix.length)))
          .child(div().child(space.hint.slice(this.prefix.length))),
      )
      .child(
        v_flex().flex_1().min_w(0).gap(2)
          .child(div().truncate().font_semibold().child(space.name))
          .child(div().truncate().text_size(11).text_color(t.muted).child(detail)),
      );
  }

  pageButton(id, label, enabled, step, t) {
    return h_flex().id(`space-jump-${id}`).min_w(88).h_full().px(8)
      .items_center().justify_center().rounded(6).text_color(enabled ? t.foreground : t.dim)
      .when(enabled, (button) => button.cursor_pointer()
        .hover((style) => style.bg(t.hover)).active((style) => style.bg(t.selected))
        .on_click((_event, cx) => this.turnPage(step, cx)))
      .child(label);
  }

  render() {
    if (this.sidebar) {
      return div().id("space-jump-sidebar").size_full().track_focus(this.handle)
        .on_key_down((event, cx) => this.keyDown(event, cx))
        .on_mouse_down_out(() => this.dismiss());
    }
    const t = theme();
    const rows = this.rows();
    const { columns, pageSize, pageCount, page } = this.pagination(rows.length);
    const visible = rows.slice(page * pageSize, (page + 1) * pageSize);
    const lineCount = Math.ceil(visible.length / columns);
    const localHome = home();
    return v_flex()
      .id("space-jump")
      .track_focus(this.handle)
      .on_key_down((event, cx) => this.keyDown(event, cx))
      .on_size_change(({ width }, cx) => {
        const wide = width >= MIN_TWO_COLUMN_WIDTH;
        if (wide === this.wide) return;
        this.wide = wide;
        this.page = 0;
        cx.notify();
      })
      .w_full().min_h(0).p(16).gap(8)
      .bg(t.popover).text_color(t.foreground).text_size(14)
      .child(
        h_flex().h(44).flex_none().items_center().justify_between().gap(8)
          .child(div().min_w(0).truncate().text_size(16).font_semibold().child("Jump to space"))
          .child(
            h_flex().min_w(0).items_center().gap(8)
              .when(this.prefix || rows.length > 0, (bar) => bar.child(
                div().truncate().text_size(12).text_color(this.prefix ? t.accent : t.muted)
                  .child(this.prefix ? `Hint: ${this.prefix}` : "Press a hint to jump"),
              ))
              .child(
                h_flex().id("space-jump-close").size(44).flex_none().items_center().justify_center()
                  .rounded(6).cursor_pointer().hover((style) => style.bg(t.hover))
                  .active((style) => style.bg(t.selected))
                  .on_click(() => this.dismiss())
                  .child(
                    div().px(6).py(2).rounded(4).border_1().border_color(t.border)
                      .text_size(11).text_color(t.muted).child("Esc"),
                  ),
              ),
          ),
      )
      .child(
        v_flex().id("space-jump-list").gap(ROW_GAP)
          .when(pageCount > 1, (list) => list.h(ROWS_PER_PAGE * (ROW_HEIGHT + ROW_GAP) - ROW_GAP)
            .on_scroll_wheel((event, cx) => this.wheel(event, cx)))
          .children(Array.from({ length: lineCount }, (_, line) => {
            const start = line * columns;
            const entries = visible.slice(start, start + columns);
            return h_flex().h(ROW_HEIGHT).flex_none().gap(8)
              .children(entries.map((space) => this.entry(space, localHome, t)))
              .when(entries.length < columns, (row) => row.child(div().flex_1()));
          }))
          .when(!rows.length, (list) => list.child(
            v_flex().h(112).items_center().justify_center().gap(8)
              .child(div().font_semibold().child(this.prefix ? "No matching hint" : "No spaces open"))
              .when(this.prefix, (empty) => empty.child(
                div().text_size(12).text_color(t.muted).child("Backspace to edit"),
              )),
          )),
      )
      .when(pageCount > 1, (dialog) => dialog.child(
        h_flex().h(44).flex_none().items_center().justify_between()
          .border_t(1).border_color(t.border).text_size(12)
          .child(this.pageButton("prev", "↑ Page Up", page > 0, -1, t))
          .child(div().text_color(t.muted).child(`Page ${page + 1} of ${pageCount}`))
          .child(this.pageButton("next", "↓ Page Down", page + 1 < pageCount, 1, t)),
      ));
  }
}
