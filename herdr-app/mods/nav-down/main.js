import { View, div } from "gpui-kit";
import { run, exec, hc, panes, terminals, closeOverlay, props } from "herdr";

export default class Nav extends View {
  init() {
    if (!props()) return;
    closeOverlay(props().overlay);
    const pane = panes().find((p) => p.focused);
    if (pane?.terminal && pane.program.key === "nvim") {
      const server = terminals().find((t) => t.address === pane.terminal)?.labels?.["nvim.server"];
      if (server) exec("nvim", ["--server", server, "--remote-send", "<C-j>"]);
      else hc(["keys", pane.terminal, "ctrl+j"]);
    } else run("pane.go", { direction: "down" });
  }

  render() {
    return div();
  }
}
