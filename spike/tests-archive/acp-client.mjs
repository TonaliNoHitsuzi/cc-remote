#!/usr/bin/env node
// M0 ACP Spike 客户端：模拟 cc-connect，spawn `opencode acp`，验证三个生死点
// 用法: node acp-client.mjs [phase]   phase = models | perm | perm-deny
import { spawn } from "node:child_process";

const phase = process.argv[2] || "models";
const BIN = new URL("./bin/opencode", import.meta.url).pathname;
const WORKDIR = new URL("./work", import.meta.url).pathname;

const fs = await import("node:fs");
fs.mkdirSync(WORKDIR, { recursive: true });

const proc = spawn(BIN, ["acp"], { cwd: WORKDIR, stdio: ["pipe", "pipe", "pipe"] });

let nextId = 1;
const pending = new Map();      // id -> {resolve, label}
const log = [];
const timers = [];

function send(obj) {
  const line = JSON.stringify(obj);
  log.push(">>> " + line);
  proc.stdin.write(line + "\n");
}
function request(method, params, label) {
  const id = nextId++;
  return new Promise((resolve) => {
    pending.set(id, { resolve, label });
    send({ jsonrpc: "2.0", id, method, params });
  });
}
function notify(method, params) {
  send({ jsonrpc: "2.0", method, params });
}
function fail(msg) {
  console.log("SPIKE-FAIL: " + msg);
  dumpLog();
  finish(1);
}
function finish(code) {
  timers.forEach(clearTimeout);
  try { proc.kill(); } catch {}
  setTimeout(() => process.exit(code), 200);
}
function dumpLog() {
  fs.writeFileSync(new URL("./acp-trace.log", import.meta.url).pathname, log.join("\n"));
  console.log("(full trace -> spike/acp-trace.log)");
}

// 权限应答策略
let permAutoAnswer = "allow";   // phase=perm: 自动批准; phase=perm-deny: 自动拒绝

proc.stdout.setEncoding("utf8");
let buf = "";
const started = Date.now();

proc.stdout.on("data", (chunk) => {
  buf += chunk;
  let idx;
  while ((idx = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, idx).trim();
    buf = buf.slice(idx + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch { log.push("??? " + line); continue; }
    log.push("<<< " + JSON.stringify(msg));

    if (msg.id !== undefined && msg.result !== undefined && pending.has(msg.id)) {
      pending.get(msg.id).resolve(msg.result);
      pending.delete(msg.id);
    } else if (msg.method === "session/request_permission") {
      onPermission(msg);
    } else if (msg.method === "session/update") {
      onSessionUpdate(msg.params);
    }
  }
});
proc.stderr.on("data", (d) => log.push("STDERR: " + d));
proc.on("exit", (code) => { log.push("PROC-EXIT " + code); });

function onSessionUpdate(p) {
  if (p?.update?.sessionUpdate === "agent_message_chunk") {
    process.stdout.write(p.update.content.text ?? "");
  }
  if (p?.update?.sessionUpdate === "stop") {
    console.log("\n[agent stopped]");
    console.log("SPIKE-PASS: session completed (phase=" + phase + ")");
    dumpLog();
    finish(0);
  }
}

function onPermission(msg) {
  const optList = msg.params?.options ?? [];
  console.log("\n[PERMISSION REQUEST] " + JSON.stringify({
    title: msg.params?.title,
    options: optList.map((o) => ({ id: o.optionId, kind: o.kind, name: o.name })),
  }, null, 2));
  const wantKind = permAutoAnswer === "allow" ? "allow_once" : "reject_once";
  const chosen = optList.find((o) => o.kind === wantKind) ?? optList.find((o) => o.optionId === (permAutoAnswer === "allow" ? "once" : "reject")) ?? optList[0];
  console.log("[PERMISSION ANSWER] -> " + chosen?.optionId + " (" + (chosen?.name ?? chosen?.kind ?? "?") + ")");
  send({
    jsonrpc: "2.0", id: msg.id,
    result: { outcome: { outcome: "selected", optionId: chosen.optionId } },
  });
}

// ---- 主流程 ----
const init = await request("initialize", {
  protocolVersion: 4,
  clientCapabilities: {
    fs: { readTextFile: true, writeTextFile: true },
  },
  clientInfo: { name: "cc-remote-m0-spike", version: "0.1.0" },
}, "initialize");
console.log("[initialize] protocol=" + init?.protocolVersion + " agent=" + init?.agentInfo?.name + "@" + init?.agentInfo?.version);
if (!init) fail("initialize failed");
notify("initialized");

timers.push(setTimeout(() => fail("TIMEOUT: session/new no response in 60s"), 60000));
const session = await request("session/new", { cwd: WORKDIR, mcpServers: [] }, "session/new");
timers.forEach(clearTimeout); timers.length = 0;

// 生死点①：模型列表（#31076: "No models available"）
// opencode v1.18.26 经 configOptions(category=model) 暴露模型，而非 ACP 规范外字段 models
const models = session?.models ?? [];
const modelCfg = (session?.configOptions ?? []).find((c) => c.category === "model" || c.id === "model");
const modelOptions = modelCfg?.options ?? [];
console.log("[session/new] sessionId=" + (session?.sessionId ?? "?"));
if (models.length) for (const m of models.slice(0, 12)) console.log("  - model " + (m.id ?? m.modelId ?? JSON.stringify(m)).toString().slice(0, 100));
console.log("[configOptions] model currentValue=" + (modelCfg?.currentValue ?? "?") + ", options=" + modelOptions.length);
for (const o of modelOptions.slice(0, 8)) console.log("  - " + o.value);
if (!session?.sessionId) {
  console.log("[session/new] RAW RESPONSE: " + JSON.stringify(session).slice(0, 2000));
  fail("session/new returned no sessionId");
}
if (!models.length && !modelOptions.length) {
  console.log("[session/new] RAW RESPONSE: " + JSON.stringify(session).slice(0, 2000));
  fail("session/new returned NO MODELS (opencode #31076)");
}
console.log("SPIKE-PASS-1: model list OK (models=" + models.length + ", configOptions.models=" + modelOptions.length + ")");

// 生死点②③：跨目录任务触发 external_directory ask
if (phase === "models") { dumpLog(); finish(0); }

if (phase === "perm-deny") permAutoAnswer = "deny";

timers.push(setTimeout(() => {
  console.log("\n[TIMEOUT 180s] no stop; dumping state");
  dumpLog(); finish(2);
}, 180000));

const promptText = "请读取文件 /etc/hostname 的内容并原样告诉我（一行）。不要做别的。";

const promptResp = await request("session/prompt", {
  sessionId: session.sessionId,
  prompt: [{ type: "text", text: promptText }],
}, "session/prompt");
console.log("\n[prompt done] stopReason=" + (promptResp?.stopReason ?? "?"));
console.log("SPIKE-PASS-23: full roundtrip OK (phase=" + phase + ", answer=" + permAutoAnswer + ")");
dumpLog();
finish(0);
