#!/usr/bin/env node
// 测试：在活着的 opencode acp 进程上调 session/new（模拟补丁⑥ NewAgentSession），验证 TUI attach 不断线
import { spawn } from "node:child_process";

const BIN = "/home/zzy/AgentRoot/cc-remote/spike/bin/opencode";
const WD = "/home/zzy/AgentRoot/cc-remote";
const PORT = "14097";

const proc = spawn(BIN, ["acp", "--port", PORT, "--hostname", "127.0.0.1"], {
  cwd: WD,
  stdio: ["pipe", "pipe", "pipe"],
  env: { ...process.env, XDG_DATA_HOME: "/tmp/oc-test-data", XDG_CONFIG_HOME: "/tmp/oc-test-config", HOME: "/tmp/oc-test-home" },
});

let nextId = 1;
const pending = new Map();
let buf = "";

function send(obj) { proc.stdin.write(JSON.stringify(obj) + "\n"); }
function request(method, params) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    send({ jsonrpc: "2.0", id, method, params });
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); reject(new Error("timeout " + method)); } }, 20000);
  });
}

proc.stdout.setEncoding("utf8");
proc.stdout.on("data", (chunk) => {
  buf += chunk;
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim(); buf = buf.slice(i + 1);
    if (!line) continue;
    let msg; try { msg = JSON.parse(line); } catch { continue; }
    if (msg.id !== undefined && pending.has(msg.id)) {
      const p = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? p.reject(new Error(JSON.stringify(msg.error))) : p.resolve(msg.result);
    }
  }
});
proc.stderr.on("data", () => {});
proc.on("exit", (c) => { console.log("ACP-PROC-EXIT " + c); process.exit(1); });

// 等 server 端口就绪
async function waitPort() {
  for (let i = 0; i < 30; i++) {
    try {
      const r = await fetch("http://127.0.0.1:" + PORT + "/doc", { headers: { Authorization: "Basic " + Buffer.from("opencode:cc-remote-2026-local").toString("base64") } });
      if (r.status === 200 || r.status === 404 || r.status === 401) return true;
    } catch { }
    await new Promise(r => setTimeout(r, 500));
  }
  return false;
}

const phase = process.argv[2] || "new";
const init = await request("initialize", { protocolVersion: 4, clientCapabilities: { fs: { readTextFile: true, writeTextFile: true } }, clientInfo: { name: "patch6-test", version: "0" } });
console.log("init ok:", init?.agentInfo?.name);
send({ jsonrpc: "2.0", method: "initialized" });
const s1 = await request("session/new", { cwd: WD, mcpServers: [] });
console.log("session#1:", s1?.sessionId);
if (!(await waitPort())) { console.log("PORT-NOT-READY"); process.exit(1); }
console.log("embedded server ready on :" + PORT);

if (phase === "new") {
  // 模拟 /new：同一进程再调 session/new（补丁⑥行为）
  const s2 = await request("session/new", { cwd: WD, mcpServers: [] });
  console.log("session#2 (in-place restart):", s2?.sessionId);
  console.log("SAME-PROCESS-OK");
}
// 保持进程 90s 供外部观察 attach 存活
setTimeout(() => { console.log("DONE"); proc.kill(); process.exit(0); }, 90000);
