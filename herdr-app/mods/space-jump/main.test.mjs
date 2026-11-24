import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { createContext, SourceTextModule, SyntheticModule } from "node:vm";

const source = await readFile(new URL("./main.js", import.meta.url), "utf8");
const sidebarSource = await readFile(new URL("../todd-spaces/main.js", import.meta.url), "utf8");

function element() {
  const node = { nodes: [], handlers: {} };
  const proxy = new Proxy(node, {
    get(target, key) {
      if (key in target) return target[key];
      if (key === "child") return (child) => { node.nodes.push(child); return proxy; };
      if (key === "children") return (children) => { node.nodes.push(...children); return proxy; };
      if (key === "when") return (condition, apply) => condition ? apply(proxy) : proxy;
      if (key === "id") return (id) => { node.elementId = id; return proxy; };
      if (key === "track_focus") return (handle) => { node.focus = handle; return proxy; };
      if (key.startsWith("on_")) return (...args) => {
        node.handlers[args.length === 2 ? `${key}:${args[0]}` : key] = args.at(-1);
        return proxy;
      };
      return () => proxy;
    },
  });
  return proxy;
}

function walk(node) {
  if (typeof node !== "object") return [];
  return [node, ...node.nodes.flatMap(walk)];
}

function content(node) {
  return typeof node === "string" ? node : node.nodes.map(content).join("");
}

async function open(count, { sidebar = false, width = 232 } = {}) {
  let items = Array.from({ length: count }, (_, index) => ({
    id: `sp${index}`,
    name: `Space ${index}`,
    folder: `/home/todd/project-${index}`,
    machine: null,
    branch: "main",
    active: index === 0,
  }));
  let focused;
  let view;
  let hostProps = {};
  const sharedValues = new Map();
  const closed = [];
  const commands = [];
  let now = 0;
  const cx = {
    notify() {},
    stop_propagation() {},
    focus_handle() {
      const handle = { focus() { focused = handle; } };
      return handle;
    },
  };
  const context = createContext({ Date: { now: () => now }, localStorage: { getItem: () => null } });
  const modules = {
    "gpui-kit": { View: class {}, div: element, svg: element },
    "gpui-base": { h_flex: element, v_flex: element, ScrollHandle: { new: () => ({ scroll_to_item() {} }) } },
    herdr: {
      closeOverlay(id) {
        closed.push(id);
        view.close();
      },
      checking: () => true,
      exec() {},
      hc() {},
      home: () => "/home/todd",
      layout: () => ({ id: "sidebar", size: { px: width } }),
      machines: () => [],
      openOverlay() {},
      panes: () => [],
      props: () => hostProps,
      run: (name, args) => commands.push({ name, args: structuredClone(args) }),
      setShared: (key, value) => sharedValues.set(key, structuredClone(value)),
      shared: (key) => sharedValues.get(key),
      spaces: () => items,
      theme: () => ({}),
      watchFolder() {},
      window: () => ({}),
    },
  };
  async function instantiate(code) {
    const mod = new SourceTextModule(code, { context });
    await mod.link((name) => {
      const exports = modules[name];
      return new SyntheticModule(Object.keys(exports), function () {
        for (const [key, value] of Object.entries(exports)) this.setExport(key, value);
      }, { context });
    });
    await mod.evaluate();
    return new mod.namespace.default();
  }
  const spacesView = sidebar ? await instantiate(sidebarSource) : null;
  spacesView?.init({}, cx);
  view = await instantiate(source);
  hostProps = { overlay: "space-jump", sidebar };
  view.init({}, cx);
  const tree = () => view.render();
  const byId = (id) => walk(tree()).find((node) => node.elementId === id);
  return {
    closed,
    commands,
    tree,
    items: () => items,
    update: (next) => { items = next; },
    isFocused: () => tree().focus === focused,
    sidebarRow(id) { return walk(spacesView.render()).find((node) => node.elementId === `space-${id}`); },
    clickSpace(id) {
      this.sidebarRow(id).handlers["on_mouse_down:left"]({}, cx);
      this.sidebarRow(id).handlers["on_mouse_up:left"]({}, cx);
    },
    outside() { tree().handlers.on_mouse_down_out({}, cx); },
    rows: () => walk(tree()).filter((node) => /^space-jump-sp\d+$/.test(node.elementId)),
    click(id) { byId(id).handlers.on_click?.({}, cx); },
    resize(width) { tree().handlers.on_size_change?.({ width, height: 480 }, cx); },
    wheel(y, { x = 0, elapsed = 0, lines = false } = {}) {
      now += elapsed;
      byId("space-jump-list").handlers.on_scroll_wheel?.({
        delta: { x, y },
        delta_lines: lines ? { x, y } : undefined,
        modifiers: { control: false },
      }, cx);
    },
    key(key, { modifiers = {}, held = false } = {}) {
      tree().handlers.on_key_down({
        key,
        keystroke: key,
        modifiers: { control: false, alt: false, platform: false, ...modifiers },
        is_held: held,
      }, cx);
    },
  };
}

