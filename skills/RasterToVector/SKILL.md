---
name: RasterToVector
description: Multi-color bitmap-to-SVG conversion via ImageMagick + potrace, with optional AI upscaling. USE WHEN converting raster images (GIF, PNG, JPEG) to scalable vector SVG format.
---

# RasterToVector

Convert raster images to multi-color SVG using color separation and vector tracing.

## Usage

```bash
# Basic conversion
bash bin/raster-to-svg.sh input.gif output.svg

# AI-upscaled circular logo (best quality)
bash bin/raster-to-svg.sh logo.gif logo.svg --ai-upscale 2 --circle --colors 5

# Quick Lanczos upscale (no AI dependency)
bash bin/raster-to-svg.sh icon.png icon.svg --scale 16 --colors 4
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--scale N` | 8 | Lanczos upscale factor (ignored when `--ai-upscale` is set) |
| `--ai-upscale N` | 0 | Number of Real-ESRGAN 4x passes (1=4x, 2=16x). See INSTALL.md |
| `--colors N` | 6 | Color quantization target — determines SVG layer count |
| `--circle` | off | Apply circular `<clipPath>` — cleans up round logos/badges |
| `--fuzz N` | 20 | Color match tolerance (%) for mask extraction |
| `--turdsize N` | 10 | Ignore traced speckles smaller than N pixels |

## Algorithm

```
Source image
    │
    ▼
1. Upscale (Lanczos or Real-ESRGAN AI)
    │
    ▼
2. Circle mask (optional — enforces perfect circular boundary)
    │
    ▼
3. Color quantization (ImageMagick -colors N)
    │   Histogram → sort by pixel count → extract dominant RGB values
    │
    ▼
4. Per-color mask extraction + potrace tracing
    │   For each color:
    │     magick -fuzz N% -opaque rgb(R,G,B) → binary mask
    │     mask → PBM → potrace → SVG paths
    │
    ▼
5. Layer combination
    │   Stack SVG <g> groups (bottom=largest area, top=smallest)
    │   Each group: fill="hex" + potrace transform
    │   Optional: wrap in <clipPath> circle
    │
    ▼
Output SVG (multi-layer, true vector)
```

## Tips

- **Low-res sources** (under 200px): Use `--ai-upscale 2` for two 4x passes (16x total). AI upscaling reconstructs edges and text that Lanczos can't.
- **Color count**: Start with `--colors 5` for logos. Increase for photographs. Each color becomes one SVG layer.
- **Fuzz tolerance**: Lower values (10-15%) give tighter color boundaries but may split similar colors. Higher values (25-30%) merge similar tones.
- **Circular logos**: Always use `--circle` — it removes anti-aliasing artifacts outside the circle boundary.

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| ImageMagick 7 (`magick`) | Yes | `brew install imagemagick` |
| potrace | Yes | `brew install potrace` |
| realesrgan-ncnn-vulkan | For `--ai-upscale` | See INSTALL.md |
