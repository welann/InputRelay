#!/bin/bash
# 构建并安装到当前用户的应用程序目录，供 Finder / Raycast 启动。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${1:-release}"
DESTINATION="$HOME/Applications/InputRelay.app"

"$ROOT/build.sh" "$CONFIG"

# 避免覆盖名称相同但不属于本项目的应用。
if [ -e "$DESTINATION" ]; then
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DESTINATION/Contents/Info.plist")
    if [ "$BUNDLE_ID" != "com.inputrelay.app" ]; then
        echo "无法安装：$DESTINATION 已被其他应用占用。" >&2
        exit 1
    fi
fi

mkdir -p "$HOME/Applications"
ditto "$ROOT/.build/InputRelay.app" "$DESTINATION"
codesign --verify --deep --strict "$DESTINATION"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DESTINATION"

echo "✅ 已安装: $DESTINATION"
echo "   可在 Raycast 中搜索 InputRelay，或运行: open \"$DESTINATION\""
echo "   如旧版本仍在运行，请从菜单栏退出后重新打开。"
