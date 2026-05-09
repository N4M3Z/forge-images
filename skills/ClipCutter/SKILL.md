---
name: ClipCutter
description: Scene-aware MP4 clip cutting from a picks file. ffmpeg scene-change detection identifies the editor's actual cuts; each pick's clip runs from the previous scene boundary to the next. Audio included. USE WHEN you need short MP4 clips around picked timestamps that respect documentary editor cuts (no mid-sentence audio bleeds, no abrupt camera-pan splices).
version: 0.1.0
---

# ClipCutter

One script that turns a picks.tsv into self-contained MP4 clips with audio — without manual scrubbing for in/out points.

## Script

| Script | What it does |
|--------|--------------|
| `cut-clips` | For each pick, find the surrounding scene window (between previous and next scene-change) and cut as MP4. |

## Quick start

```sh
# Assumes you already have picks.tsv from FramePicker.
cut-clips video.mp4 picks.tsv --prefix doc-2024 --output-dir clips/
```

Output: one `.mp4` per pick, named with the same timestamp slug as the still extraction (`doc-2024-01h25m13s.mp4`). Stills and clips are interchangeable in slides.

## How `cut-clips` works

1. **Scene-boundary pass**: runs ffmpeg's scene-change detection across the whole video to capture *all* boundaries (sorted pts_times).
2. **Window selection per pick**: for each picked pts, find `previous_change ≤ pts < next_change`. The scene window IS the clip.
3. **Min/max bounds**: if a scene is shorter than `--min-duration` (default 3s), pad symmetrically around the pick. If longer than `--max-duration` (default 20s), centre on the pick.
4. **ffmpeg cut**: `-ss START -i VIDEO -t DURATION -c:v libx264 -crf 23 -c:a aac -movflags +faststart` produces a small audio-included MP4 with instant playback.

Result: every clip is a self-contained shot. Editor's intent is preserved — no mid-sentence audio bleeds, no abrupt camera-pan cuts.

## Why scene-aware over fixed-window

A fixed `±N seconds` window is simpler but cuts mid-shot if the surrounding scene is short, or includes irrelevant adjacent footage if scenes are long. Documentary editing pacing varies wildly (2s reaction shots, 25s map-zoom monologues). Scene boundaries match what the editor intended — clips become naturally watchable.

## Picks file format

Same as FramePicker output:

```
frame   timestamp   pts_seconds
0001    00:00:03    3.00
0007    00:01:10    70.20
```

A 4th `label` column is ignored by `cut-clips` but consumed by sibling tooling (see CaptureOrganizer).

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--prefix` | required | Slug prefix for output filenames |
| `--output-dir` | required | Output directory |
| `--threshold` | 0.4 | Scene detection threshold (match the FramePicker threshold for consistent boundaries) |
| `--min-duration` | 3.0 | Minimum clip length (seconds) |
| `--max-duration` | 20.0 | Maximum clip length (seconds) |
| `--crf` | 23 | x264 quality. 18=visually lossless, 23=balanced default, 28=small files |

## Disk-space note

A 4K source produces 4K clips by default. Average documentary shot is ~10–12 seconds; a 200-pick set typically lands at 3–4 GB on disk. For projection/screen use 1080p is plenty — pre-scale the source video before cutting if disk is tight, or accept the larger output and downscale only what gets embedded into the deck.

## Companions

- **FramePicker** — produces the picks.tsv this script consumes.
- **CaptureOrganizer** — sorts clips into per-chapter folders post-cut.

## Dependencies

- `ffmpeg` (with libx264) — `brew install ffmpeg`
- `ffprobe` (bundled with ffmpeg) — for source duration probe
- Python 3.9+ — bundled on macOS

No Python packages beyond stdlib.

## Tips

- **Audio matters**: clips include the narrator's voice. If you only want stills, use `extract-frames` from FramePicker instead.
- **Threshold consistency**: use the same `--threshold` value as the picker run. Different thresholds produce different boundary sets, which causes clip windows to shift.
- **Run after picker**: ClipCutter assumes the picks file is final. If you re-pick, re-run.
- **Skip already-cut**: existing output files are skipped on re-runs, so you can rerun safely after adding new picks.
