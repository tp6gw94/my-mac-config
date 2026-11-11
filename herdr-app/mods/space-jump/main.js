import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { closeOverlay, home, props, run, spaces, theme } from "herdr";

const HINT_KEYS = "asdfghjklqwertyuiopzxcvbnm";

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
    this.targets = labelSpaces(spaces());
    this.prefix = "";
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  select(id) {
    this.dismiss();
    run("space.select", { id });
  }

  rows() {
    const live = new Map(spaces().map((space) => [space.id, space]));
    return this.targets
      .filter((target) => live.has(target.id) && target.hint.startsWith(this.prefix))
      .map((target) => ({ ...live.get(target.id), hint: target.hint }));
  }

  keyDown(event, cx) {
    cx.stop_propagation();
    if (event.keystroke === "escape") {
      this.dismiss();
      return;
    }
    if (event.keystroke === "backspace") {
      this.prefix = this.prefix.slice(0, -1);
      cx.notify();
      return;
    }
    const { control, alt, platform } = event.modifiers;
    const key = event.key.toLowerCase();
    if (control || alt || platform || event.is_held || key.length !== 1 || !HINT_KEYS.includes(key)) return;
    this.prefix += key;
    const match = this.rows().find((space) => space.hint === this.prefix);
    if (match) this.select(match.id);
    else cx.notify();
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const localHome = home();
    return v_flex()
      .id("space-jump")
      .track_focus(this.handle)
      .on_key_down((event, cx) => this.keyDown(event, cx))
      .w_full().max_h(480).min_h(0).p(16).gap(8)
      .bg(t.popover).text_color(t.foreground).text_size(14)
      .child(
        h_flex().h(40).flex_none().items_center().justify_between().gap(16)
          .child(div().text_size(16).font_semibold().child("Jump to space"))
          .child(
            h_flex().items_center().gap(8)
              .child(div().w(64).font_family("monospace").text_color(t.accent).child(this.prefix))
              .child(
                h_flex().id("space-jump-close").size(40).items_center().justify_center()
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
        v_flex().id("space-jump-list").min_h(0)
          .h(Math.min(392, rows.length ? rows.length * 60 - 4 : 112))
          .gap(4).overflow_y_scrollbar()
          .children(rows.map((space) => {
            const folder = space.folder === localHome ? "~"
              : space.folder.startsWith(localHome + "/") ? "~" + space.folder.slice(localHome.length)
              : space.folder;
            const detail = [space.machine, folder, space.branch].filter(Boolean).join(" · ");
            return h_flex()
              .id(`space-jump-${space.id}`)
              .h(56).flex_none().px(10).gap(12).items_center().rounded(8)
              .bg(space.active ? t.selected : t.popover)
              .cursor_pointer().hover((style) => style.bg(t.hover))
              .active((style) => style.bg(t.selected))
              .on_click(() => this.select(space.id))
              .child(
                h_flex().min_w(36).h(32).px(8).flex_none().items_center().justify_center()
                  .rounded(5).border_1().border_color(t.input).bg(t.raised)
                  .font_family("monospace").font_semibold().text_color(t.accent)
                  .child(div().text_color(t.muted).child(space.hint.slice(0, this.prefix.length)))
                  .child(div().child(space.hint.slice(this.prefix.length))),
              )
              .child(
                v_flex().flex_1().min_w(0).gap(4)
                  .child(div().truncate().font_semibold().child(space.name))
                  .child(div().truncate().text_size(11).text_color(t.muted).child(detail)),
              )
              .when(space.active, (row) => row.child(
                div().flex_none().text_size(11).text_color(t.muted).child("Current"),
              ));
          }))
          .when(!rows.length, (list) => list.child(
            v_flex().h(112).items_center().justify_center().gap(8)
              .child(div().font_semibold().child(this.prefix ? "No matching hint" : "No spaces open"))
              .when(this.prefix, (empty) => empty.child(
                div().text_size(12).text_color(t.muted).child("Backspace to edit"),
              )),
          )),
      );
  }
}
