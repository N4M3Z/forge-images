---
name: RasterToVector
version: 0.1.0
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

## Hybrid Approach (Best Quality)

The automated script produces a good starting point, but logos with ideal geometry (perfect circles, parallel lines, elliptical orbits) benefit from a **hybrid** post-processing step:

1. **Run the script** to get traced paths with correct proportions and colors
2. **Replace geometric elements** with clean SVG primitives:
   - Background circles → `<circle>` elements (no wobble)
   - Orbital rings → `<ellipse>` with `transform="rotate()"`
   - Clip boundaries → `<clipPath>` with `<circle>`
3. **Keep traced paths** for complex shapes (text, crescents, irregular forms)
4. **Tune potrace smoothing** for remaining traced layers:
   - `--alphamax 1.334` — maximum curve smoothing
   - `--opttolerance 0.5` — more tolerance for curve fitting
   - `--turdsize 25` — ignore larger speckles

### Hybrid SVG structure

```xml
<svg viewBox="0 0 1472 1472">
  <defs>
    <clipPath id="badge"><circle cx="736" cy="736" r="680"/></clipPath>
  </defs>
  <!-- Clean geometric background -->
  <circle cx="736" cy="736" r="725" fill="#0857E4"/>
  <circle cx="736" cy="736" r="680" fill="#06376A"/>
  <!-- Smooth traced detail layers (clipped) -->
  <g clip-path="url(#badge)">
    <g fill="#color" transform="translate(0,1472) scale(0.1,-0.1)">
      <!-- potrace paths here -->
    </g>
  </g>
</svg>
```

### Color count guidance

| Colors | Use case |
|--------|----------|
| 5-6 | Simple logos, badges |
| 7-8 | Logos with gradients, borders, or ring structures |
| 10+ | Photographs, complex illustrations |

When a color band is missing (e.g., a grey ring border), increase `--colors` by 1-2 and retrace. Check with `magick input -colors N -depth 8 txt:- | histogram` to preview what colors the quantizer finds.

## Tips

- **Low-res sources** (under 200px): Use `--ai-upscale 2` for two 4x passes (16x total). AI upscaling reconstructs edges and text that Lanczos can't.
- **Color count**: Start with `--colors 6` for logos. Increase if ring borders or subtle bands are missing.
- **Fuzz tolerance**: Lower values (10-15%) give tighter color boundaries but may split similar colors. Higher values (25-30%) merge similar tones.
- **Circular logos**: Always use `--circle` — it removes anti-aliasing artifacts outside the circle boundary.
- **Layer order**: Paint largest-area colors first (bottom), smallest last (top). This is the default behavior.
- **Iterative refinement**: Use a comparison HTML page to view original, AI-upscaled, traced, and hybrid versions side by side.

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| ImageMagick 7 (`magick`) | Yes | `brew install imagemagick` |
| potrace | Yes | `brew install potrace` |
| realesrgan-ncnn-vulkan | For `--ai-upscale` | See INSTALL.md |
