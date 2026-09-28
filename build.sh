#!/bin/bash

# 构建脚本 - 使用 Xcode 构建

echo "🔨 开始构建 InputRelay..."

# 检查是否安装了 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 未找到 xcodebuild，请安装 Xcode"
    exit 1
fi

# 清理旧的构建
echo "🧹 清理旧构建..."
rm -rf .build

# 生成 Xcode 项目
echo "📦 生成 Xcode 项目..."
swift package generate-xcodeproj

# 使用 Xcode 构建
echo "🔧 使用 Xcode 构建..."
xcodebuild -scheme InputRelay -configuration Release

echo "✅ 构建完成！"
