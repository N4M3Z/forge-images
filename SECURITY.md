# Security

## Reporting a Vulnerability

Email **martin.zeman@pm.me** with `[forge-media security]` in the subject. Please include:

- Affected skill or script (path within the repo)
- Reproduction steps or proof-of-concept
- Observed vs expected behaviour

Expect an initial acknowledgement within 72 hours.

## Scope

In scope:

- Malicious or unsafe behaviour in skill instructions (including prompt-injection vectors)
- Unsafe shell invocation in bundled scripts (`bin/`)
- Secret disclosure in committed content

Out of scope:

- Vulnerabilities in the forge toolchain itself: see [forge-cli](https://github.com/N4M3Z/forge-cli) / [forge-core](https://github.com/N4M3Z/forge-core)
- Vulnerabilities in third-party tools the skills drive (yt-dlp, ffmpeg, ImageMagick, potrace): report upstream
