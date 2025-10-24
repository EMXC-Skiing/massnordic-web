#!/usr/bin/env zsh
# Optimize JPEGs from raw/ -> optimized/ using ImageMagick + mozjpeg
# - Resize to max width 1200px (no upscaling)
# - Strip metadata
# - Re-encode as progressive JPEG (~85% quality)

set -euo pipefail
setopt null_glob

# --- config ---
SRC_DIR="raw"
OUT_DIR="optimized"
MAX_WIDTH=1200
QUALITY=85

# --- deps ---
for cmd in cjpeg; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: '$cmd' (mozjpeg) not found on PATH." >&2
    echo "Install: macOS 'brew install mozjpeg', Linux distro packages or source." >&2
    exit 1
  }
done

# Prefer 'magick' (IM v7). Fallback to 'convert' (IM v6).
if command -v magick >/dev/null 2>&1; then
  IM_BIN="magick"
elif command -v convert >/dev/null 2>&1; then
  IM_BIN="convert"
else
  echo "Error: ImageMagick ('magick' or 'convert') not found on PATH." >&2
  exit 1
fi

# --- setup ---
[[ -d "$SRC_DIR" ]] || { echo "Error: source dir '$SRC_DIR' not found." >&2; exit 1; }
mkdir -p "$OUT_DIR"

# Process only .jpg; add patterns for .JPG/.jpeg if desired
typeset -i count=0
for f in "$SRC_DIR"/*.jpg; do
  base="${f:t}"                 # zsh: tail (filename)
  name="${base%.*}"
  out="$OUT_DIR/$name.jpg"

  echo "→ $base  →  ${out#$OUT_DIR/}"

  # Resize down to MAX_WIDTH (no upscaling), strip metadata, sRGB, pipe to mozjpeg
  # Note: cjpeg from mozjpeg strips metadata by default unless -copy is used.
  # We still use -strip on the IM side to drop profiles before encode.
"$IM_BIN" "$f" \
  -resize "${MAX_WIDTH}x>" \
  -strip \
  -colorspace sRGB \
  ppm:- \
| cjpeg -quality "$QUALITY" -progressive -optimize -outfile "$out"

  (( ++count ))
done

if (( count == 0 )); then
  echo "No .jpg files found in '$SRC_DIR'."
else
  echo "Done. Processed $count file(s) → '$OUT_DIR/'."
fi
