<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Design/AppIcon/Previews/typelock-icon-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="Design/AppIcon/Previews/typelock-icon-default.png">
    <img src="Design/AppIcon/Previews/typelock-icon-default.png" width="160" alt="TypeLock 图标">
  </picture>
</p>

<h1 align="center">TypeLock</h1>

<p align="center">TypeLock 是一款原生 macOS 输入法管理器。它支持按 App 的启动/激活规则、浏览器域名规则和终端程序规则切换输入法，并提供屏幕提示、每输入法快捷键、排除列表和配置备份。</p>

<p align="center">
  <a href="https://swift.org"><img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-orange.svg"></a>
  <a href="https://www.apple.com/macos/"><img alt="Platform" src="https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <a href="https://github.com/zbl-jerry/TypeLock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/zbl-jerry/TypeLock?include_prereleases"></a>
  <a href="https://github.com/zbl-jerry/TypeLock/pulls"><img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"></a>
</p>

<p align="center">🇨🇳 <strong>简体中文</strong> · 🇺🇸 <a href="README.md">English</a></p>

## ✨ 功能

- **每 App 双时机规则。** App 启动后的首次前台和从后台切回前台可以使用不同输入法；规则可继承全局默认、禁止切换、记住上次输入法或指定固定输入法。
- **浏览器域名规则。** 支持精确域名、域名后缀和完整 URL 正则；当前台浏览器上报匹配 URL 时应用。
- **终端程序规则。** 按终端聚焦 pane 中的前台程序切换，例如 `nvim`、`ssh`、`claude`。
- **输入法指示器。** 可在文本光标、鼠标或屏幕边缘显示当前输入法；支持时长、9 向对齐、间距、尺寸、样式、Caps Lock、常驻显示，以及每输入法的短标签和颜色。
- **全局快捷键。** 为任意输入法绑定快捷键，支持冲突检测和录制。
- **排除列表。** 自动切换和输入法提示分别维护独立排除列表。
- **可靠性工具。** 通过焦点落定修复输入法切换不同步；可选关闭 macOS 14 实验性文本光标，缓解输入/光标卡顿。
- **配置备份。** 以 JSON 导出和导入全部规则与偏好，支持合并或替换。
- **本地优先。** 规则、统计和诊断保存在本机；更新使用 Sparkle 和签名 appcast。

## 🔀 切换优先级

每次前台事件按以下顺序解析：

1. 当前 App 的应用切换排除。
2. 匹配当前浏览器 URL 的浏览器规则。
3. 匹配当前终端前台程序的终端规则。
4. 每 App 的启动规则（启动后首次前台）或激活规则（从后台返回）。
5. 全局启动或激活策略。
6. 不自动切换。

浏览器规则使用当前浏览器上报的页面 URL；TypeLock 不提供单独的“地址栏聚焦”规则。

## 🖥️ 设置

设置窗口包含：

- **通用** — 登录时启动、启动时输入法、全局默认规则、数据版本、配置备份。
- **自定义 App** — 每个 App 的启动和激活规则。
- **输入法提示** — 开关、仅变化时提示、光标优先、时长、位置、光标锚定、对齐、间距、样式、尺寸、Caps Lock、常驻显示、每输入法外观。
- **输入法快捷键** — 每个输入法的全局快捷键。
- **浏览器与域名** — 精确域名、后缀和 URL 正则规则。
- **终端规则** — 程序名到输入法的规则。
- **应用排除** — 切换排除和提示排除两栏。
- **故障排查** — 权限状态、CJKV 焦点修复、光标卡顿修复。
- **关于** — 版本、项目链接、问题反馈、Beta 更新。

## 🌐 浏览器支持

TypeLock 会从以下浏览器读取当前 URL：

- Safari、Safari Technology Preview
- Chrome、Chromium、Thorium
- Edge
- Firefox、Firefox Developer Edition、Firefox Nightly
- Brave、Brave Beta、Brave Nightly
- Arc、Vivaldi、Opera、Zen、Dia、Helium、Comet、Aside、Whale

如果浏览器未通过辅助功能暴露 URL，TypeLock 回退到 App 规则。

## ⌨️ 终端支持

- **Terminal**、**iTerm2** — 通过 AppleScript 获取聚焦 tty。
- **tmux** — 将终端 client tty 映射到当前 pane tty。
- **WezTerm** — 通过 `wezterm cli list --format json` 读取当前 pane。
- **Ghostty**、**Alacritty**、**zellij** 尚未适配，回退到终端 App 规则。

## 🔐 权限

| 权限 | 用途 |
|---|---|
| 辅助功能 | 读取浏览器 URL、文本光标位置、终端 pane 焦点和常驻指示器位置 |
| 自动化 / Apple Events | 向 Terminal 或 iTerm2 查询聚焦 tty |
| 登录项 | 登录时启动 |

