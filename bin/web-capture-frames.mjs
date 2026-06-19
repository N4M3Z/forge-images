#!/usr/bin/env node
// Capture an animation in one persistent CDP session: step through frames (run JS, wait, shoot),
// writing numbered PNGs to a directory. The `web-gif` wrapper stitches them with ffmpeg. The frames
// file is a JS module default-exporting an array of steps: { eval?: "JS", wait?: ms, hold?: frames }.
// Usage: web-capture-frames.mjs <port> <url> <outDir> <framesFile> [waitMs] [authHeader|-]
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const [port, url, outDir, framesFile, waitMs, auth] = process.argv.slice(2);

const target = await (
    await fetch(`http://localhost:${port}/json/new?about:blank`, { method: "PUT" })
).json();
const ws = new WebSocket(target.webSocketDebuggerUrl);
let id = 0;
const pending = new Map();
const send = (method, params = {}) =>
    new Promise((resolve) => {
        const i = ++id;
        pending.set(i, resolve);
        ws.send(JSON.stringify({ id: i, method, params }));
    });
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
await new Promise((r) => (ws.onopen = r));
ws.onmessage = (message) => {
    const data = JSON.parse(message.data);
    if (data.id && pending.has(data.id)) {
        pending.get(data.id)(data.result);
        pending.delete(data.id);
    }
};

await send("Page.enable");
await send("Runtime.enable");
if (auth && auth !== "-") {
    await send("Network.enable");
    await send("Network.setExtraHTTPHeaders", { headers: { Authorization: auth } });
}
await send("Page.navigate", { url });
await wait(Number(waitMs) || 6500);

const frames = (await import(pathToFileURL(path.resolve(framesFile)).href)).default;
fs.mkdirSync(outDir, { recursive: true });
let n = 0;
for (const frame of frames) {
    if (frame.eval) await send("Runtime.evaluate", { expression: frame.eval });
    await wait(frame.wait ?? 500);
    const { data } = await send("Page.captureScreenshot", { format: "png" });
    const buffer = Buffer.from(data, "base64");
    const hold = Math.max(1, frame.hold ?? 6); // duplicate frames pause the GIF on this state
    for (let h = 0; h < hold; h++) {
        fs.writeFileSync(path.join(outDir, String(n++).padStart(4, "0") + ".png"), buffer);
    }
}
ws.close();
console.log("captured", n, "frames");
process.exit(0);
