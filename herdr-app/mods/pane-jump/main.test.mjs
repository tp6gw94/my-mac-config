import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { createContext, SourceTextModule, SyntheticModule } from "node:vm";

const source = await readFile(new URL("./main.js", import.meta.url), "utf8");

function element() {
  const node = { children: [] };
  const builder = new Proxy(node, {
    get(target, key) {
      if (key in target) return target[key];
      if (key === "child") return (child) => { node.children.push(child); return builder; };
      if (key === "when") return (condition, apply) => condition ? apply(builder) : builder;
      if (["id", "on_key_down", "track_focus"].includes(key)) {
        return (value) => { node[key] = value; return builder; };
      }
      return () => builder;
    },
  });
  return builder;
}

function find(node, id) {
  if (typeof node === "string") return;
  if (node.id === id) return node;
  return node.children.map((child) => find(child, id)).find(Boolean);
}

async function app({ count = 4, zoomed = false } = {}) {
  const overlay = "mod-pane-jump";
  const items = [
    ...Array.from({ length: count }, (_, i) => ({ pane: `p${i}`, tab: "current", zoomed: zoomed && i === 0 })),
    { pane: "other", tab: "background" },
  ];
  const store = new Map();
  const context = createContext();
  let current = "p0";
  let keyboard;
  let open = false;
  let viewProps = {};
  let panel;
  const notices = [];
  const cx = {
    focus_handle() {
      const handle = { focus() { keyboard = handle; } };
      return handle;
    },
    stop_propagation() {},
  };
  const modules = {
    "gpui-kit": { View: class {}, div: element, svg: element, image: element },
    "gpui-base": { h_flex: element },
    herdr: {
      closeOverlay(id) {
        assert.equal(id, overlay);
        open = false;
        panel.close();
      },
      focused: () => ({ tab: "current", pane: current }),
      home: () => "/home/todd",
      layout: () => ({}),
      notify: ({ body }) => notices.push(body),
      panes: () => items,
      props: () => viewProps,
      run(command, args) {
        assert.equal(command, "pane.focus");
        current = args.pane;
      },
      setShared: (key, value) => store.set(key, structuredClone(value)),
      shared: (key) => store.get(key),
      theme: () => ({}),
    },
  };
  const mod = new SourceTextModule(source, { context });
  await mod.link((name) => {
    const entries = Object.entries(modules[name]);
    return new SyntheticModule(entries.map(([key]) => key), function () {
      for (const [key, value] of entries) this.setExport(key, value);
    }, { context });
  });
  await mod.evaluate();
  const View = mod.namespace.default;
  return {
    open() {
      viewProps = { overlay };
      panel = new View();
      open = true;
      panel.init(viewProps, cx);
      if (open) {
        assert.ok(keyboard);
        assert.equal(panel.render().track_focus, keyboard);
      }
    },
    hint(pane) {
      viewProps = { pane };
      const header = new View();
      header.init(viewProps, cx);
      return find(header.render(), `pane-jump-hint-${pane}`)?.children[0];
    },
    key(key) {
      assert.equal(open, true);
      panel.render().on_key_down({ key, keystroke: key, modifiers: {} }, cx);
    },
    current: () => current,
    isOpen: () => open,
    notices,
  };
}

test("shows pane hints in the current tab and jumps directly to the selected pane", async () => {
  const window = await app();
  assert.equal(window.hint("p0"), undefined);
  window.open();
  assert.deepEqual([0, 1, 2, 3].map((i) => window.hint(`p${i}`)), ["a", "s", "d", "f"]);
  assert.equal(window.hint("other"), undefined);
  window.key("f");
  assert.equal(window.isOpen(), false);
  assert.equal(window.current(), "p3");
  assert.equal(window.hint("p3"), undefined);
});

test("Escape removes hints without changing the focused pane", async () => {
  const window = await app();
  window.open();
  window.key("escape");
  assert.equal(window.isOpen(), false);
  assert.equal(window.current(), "p0");
  assert.equal(window.hint("p0"), undefined);
});

test("a zoomed tab shows how to jump without leaving the picker open", async () => {
  const window = await app({ zoomed: true });
  window.open();
  assert.equal(window.isOpen(), false);
  assert.equal(window.hint("p0"), undefined);
  assert.deepEqual(window.notices, ["Unzoom to jump between panes"]);
});

test("a single pane shows a notice without opening the picker", async () => {
  const window = await app({ count: 1 });
  window.open();
  assert.equal(window.isOpen(), false);
  assert.equal(window.hint("p0"), undefined);
  assert.deepEqual(window.notices, ["No other panes in this tab"]);
});

test("tabs with more than 26 panes use unambiguous multi-letter hints", async () => {
  const window = await app({ count: 27 });
  window.open();
  const hints = Array.from({ length: 27 }, (_, i) => window.hint(`p${i}`));
  assert.equal(new Set(hints).size, 27);
  assert.ok(hints.every((hint) => hint.length === 2));
  window.key(hints[26][0]);
  assert.equal(window.isOpen(), true);
  window.key(hints[26][1]);
  assert.equal(window.current(), "p26");
});
