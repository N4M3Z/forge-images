#!/usr/bin/env node
// Render a web page to PNG over the Chrome DevTools Protocol. Drives an already-running headless
// Chrome (started by the `web-capture` wrapper) so it can authenticate via a header, run JS to
// reach interactive states (clicks, reveals), and clip a region. No dependencies: Node's built-in
// fetch + WebSocket (Node 21+).
//
// Usage: web-capture.mjs <port> <url> <out.png> [evalJS|@file|-] [waitMs] [authHeader|-] [x,y,w,h|-]
import fs from "node:fs";

const [port, url, out, evalJS, waitMs, auth, clipArg] = process.argv.slice(2);

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
    // Auth via a header (not URL credentials) so the page's own frontend fetches still work.
    await send("Network.enable");
    await send("Network.setExtraHTTPHeaders", { headers: { Authorization: auth } });
}

await send("Page.navigate", { url });
await wait(Number(waitMs) || 6500); // let the page (and any async fragments) load

let expr = evalJS;
if (expr && expr.startsWith("@")) expr = fs.readFileSync(expr.slice(1), "utf8");
if (expr && expr !== "-") {
    await send("Runtime.evaluate", { expression: expr });
    await wait(4000); // let a triggered fragment / scroll / row expansion render
}

let shotParams = { format: "png" };
if (clipArg && clipArg !== "-") {
    const [x, y, width, height] = clipArg.split(",").map(Number);
    shotParams = {
        format: "png",
        captureBeyondViewport: true,
        clip: { x, y, width, height, scale: 1 },
    };
}
const { data } = await send("Page.captureScreenshot", shotParams);
fs.writeFileSync(out, Buffer.from(data, "base64"));
ws.close();
console.log("wrote", out);
process.exit(0);
