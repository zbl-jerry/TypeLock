# TypeLock 产品与功能文档

| 项目 | 内容 |
|---|---|
| 文档版本 | 1.0（当前实现） |
| 日期 | 2026-11-18 |
| 平台 | macOS 14.0+ |
| 开发分支 | `dev` |
| 工具链 | Xcode 26.3 / Swift 5.9 语言模式 |
| 分发 | GitHub Releases + Sparkle；未签名、未公证；不上架 App Store |

---

## 1. 产品概述

TypeLock 是一款原生 macOS 输入法管理器。它根据当前应用、浏览器域名、终端前台程序以及应用启动/激活时机选择输入法，并提供可选指示器、快捷键、排除列表、配置备份和输入法可靠性修复。

产品以本地规则为核心：不提供账号、云同步或默认遥测。

## 2. 目标用户与场景

- 在多个 App 之间频繁切换、需要为每个 App 保持不同输入法的用户。
- 在同一浏览器访问多语言网站，希望按域名切换输入法的用户。
- 在终端中运行 `nvim`、`ssh`、`claude` 等程序，希望按程序切换输入法的用户。
- 需要全局快捷键、切换提示或排除特定 App 的用户。
- 需要导入/导出配置、在多台 Mac 之间迁移的用户。

## 3. 功能范围

### 3.1 应用规则

每个 Bundle ID 保存两条规则：

- **启动规则**：应用进程启动后的首次前台。
  - 继承全局
  - 不切换
  - 记住上次
  - 固定输入法
- **激活规则**：应用从后台返回前台。
  - 继承全局
  - 不切换
  - 记住上次
  - 固定输入法
  - 忽略

全局规则同样区分启动和激活。应用规则优先于全局规则。

### 3.2 浏览器规则

- 匹配方式：精确域名、域名后缀、完整 URL 正则。
- 通过 Accessibility 读取当前前台浏览器的页面 URL。
- 支持 Safari、Safari Technology Preview、Chrome、Chromium、Thorium、Edge、Firefox 及开发版/Nightly、Brave 及 Beta/Nightly、Arc、Vivaldi、Opera、Zen、Dia、Helium、Comet、Aside、Whale。
- 浏览器未暴露 URL 或规则无效时回退 App 规则。
- 不实现单独的地址栏聚焦规则。

### 3.3 终端规则

- 按终端聚焦 pane 的前台程序名匹配输入法。
- Terminal、iTerm2：通过 AppleScript 获取 tty，再读取前台进程组。
- tmux：将 client tty 映射到当前 pane tty。
- WezTerm：通过 CLI 读取 active pane。
- Ghostty、Alacritty、zellij 暂未适配，回退 App 规则。
- 探针失败、权限拒绝或程序无法识别时回退 App 规则，不阻塞切换。

### 3.4 输入法指示器

- 显示开关、仅在输入法变化时提示、优先/仅文本光标位置。
- 显示时长：1/2/3/5 秒。
- 位置：屏幕或鼠标；9 向对齐；6 档间距。
- 样式：图标+文字、仅图标、仅文字；正常/中等/超大。
- Caps Lock 状态显示。
- 常驻显示：在文本光标位置持续显示当前输入法。
- 每输入法短标签、背景色和文字色。
- 非激活浮层，不抢焦点、不接收鼠标事件。
- 光标不可用时回退鼠标/屏幕位置；仅光标模式下不显示。

### 3.5 输入法快捷键

- 每个输入法可绑定一个全局快捷键。
- 使用 Carbon `RegisterEventHotKey`。
- 支持录制、清除和冲突检测。
- 快捷键属于显式用户操作，不受应用切换排除影响。

### 3.6 排除

两套独立列表：

- **应用切换排除**：不执行自动切换。
- **指示器排除**：正常切换，但不显示指示器。

忽略某个应用会同步加入切换排除；恢复时移除。显式排除与忽略规则在 UI 中统一展示。

### 3.7 可靠性

- **CJKV 修复**：切换成功后短暂改变焦点，让 macOS 落定实际输入法；默认关闭。
- **Cursor Lag Fix**：通过管理员授权关闭 macOS 14 实验性文本光标，缓解输入/光标卡顿；默认关闭。
- **Cursor Helper**：可选独立 helper，在直接 Accessibility 读取失败时提供光标位置；不可用时回退。

### 3.8 配置备份

- JSON 导出/导入。
- 包含 App 规则、全局规则、浏览器规则、终端规则、排除、指示器偏好、快捷键偏好和可靠性偏好。
- 支持合并和替换；导入前校验 schema、Bundle ID 和 fallback 策略。
- 统计默认不导出。
- 备份日期归一化到秒，保证编码/解码稳定。

### 3.9 更新

- Sparkle appcast。
- 稳定通道和 Beta 通道。
- 后台检查只更新菜单状态，不自动弹窗、下载或安装。

### 3.10 本地化

支持 Base（简中）、简中、繁中、英文、日文、韩文、波斯文。新增文案必须保持所有语言的 key 和 placeholder 一致。

## 4. 切换优先级

1. 应用切换排除。
2. 浏览器规则（当前浏览器 URL）。
3. 终端规则（当前终端前台程序）。
4. 应用启动或激活规则。
5. 全局启动或激活规则。
6. 不切换。

解析失败时记录诊断并进入下一级；不会因为浏览器或终端探针失败而中断普通 App 切换。

## 5. 设置窗口