test("opening focuses the keyboard target and shows single-letter hints", async () => {
  const app = await open(5);
  assert.equal(app.isFocused(), true);
  assert.deepEqual(app.rows().map((row) => content(row.nodes[0])), ["a", "s", "d", "f", "g"]);
  assert.match(content(app.tree()), /Jump to space/);
  assert.match(content(app.tree()), /Current/);
  assert.match(content(app.tree()), /Esc/);
  assert.match(content(app.tree()), /~\/project-0/);
  assert.match(content(app.tree()), /Press a hint to jump/);
  assert.doesNotMatch(content(app.tree()), /Page \d|Enter|Ctrl\+A|[\u3400-\u9fff]/);
});

test("a hint switches directly to its space and dismisses the overlay", async () => {
  const app = await open(5);
  app.key("s");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp1" } }]);
  assert.deepEqual(app.closed, ["space-jump"]);
});

test("sidebar mode puts the hints on existing space rows and jumps without a dialog", async () => {
  const app = await open(4, { sidebar: true });
  assert.equal(app.isFocused(), true);
  assert.equal(content(app.tree()), "");
  assert.deepEqual([0, 1, 2, 3].map((i) => content(app.sidebarRow(`sp${i}`))), [
    "SSpace 0a", "SSpace 1s", "SSpace 2d", "SSpace 3f",
  ]);
  app.key("x");
  app.key("d");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp2" } }]);
  assert.equal(content(app.sidebarRow("sp2")), "SSpace 2");
});

test("clicking a sidebar row while hints are showing also selects the space", async () => {
  const app = await open(4, { sidebar: true });
  app.clickSpace("sp1");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp1" } }]);
  assert.equal(content(app.sidebarRow("sp1")), "SSpace 1");
});

test("the narrow sidebar shows a hint instead of the space number until it is dismissed", async () => {
  const app = await open(4, { sidebar: true, width: 44 });
  assert.equal(content(app.sidebarRow("sp1")), "s");
  app.outside();
  assert.match(content(app.sidebarRow("sp1")), /^2/);
  assert.deepEqual(app.commands, []);
});

test("large lists have unique, equal-length hints without prefix collisions", async () => {
  for (const [count, width] of [[26, 1], [27, 2], [676, 2], [677, 3]]) {
    const app = await open(count);
    const hints = [];
    for (let page = 0; page < Math.ceil(count / 14); page++) {
      hints.push(...app.rows().map((row) => content(row.nodes[0])));
      app.key("pagedown");
    }
    assert.equal(hints.length, count);
    assert.equal(new Set(hints).size, count);
    assert.ok(hints.every((hint) => hint.length === width));
  }
});

test("fourteen spaces fit on one page at normal width, and narrow windows use one column", async () => {
  const app = await open(14);
  assert.equal(app.rows().length, 14);
  assert.doesNotMatch(content(app.tree()), /Page \d/);
  app.resize(480);
  assert.equal(app.rows().length, 7);
  assert.match(content(app.tree()), /Page 1 of 2/);
  app.key("pagedown");
  assert.equal(app.rows()[0].elementId, "space-jump-sp7");
});

test("Page Up and Page Down browse whole pages without selecting a space", async () => {
  const app = await open(18);
  assert.match(content(app.tree()), /Page 1 of 2/);
  app.key("pagedown");
  assert.match(content(app.tree()), /Page 2 of 2/);
  assert.equal(app.rows()[0].elementId, "space-jump-sp14");
  app.key("pagedown", { held: true });
  assert.match(content(app.tree()), /Page 2 of 2/);
  app.key("pageup");
  assert.match(content(app.tree()), /Page 1 of 2/);
  assert.deepEqual(app.commands, []);
});