TypeLock 不请求屏幕录制权限，也不会上传规则或使用数据。

可选的 Cursor Helper 是独立可执行文件，可能需要单独授予辅助功能权限；不可用时回退到直接读取 Accessibility，再回退到鼠标/屏幕位置。

## 💾 本地数据

配置保存在：

```text
~/Library/Application Support/io.github.zbl-jerry.TypeLock/
```

包括 App 规则、fallback 规则、浏览器规则、终端规则、排除列表、指示器偏好、快捷键偏好、可靠性偏好和切换统计。备份默认包含规则与偏好，不包含统计。

## 📦 安装

TypeLock 以 Universal Binary `.zip` 从 [GitHub Releases](https://github.com/zbl-jerry/TypeLock/releases) 发布；没有 Homebrew cask。当前构建未签名、未公证。

1. 从 Releases 下载最新构建。
2. 将 `TypeLock.app` 移入“应用程序”。
3. 按住 Control 点击 App，选择“打开”并确认。
4. 如果 macOS 仍然阻止，请前往“系统设置 → 隐私与安全性 → 仍要打开”。
5. 授予上述权限。

## 🧭 使用

1. 启动 TypeLock，菜单栏出现图标。
2. 菜单中可配置当前 App、运行中 App、已配置 App、找不到的 App、已忽略 App、切换统计和全局设置。
3. 打开 **设置…** 使用完整规则与指示器编辑器。
4. 配置每 App 的启动/激活规则，再按需添加浏览器、终端和排除规则。
5. 大量修改前可先导出配置，或用于迁移到另一台 Mac。

## 🚧 已知限制

- 不提供每 App“强制英文标点”。
- 不提供每 App 功能键模式。
- 未专门处理 Spotlight、Alfred、Raycast 浮窗仲裁。
- 未适配 Ghostty、Alacritty、zellij 的终端前台程序。
- 浏览器只做 URL/域名匹配，不做独立地址栏聚焦规则。
- Cursor Helper 为 best-effort，需要自身辅助功能权限。
- 日文、韩文、波斯文已翻译常用界面，部分技术/错误文案仍回退英文。
- 发布构建未签名、未公证。

## 🧰 技术栈

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) `1.26.0`
- [Sharing](https://github.com/pointfreeco/swift-sharing) `2.9.1`
- [Sparkle](https://github.com/sparkle-project/Sparkle) `2.9.4`
- CasePaths、Dependencies `1.12.0`、PerceptionCore
- [Tuist](https://github.com/tuist/tuist)：项目生成

## 🧪 开发

### 环境要求

- Xcode 26.3+
- Swift 5.9 语言模式
- macOS 14.0+
- [just](https://github.com/casey/just)
- [Tuist](https://github.com/tuist/tuist)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) `0.62.1`（由 `.swiftformat-version` 固定）

### 工具链固定

- CI 固定 **Xcode 26.3**；`just test` 会拒绝更低版本。
- `swift-dependencies` 固定为 **1.12.0**，传递依赖 `swift-syntax` 固定为 **602.0.0**，因为更新版本要求 Swift 6.3。
- 在 CI 工具链升级前不要提升这些版本。

### 构建与测试

```bash
sudo xcode-select -s /Applications/Xcode-26.3.0.app
tuist generate --no-open
just test
```

运行格式、单元测试、release 脚本和许可证检查：

```bash
just check
```

### CI 与发布

- **Build** 在推送到 `dev` 和手动触发时运行：测试、归档 Universal Binary、打包 `TypeLock-macOS-universal.zip`，并上传 checksums artifact。
- **PR Checks** 在 Pull Request 上运行格式、测试、release 脚本和许可证检查。
- **Release** 由包含于 `dev` 的 annotated `vX.Y.Z` tag 触发，发布 zip、checksums、签名 Sparkle appcast 和 Artifact Attestation。
- `main` 只保留只读历史镜像；TypeLock 的开发、构建和发布都在 `dev`。

## 🧱 项目结构

```text
TypeLock/Sources/App              TCA feature、依赖、切换解析
TypeLock/Sources/Core             模型、存储、URL 辅助
TypeLock/Sources/Services         输入法、浏览器/终端、更新、可靠性
TypeLock/Sources/UI               菜单栏、设置、指示器
TypeLock/Sources/Migrations       schema 版本
TypeLockTests                     XCTest 覆盖
TypeLockCursorHelper              可选 Accessibility helper
Documentation                     当前产品与架构文档
```

## 🙏 致谢

- [SwitchKey](https://github.com/itsuhane/SwitchKey)，一款 macOS 输入法切换工具
- Swift 和 SwiftUI 社区
- 提供反馈的贡献者和用户
