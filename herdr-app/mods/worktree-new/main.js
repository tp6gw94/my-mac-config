import { View, div } from "gpui-kit";
import { focused, openOverlay, closeOverlay, props } from "herdr";

export default class WorktreeLauncher extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      const f = focused();
      openOverlay({ mod: "worktree", kind: "dialog", width: 460, height: 280, props: { space: f?.space, folder: f?.cwd, action: "new" } });
      closeOverlay(props().overlay);
    });
  }

  render() {
    return div();
  }
}
