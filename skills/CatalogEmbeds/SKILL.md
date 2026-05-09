---
name: CatalogEmbeds
description: 'Insert inline `![[file|600]]` image previews under every `## Title` entry in a Markdown catalog that follows the `**Local file**: \`Assets/<dir>/<filename>\`` convention. Idempotent and self-healing — wrong embeds (where Local file is "not downloaded" or missing) are removed automatically. USE WHEN turning a text-only asset catalog into a visually-scannable mood-board for slide construction.'
version: 0.1.0
---

# CatalogEmbeds

One script that adds inline image previews to a catalog markdown, turning it from a filename-list into a visual mood-board for slide construction.

## When to use

You have a Markdown catalog of assets — one entry per asset, structured as:

```markdown
## <Title>

- **Source**: ...
- **URL**: ...
- **License**: ...
- **Local file**: `Assets/Photographs/<filename>.jpg`

<paragraph context>
```

…and you want every entry to have a `![[<filename>|600]]` preview line right below the heading so the catalog renders as a scrollable visual index in Obsidian. Hand-editing 200 entries is tedious; this script does it in one shot.

## Quick start

```sh
add-catalog-embeds "Photographs catalog.md" "Maps catalog.md"
```

Output:

```
✓ Photographs catalog.md: inserted 178, fixed 4, removed 14
✓ Maps catalog.md: inserted 41, fixed 0, removed 1
```

- **inserted** — entries that didn't have an embed before
- **fixed** — entries with an embed that had wrong filename or wrong width spec
- **removed** — entries with `**Local file**: not downloaded` (or no Asset path) that wrongly had an embed

The script is **idempotent and self-healing** — re-run safely after manual edits.

## How it works

1. Splits the file into entries, where each entry runs from a `## ` heading to the next `## ` (or EOF).
2. Within each entry block, looks for `**Local file**: \`Assets/<dir>/<filename>\`` to extract the canonical filename.
3. Looks at the first 6 lines after the heading for an existing `![[…]]` embed.
4. Decides:
   - Filename present + no embed → insert `![[<filename>|600]]`
   - Filename present + embed with wrong filename or wrong width → replace
   - Filename absent + embed present → remove (the embed is stale)
   - Filename absent + no embed → leave alone

Bounded scan: never bleeds into the next entry's content (early version of this script had that bug).

## Catalog convention assumed

The script expects this structure for each entry:

```markdown
## <Subject — short title>

(optional ![[<filename>|600]] preview — script inserts here)

- **Source**: <institution>
- **URL**: <descriptionurl>
- **Year**: <date>
- **License**: <PD / CC-BY-SA>
- **Local file**: `Assets/Photographs/<filename>`

<paragraph context>
```

Fields other than `**Local file**` are not parsed. The Local file field is the only signal — its presence and form decide insert/fix/remove.

## Why `|600` width

`![[file|600]]` is Obsidian's wikilink syntax for "embed this file at 600px wide, preserving aspect ratio." Result:

- Wide panoramas cap at 600px wide
- Tall portraits stay tall (no awkward cropping)
- Catalog scrolls at consistent visual cadence — your eye scans rows of similar widths

If you want a different width, edit the literal `|600` in the script. There's no flag yet (PR welcome).

## Options

| Flag | Default | Description |
|------|---------|-------------|
| (positional) | required | Path(s) to catalog Markdown file(s) |

Multi-file: pass multiple paths to process several catalogs in one invocation.

## Companions

- **ImageMatcher**'s `download-matches` produces a catalog snippet that already includes embed lines — running CatalogEmbeds on the merged catalog will be a no-op for those, normalising any older entries that lack embeds.

## Dependencies

Python 3.9+ stdlib only. No external packages.

## Tips

- **Run after appending new entries**: every time you add an entry by hand or via `download-matches`, run the script to normalise embeds.
- **Section headings vs entry headings**: top-level dividers like `## Catalog` or `## Sarajevo and July 1914` don't have a `**Local file**` field, so they're skipped naturally — no need to pre-filter.
- **Re-running is safe**: idempotent. The script is the source-of-truth for catalog visual format; manual `![[…]]` edits will be normalised to `|600`.
- **Custom width**: if you want different display sizes for different catalogs, run the script then sed-rewrite `|600` → `|400` (etc.) per catalog.
