# forge-media

Media processing and acquisition: image format conversion and raster-to-vector tracing (ImageMagick + potrace), video-to-GIF and A/V transcoding (ffmpeg), and media download (yt-dlp), with optional AI upscaling. Shell module, no Rust.

## Scripts

| Script | Purpose |
|--------|---------|
| `bin/raster-to-svg.sh` | Convert GIF/PNG/JPEG to scalable SVG |

## Skills

MediaCapture: download video/audio/subtitles via yt-dlp
RasterToVector: guided bitmap-to-SVG conversion

## Dependencies

- `magick` (ImageMagick)
- `potrace`
- `vendor/realesrgan/` (bundled, optional AI upscaler)

## Code Style

- `#!/usr/bin/env bash` + `set -euo pipefail`
- Double-quote all variables, `shellcheck` clean
