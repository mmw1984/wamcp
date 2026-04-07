import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";

import { Poke } from "poke";

function nowIso() {
  return new Date().toISOString();
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function safeJsonRead(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function safeJsonWrite(file, obj) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(obj, null, 2));
}

function hashText(s) {
  return crypto.createHash("sha256").update(s).digest("hex").slice(0, 12);
}

function normalizePhone(sender) {
  if (!sender) return "";
  return String(sender).replace(/[^0-9]/g, "");
}

function formatDmMessage(m) {
  // m fields: id, chat_jid, chat_name, sender, content, timestamp, is_from_me, media_type
  const from = normalizePhone(m.sender) || m.sender || "unknown";
  const to = "me";
  const content = (m.content ?? "").toString();
  return `received a message from whatsapp from ${from} to ${to}\n> ${content}`;
}

function formatGroupMessage(m) {
  const group = m.chat_name || m.chat_jid;
  const from = normalizePhone(m.sender) || m.sender || "unknown";
  const content = (m.content ?? "").toString();
  return `received a group message in ${group} from ${from}\n> ${content}`;
}

function listMessagesViaPython({ rootDir, afterIso }) {
  const py = `
import json
import main
after = ${afterIso ? "json.loads(" + JSON.stringify(JSON.stringify(afterIso)) + ")" : "None"}
msgs = main.list_messages(after, None, None, None, 200, 0)
print(json.dumps(msgs, ensure_ascii=False))
`;
  const out = execFileSync(
    "uv",
    ["run", "--directory", path.join(rootDir, "whatsapp-mcp-server"), "python", "-c", py],
    { encoding: "utf8", env: process.env }
  );
  return JSON.parse(out);
}

function shouldNotify({ msg, mode, myPhone }) {
  const chatJid = msg.chat_jid || "";
  const isGroup = chatJid.endsWith("@g.us");
  const isFromMe = Boolean(msg.is_from_me);

  if (isFromMe) return false;

  if (!isGroup) {
    return mode.dm === true;
  }

  if (mode.group === "all") return true;

  // group tag only:
  // Prefer true mention metadata if present (not currently stored in DB), fallback to text contains
  const text = (msg.content ?? "").toString();
  if (!myPhone) return false;
  const candidates = [
    `@${myPhone}`,
    myPhone,
  ];
  return candidates.some((c) => text.includes(c));
}

async function main() {
  const configPath = process.env.WAMCP_POKE_CONFIG;
  const statePath = process.env.WAMCP_POKE_STATE;
  const rootDir = process.env.WAMCP_ROOT;
  if (!configPath || !statePath) {
    console.error("[wamcp-poke] missing WAMCP_POKE_CONFIG or WAMCP_POKE_STATE");
    process.exit(2);
  }
  if (!rootDir) {
    console.error("[wamcp-poke] missing WAMCP_ROOT");
    process.exit(2);
  }

  const cfg = safeJsonRead(configPath, null);
  if (!cfg) {
    console.error(`[wamcp-poke] config not found: ${configPath}`);
    process.exit(2);
  }

  const intervalMs = cfg.interval_ms ?? 30000;
  const mode = cfg.mode ?? { dm: true, group: "tag" };
  const myPhone = cfg.my_phone ?? "";
  const chatFilter = cfg.chat_filter ?? null; // optional allowlist

  const poke = new Poke(); // resolves credentials from env or poke login

  let st = safeJsonRead(statePath, { seen: {}, last_run_at: null, last_after: null });

  console.log(`[wamcp-poke] started at ${nowIso()} interval_ms=${intervalMs}`);

  while (true) {
    st.last_run_at = nowIso();
    safeJsonWrite(statePath, st);

    try {
      const afterIso = st.last_after;
      const batch = listMessagesViaPython({ rootDir, afterIso });

      // advance watermark to now: only notify on messages arriving after this tick
      st.last_after = nowIso();
      safeJsonWrite(statePath, st);

      for (const msg of batch) {
        const id = msg.id || `${msg.chat_jid}|${msg.timestamp}|${msg.sender}|${hashText(String(msg.content || ""))}`;
        if (st.seen[id]) continue;
        st.seen[id] = true;

        if (chatFilter && Array.isArray(chatFilter) && !chatFilter.includes(msg.chat_jid)) {
          continue;
        }

        if (!shouldNotify({ msg, mode, myPhone })) continue;

        const isGroup = (msg.chat_jid || "").endsWith("@g.us");
        const text = isGroup ? formatGroupMessage(msg) : formatDmMessage(msg);

        try {
          await poke.sendMessage(text);
          console.log(`[wamcp-poke] sent to poke (${isGroup ? "group" : "dm"}) id=${id}`);
        } catch (e) {
          console.error(`[wamcp-poke] failed to send to poke id=${id}: ${e?.message || e}`);
        }

        // keep seen map bounded
        const keys = Object.keys(st.seen);
        if (keys.length > 5000) {
          for (const k of keys.slice(0, keys.length - 3000)) delete st.seen[k];
        }
        safeJsonWrite(statePath, st);
      }
    } catch (e) {
      console.error(`[wamcp-poke] poll error: ${e?.message || e}`);
    }

    await sleep(intervalMs);
  }
}

main().catch((e) => {
  console.error(`[wamcp-poke] fatal: ${e?.stack || e}`);
  process.exit(1);
});

