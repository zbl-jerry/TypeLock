# TypeLock 架构

## 1. 目录结构

```text
TypeLock/Sources/App              TCA features、客户端依赖、切换解析
TypeLock/Sources/Core             Codable 模型、存储、URL 辅助
TypeLock/Sources/Services         InputMethod、浏览器、终端、更新、可靠性
TypeLock/Sources/UI               MenuBar、Settings、Indicator
TypeLock/Sources/Migrations       schema 版本
TypeLockTests                     XCTest
TypeLockCursorHelper              可选 Accessibility helper
```

## 2. TCA 结构

- `AppFeature` 是根 reducer，持有规则、排除、指示器、快捷键、可靠性偏好和 `SwitchingFeature.State`。
- `SwitchingFeature` 负责输入法目录、前台事件、启动/激活解析、切换尝试、统计和指示器触发。
- `SwitchResolver` 是无依赖的纯逻辑，负责激活/启动策略和 fallback 归一化。
- 所有外部能力通过 `DependencyKey` 注入：workspace、input method、browser URL、terminal program、hotkey、indicator、reliability、launch at login、app availability。

### 事件流

```text
NSWorkspace activation/launch
  → AppFeature.system(workspaceEvent)
  → SwitchingFeature
  → SwitchResolver
  → InputMethodClient
  → programmaticSwitchFinished
  → statistics / indicator / diagnostics
```

## 3. 切换解析

优先级：

1. `ExclusionsStore.switchingBundleIds`
2. `BrowserRuleMatcher.firstMatch` + `BrowserURLService`
3. `TerminalRulesStore.firstMatch` + `TerminalProgramService`
4. App 启动规则或激活规则
5. 全局启动/激活规则
6. `.none`

`AppFeature` 在 `didLaunchApplicationNotification` 中记录启动候选；该候选在短时间内首次激活时使用启动规则，超时后使用激活规则。

## 4. 持久化

- 使用 `Sharing` 的 `@Shared` + `.fileStorage`。
- 每个领域一个 JSON 文件，见 `Documentation/PRD-TypeLock.md` §6。
- 所有文件带 `v` 字段；`MigrationVersion.current = 2`。
- `AppRuleRecord` 保留旧 `strategy` 作为激活策略；缺失 `launchStrategy` 时默认 `.inherit`。
- `SettingsBackup` 将日期归一化到秒，使用 epoch 秒编码，保证往返稳定。

## 5. 服务

### 输入法

`InputMethodService` 通过 TIS API 枚举、选择和验证输入源。`SwitchingFeature` 只通过 `InputMethodClient` 访问。

### 浏览器

`BrowserURLService` 通过 Accessibility 读取前台浏览器的 focused window/document URL。`BrowserRuleMatcher` 是纯函数，支持精确域名、后缀和正则。

### 终端

`TerminalProgramService`：

- Terminal/iTerm2 → AppleScript 获取 tty。
- tty → `/bin/ps` 前台进程组。
- tmux → client tty 映射 pane tty。
- WezTerm → CLI active pane。
- 所有外部命令使用固定参数，不拼接用户输入。

### 指示器

`IndicatorWindowController` 使用非激活 `NSPanel`：

- `IndicatorLayout` 纯函数计算屏幕、鼠标、光标位置和对齐。
- `CaretLocator` 读取 AX focused element position/size；失败时调用可选 `CursorHelperClient`。
- 常驻模式使用 300ms 循环，只走直接 AX 路径，避免频繁启动 helper。
- `IndicatorView` 根据偏好渲染图标/文字、Caps Lock、尺寸和每输入法颜色/标签。

### 快捷键

`GlobalHotkeyService` 使用 Carbon `RegisterEventHotKey` 注册每个输入法快捷键，事件通过 `HotkeyClient` 进入 `SwitchingFeature`。`HotkeyRecorder` 使用本地 `NSEvent` monitor 捕获组合键并检测冲突。

### 可靠性

- `InputMethodRepairService` 通过短暂焦点窗口让系统落定输入法。
- `CursorLagFixService` 使用 `osascript` + 管理员授权关闭 macOS 14 实验性光标。
- `CursorHelperClient` 启动可选 helper，解析 JSON 光标矩形；失败回退。

## 6. UI

- `TypeLockApp` 提供 `MenuBarExtra` 和 `Settings` scene。
- 菜单栏提供当前 App、运行中/已配置/找不到/已忽略 App、统计、快速设置和关于。
- `SettingsRootView` 使用 `NavigationSplitView`，9 个分组。
- 指示器是独立 `NSPanel`，不参与主窗口生命周期。

## 7. 权限

| 权限 | 代码入口 |
|---|---|
| Accessibility | `PermissionService`、`BrowserURLService`、`CaretLocator`、`TerminalProgramService` |
| Automation / Apple Events | `TerminalProgramService`（NSAppleScript） |
| Login Items | `LaunchAtLoginService` |

权限被拒绝时，服务返回 nil/降级状态，由 UI 显示并提供系统设置入口。

## 8. 构建与 CI

- Tuist 生成工程；`Project.swift` 声明 targets 和 packages。
- CI 固定 Xcode 26.3。
- 直接依赖使用 exact 版本；`swift-dependencies` 1.12.0、`swift-syntax` 602.0.0 为 Swift 6.2 兼容下限。
- `.package.resolved` 是实际解析锁文件，`tuist generate` 不应改写它。
- Build workflow：测试、Universal archive、zip、checksums、artifact。
- Release workflow：annotated `vX.Y.Z` tag、测试、archive、Sparkle appcast、attestation、GitHub Release。

## 9. 测试

- `TypeLockTests` 使用 XCTest，225 个测试。
- 纯逻辑：迁移、`SwitchResolver`、backup、exclusions、indicator layout、hotkeys、browser/terminal matching。
- Reducer：TestStore，所有依赖注入 testValue。
- 本地：`just test` 在 Xcode 26.3 下执行完整测试。
- CI：Build workflow 执行同一测试集并归档。

## 10. 技术限制

- Accessibility 和 AppleScript 行为受第三方应用版本影响。
- Cursor Helper 需要独立权限，未签名时 Gatekeeper 可能阻止。
- 私有的输入法直接激活 API 未使用；CJKV 修复只使用焦点落定。
- Ghostty/Alacritty/zellij 没有稳定接口，当前不检测其前台程序。
- 发布构建未签名、未公证。
