import { View, div } from "gpui-kit";
import { run, hc, panes, closeOverlay, props } from "herdr";

export default class Nav extends View {
  init() {
    if (!props()) return;
    closeOverlay(props().overlay);
    const pane = panes().find((p) => p.focused);
    if (pane?.terminal && pane.program.key === "nvim") hc(["keys", pane.terminal, "ctrl+l"]);
    else run("pane.go", { direction: "right" });
  }

  render() {
    return div();
  }
}
