# Changelog

## v1.0.0

### 🇨🇳 中文

#### 新增

- 每个 App 支持独立的启动规则和激活规则，可继承全局、不切换、记住上次或指定输入法。
- 支持全局启动/激活输入法、浏览器域名/后缀/正则规则、终端程序规则。
- 支持 Terminal、iTerm2、tmux 和 WezTerm 的终端前台程序识别。
- 新增输入法指示器：光标锚定、9 向对齐、间距、尺寸、样式、Caps Lock、常驻显示、每输入法短标签和颜色。
- 新增每个输入法的全局快捷键，支持录制和冲突检测。
- 新增应用切换排除和指示器排除两套独立列表。
- 新增 CJKV 输入法切换修复、Cursor Lag Fix 和可选 Cursor Helper。
- 新增配置导入/导出，支持合并和替换。
- 新增 Beta 更新通道。
- 新增日文、韩文和波斯文界面；常用文案已翻译，部分技术/错误文案暂用英文兜底。
- 设置窗口按通用、自定义 App、输入法提示、快捷键、浏览器与域名、终端、排除、故障排查、关于分组。
- 自定义 App 每行直接显示“启动/激活”当前输入法的图标和名称，菜单项带输入法图标，并提供“使用当前输入法”快捷项。
- 设置窗口移除顶部标题栏和空白 toolbar，内容直接顶到窗口顶部。

#### 变更

- 最低系统版本为 macOS 14.0，发布构建为 Universal Binary。
- 开发和 CI 固定 Xcode 26.3；`swift-dependencies` 固定为 1.12.0，`swift-syntax` 固定为 602.0.0。
- 所有开发和发布在 `dev` 分支进行；`main` 仅保留只读历史镜像。
- 发布 workflow 从 `dev` 的 annotated `vX.Y.Z` tag 触发。
- 构建产物未签名、未公证。

#### 明确不做

- 每 App 强制英文标点。
- 每 App 功能键模式。
- Spotlight、Alfred、Raycast 浮窗仲裁。

### 🇺🇸 English

#### Added

- Per-app launch and activation rules with inherit, no-switch, remember-last, and fixed input-source strategies.
- Global launch/activation strategies, browser domain/suffix/regex rules, and terminal-program rules.
- Terminal program detection for Terminal, iTerm2, tmux, and WezTerm.
- Input-source indicator with caret anchoring, nine alignments, spacing, size, style, Caps Lock, always-on mode, and per-input-source labels/colors.
- Global shortcut per input source with a recorder and conflict detection.
- Separate switching and indicator exclusion lists.
- CJKV focus repair, Cursor Lag Fix, and an optional Cursor Helper.
- Configuration export/import with merge and replace modes.
- Beta update channel.
- Japanese, Korean, and Persian UI; common strings are translated and some technical/error strings currently fall back to English.
- Settings grouped into General, App Rules, Indicator, Hot Keys, Browser & Domains, Terminal Rules, Exclusions, Troubleshooting, and About.
- App Rules rows show the current launch/activation input source with its icon; menus use input-source icons and offer a Use Current Input Method shortcut.
- The settings window removes the title bar and empty toolbar so content starts at the top edge.

#### Changed

- Minimum macOS is 14.0; releases are Universal Binary.
- Development and CI pin Xcode 26.3, `swift-dependencies` 1.12.0, and `swift-syntax` 602.0.0.
- All development and releases happen on `dev`; `main` keeps a read-only history mirror only.
- Releases are triggered by annotated `vX.Y.Z` tags contained in `dev`.
- Builds are unsigned and not notarized.

#### Not Planned

- Per-app forced English punctuation.
- Per-app function-key mode.
- Spotlight, Alfred, and Raycast floating-window arbitration.