test("arrow keys flip whole pages and can repeat without selecting a space", async () => {
  const app = await open(42);
  assert.match(content(app.tree()), /↑ Page Up.*↓ Page Down/);
  app.key("up");
  assert.match(content(app.tree()), /Page 1 of 3/);
  app.key("down");
  assert.match(content(app.tree()), /Page 2 of 3/);
  app.key("down", { held: true });
  assert.match(content(app.tree()), /Page 3 of 3/);
  app.key("up");
  assert.match(content(app.tree()), /Page 2 of 3/);
  assert.deepEqual(app.commands, []);
});

test("hints can jump to a space on a different page without browsing", async () => {
  const app = await open(18);
  app.key("y");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp14" } }]);
  const paged = await open(18);
  paged.key("pagedown");
  assert.equal(paged.rows()[0].elementId, "space-jump-sp14");
  paged.key("a");
  assert.deepEqual(paged.commands, [{ name: "space.select", args: { id: "sp0" } }]);
});

test("wheel and trackpad browse by page without skipping on swipe inertia", async () => {
  const app = await open(42);
  app.wheel(-60, { x: 100 });
  app.wheel(-12);
  assert.match(content(app.tree()), /Page 1 of 3/);
  app.wheel(-12, { elapsed: 16 });
  app.wheel(-90, { elapsed: 16 });
  assert.match(content(app.tree()), /Page 2 of 3/);
  app.wheel(-30, { elapsed: 150 });
  assert.match(content(app.tree()), /Page 3 of 3/);
  app.wheel(1, { lines: true });
  assert.match(content(app.tree()), /Page 2 of 3/);
  assert.deepEqual(app.commands, []);
});

test("the next-page button and space entries remain clickable", async () => {
  const app = await open(18);
  app.click("space-jump-next");
  app.click("space-jump-next");
  assert.match(content(app.tree()), /Page 2 of 2/);
  app.click("space-jump-sp14");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp14" } }]);
});

test("editing a hint starts the filtered view on its first page", async () => {
  const app = await open(27);
  app.key("pagedown");
  app.key("s");
  assert.equal(app.rows()[0].elementId, "space-jump-sp26");
  app.key("backspace");
  assert.match(content(app.tree()), /Page 1 of 2/);
  assert.equal(app.rows()[0].elementId, "space-jump-sp0");
});

test("partial hints narrow the list without jumping before the full label", async () => {
  const app = await open(27);
  app.key("s");
  assert.equal(app.rows().length, 1);
  assert.deepEqual(app.commands, []);
  app.key("a");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp26" } }]);
});

test("a mistyped hint shows recovery instructions and Backspace restores candidates", async () => {
  const app = await open(27);
  app.key("q");
  assert.match(content(app.tree()), /No matching hint/);
  assert.match(content(app.tree()), /Backspace/);
  app.key("backspace");
  assert.match(content(app.tree()), /Page 1 of 2/);
  app.key("a");
  app.key("s");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp1" } }]);
});

test("Escape dismisses without switching spaces", async () => {
  const app = await open(5);
  app.key("escape");
  assert.deepEqual(app.closed, ["space-jump"]);
  assert.deepEqual(app.commands, []);
});

test("live reorder, addition and removal do not reassign existing hints", async () => {
  const app = await open(5);
  const original = app.items();
  app.update([original[4], original[0], original[3], original[2], { ...original[1], id: "new-space" }]);
  assert.deepEqual(app.rows().map((row) => content(row.nodes[0])), ["a", "d", "f", "g"]);
  app.key("s");
  assert.deepEqual(app.commands, []);
  app.key("backspace");
  app.key("d");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp2" } }]);
});

test("modified and repeated keys cannot select a space", async () => {
  const app = await open(5);
  for (const modifier of ["control", "alt", "platform"]) {
    app.key("s", { modifiers: { [modifier]: true } });
  }
  app.key("s", { held: true });
  assert.deepEqual(app.commands, []);
  assert.equal(app.rows().length, 5);
  app.key("S", { modifiers: { shift: true } });
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp1" } }]);
});

test("empty space lists show a concise English empty state and support Escape", async () => {
  const app = await open(0);
  assert.match(content(app.tree()), /No spaces open/);
  app.key("escape");
  assert.deepEqual(app.closed, ["space-jump"]);
  assert.deepEqual(app.commands, []);
});
