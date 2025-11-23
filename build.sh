#!/bin/bash

# 构建 macOS 应用的脚本
# 使用 Swift Package Manager 构建，然后创建 App Bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="LuckyTrans"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 开始构建 ${APP_NAME}..."

# 清理之前的构建
if [ -d "${APP_BUNDLE}" ]; then
    echo "清理旧的 App Bundle..."
    rm -rf "${APP_BUNDLE}"
fi

# 使用 Swift Package Manager 构建
echo "编译 Swift 代码..."
swift build -c release

# 获取构建产物路径
BUILD_DIR="${SCRIPT_DIR}/.build/release"
EXECUTABLE="${BUILD_DIR}/${APP_NAME}"

if [ ! -f "${EXECUTABLE}" ]; then
    echo "❌ 错误: 找不到可执行文件 ${EXECUTABLE}"
    echo "构建可能失败，请检查错误信息"
    exit 1
fi

# 创建 App Bundle 结构
echo "创建 App Bundle 结构..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 复制可执行文件
echo "复制可执行文件..."
cp "${EXECUTABLE}" "${MACOS_DIR}/${APP_NAME}"

# 复制并处理 Info.plist
echo "复制 Info.plist..."
cp "${SCRIPT_DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"

# 确保 Info.plist 中的可执行文件名正确
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ${APP_NAME}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null || true

# 创建 PkgInfo（可选，但有些应用需要）
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# 设置可执行权限
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "✅ 构建完成！"
echo "App Bundle 位置: ${APP_BUNDLE}"
echo ""
echo "运行应用:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "或者直接运行可执行文件:"
echo "  ${MACOS_DIR}/${APP_NAME}"

