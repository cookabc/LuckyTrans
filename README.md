# LuckyTrans

一个 macOS 划词翻译工具，支持通过全局快捷键翻译屏幕内选中的文本或识别截图内容。

## 功能特性

- **多服务支持**: 
  - OpenAI Compatible API
  - DeepL API
  - Google 翻译 (免费使用)
  - 百度翻译
- **翻译模式**:
  - 划词翻译（默认：Cmd + Shift + T）
  - 截图翻译（默认：Opt + S）
  - 输入翻译（默认：Opt + A）
  - 剪贴板翻译
- **OCR 文字识别**:
  - 截图 OCR (默认：Cmd + Shift + O)
  - 自动识别并复制文本到剪贴板
- **现代化 UI**:
  - 悬浮窗口显示结果
  - 支持浅色/深色模式
  - 菜单栏快速访问
  
## 系统要求

- macOS 13.0 或更高版本
- 需要授予辅助功能权限（用于获取选中文本）
- 需要授予屏幕录制权限（用于截图 OCR）

## 快速开始

```bash
# 构建应用
./build.sh

# 运行应用
open LuckyTrans.app
```

## 使用说明

1. **授予权限**
   - 首次运行需要授予辅助功能权限，以便应用获取选中文本。
   - 使用截图功能时需要授予屏幕录制权限。

2. **配置翻译服务**
   - 点击菜单栏图标 > "偏好设置" > "翻译"
   - 选择您喜欢的翻译服务并配置（如 API Key）

3. **设置快捷键**
   - 在 "设置 > 快捷键" 中自定义各种功能的快捷键

4. **开始使用**
   - **划词翻译**: 选中任意文本，按下快捷键（默认 Cmd+Shift+T）
   - **截图 OCR**: 按下快捷键（默认 Cmd+Shift+O），框选屏幕区域识别文字

## 开发

### 项目结构

```
LuckyTrans/
├── Sources/LuckyTrans/     # 源码目录
│   ├── DesignSystem.swift  # 设计系统（颜色、字体）
│   ├── EnhancedShortcutManager.swift # 快捷键管理
│   ├── SimpleOCREngine.swift # OCR 引擎
│   ├── MenuBarManager.swift # 菜单栏管理
│   └── ...
├── build.sh                 # 构建脚本
└── Package.swift            # Swift Package 配置
```

### 构建

```bash
./build.sh
```

## 技术栈

- **语言**: Swift
- **框架**: SwiftUI + AppKit + Vision + Carbon
- **构建工具**: Swift Package Manager

## 许可证

Copyright © 2025 LuckyTrans. All rights reserved.
