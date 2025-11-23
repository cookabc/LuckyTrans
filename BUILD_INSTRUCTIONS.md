# 构建说明

## 项目结构

这是一个使用 Swift Package Manager 的 macOS 应用项目。

## 在 Xcode 中构建

### 方法 1: 创建新的 Xcode 项目

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "macOS" > "App"
4. 填写项目信息：
   - Product Name: LuckyTrans
   - Interface: SwiftUI
   - Language: Swift
5. 将 `Sources/LuckyTrans/` 目录下的所有 Swift 文件添加到项目
6. 将 `Info.plist` 添加到项目
7. 在项目设置中配置：
   - Bundle Identifier: `com.luckytrans.app`
   - Deployment Target: macOS 13.0
   - 添加辅助功能权限说明

### 方法 2: 使用 Swift Package Manager

由于这是一个库项目结构，要作为应用运行，需要：

1. 修改 `Package.swift` 为可执行文件
2. 或者创建 Xcode 项目并导入源代码

## 运行测试

```bash
swift test
```

## 配置应用

1. 首次运行需要授予辅助功能权限
2. 打开设置（菜单栏图标 > 设置）
3. 配置 API 端点（默认：https://api.openai.com/v1/chat/completions）
4. 输入并保存 API Key
5. 选择目标语言

## 使用

1. 选中任何文本
2. 按 `Cmd + Shift + T` 快捷键
3. 翻译结果会在悬浮窗口中显示

## Git 提交

运行以下脚本初始化 Git 并提交代码：

```bash
./setup-git.sh
```

或手动执行：

```bash
git init
git add -A
git commit -m "feat: 完成 macOS 翻译应用核心功能"
```

