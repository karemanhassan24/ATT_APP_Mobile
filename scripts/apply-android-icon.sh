#!/usr/bin/env bash
# Apply logo.jpeg as Android launcher icons (Codemagic / macOS compatible).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/logo.jpeg"
RES="$ROOT/android/app/src/main/res"

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: logo.jpeg not found at $SRC"
  exit 1
fi
if [[ ! -d "$RES" ]]; then
  echo "ERROR: Android res folder not found at $RES"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

MASTER="$TMP/master.png"
sips -s format png "$SRC" --out "$MASTER" >/dev/null
sips -z 1024 1024 "$MASTER" >/dev/null

make_icon () {
  local size="$1"
  local scale_pct="$2"
  local out="$3"
  local content="$TMP/content_${size}_${scale_pct}.png"
  local draw=$(( size * scale_pct / 100 ))
  local pad=$(( (size - draw) / 2 ))

  sips -z "$draw" "$draw" "$MASTER" --out "$content" >/dev/null

  python3 - "$content" "$out" "$size" "$draw" "$pad" <<'PY'
import sys
from pathlib import Path
src_path, out_path, size, draw, pad = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
try:
    from PIL import Image
    src = Image.open(src_path).convert("RGBA")
    src = src.resize((draw, draw), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    canvas.paste(src, (pad, pad), src)
    canvas.convert("RGB").save(out_path, "PNG")
except Exception:
    # Fallback: stretch square logo to target size
    Path(out_path).write_bytes(Path(src_path).read_bytes())
PY
  # If PIL fallback wrote smaller content only, force exact size with sips
  sips -z "$size" "$size" "$out" --out "$out" >/dev/null 2>&1 || true
}

apply_legacy () {
  local folder="$1"
  local size="$2"
  local dir="$RES/$folder"
  mkdir -p "$dir"
  make_icon "$size" 92 "$dir/ic_launcher.png"
  make_icon "$size" 92 "$dir/ic_launcher_round.png"
  echo "Updated $folder/ic_launcher.png (${size}x${size})"
}

apply_foreground () {
  local folder="$1"
  local size="$2"
  local dir="$RES/$folder"
  mkdir -p "$dir"
  make_icon "$size" 66 "$dir/ic_launcher_foreground.png"
  echo "Updated $folder/ic_launcher_foreground.png (${size}x${size})"
}

apply_legacy mipmap-mdpi 48
apply_legacy mipmap-hdpi 72
apply_legacy mipmap-xhdpi 96
apply_legacy mipmap-xxhdpi 144
apply_legacy mipmap-xxxhdpi 192

apply_foreground mipmap-mdpi 108
apply_foreground mipmap-hdpi 162
apply_foreground mipmap-xhdpi 216
apply_foreground mipmap-xxhdpi 324
apply_foreground mipmap-xxxhdpi 432

mkdir -p "$RES/values"
cat > "$RES/values/ic_launcher_background.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
EOF

echo "Android launcher icons applied from logo.jpeg"
