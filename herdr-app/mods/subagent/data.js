import { exec, readTextFile, home } from "herdr";

export const ACTIVE = ["queued", "starting", "running", "waiting_input", "cancelling"];
const ACTIVE_PATTERN = `"status":"(${ACTIVE.join("|")})"`;
const SESSION_TAIL_BYTES = 600000;
const RECENT_SCAN = 40;
const RECENT_SHOWN = 10;

const tasksRoot = () => `${home()}/.pi/agent/rpc-subagents/data/tasks`;
export const viewerPath = () => `${home()}/.pi/agent/git/github.com/tp6gw94/pi-extras/extensions/rpc-subagents/viewer.mjs`;

export const inside = (cwd, dir) => Boolean(dir) && (cwd === dir || cwd.startsWith(dir.endsWith("/") ? dir : `${dir}/`));
const started = (task) => task.startedAt ?? task.createdAt;

async function readStates(files) {
  const texts = await Promise.all([...new Set(files)].map((file) => readTextFile(file)));
  return texts.filter(Boolean).map((text) => JSON.parse(text));
}

const lines = (stdout) => stdout.split("\n").filter(Boolean);

export async function runningTasks() {
  const found = await exec("grep", ["-rlE", "--include=state.json", ACTIVE_PATTERN, tasksRoot()]);
  return (await readStates(lines(found.stdout))).filter((task) => ACTIVE.includes(task.status));
}

export async function folderTasks(dir) {
  const script = 'grep -rlF --include=state.json "$1" "$2" | xargs -r ls -t | head -n "$3"; grep -rlE --include=state.json "$4" "$2"';
  const found = await exec("sh", ["-c", script, "sh", `"cwd":${JSON.stringify(dir).slice(0, -1)}`, tasksRoot(), String(RECENT_SCAN), ACTIVE_PATTERN]);
  const tasks = (await readStates(lines(found.stdout))).filter((task) => inside(task.cwd, dir));
  return {
    running: tasks.filter((task) => ACTIVE.includes(task.status)).sort((a, b) => started(a) - started(b)),
    recent: tasks.filter((task) => !ACTIVE.includes(task.status))
      .sort((a, b) => (b.finishedAt ?? started(b)) - (a.finishedAt ?? started(a))).slice(0, RECENT_SHOWN),
  };
}

const textOf = (content) => typeof content === "string" ? content
  : (content ?? []).filter((part) => part.type === "text").map((part) => part.text).join("\n");

function parseLine(line) {
  try { return JSON.parse(line); } catch { return null; }
}

export async function loadSession(task) {
  if (!task.sessionFile) return { prompt: "", entries: [], clipped: false };
  const [first, tail] = await Promise.all([
    exec("grep", ["-m1", '"role":"user"', task.sessionFile]),
    exec("tail", ["-c", String(SESSION_TAIL_BYTES), task.sessionFile]),
  ]);
  const prompt = textOf(parseLine(first.stdout)?.message?.content);
  const records = lines(tail.stdout).map(parseLine);
  const clipped = records.length > 0 && records[0] === null;
  const entries = [];
  const tools = new Map();
  let promptSeen = false;
  for (const record of records) {
    if (record?.type !== "message") continue;
    const message = record.message;
    if (message.role === "user") {
      const text = textOf(message.content);
      if (!promptSeen && !clipped && text === prompt) { promptSeen = true; continue; }
      entries.push({ kind: "user", text });
    } else if (message.role === "assistant") {
      for (const part of message.content ?? []) {
        if (part.type === "thinking" && part.thinking?.trim()) entries.push({ kind: "thinking", text: part.thinking.trim() });
        else if (part.type === "text" && part.text?.trim()) entries.push({ kind: "text", text: part.text.trim() });
        else if (part.type === "toolCall") {
          const entry = { kind: "tool", name: part.name, args: part.arguments ?? {}, result: null };
          tools.set(part.id, entry);
          entries.push(entry);
        }
      }
    } else if (message.role === "toolResult") {
      const entry = tools.get(message.toolCallId);
      const result = { text: textOf(message.content), error: Boolean(message.isError), durationMs: message.durationMs };
      if (entry) entry.result = result;
      else entries.push({ kind: "tool", name: message.toolName, args: {}, result });
    }
  }
  return { prompt, entries, clipped };
}

export function toolSummary(args) {
  if (typeof args.command === "string") return args.command;
  if (typeof args.code === "string") return args.code;
  if (typeof args.path === "string") return args.path;
  if (typeof args.query === "string") return args.query;
  if (Array.isArray(args.queries)) return args.queries.join("\n");
  if (typeof args.url === "string") return args.url;
  if (typeof args.prompt === "string") return args.prompt;
  const json = JSON.stringify(args);
  return json === "{}" ? "" : json;
}
