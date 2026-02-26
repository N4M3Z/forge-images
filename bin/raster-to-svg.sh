#!/usr/bin/env bash
set -euo pipefail

# raster-to-svg.sh — Multi-color bitmap-to-SVG conversion
#
# Usage: raster-to-svg.sh <input> <output.svg> [options]
#
# Dependencies: magick (ImageMagick 7), potrace
# Optional:     realesrgan-ncnn-vulkan (for --ai-upscale)

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(command cd "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(command cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <input> <output.svg> [options]

Options:
  --scale N        Lanczos upscale factor before tracing (default: 8)
  --ai-upscale N   AI upscale passes using Real-ESRGAN (each pass = 4x)
                   Requires realesrgan-ncnn-vulkan in vendor/ (see INSTALL.md)
  --colors N       Number of colors to quantize to (default: 6)
  --circle         Apply circular clip-path to output
  --fuzz N         Color match tolerance in percent (default: 20)
  --turdsize N     Ignore speckles smaller than N pixels (default: 10)
  --help           Show this help

Examples:
  $SCRIPT_NAME logo.gif logo.svg
  $SCRIPT_NAME icon.png icon.svg --circle --colors 4
  $SCRIPT_NAME badge.gif badge.svg --ai-upscale 2 --circle --fuzz 15
EOF
  exit 0
}

# --- Argument parsing ---
INPUT=""
OUTPUT=""
SCALE=8
AI_PASSES=0
NUM_COLORS=6
CIRCLE=false
FUZZ=20
TURDSIZE=10

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scale)       SCALE="$2"; shift 2 ;;
    --ai-upscale)  AI_PASSES="$2"; shift 2 ;;
    --colors)      NUM_COLORS="$2"; shift 2 ;;
    --circle)      CIRCLE=true; shift ;;
    --fuzz)        FUZZ="$2"; shift 2 ;;
    --turdsize)    TURDSIZE="$2"; shift 2 ;;
    --help)        usage ;;
    -*)            echo "Error: unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      elif [[ -z "$OUTPUT" ]]; then
        OUTPUT="$1"
      else
        echo "Error: unexpected argument: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Error: input and output paths required" >&2
  usage
fi

# --- Dependency check ---
for cmd in magick potrace; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd not found. Install via: brew install ${cmd/magick/imagemagick}" >&2
    exit 1
  fi
done

ESRGAN_BIN="$MODULE_ROOT/vendor/realesrgan/realesrgan-ncnn-vulkan"
ESRGAN_MODELS="$MODULE_ROOT/vendor/realesrgan/models"

if [[ "$AI_PASSES" -gt 0 ]] && [[ ! -x "$ESRGAN_BIN" ]]; then
  echo "Error: realesrgan-ncnn-vulkan not found at $ESRGAN_BIN" >&2
  echo "Run the setup in INSTALL.md to install it." >&2
  exit 1
fi

# --- Setup ---
WORK_DIR="$(mktemp -d)"
trap 'command rm -rf "$WORK_DIR"' EXIT

# Get source dimensions
SRC_DIMS=$(magick "$INPUT" -format "%w %h" info:)
SRC_W="${SRC_DIMS%% *}"
SRC_H="${SRC_DIMS##* }"

# --- Step 1: Upscale ---
# Convert to PNG first (Real-ESRGAN needs PNG)
magick "$INPUT" "$WORK_DIR/source.png"

if [[ "$AI_PASSES" -gt 0 ]]; then
  # AI upscale with Real-ESRGAN (each pass = 4x)
  CURRENT="$WORK_DIR/source.png"
  for ((pass=1; pass<=AI_PASSES; pass++)); do
    NEXT="$WORK_DIR/ai-pass-${pass}.png"
    echo "AI upscale pass $pass/${AI_PASSES}..." >&2
    "$ESRGAN_BIN" \
      -i "$CURRENT" \
      -o "$NEXT" \
      -n realesrgan-x4plus \
      -m "$ESRGAN_MODELS" \
      -s 4 2>&1 | grep -v '^\[' || true
    CURRENT="$NEXT"
  done
  command cp "$CURRENT" "$WORK_DIR/upscaled.png"
  # Get actual dimensions after AI upscale
  UP_DIMS=$(magick "$WORK_DIR/upscaled.png" -format "%w %h" info:)
  TARGET_W="${UP_DIMS%% *}"
  TARGET_H="${UP_DIMS##* }"
