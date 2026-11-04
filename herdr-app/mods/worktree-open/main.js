import { View, div } from "gpui-kit";
import { focused, openOverlay, closeOverlay, props } from "herdr";

export default class WorktreeLauncher extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      const f = focused();
      openOverlay({ mod: "worktree", kind: "dialog", width: 560, height: 480, props: { space: f?.space, folder: f?.cwd, action: "open" } });
      closeOverlay(props().overlay);
    });
  }

  render() {
    return div();
  }
}
