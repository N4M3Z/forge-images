# GEMINI.md

This file provides instructional context for the Gemini AI agent when working with the **forge-media** codebase.

## Project Overview

**forge-media** is a media processing and acquisition module for the Forge ecosystem. It provides skills and scripts covering image format conversion, raster-to-vector tracing, video-to-GIF, audio/video transcoding, and downloading media with yt-dlp.

### Core Responsibilities

- **Image Processing:** Raster-to-vector tracing (ImageMagick + potrace), format conversion, optional AI upscaling.
- **Video and Audio:** Video-to-GIF, transcoding, trimming, and audio extraction via ffmpeg.
- **Acquisition:** Downloading video, audio, and subtitles from YouTube and ~1800 other sites via yt-dlp.

## Building and Testing

```bash
make install          # deploy skills via forge CLI and activate git hooks
make validate         # module structure and code checks
make release          # build release tarball
make clean            # remove build artifacts
```

## Skills

| Skill | Responsibilities |
|:------|:-----------------|
| `MediaCapture` | Download video, audio, and subtitles from YouTube and ~1800 sites via yt-dlp |
| `RasterToVector` | Multi-color bitmap-to-SVG conversion via ImageMagick + potrace |

## Skill File Convention

Each skill directory contains:

- `SKILL.md` -- AI instructions with YAML frontmatter (name, description, version)
- `SKILL.yaml` -- sidecar metadata (sources, provider-specific config)

## Configuration

- `defaults.yaml`: module config stub (committed)
- `config.yaml`: user overrides (gitignored), same structure as defaults
- `module.yaml`: module metadata (name, version, description)

## Dependencies

The skills drive external tools, provisioned via forge-provision's Brewfile:

- `magick` (ImageMagick) and `potrace` for RasterToVector
- `ffmpeg` and `yt-dlp` for MediaCapture and video work

## Development Conventions

- **Skill naming**: PascalCase directories matching `name:` in SKILL.md frontmatter
- **Provider routing**: all skills deploy to all providers; the forge CLI's embedded defaults define provider targets
- **Deployment**: [forge CLI](https://github.com/N4M3Z/forge-cli) assembles and deploys skills per provider
