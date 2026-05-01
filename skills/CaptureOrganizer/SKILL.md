---
name: CaptureOrganizer
description: Post-process FramePicker / ClipCutter outputs. Auto-derive content labels from SRT context (writes a 4th label column to picks.tsv) and move stills/clips into per-chapter section folders based on a sections.tsv. USE WHEN naming captures by topic or sorting hundreds of files into editor-friendly directory structure (Boer War / Russo-Japanese / etc.).
---

# CaptureOrganizer

Two scripts that label and shelve captures after the picking and cutting are done.

## Scripts

| Script | What it does |
|--------|--------------|
| `label-picks` | Auto-derive kebab-case content slugs from SRT context. Writes augmented picks file with a 4th `label` column. |
| `section-files` | Move/copy capture files into chronologically-numbered per-section folders based on a sections TSV. |

## Quick start

```sh
# Auto-label picks (review the output and hand-fix; auto-CC is imperfect)
label-picks picks.tsv video.en.srt --output picks.labelled.tsv

# Move stills into per-section folders
section-files stills/ sections.tsv \
    --prefix-filter doc-2024 \
    --output-dir captures-by-section/

# Move clips alongside, into the same section folders
section-files clips/ sections.tsv \
    --prefix-filter doc-2024 \
    --output-dir captures-by-section/
```

## How `label-picks` works

1. Reads picks file + SRT.
2. For each pick's pts, gathers SRT lines within ±8s.
3. Scores tokens — numbers (3 pts), capitalised proper-noun candidates (2 pts), long content words (1 pt). Stop-words removed.
4. Selects up to 6 highest-scoring tokens, preserving original order.
5. Slugifies: lowercase, kebab-case, max 60 chars.
6. Writes `<picks>.labelled.tsv` with a 4th `label` column.

**Quality is uneven on YouTube auto-captioning**: proper nouns get mangled (Hobhouse → "hobouss"; Mukden → "mukten"). Treat output as a starting point — review the labelled TSV and hand-fix the picks you actually want to use.

## How `section-files` works

Sections TSV format (tab-separated, header optional):

```
start       end         slug
00:00:00    00:30:00    boer-war
00:30:00    01:00:00    russo-japanese
01:00:00    01:08:00    bosnia-crisis-1908
```

Each section becomes a numbered subfolder under `--output-dir` (`01-boer-war/`, `02-russo-japanese/`, etc.). The script:

1. Lists files in the source directory.
2. For each filename matching `--prefix-filter`, parses the timestamp from the slug pattern `-NNhMNNmSSs`.
3. Maps timestamp → section (first matching section wins, so sections must be in chronological order).
4. Moves (or copies with `--copy`) the file into the corresponding section folder.

Files outside any section are listed under "unmatched" — most often `01-intro` and `NN-outro` ranges.

After running on both stills/ and clips/, each section folder contains both `.jpg` and `.mp4` files for the same picks. Add `stills/` and `clips/` subfolders manually if you want the file types separated.

## Picks file format (label column)

```
frame   timestamp   pts_seconds   label
0001    00:00:03    3.00          europe-powers-global-empires-armies
0007    00:01:10    70.20         overseas-empire-bluewater-germany
```

Label column is optional; absent means the script ran on the un-augmented picks file.

## Sections file format

```
start       end         slug
00:00:00    00:03:00    intro
00:03:00    00:30:00    boer-war
00:30:00    01:00:00    russo-japanese
```

Section boundaries should be in chronological order. The first matching section claims a file; gaps are unmatched. Slugs become folder names verbatim, prefixed by 2-digit ordinal (`01-intro/`, `02-boer-war/`).

## Options

### `label-picks`

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | `<picks>.labelled.tsv` | Augmented picks file |
| `--window` | 8.0 | SRT lookup window (seconds around the pick) |
| `--max-tokens` | 6 | Maximum words per label slug |

### `section-files`

| Flag | Default | Description |
|------|---------|-------------|
| `--output-dir` | required | Destination root (one numbered folder per section) |
| `--prefix-filter` | none | Only operate on files starting with this prefix |
| `--copy` | off | Copy instead of move |
| `--dry-run` | off | Show plan, take no action |

## Companions

- **FramePicker** produces the picks.tsv that `label-picks` consumes.
- **ClipCutter** produces the clips that `section-files` shelves alongside stills.

## Dependencies

- Python 3.9+ — bundled on macOS

No external CLI tools, no Python packages beyond stdlib.

## Tips

- **Sections file is project-specific**: build it once per documentary, persist alongside the picks file in version control. Reuse for re-runs after adding picks.
- **Hand-fix labels in the TSV** — text editor, sort by topic, fix the 30 you actually use, ignore the noise.
- **Filename-based timestamp parsing** is what makes `section-files` work — it expects the `-NNhMMmSSs` slug pattern that FramePicker / ClipCutter both produce. Custom-named files won't match.
- **Multi-source organising**: run `section-files` once per source-prefix per output type. The destination directory accumulates into one combined section structure.