- 通用：登录启动、启动时输入法、全局默认规则、数据版本、配置备份。
- 自定义 App：启动/激活规则；行内显示当前输入法图标和名称，菜单支持图标选择及“使用当前输入法”。
- 输入法提示：显示、位置、对齐、间距、样式、尺寸、Caps Lock、常驻、每输入法外观。
- 输入法快捷键：录制、清除、冲突提示。
- 浏览器与域名：规则增删改、匹配类型、输入法、启停。
- 终端规则：程序名、输入法、启停。
- 应用排除：切换排除和提示排除。
- 故障排查：权限状态、CJKV 修复、Cursor Lag Fix。
- 关于：版本、项目主页、问题反馈、Beta 更新。

菜单栏保留当前 App、运行中/已配置/找不到/已忽略 App、切换统计和快速设置入口。

## 6. 数据模型与存储

存储目录：

```text
~/Library/Application Support/io.github.zbl-jerry.TypeLock/
```

| 文件 | 内容 |
|---|---|
| `app-rules.json` | 每 App 启动/激活规则 |
| `fallback-rule.json` | 全局启动/激活规则 |
| `app-switch-statistics.json` | 成功切换次数 |
| `browser-rules.json` | 浏览器/域名规则 |
| `terminal-rules.json` | 终端程序规则 |
| `exclusions.json` | 切换/指示器排除 |
| `indicator.json` | 指示器偏好和每输入法外观 |
| `hotkeys.json` | 每输入法快捷键 |
| `reliability.json` | CJKV 修复、Cursor Lag Fix |

所有文件带 schema 版本；迁移前备份旧数据。规则写入使用原子文件操作。

## 7. 权限

- **Accessibility**：浏览器 URL、文本光标、终端 pane 焦点、常驻指示器。
- **Automation / Apple Events**：向 Terminal/iTerm2 查询 tty。
- **Login Items**：登录时启动。
- 不申请屏幕录制。
- 权限被拒绝或撤销时提供状态提示并降级，不阻塞核心 App 切换。
- Cursor Helper 可能需要独立 Accessibility 授权。

## 8. 非功能要求

| 维度 | 目标 |
|---|---|
| 切换延迟 | P95 < 100ms（不含系统输入法切换耗时） |
| 指示器延迟 | P95 < 50ms |
| 终端探针 | 前台终端 P95 < 80ms；失焦停止 |
| 空闲 CPU | 平均 < 0.5%；无持续轮询 |
| 内存 | 稳态 < 200MB |
| 崩溃隔离 | Cursor Helper 崩溃不影响主 App |
| 兼容性 | macOS 14.0+，Universal Binary |
| 隐私 | 默认无网络请求（Sparkle 除外） |

这些是验收目标，需在实机和长期运行中持续测量。

## 9. 分发与更新

- 通过 GitHub Releases 发布 Universal Binary zip。
- Sparkle appcast 指向 TypeLock Releases。
- 当前未签名、未公证；用户需按 README 手动放行。
- 不上架 Mac App Store。
- 发布由包含于 `dev` 的 annotated `vX.Y.Z` tag 触发。
- 发布产物包含 zip、checksums、appcast 和 Artifact Attestation。

## 10. 明确不做 / 暂缓

| 功能 | 状态 |
|---|---|
| 每 App 强制英文标点 | 不做。需要事件拦截，权限与稳定性成本过高。 |
| 每 App 功能键模式 | 暂缓。macOS 功能键状态偏全局，可行性未确认。 |
| Spotlight/Alfred/Raycast 浮窗仲裁 | 暂缓。需要额外窗口观察与事件仲裁。 |
| Developer ID 签名与公证 | 暂缓。当前没有证书。 |
| Ghostty/Alacritty/zellij 终端适配 | 暂缓。缺少稳定脚本接口。 |
| 地址栏聚焦规则 | 不做。浏览器规则只基于页面 URL。 |

## 11. 验证与 CI

- 本地：Xcode 26.3 / Swift 6.2.4，Tuist 生成工程，`just test` 执行完整 XCTest。
- 远程：Build workflow 在 `dev` 推送时运行测试、归档 Universal Binary、打包和上传 artifact。
- PR Checks：SwiftFormat、测试、release 脚本和许可证检查。
- Release：仅从 `dev` 的 annotated tag 发布。
- 当前测试规模：225 个 XCTest，0 失败。

## 12. 已知限制

- 未签名、未公证，Gatekeeper 需要手动放行。
- Cursor Helper 是 best-effort，权限和系统版本可能影响效果。
- 日/韩/波斯语部分技术文案仍为英文。
- 浏览器和终端适配依赖第三方应用的 Accessibility/AppleScript 行为，系统或应用更新可能导致回退。
- 指示器常驻模式会周期性读取光标位置，可能增加少量 CPU 占用。

## 13. 术语

| 术语 | 定义 |
|---|---|
| 启动规则 | 应用启动后首次前台使用的规则 |
| 激活规则 | 应用从后台返回前台使用的规则 |
| 跟随上次 | 恢复该应用上次用户选择的输入法 |
| 浏览器规则 | 按页面 URL 匹配的输入法规则 |
| 终端规则 | 按终端前台程序匹配的输入法规则 |
| 指示器 | 输入法切换时显示的非激活浮层 |
| 排除 | 禁用自动切换或指示器反馈 |
| CJKV 修复 | 修复图标已切换但实际输入未生效的问题 |
| Cursor Helper | 辅助读取文本光标位置的独立可执行文件 |
