#!/bin/bash

# 初始化 Git 仓库并提交代码

cd "$(dirname "$0")"

# 初始化 Git 仓库（如果还没有）
if [ ! -d .git ]; then
    git init
fi

# 添加所有文件
git add -A

# 提交
git commit -m "feat: 完成 macOS 翻译应用核心功能

- 实现应用入口、菜单栏和基础 UI 结构
- 创建设置界面和配置管理（API 端点、API Key、目标语言）
- 实现全局快捷键监听和文本获取功能
- 集成 OpenAI compatible API 翻译服务
- 创建悬浮窗口 UI 显示翻译结果
- 添加加载状态、错误提示和用户体验优化
- 添加单元测试覆盖核心功能
- 添加 Info.plist 配置和权限声明"

echo "Git 仓库已初始化并提交代码"

