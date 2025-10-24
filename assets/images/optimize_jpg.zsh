#!/usr/bin/env zsh
# Optimize JPEGs from raw/ → optimized/
# - Resize to max width (default 1200, CLI override)
# - Strip metadata
# - Re-encode as progressive JPEG (default 85% quality, CLI override)


# USAGE:
# Use defaults (1200px, 85% quality):
# ./optimize_jpg.sh

# Custom max width and quality:
# ./optimize_jpg.sh 1600 75

# Just custom width (quality falls back to 85):
# ./optimize_jpg.sh 1024

set -euo pipefail
setopt null_glob

# --- defaults ---
SRC_DIR="raw"
OUT_DIR="optimized"
MAX_WIDTH=${1:-1200}
QUALITY=${2:-85}

# --- dependency checks ---
for cmd in cjpeg; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' (mozjpeg) not found on PATH." >&2
    echo "Install: brew install mozjpeg  # or your distro's equivalent" >&2
    exit 1
  fi
done

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

echo "   max width:  $MAX_WIDTH px"
echo "   quality:    $QUALITY%"
echo "   input dir:  $SRC_DIR/"
echo "   output dir: $OUT_DIR/"
echo ""

typeset -i count=0
for f in "$SRC_DIR"/*.jpg "$SRC_DIR"/*.JPG(N) "$SRC_DIR"/*.jpeg(N); do
  base="${f:t}"
  name="${base%.*}"
  out="$OUT_DIR/$name.jpg"

  echo "→ $base → ${out#$OUT_DIR/}"

  "$IM_BIN" "$f" \
    -resize "${MAX_WIDTH}x>" \
    -strip \
    -colorspace sRGB \
    ppm:- \
  | cjpeg -quality "$QUALITY" -progressive -optimize -outfile "$out"

  (( ++count ))
done

if (( count == 0 )); then
  echo "No matching images found in '$SRC_DIR'."
else
  echo " Done. Processed $count file(s) → '$OUT_DIR/'."
fi
