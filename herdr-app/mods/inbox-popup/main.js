import { View, div } from "gpui-kit";
import { hc, focused, openOverlay, closeOverlay, props, home } from "herdr";

const COMMAND = 'nvim "$OBSIDIAN/inbox.md"';

const MATERIALIZE = "import ctypes, os, sys; ctypes.CDLL(None).setiopolicy_np(3, 0, 2); os.execvp(sys.argv[1], sys.argv[1:])";

export default class Launcher extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      const r = await hc(["run", "--bg", "--json", "--rm", "--no-parent", "--cwd", focused()?.cwd || home(), "--", "/usr/bin/python3", "-I", "-c", MATERIALIZE, "zsh", "-lc", COMMAND]);
      const { address } = JSON.parse(r.stdout);
      closeOverlay(props().overlay);
      openOverlay({ kind: "dialog", modal: true, width: 0.8, height: 0.8, layout: { type: "block", content: { terminal: address } } });
    });
  }

  render() {
    return div();
  }
}
