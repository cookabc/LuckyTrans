#!/bin/bash

# 直接运行应用（开发模式）
# 使用 swift run 快速运行，无需创建 App Bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 运行 ${APP_NAME} (开发模式)..."
echo "注意: 开发模式下某些功能可能受限"
echo ""

# 使用 swift run 运行
swift run


