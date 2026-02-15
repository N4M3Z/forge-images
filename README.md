# forge-images

Image processing utilities for the Forge framework.

## Skills

| Skill | Purpose |
|-------|---------|
| RasterToVector | Multi-color bitmap-to-SVG conversion via ImageMagick + potrace |

## Dependencies

- [ImageMagick](https://imagemagick.org/) (`magick` CLI)
- [potrace](https://potrace.sourceforge.net/) (bitmap tracer)

Install via Homebrew:

```bash
brew install imagemagick potrace
```

## Usage

Skills are invoked via Claude Code's `/RasterToVector` command or by the AI when image conversion is needed.

The `bin/raster-to-svg.sh` script can also be run standalone:

```bash
bash bin/raster-to-svg.sh input.gif output.svg
```
