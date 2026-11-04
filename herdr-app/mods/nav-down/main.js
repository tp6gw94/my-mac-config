import { View, div } from "gpui-kit";
import { run, hc, panes, closeOverlay, props } from "herdr";

export default class Nav extends View {
  init() {
    if (!props()) return;
    closeOverlay(props().overlay);
    const pane = panes().find((p) => p.focused);
    if (pane?.terminal && pane.program.key === "nvim") hc(["keys", pane.terminal, "ctrl+j"]);
    else run("pane.go", { direction: "down" });
  }

  render() {
    return div();
  }
}
