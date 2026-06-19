---
name: WebCapture
version: 0.1.0
description: Capture web pages and UI animations to PNG/GIF/MP4 — headless via the DevTools protocol (auth, interactive states, virtualized content, clipping) or through the Claude-in-Chrome extension for a real logged-in browser. USE WHEN screenshotting a localhost dashboard or web app, recording a UI walkthrough as a GIF, scripting deterministic captures for docs or demos, capturing a page behind basic auth, grabbing a state that needs a click or JS injection, or building a storyboard of web UI states.
---

# WebCapture

Capture web UI as images, GIFs, or MP4. Two paths:

- **Headless (these scripts)** — drive headless Chrome over the DevTools protocol. Deterministic, no
  extension session, no screen-recording permission, no window focus. Best for scripted captures,
  CI, docs, and demos. **Default to this.**
- **Claude-in-Chrome (MCP tools)** — drive the operator's real Chrome via `mcp__claude-in-chrome__*`.
  Use only when you need a real logged-in session or live exploration (see the section below).

## Headless: stills

```bash
# Basic — render a URL to a file
bin/web-capture http://localhost:8765/ out.png

# Behind basic auth (header, not URL credentials — Grafana, internal tools)
bin/web-capture http://localhost:3000/d/uid/dash?kiosk out.png \
    --auth "Basic $(printf 'USER:PASS' | base64)" --wait 12000

# Reach an interactive state — run JS before the shot (open a modal, reveal a value)
bin/web-capture http://localhost:8765/audit modal.png \
    --eval "document.querySelector('.harness-btn').click()"

# Complex interaction — read the JS from a file (scroll a virtualized list, expand a row)
bin/web-capture http://localhost:3000/explore logs.png --eval @expand-log.js --wait 12000

# Clip a region at normal scale out of a tall page (good for long, virtualized content)
bin/web-capture http://localhost:3000/explore logs.png --size 1500,2600 --clip 300,755,1200,1010
```

| Flag | Default | Description |
|------|---------|-------------|
| `--eval JS\|@file` | none | JS to run before the shot. `@file` reads the expression from a file (avoids shell quoting) |
| `--wait MS` | 6500 | Wait after navigation before the eval/shot. Raise for SPAs (Grafana ~12000) |
| `--auth HEADER` | none | `Authorization` header, injected on every request so frontend fetches also authenticate |
| `--clip x,y,w,h` | none | Capture only this region (full-page coordinates) |
| `--size WxH` | 1500,1000 | Viewport. Use a tall height to fit a long page without scrolling |
| `CHROME_BIN` (env) | macOS path | Override the Chrome executable |

## Headless: GIF / MP4

`web-gif` steps through a frames script (states reached by JS) in one persistent session, then
stitches the frames with ffmpeg. Output is `.gif` or `.mp4` by extension.

```bash
bin/web-gif http://localhost:8765/runs?run=matthew-zhang out.gif --frames frames.mjs --fps 10
```

The frames file is a JS module default-exporting an array of steps:

```js
// frames.mjs — each step runs optional JS, waits, then captures `hold` frames (the pause on that state)
const reveal = "document.querySelectorAll('.ub').forEach(e=>{e.classList.add('revealed');e.textContent=e.dataset.real})";
const blind  = "document.querySelectorAll('.ub').forEach(e=>{e.classList.remove('revealed');e.textContent=e.dataset.token})";
export default [
    { wait: 800, hold: 12 },             // hold the initial state
    { eval: reveal, wait: 500, hold: 16 }, // reach a state via JS, hold longer
    { eval: blind,  wait: 500, hold: 10 }, // back to start — the GIF loops
];
```

`web-gif` takes the same `--auth`, `--size`, and `--wait` flags. `--fps` plus per-step `hold`
controls timing.

## Patterns

- **Auth is a header, never URL credentials.** `http://user:pass@host/` authenticates the document
  but the page's own `fetch()` rejects credentialed URLs (Grafana: "Failed to load dashboard").
  `--auth` sets the header on every request instead.
- **Interactive states via `--eval`.** Click, toggle, or set state; the shot is taken after a settle.
  Use `@file` when the JS has quotes or multiple statements.
- **Virtualized content (Grafana logs, long lists) only renders when scrolled into view, and the
  page often scrolls an inner container, not the window.** Find that container and set its
  `scrollTop`, or render in a tall `--size` and `--clip` the region at normal scale.
- **Probe before guessing selectors.** Dynamic class names (`css-*`) change; query the live DOM in
  one `--eval` that returns markup before writing the click.

## Claude-in-Chrome (real browser)

Use the `mcp__claude-in-chrome__*` tools when the headless path can't reach the page — a real
logged-in session, an authenticated app you can't header-auth, or live interactive exploration.

- **First call `tabs_context_mcp` (`createIfEmpty: true`)** to own a tab group, then
  `tabs_create_mcp` and `navigate`. `computer` takes screenshots; `gif_creator` records.
- **GIF recording:** `gif_creator start_recording` → screenshot (first frame) → drive actions →
  screenshot (last frame) → `gif_creator export {download: true}`.
- **Known caveat — the recorder binds to a tab group the agent "manages."** Long, continued,
  compacted, or resumed sessions lose that ownership, and *every* `start_recording` fails with
  "not in the agent's managed tab group" — even on a freshly created group. There is no fix from
  inside such a session.
- **`computer` `save_to_disk` keeps frames in the extension's store, not a filesystem path.** You
  get the inline image but no reachable file.
- **When either bites, fall back to the headless scripts** — they need no session, no permission,
  and always write a real file.

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| Google Chrome (or Chromium) | Yes | `brew install --cask google-chrome` |
| Node 21+ (built-in `fetch` + `WebSocket`) | Yes | `brew install node` |
| ffmpeg | For `web-gif` | `brew install ffmpeg` |