else
  # Lanczos upscale
  TARGET_W=$((SRC_W * SCALE))
  TARGET_H=$((SRC_H * SCALE))
  magick "$WORK_DIR/source.png" \
    -resize "${TARGET_W}x${TARGET_H}" \
    -filter Lanczos \
    -sharpen 0x1.5 \
    "$WORK_DIR/upscaled.png"
fi

echo "Source: ${SRC_W}x${SRC_H} → Upscaled: ${TARGET_W}x${TARGET_H}" >&2

# --- Step 2: Apply circle mask (optional) ---
if [[ "$CIRCLE" == true ]]; then
  CX=$((TARGET_W / 2))
  CY=$((TARGET_H / 2))
  RADIUS=$(( (TARGET_W < TARGET_H ? TARGET_W : TARGET_H) / 2 - 10 ))
  magick -size "${TARGET_W}x${TARGET_H}" xc:black \
    -fill white -draw "circle $CX,$CY $CX,$((CY - RADIUS))" \
    "$WORK_DIR/circle-mask.png"
  magick "$WORK_DIR/upscaled.png" "$WORK_DIR/circle-mask.png" \
    -alpha off -compose multiply -composite \
    "$WORK_DIR/upscaled.png"
fi

# --- Step 3: Combine traced layers into SVG ---
combine_layers() {
  local output="$1"
  shift

  local transform="translate(0.000000,${TARGET_H}.000000) scale(0.100000,-0.100000)"

  {
    cat <<HEADER
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 $TARGET_W $TARGET_H">
HEADER

    if [[ "$CIRCLE" == true ]]; then
      local cx=$((TARGET_W / 2))
      local cy=$((TARGET_H / 2))
      local r=$(( (TARGET_W < TARGET_H ? TARGET_W : TARGET_H) / 2 - 10 ))
      cat <<CLIP
<defs>
  <clipPath id="circle-clip">
    <circle cx="$cx" cy="$cy" r="$r"/>
  </clipPath>
</defs>
<g clip-path="url(#circle-clip)">
CLIP
    fi

    while [[ $# -ge 2 ]]; do
      local color="$1"
      local svg_file="$2"
      shift 2

      printf '<g fill="%s" stroke="none" transform="%s">\n' "$color" "$transform"
      # Extract path data from potrace SVG (skip multi-line <g> tag)
      awk '
        /<g /{in_g=1; next}
        in_g && /stroke="none">/{in_g=0; collecting=1; next}
        collecting && /<\/g>/{collecting=0; next}
        collecting{print}
      ' "$svg_file"
      echo '</g>'
    done

    if [[ "$CIRCLE" == true ]]; then
      echo '</g>'
    fi

    echo '</svg>'
  } > "$output"
}

# --- Main pipeline ---
main() {
  # Step 3: Quantize and discover dominant colors
  local -a COLORS
  mapfile -t COLORS < <(
    magick "$WORK_DIR/upscaled.png" \
      -alpha off -colors "$NUM_COLORS" -depth 8 txt:- 2>/dev/null \
    | awk 'NR>1' \
    | awk -F'[()]' '{print $2}' \
    | sort \
    | uniq -c \
    | sort -rn \
    | awk '{print $2}' \
    | (grep -v '^0,0,0$' || true)
  )

  echo "Discovered ${#COLORS[@]} colors" >&2

  # Step 4: For each color, create a mask and trace it
  local -a LAYER_ARGS=()
  local i=0
  for rgb in "${COLORS[@]}"; do
    local hex
    hex=$(printf '#%02X%02X%02X' $(echo "$rgb" | tr ',' ' '))
    echo "  Layer $i: $hex ($rgb)" >&2

    # Create binary mask for this color
    magick "$WORK_DIR/upscaled.png" \
      -alpha off \
      -fuzz "${FUZZ}%" \
      -fill white -opaque "rgb($rgb)" \
      -fill black +opaque white \
      "$WORK_DIR/mask-${i}.png"

    # Convert to PBM and trace
    magick "$WORK_DIR/mask-${i}.png" -negate "$WORK_DIR/mask-${i}.pbm"
    potrace "$WORK_DIR/mask-${i}.pbm" \
      -s -o "$WORK_DIR/trace-${i}.svg" \
      --turdsize "$TURDSIZE" \
      --alphamax 0.8 \
      --opttolerance 0.1 2>&1

    LAYER_ARGS+=("$hex" "$WORK_DIR/trace-${i}.svg")
    i=$((i + 1))
  done

  # Step 5: Combine
  combine_layers "$OUTPUT" "${LAYER_ARGS[@]}"

  local size
  size=$(wc -c < "$OUTPUT")
  echo "Output: $OUTPUT (${size} bytes, ${#COLORS[@]} layers)" >&2
}

main
