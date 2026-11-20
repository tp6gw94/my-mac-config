import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { createContext, SourceTextModule, SyntheticModule } from "node:vm";

const config = JSON.parse(await readFile(new URL("../../keys.json", import.meta.url), "utf8"));
const source = await readFile(new URL("./main.js", import.meta.url), "utf8");

function element() {
  const node = { nodes: [] };
  const proxy = new Proxy(node, {
    get(target, key) {
      if (key in target) return target[key];
      if (key === "child") return (child) => { node.nodes.push(child); return proxy; };
      if (key === "children") return (children) => { node.nodes.push(...children); return proxy; };
      if (key === "when") return (condition, apply) => condition ? apply(proxy) : proxy;
      if (["id", "track_focus", "on_key_down", "on_click"].includes(key)) {
        return (value) => { node[key] = value; return proxy; };
      }
      return () => proxy;
    },
  });
  return proxy;
}

function text(node) {
  return typeof node === "string" ? node : node.nodes.map(text).join(" ");
}

function find(node, id) {
  if (typeof node === "string") return;
  if (node.id === id) return node;
  return node.nodes.map((child) => find(child, id)).find(Boolean);
}

async function open(extra = []) {
  const actions = [];
  let focus;
  const handle = { focus: () => { focus = handle; } };
  const cx = { focus_handle: () => handle, notify() {}, stop_propagation() { actions.push("consumed"); } };
  const modules = {
    "gpui-kit": { View: class {}, div: element },
    "gpui-base": { h_flex: element, v_flex: element },
    herdr: {
      closeOverlay: (id) => actions.push(["close", id]),
      commands: () => Object.entries({ "mod.open": "name", "space.select": "index", "pane.split": "direction", "layout.toggle": "id" })
        .map(([name, arg]) => ({ name, args: [{ name: arg }] })),
      focused: () => ({ terminal: "t1" }),
      keys: () => [...Object.entries(config).flatMap(([section, bindings]) =>
        Object.entries(bindings).map(([keys, action]) => ({ section, keys, action }))), ...extra],
      props: () => ({ overlay: "which-key" }),
      run: (name, args) => actions.push([name, args]),
      shared: () => "main",
      theme: () => ({}),
    },
  };
  const context = createContext({});
  const mod = new SourceTextModule(source, { context });
  await mod.link((name) => new SyntheticModule(Object.keys(modules[name]), function () {
    for (const [key, value] of Object.entries(modules[name])) this.setExport(key, value);
  }, { context }));
  await mod.evaluate();
  const view = new mod.namespace.default();
  view.init({}, cx);
  return {
    actions,
    content: () => text(view.render()),
    focused: () => view.render().track_focus === focus && focus !== undefined,
    key: (keystroke, is_held = false) => view.render().on_key_down({ keystroke, is_held }, cx),
    click: (id) => find(view.render(), id).on_click({}, cx),
  };
}

test("the separate opener preserves Ctrl+A help and presents the Git branch", async () => {
  assert.equal(config.global["cmd-shift-k"], "mod.open:which-key");
  assert.equal(config.global["ctrl-a shift-/"], "app.help");
  const menu = await open();
  assert.equal(menu.focused(), true);
  assert.match(menu.content(), /Ctrl\+A.*Git/);
  menu.key("g");
  assert.match(menu.content(), /Lazygit.*Hunk Diff/);
  assert.doesNotMatch(menu.content(), /Split right/);
  menu.key("h");
  assert.deepEqual(structuredClone(menu.actions), ["consumed", "consumed", ["close", "which-key"], ["mod.open", { name: "hunk-diff" }]]);
});

test("unmapped and repeated keys are consumed without leaving the current branch", async () => {
  const menu = await open();
  menu.key("g");
  menu.key("y");
  menu.key("g", true);
  assert.match(menu.content(), /Lazygit.*No shortcut for y/);
  assert.deepEqual(menu.actions, ["consumed", "consumed", "consumed"]);
  menu.key("backspace");
  assert.match(menu.content(), /Which key.*Split right/);
  assert.doesNotMatch(menu.content(), /No shortcut/);
  menu.key("escape");
  assert.deepEqual(menu.actions.at(-1), ["close", "which-key"]);
});

test("clicks and modified keys execute the current bindings with their arguments", async () => {
  const notes = await open();
  notes.click("which-key-row-n");
  notes.click("which-key-row-q");
  assert.deepEqual(structuredClone(notes.actions.at(-1)), ["mod.open", { name: "quicknote" }]);
  const spaces = await open([{ section: "terminal", keys: "ctrl-a shift-1", action: "space.select:2" }]);
  spaces.key("!");
  assert.deepEqual(structuredClone(spaces.actions.at(-1)), ["space.select", { index: 2 }]);
});
