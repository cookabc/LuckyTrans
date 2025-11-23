# 快速开始指南

## 命令行构建和运行（无需 Xcode）

### 1. 构建应用

```bash
./build.sh
```

这会：
- 使用 Swift Package Manager 编译代码
- 创建标准的 macOS App Bundle (`LuckyTrans.app`)
- 配置所有必要的文件

### 2. 运行应用

```bash
open LuckyTrans.app
```

或者直接运行可执行文件：

```bash
./LuckyTrans.app/Contents/MacOS/LuckyTrans
```

### 3. 开发模式运行

如果你想快速测试而不创建 App Bundle：

```bash
./run.sh
```

或者：

```bash
swift run
```

## 首次使用

1. **授予辅助功能权限**
   - 应用启动后会提示
   - 或在"系统设置 > 隐私与安全性 > 辅助功能"中手动启用

2. **配置 API**
   - 点击菜单栏图标
   - 选择"设置"
   - 输入 API 端点和 API Key
   - 选择目标语言

3. **开始翻译**
   - 选中任何文本
   - 按 `Cmd + Shift + T`
   - 查看翻译结果

## 测试

```bash
swift test
```

## 清理构建

```bash
rm -rf .build LuckyTrans.app
```

## 常见问题

### 构建失败？

- 确保 macOS 版本 >= 13.0
- 确保已安装 Xcode Command Line Tools: `xcode-select --install`

### 应用无法启动？

- 检查是否授予了辅助功能权限
- 查看控制台日志: `log show --predicate 'process == "LuckyTrans"' --last 1m`

### 快捷键不工作？

- 确保已授予辅助功能权限
- 检查是否有其他应用占用了相同的快捷键

