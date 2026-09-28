#!/bin/bash
#
# 构建 InputRelay.app
#
# 只依赖 Swift 工具链（CommandLineTools 即可），不需要完整 Xcode：
# SwiftUI / GameController / CoreGraphics 都由 macOS SDK 提供。
#
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="InputRelay"
BUILD_DIR="$ROOT/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:--}"
BUILD_OPTIONS=(--package-path "$ROOT")
if [ -n "${INPUTRELAY_SDK:-}" ]; then
    BUILD_OPTIONS+=(--sdk "$INPUTRELAY_SDK")
fi
if [ "${INPUTRELAY_DISABLE_SANDBOX:-0}" = "1" ]; then
    BUILD_OPTIONS+=(--disable-sandbox)
fi
if [ -n "${INPUTRELAY_BUILD_SYSTEM:-}" ]; then
    BUILD_OPTIONS+=(--build-system "$INPUTRELAY_BUILD_SYSTEM")
fi

echo "🔨 构建 $APP_NAME ($CONFIG)..."

# 1. 编译可执行文件
swift build -c "$CONFIG" "${BUILD_OPTIONS[@]}"

BIN_DIR="$(swift build -c "$CONFIG" "${BUILD_OPTIONS[@]}" --show-bin-path)"
BINARY="$BIN_DIR/$APP_NAME"

if [ ! -x "$BINARY" ]; then
    echo "❌ 未找到可执行文件: $BINARY"
    exit 1
fi

# 2. 组装 .app bundle
#    标准应用在启动时显示窗口，并保留菜单栏快捷入口。
echo "📦 组装 $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/InputRelay/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# CI 发布时同步标签版本；必须在签名前写入。
if [ -n "${INPUTRELAY_VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $INPUTRELAY_VERSION" "$APP_BUNDLE/Contents/Info.plist"
fi
if [ -n "${INPUTRELAY_BUILD_NUMBER:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $INPUTRELAY_BUILD_NUMBER" "$APP_BUNDLE/Contents/Info.plist"
fi

# 复制编译产物中的资源（预设配置等）
for bundle in "$BIN_DIR"/*.bundle; do
    [ -e "$bundle" ] || continue
    cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/"
done

# Info.plist 若声明了图标则一并复制
if [ -f "$ROOT/InputRelay/Resources/AppIcon.icns" ]; then
    cp "$ROOT/InputRelay/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# 品牌标识（窗口标题与菜单栏共用）
if [ -f "$ROOT/InputRelay/Resources/fox-mark.png" ]; then
    cp "$ROOT/InputRelay/Resources/fox-mark.png" "$APP_BUNDLE/Contents/Resources/"
fi

# 3. 有证书时保持相同签名身份；本地临时签名在重建后可能需要重新授权。
codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"
if [ "$SIGNING_IDENTITY" = "-" ]; then
    echo "提示：当前使用临时签名；重建后若辅助功能权限失效，请移除旧条目并重新添加此应用。"
fi

echo "✅ 构建完成: $APP_BUNDLE"
echo "   运行: open \"$APP_BUNDLE\""
