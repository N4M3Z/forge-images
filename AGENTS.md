# forge-media

Image processing — multi-color raster-to-vector conversion via ImageMagick + potrace, with optional AI upscaling. Shell module, no Rust.

## Scripts

| Script | Purpose |
|--------|---------|
| `bin/raster-to-svg.sh` | Convert GIF/PNG/JPEG to scalable SVG |

## Skills (1)

RasterToVector — guided bitmap-to-SVG conversion

## Dependencies

- `magick` (ImageMagick)
- `potrace`
- `vendor/realesrgan/` (bundled, optional AI upscaler)

## Code Style

- `#!/usr/bin/env bash` + `set -euo pipefail`
- Double-quote all variables, `shellcheck` clean
