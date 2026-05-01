---
name: FramePicker
description: Interactive HTML frame picker for documentary videos + native-resolution still extraction. ffmpeg scene-change detection finds every visual cut, the picker page lays out 4×N thumbnails with SRT context, you select by checkbox and clipboard-export to a picks.tsv. USE WHEN harvesting period photographs / archive stills / map frames from YouTube documentaries or talking-head videos for slide-deck imagery.
---

# FramePicker

Two scripts that turn a video + subtitle file into a visually-reviewed pick list and full-resolution stills.

## Scripts

| Script | What it does |
|--------|--------------|
| `pick-frames` | ffmpeg scene-detection → HTML picker grid. Each thumbnail labelled with timestamp + nearby SRT dialogue. Browse offline, click checkboxes, copy picks to clipboard. |
| `extract-frames` | Read tab-separated picks file (output of the picker), extract one full-resolution still per pick. |

## Quick start

```sh
# 1. Pull video + auto-subs
yt-dlp --write-auto-sub --sub-lang en --sub-format srt --convert-subs srt \
    -f "bestvideo[height<=2160][ext=mp4]+bestaudio/best" \
    "https://www.youtube.com/watch?v=VIDEO_ID"

# 2. Build the picker
pick-frames video.mp4 video.en.srt --output-dir contact-sheet

# 3. Open contact-sheet/index.html, browse, click checkboxes, copy picks to clipboard,
#    paste into picks.tsv

# 4. Extract stills at full resolution (4K JPEG if source is 4K)
extract-frames video.mp4 picks.tsv --prefix doc-2024 --output-dir stills/
```

Output stills use timestamp slugs (`doc-2024-01h25m13s.jpg`) so they sort chronologically and stay traceable to the source moment.

## How `pick-frames` works

1. **Scene-change detection**: `ffmpeg -vf select=gt(scene,THRESHOLD),showinfo` extracts one frame per visual cut and prints `pts_time` for each.
2. **SRT context match**: for each frame's timestamp, gather SRT lines within ±8s.
3. **HTML grid**: responsive 4×N layout, lazy-loaded 480px thumbnails, search filter (by topic word or timestamp prefix), checkbox selection, one-click clipboard export.

The HTML page is fully offline — open with `file://` URL, no server needed.

Threshold 0.4 is a good default. Drop to 0.3 for rapid montage, raise to 0.5–0.6 for static talking-head footage.

## How `extract-frames` works

For each pick, runs `ffmpeg -ss PTS -i VIDEO -frames:v 1 -q:v 2`. Output is JPEG at native source resolution. Single-pass fast seek; the pts is precise enough that the same frame the user picked from the thumbnail is the same frame extracted at full size.

## Picks file format

Tab-separated, header row optional. The picker exports this format directly to clipboard:

```
frame   timestamp   pts_seconds
0001    00:00:03    3.00
0007    00:01:10    70.20
```

Save to your project (e.g. `picks-2024-07-doc.tsv`). Re-running extraction with new options is a one-liner.

## Options

### `pick-frames`

| Flag | Default | Description |
|------|---------|-------------|
| `--output-dir` | required | Where `frames/` and `index.html` are written |
| `--threshold` | 0.4 | Scene detection sensitivity (0.0–1.0) |

### `extract-frames`

| Flag | Default | Description |
|------|---------|-------------|
| `--prefix` | required | Slug prefix for output filenames |
| `--output-dir` | required | Output directory |
| `--quality` | 2 | JPEG quality (1=highest, 31=lowest) |

## Why this beats SRT-based guessing

The SRT only tells you what's *said*, not what's *shown*. The two desync constantly. Asking the speaker to manually scrub 50+ frames per video is tedious. This skill replaces both:

- **Visual review by the human eye** — your eyes scan a 4×N grid faster than any LLM analyses frames.
- **Algorithmic scene cuts** — ffmpeg knows where the editor cut. No guessing.
- **Persistent picks files** — re-run extraction with new options without redoing the picker session.

## Companions

The output picks file is the input format for two sibling skills:

- **ClipCutter** — cut scene-aware MP4 clips around each pick (with audio).
- **CaptureOrganizer** — auto-label picks from SRT context + sort capture files by chapter.

## Dependencies

- `ffmpeg` (with libx264) — `brew install ffmpeg`
- Python 3.9+ — bundled on macOS
- `yt-dlp` (optional, for source pulls) — `brew install yt-dlp`

No Python packages beyond stdlib.

## Tips

- **Captures don't belong in the vault** — multi-GB media files trigger Obsidian Sync. Store under `~/Data/Captures/<project>/`; embed thumbnails into the deck only when finalised.
- **Naming**: prefix files by source (`rth-2024-07`, `bbc-1964-ep03`). Keeps multiple sources clean in one directory.
- **Long videos**: scene detection on a 4K 3-hour video takes ~5 min. Run in background.
- **Picks don't need to be exhaustive** — review hundreds of thumbnails in minutes, refine later. The picks file is cheap to edit.
