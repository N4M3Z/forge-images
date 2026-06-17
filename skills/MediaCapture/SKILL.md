---
name: MediaCapture
version: 0.1.0
description: Download video, audio, and subtitles from YouTube and ~1800 other sites with yt-dlp, with format selection, audio extraction, clipping, playlist archiving, and SponsorBlock removal. USE WHEN capturing a YouTube video, ripping audio (mp3/m4a) from a link, grabbing or embedding subtitles, downloading a clip or section, archiving a channel or playlist, or fetching media from Vimeo, Twitch, SoundCloud, or a podcast feed.
---

# MediaCapture

Drive `yt-dlp` to download and convert media from the command line. `yt-dlp` and
its required companion `ffmpeg` are provisioned via forge-provision's Brewfile
(`brew install yt-dlp ffmpeg`). ffmpeg is mandatory for merging high-resolution
streams, extracting audio, and embedding metadata; without it yt-dlp is capped
at pre-merged formats.

## Usage

Inspect first when the desired format is uncertain, then download:

```bash
yt-dlp -F "URL"     # list available formats and codes
yt-dlp "URL"        # best video+audio, merged (the default)
```

Always quote the URL. YouTube links contain `?`, `&`, and `=` that the shell
otherwise interprets.

## Intent to invocation

| Want | Command |
|------|---------|
| Best-quality video (default) | `yt-dlp "URL"` |
| MP3 audio only | `yt-dlp -t mp3 "URL"` |
| M4A (AAC) audio | `yt-dlp -t aac "URL"` |
| Force MP4 container | `yt-dlp -t mp4 "URL"` |
| Cap at 1080p, prefer MP4 | `yt-dlp -S "res:1080,ext:mp4" "URL"` |
| Pick an exact format code | `yt-dlp -f 137+140 "URL"` (from `-F` output) |
| Subtitles to a file | `yt-dlp --write-subs --sub-langs "en.*" "URL"` |
| Subtitles embedded in the file | add `--embed-subs` |
| Auto-captions when no human subs exist | add `--write-auto-subs` |
| Embed thumbnail, metadata, chapters | `--embed-thumbnail --embed-metadata --embed-chapters` |
| Just a section/clip | `yt-dlp --download-sections "*00:01:30-00:02:45" --force-keyframes-at-cuts "URL"` |
| Strip sponsor segments | `yt-dlp --sponsorblock-remove sponsor,selfpromo "URL"` |
| Whole playlist or channel | `yt-dlp -o "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" "URL"` |
| Single video from a playlist URL | add `--no-playlist` |
| Resume / skip already-grabbed | `--download-archive archive.txt` |
| Age- or login-gated content | `--cookies-from-browser safari` (or `chrome`, `firefox`) |
| Choose output directory | `-P "~/Data/Media"` |
| ASCII-safe filenames | `--restrict-filenames` |

`-t/--preset-alias` (`mp3`, `aac`, `mp4`, `mkv`) bundles the right
`--extract-audio`/`--remux-video`/`--merge-output-format` flags, so prefer it
over hand-rolling those.

## Output template

`-o` takes a filename template of `%(field)s` placeholders. Useful fields:
`%(title)s`, `%(id)s`, `%(ext)s`, `%(uploader)s`, `%(upload_date>%Y-%m-%d)s`,
`%(playlist)s`, `%(playlist_index)s`. The default lands the file in the current
directory, so pass `-o` or `-P` so downloads do not dump into a repo (land them
under `~/Data` per the working-layer convention).

A solid house default that names, organizes, and self-describes the file:

```bash
yt-dlp \
  -P "~/Data/Media" \
  -o "%(uploader)s/%(upload_date>%Y-%m-%d)s %(title)s [%(id)s].%(ext)s" \
  --embed-metadata --embed-thumbnail --embed-chapters \
  --write-subs --sub-langs "en.*" --embed-subs \
  "URL"
```

## Recipes

```bash
# Incrementally archive a channel; reruns skip what is already downloaded
yt-dlp --download-archive ~/Data/Media/archive.txt \
  -o "%(uploader)s/%(title)s [%(id)s].%(ext)s" "CHANNEL_URL"

# Extract a 30-second clip without re-encoding the whole video
yt-dlp --download-sections "*00:00:10-00:00:40" --force-keyframes-at-cuts "URL"
```

SponsorBlock categories: `sponsor`, `intro`, `outro`, `selfpromo`, `preview`,
`filler`, `interaction`, `music_offtopic`. Combine with commas.

## Constraints

- Run `-F` before guessing a format code; format availability varies per video.
- Keep yt-dlp current (`brew upgrade yt-dlp`). Sites change their players often;
  a stale binary fails with extractor errors that an upgrade usually fixes.
- Download only content you are permitted to. Respect copyright and each site's
  Terms of Service; do not use `--cookies-from-browser` to bypass paywalls for
  content you have no rights to.
- This skill teaches direct yt-dlp invocation; it ships no wrapper script.
  Build the command from the intent table rather than reaching for a default.
