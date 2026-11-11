import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { createContext, SourceTextModule, SyntheticModule } from "node:vm";

const source = await readFile(new URL("./main.js", import.meta.url), "utf8");

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
      if (key === "on_key_down") return (handler) => { node.handlers.keyDown = handler; return proxy; };
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

async function open(count) {
  let items = Array.from({ length: count }, (_, index) => ({
    id: `sp${index}`,
    name: `Space ${index}`,
    folder: `/home/todd/project-${index}`,
    machine: null,
    branch: "main",
    active: index === 0,
  }));
  let focused;
  const closed = [];
  const commands = [];
  const cx = {
    notify() {},
    stop_propagation() {},
    focus_handle() {
      const handle = { focus() { focused = handle; } };
      return handle;
    },
  };
  const context = createContext({});
  const modules = {
    "gpui-kit": { View: class {}, div: element },
    "gpui-base": { h_flex: element, v_flex: element },
    herdr: {
      closeOverlay: (id) => closed.push(id),
      home: () => "/home/todd",
      props: () => ({ overlay: "space-jump" }),
      run: (name, args) => commands.push({ name, args: structuredClone(args) }),
      spaces: () => items,
      theme: () => ({}),
    },
  };
  const mod = new SourceTextModule(source, { context });
  await mod.link((name) => {
    const exports = modules[name];
    return new SyntheticModule(Object.keys(exports), function () {
      for (const [key, value] of Object.entries(exports)) this.setExport(key, value);
    }, { context });
  });
  await mod.evaluate();
  const view = new mod.namespace.default();
  view.init({}, cx);
  const tree = () => view.render();
  return {
    closed,
    commands,
    tree,
    items: () => items,
    update: (next) => { items = next; },
    isFocused: () => tree().focus === focused,
    rows: () => walk(tree()).filter((node) => /^space-jump-sp\d+$/.test(node.elementId)),
    key(key, { modifiers = {}, held = false } = {}) {
      tree().handlers.keyDown({
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
  assert.doesNotMatch(content(app.tree()), /Ctrl\+A|Enter|[\u3400-\u9fff]/);
});

test("a hint switches directly to its space and dismisses the overlay", async () => {
  const app = await open(5);
  app.key("s");
  assert.deepEqual(app.commands, [{ name: "space.select", args: { id: "sp1" } }]);
  assert.deepEqual(app.closed, ["space-jump"]);
});

test("large lists have unique, equal-length hints without prefix collisions", async () => {
  for (const [count, width] of [[26, 1], [27, 2], [676, 2], [677, 3]]) {
    const app = await open(count);
    const hints = app.rows().map((row) => content(row.nodes[0]));
    assert.equal(new Set(hints).size, count);
    assert.ok(hints.every((hint) => hint.length === width));
  }
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
  assert.equal(app.rows().length, 27);
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
