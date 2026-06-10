#!/bin/bash
set -euo pipefail

# 生成 AppIcon.icns（squircle 茶杯图标 → 全尺寸 iconset → icns）
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PNG="$TMP/icon-1024.png"
swift "$ROOT/scripts/make-icon.swift" "$PNG"

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$PNG" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d "$PNG" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

mkdir -p "$ROOT/assets"
iconutil -c icns "$ICONSET" -o "$ROOT/assets/AppIcon.icns"
cp "$PNG" "$ROOT/assets/icon-1024.png"
echo "✓ assets/AppIcon.icns + assets/icon-1024.png"
