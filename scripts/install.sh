#!/bin/bash
# Build a release, wrap it into QwenLocal.app, ad-hoc sign it, install to ~/Applications and open it.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
app=build/QwenLocal.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/QwenLocal" "$app/Contents/MacOS/QwenLocal"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>mp.kaio.qwenlocal</string>
    <key>CFBundleName</key><string>QwenLocal</string>
    <key>CFBundleExecutable</key><string>QwenLocal</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST
codesign --force --sign - "$app"

pkill -x QwenLocal || true
mkdir -p ~/Applications
rm -rf ~/Applications/QwenLocal.app
cp -R "$app" ~/Applications/QwenLocal.app
open ~/Applications/QwenLocal.app
echo "Installed ~/Applications/QwenLocal.app"
