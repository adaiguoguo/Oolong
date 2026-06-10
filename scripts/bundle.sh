#!/bin/bash
set -euo pipefail

# 组装 Oolong.app
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Oolong"
BUILD_DIR="$ROOT/.build/release"
APP="$ROOT/dist/$APP_NAME.app"

echo "==> swift build -c release"
swift build -c release --package-path "$ROOT"

echo "==> 组装 $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Oolong</string>
    <key>CFBundleDisplayName</key>     <string>Oolong</string>
    <key>CFBundleIdentifier</key>      <string>com.damon.oolong</string>
    <key>CFBundleExecutable</key>      <string>Oolong</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "APPL????" > "$APP/Contents/PkgInfo"

echo "==> ad-hoc 签名 (SMAppService 开机自启需要)"
codesign --force --deep --sign - "$APP"

echo "==> 完成: $APP"
