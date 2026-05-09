---
name: ImageMatcher
description: Algorithmic reverse image lookup against Wikimedia Commons (or any image source). Perceptual-hash a local image set, harvest candidates from Wikimedia categories, match by Hamming distance, download the originals with their canonical filenames + emit a Markdown catalog snippet with full attribution. USE WHEN you have a local pile of images (documentary frame captures, web screenshots, scanned material) and need to find the original sourced version on Wikimedia Commons without sending the images to any LLM or paid API.
version: 0.1.0
---

# ImageMatcher

Four scripts that turn a folder of mystery images into a catalogued, attributed library — purely algorithmic, no LLM tokens, no paid APIs.

## When to use

You have a local image collection you want to *source* — figure out where each came from, get the canonical version, attach license + attribution. The naive paths (Google reverse image search, paid TinEye API, asking an LLM) are either expensive, throttled, or impossible at scale. ImageMatcher does it locally with perceptual hashing.

Typical flow:

1. **`phash-images`** — perceptual-hash every image in a directory (TSV).
2. **`wikimedia-fetch`** — pull candidates from one or more Wikimedia categories, hash their thumbnails (TSV).
3. **`match-hashes`** — compare the two hash sets by Hamming distance (TSV of `local_file → remote_file → distance`).
4. **`download-matches`** — for each match below threshold, download the Wikimedia original at full resolution with its canonical filename, and emit a Markdown catalog snippet with full attribution.

Output is a sourcing catalog ready to paste into an Obsidian vault note.

## Quick start

```sh
# 1. Hash local captures (.jpg/.png/.webp etc)
phash-images /path/to/captures --output captures.tsv

# 2. Pull + hash candidates from relevant Wikimedia categories
wikimedia-fetch \
    --category "Second Boer War" \
    --category "Concentration camps in the Second Boer War" \
    --output wiki-boer.tsv \
    --limit 200

# 3. Match — Hamming distance ≤ 18 by default
match-hashes captures.tsv wiki-boer.tsv \
    --output matches.tsv \
    --max-distance 18 \
    --top-k 1

# 4. Download originals + emit catalog snippet
download-matches matches.tsv \
    --output-dir /path/to/Assets/Photographs \
    --catalog-snippet boer-snippet.md \
    --source-label "RTH match" \
    --max-distance 18
```

The snippet is ready to append to a Photographs-catalog-style markdown note. Each entry has `![[<filename>]]` embed, source URL, year, license, the original Wikimedia filename, and a "discovery capture" provenance line.

## How perceptual hashing works

Each image gets a 64-bit hash derived from its low-frequency structure (pHash) plus a difference-based hash (dHash). The hashes are robust to:

- Resizing (any aspect ratio preserved)
- Compression / re-encoding
- Slight cropping
- Color palette shifts
- Watermarks (modest)

Hamming distance between two hashes:
- **0–10**: same image
- **11–18**: same scene, possibly cropped or recolored
- **19–25**: similar subject
- **26+**: different image

`match-hashes` weighs pHash 2× heavier than dHash for the combined sort score.

## How Wikimedia harvesting works

`wikimedia-fetch` queries Commons via the MediaWiki API:

1. `categorymembers` — list files in each `--category`
2. `imageinfo` — resolve thumbnail URLs (default 480px wide)
3. Download each thumbnail, perceptual-hash it, write to TSV

Rate-limit handling: exponential backoff on HTTP 429/503 with `Retry-After` honored. Honest user-agent string. Respects MediaWiki's etiquette (~0.6s between paginated calls).

Limit `--limit N` per category caps pull size. 100–300 is a good range — bigger pulls give better recall but cost more API time.

## How `download-matches` works

For each row in matches.tsv (filtered by `--max-distance`):

1. Resolve full-resolution URL via Wikimedia `imageinfo` API
2. Download bytes to `<output-dir>/<original-wikimedia-filename>`
3. Pull metadata (artist, year, license, credit) from extmetadata
4. Append a Markdown catalog block with `![[…]]` embed, attribution, and discovery provenance

Skips already-downloaded files (idempotent). Confidence labelled in the catalog block: `same image` for d≤10, `relevant` for d>10.

## Picks file format

The output of `match-hashes` (and input to `download-matches`):

```
capture_filename	phash_distance	dhash_distance	remote_filename	category	page_url	thumb_url
rth-2025-09-00h07m24s.jpg	10	14	COLLECTIE TROPENMUSEUM Boerenguerrilla's poseren ... .jpg	Second Boer War	https://commons.wikimedia.org/wiki/...	https://upload.wikimedia.org/...
```

## Options

### `phash-images`

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | required | Output TSV path |
| `--recursive` | off | Recurse into subdirectories |

Supported file types: `.jpg .jpeg .png .webp .gif .tiff .bmp`.

### `wikimedia-fetch`

| Flag | Default | Description |
|------|---------|-------------|
| `--category` | required (repeat) | Wikimedia category (without `Category:` prefix). Repeat for multiple. |
| `--output` | required | Output TSV path |
| `--limit` | 300 | Max files per category |
| `--filetypes` | `.jpg,.jpeg,.png` | Comma-separated extensions to include |

### `match-hashes`

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | required | Output TSV |
| `--max-distance` | 14 | Reject matches with phash Hamming > N |
| `--top-k` | 1 | Keep top K matches per capture |

### `download-matches`

| Flag | Default | Description |
|------|---------|-------------|
| `--output-dir` | required | Where to save downloaded originals |
| `--catalog-snippet` | none | Optional Markdown snippet output path |
| `--max-distance` | 20 | Skip matches with distance > N |
| `--source-label` | "RTH documentary" | Free-form label for catalog entry's "match source" |

## Companions

- **FramePicker** — produces capture sets (from documentary screen-grabs) that ImageMatcher can match against Wikimedia.
- **CatalogEmbeds** — post-processes the catalog Markdown produced by `download-matches`, ensuring inline `![[…|600]]` previews on every entry.

## Dependencies

```sh
brew install ffmpeg            # for thumbnail-decoder side of imagehash
uv pip install imagehash Pillow requests
```

Set up a venv inside the project:

```sh
uv venv .venv
uv pip install --python .venv/bin/python imagehash Pillow requests
```

The scripts use only stdlib + those three packages.

## Tips

- **Threshold tuning**: start at 18, examine results, lower to 14 if false positives are common, raise to 22 if you want to capture similar (not identical) scenes.
- **Multiple categories** widen recall — for "Second Boer War" alone Commons might miss material that lives under "Concentration camps in the Second Boer War" or "Battles of the Second Boer War".
- **Recurse subcategories** is not yet supported — Commons has deep category trees; for now list specific subcategories explicitly.
- **Long-filename Rijksmuseum entries**: API uses POST so URL-length isn't an issue, but the filenames themselves stay long; that's the canonical reference.
- **Workflow integration**: pair with FramePicker → CaptureOrganizer → ImageMatcher for a full pipeline from documentary video to attribution-clean Wikimedia-sourced collection.

## Why this beats alternatives

| Alternative | Issue |
|-------------|-------|
| Google reverse image search | Manual, one image at a time, no API for free |
| TinEye API | Paid, rate-limited, results often miss Wikimedia |
| Asking an LLM (vision model) | Expensive in tokens, hallucinates filenames, can't return URLs |
| Manual lookup | Slow, error-prone for hundreds of images |

ImageMatcher: zero API cost, zero LLM tokens, processes hundreds of images in minutes, hits canonical Wikimedia attribution directly.
