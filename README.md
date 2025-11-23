# LuckyTrans

一个 macOS 翻译应用，支持通过全局快捷键翻译屏幕内任何选中的文本。

## 功能特性

- 全局快捷键翻译（默认：Cmd + Shift + T）
- 自动获取选中文本
- 使用 OpenAI compatible API 进行翻译
- 悬浮窗口显示翻译结果
- 支持自定义 API 端点
- 安全存储 API Key

## 系统要求

- macOS 13.0 或更高版本
- 需要授予辅助功能权限以获取选中文本

## 快速开始

### 方式 1: 命令行构建（推荐，无需 Xcode）

```bash
# 构建应用
./build.sh

# 运行应用
open LuckyTrans.app
```

### 方式 2: 开发模式运行

```bash
# 直接运行（开发模式）
./run.sh
```

### 方式 3: 使用 Swift Package Manager

```bash
# 构建
swift build -c release

# 运行测试
swift test

# 运行（开发模式）
swift run
```

### 方式 4: 在 Xcode 中打开

1. 创建新的 Xcode 项目（macOS App）
2. 将 `Sources/LuckyTrans/` 目录下的所有 Swift 文件添加到项目
3. 配置 Info.plist 和 Bundle ID
4. 运行项目

## 使用说明

1. **首次运行需要授予辅助功能权限**
   - 应用会提示您打开系统设置
   - 在"系统设置 > 隐私与安全性 > 辅助功能"中启用 LuckyTrans

2. **配置 API**
   - 点击菜单栏图标
   - 选择"设置"
   - 配置 API 端点（默认：`https://api.openai.com/v1/chat/completions`）
   - 输入并保存 API Key
   - 选择目标语言

3. **使用翻译**
   - 选中任何文本
   - 按 `Cmd + Shift + T` 快捷键
   - 翻译结果会在悬浮窗口中显示

## 开发

### 项目结构

```
LuckyTrans/
├── Sources/LuckyTrans/     # 核心功能代码
├── Tests/LuckyTransTests/   # 测试代码
├── build.sh                 # 构建脚本（创建 App Bundle）
├── run.sh                   # 开发模式运行脚本
├── Package.swift            # Swift Package 配置
└── Info.plist              # 应用配置和权限声明
```

### 构建说明

- `build.sh`: 使用 Swift Package Manager 构建，然后创建标准的 macOS App Bundle
- `run.sh`: 使用 `swift run` 快速运行（开发模式）
- `swift build`: 直接使用 SPM 构建
- `swift test`: 运行测试

### 测试

```bash
swift test
```

## 技术栈

- **语言**: Swift
- **框架**: SwiftUI + AppKit
- **构建工具**: Swift Package Manager
- **翻译服务**: OpenAI compatible API

## 注意事项

1. 首次运行需要授予辅助功能权限
2. API 端点和 API Key 需要用户自行配置
3. 需要处理网络错误和 API 限流
4. 应用使用 Keychain 安全存储 API Key

## 许可证

Copyright © 2024 LuckyTrans. All rights reserved.
