#!/bin/bash
#
# 构建 InputRelay.app
#
# 只依赖 Swift 工具链（CommandLineTools 即可），不需要完整 Xcode：
# SwiftUI / IOKit / CoreGraphics 都由 macOS SDK 提供。
#
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="InputRelay"
BUILD_DIR="$ROOT/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 构建 $APP_NAME ($CONFIG)..."

# 1. 编译可执行文件
swift build -c "$CONFIG" --package-path "$ROOT"

BIN_DIR="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)"
BINARY="$BIN_DIR/$APP_NAME"

if [ ! -x "$BINARY" ]; then
    echo "❌ 未找到可执行文件: $BINARY"
    exit 1
fi

# 2. 组装 .app bundle
#    Info.plist 中的 LSUIElement=true 让应用只出现在菜单栏，不占用 Dock。
echo "📦 组装 $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/InputRelay/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# 复制编译产物中的资源（预设配置等）
for bundle in "$BIN_DIR"/*.bundle; do
    [ -e "$bundle" ] || continue
    cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/"
done

# Info.plist 若声明了图标则一并复制
if [ -f "$ROOT/InputRelay/Resources/AppIcon.icns" ]; then
    cp "$ROOT/InputRelay/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# 3. 临时签名，便于本机授予辅助功能权限
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null \
    || echo "⚠️  签名失败，应用仍可运行，但每次重新构建都需要重新授权辅助功能"

echo "✅ 构建完成: $APP_BUNDLE"
echo "   运行: open \"$APP_BUNDLE\""
