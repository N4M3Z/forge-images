# Installation

## Required Dependencies

```bash
brew install imagemagick potrace
```

## Optional: Real-ESRGAN AI Upscaling

The `--ai-upscale` flag requires Real-ESRGAN ncnn Vulkan, a GPU-accelerated image super-resolution tool. There is no Homebrew formula — install from GitHub releases:

### Automated setup

```bash
cd Modules/forge-images

# Download macOS binary + models from Real-ESRGAN v0.2.5.0
mkdir -p vendor
gh release download v0.2.5.0 --repo xinntao/Real-ESRGAN \
  --pattern "realesrgan-ncnn-vulkan-*-macos.zip" \
  --dir vendor

# Extract and set permissions
unzip vendor/realesrgan-ncnn-vulkan-*-macos.zip -d vendor/realesrgan
chmod +x vendor/realesrgan/realesrgan-ncnn-vulkan

# Verify
vendor/realesrgan/realesrgan-ncnn-vulkan -h
```

### What's included

The release bundle contains:
- `realesrgan-ncnn-vulkan` — the upscaler binary (Vulkan GPU acceleration)
- `models/` — pre-trained neural network models:
  - `realesrgan-x4plus` — general-purpose 4x upscaler (default)
  - `realesrgan-x4plus-anime` — optimized for anime/illustration
  - `realesr-animevideov3` — video frame upscaler

### Hardware requirements

- macOS with Metal/Vulkan support (Apple Silicon or discrete GPU)
- Tested on Apple M1 Max — runs in under a second for small images

### Cleanup

The downloaded zip can be removed after extraction:

```bash
rm vendor/realesrgan-ncnn-vulkan-*-macos.zip
```

The `vendor/` directory is gitignored — each machine needs its own binary.

## Recommended Security Tools

See [root installation guide](../../INSTALL.md#recommended-security-tools) for full setup. This module benefits from:

- **shellcheck** — `brew install shellcheck` (shell script linting)
- **[safety-net](https://github.com/kenryu42/claude-code-safety-net)** — destructive command protection
