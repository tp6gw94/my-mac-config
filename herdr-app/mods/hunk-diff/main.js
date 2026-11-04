import { View, div } from "gpui-kit";
import { run, hc, spaces, focused, closeOverlay, props, home } from "herdr";

const NAME = "Hunk Diff";

function findTab(id) {
  return spaces().flatMap((s) => s.tabs).find((t) => t.id === id);
}

export default class HunkDiff extends View {
  init(_props, cx) {
    const f = focused();
    if (!f) return;
    this.tab = `hunk-${f.space}`;
    if (findTab(this.tab)) {
      this.show();
      return;
    }
    cx.spawn(async () => {
      await hc(["run", "--bg", "--json", "--rm", "--no-parent", "--label", `herdr.space=${f.space}`, "--label", `herdr.tab=${this.tab}`, "--cwd", f.cwd || home(), "--", "hunk", "diff"]);
    });
  }

  show() {
    run("tab.rename", { id: this.tab, name: NAME });
    run("tab.select", { id: this.tab });
    closeOverlay(props().overlay);
  }

  render() {
    if (findTab(this.tab)) this.show();
    return div();
  }
}
