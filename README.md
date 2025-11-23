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

## 安装

1. 克隆项目
2. 使用 Xcode 打开项目
3. 配置 API 端点和 API Key
4. 运行应用

## 使用说明

1. 首次运行需要授予辅助功能权限
2. 在设置中配置 API 端点和 API Key
3. 选择目标语言
4. 选中文本后按快捷键（默认 Cmd + Shift + T）进行翻译

## 开发

项目使用 Swift Package Manager 管理依赖。

```bash
swift build
swift test
```

