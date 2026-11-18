# TypeLock 产品需求文档（PRD）

> 从轻量菜单栏工具转向全功能输入法场景管理器

| 项目 | 内容 |
|---|---|
| 文档版本 | v0.2（Draft） |
| 日期 | 2026-11-18 |
| 负责人 | zbl-jerry |
| 开发分支 | `dev` |
| 上游基线 | TypeSwitch v0.10.3 |
| 主要竞品 | [KeyboardHolder](https://github.com/leaves615/KeyboardHolder) v1.14.16 |
| 次要竞品 / 工程参考 | [Input Source Pro](https://github.com/runjuu/InputSourcePro)（GPL-3.0） |
| 分发方式 | 官网/GitHub Releases 直链下载 + Sparkle；不上架 App Store |
| 实现策略 | 产品行为可借鉴，源码不复制；独立实现 |
| 文档状态 | 待评审，未提交代码 |

---

## 0. 摘要

TypeLock 当前是 TypeSwitch 的轻量 fork：纯菜单栏、低权限、按 App 激活切换输入法，附带规则管理、切换统计和输入法诊断。

本 PRD 确认一次产品定位调整：

> **“轻量”不再是目标。TypeLock 要在保留现有稳定性与可观测性的基础上，先补齐 KeyboardHolder 的全部产品能力，再吸收 Input Source Pro 在终端规则、Indicator、快捷键和输入法可靠性上的高阶能力，成为 macOS 上面向多输入法重度用户的完整输入法场景管理器。**

这意味着产品需要新增：独立设置窗口、每 App 双时机规则、全局启动/激活规则、输入法 HUD/Indicator、输入法快捷键、浏览器地址栏与域名规则、终端规则、应用排除、特殊 App/浮窗支持、配置导入导出、权限向导、输入法可靠性修复等能力，并接受辅助功能（Accessibility）、Input Monitoring、Apple Events 权限带来的复杂度。

**全功能不等于云端化。** 配置、规则和统计仍只保存在本地，默认不引入遥测。

**分发约束。** TypeLock 不走 App Store，采用直链下载 + Sparkle 更新。因此不受沙盒和 App Review 限制，但仍需对辅助功能授权、私有 API 风险、Helper 签名与公证负责。

**实现边界。** KeyboardHolder 与 Input Source Pro 只作为产品行为和工程思路参考；Input Source Pro 为 GPL-3.0，TypeLock 为 MIT，禁止复制其源码、注释、素材或测试。所有实现必须独立完成，详见 2.8。

---

## 1. 背景与决策

### 1.1 当前产品现状

TypeLock 继承自 TypeSwitch，现有能力包括：

- 纯菜单栏 `MenuBarExtra`，`LSUIElement = true`，无独立设置窗口。
- 每个 App 一条策略：`默认 / 记住上次切换 / 指定输入法 / 忽略`。
- 一条“未配置 App 的默认规则”。
- 监听 `NSWorkspace.didActivateApplicationNotification` 执行切换；`didLaunchApplicationNotification` 只刷新运行列表。
- 运行中/已配置/未配置/找不到的 App 分组，忽略 App 可恢复。
- 每 App 与总成功切换次数统计。
- 输入法目录读取失败、切换失败的重试与诊断入口。
- 登录时启动（Login Items + LaunchAgent 兜底）。
- Sparkle 静默检查与手动更新。
- 简中/繁中/英文三语本地化。
- 最低 macOS 14.0，Universal Binary，`dev` 分支构建与发布。

当前数据模型的关键限制：`AppRuleRecord` 只有一个 `strategy` 字段，无法表达“启动时”和“激活时”两套规则。

### 1.2 定位调整

| 维度 | 旧定位 | 新定位 |
|---|---|---|
| 产品形态 | 菜单栏小工具 | 菜单栏快捷入口 + 完整设置窗口 |
| 功能范围 | 按 App 切换输入法 | 覆盖应用、启动/激活、浏览器、域名、浮窗、快捷键、HUD |
| 权限策略 | 尽量低权限 | 为能力接受辅助功能、Input Monitoring、Apple Events，但必须可解释、可降级 |
| 复杂度 | 刻意克制 | 接受复杂度，以稳定性和可测试性兜底 |
| 竞品目标 | TypeSwitch | KeyboardHolder 功能对齐 + Input Source Pro 高阶能力吸收 |
| 分发方式 | GitHub Releases | 直链下载 + Sparkle，不上架 App Store |
| 实现方式 | 直接改写上游 | 行为借鉴、独立实现，不复制第三方源码 |

### 1.3 一句话定位

> TypeLock 记住每个 App、每个网站、每个启动场景该用哪种输入法，并在切换时给出明确反馈。

### 1.4 产品目标

1. **KeyboardHolder 功能对齐**：KeyboardHolder v1.14.16 的公开产品能力，TypeLock 都要有对应实现。
2. **Input Source Pro 高阶能力吸收**：终端规则、增强 Indicator、快捷键组/纯修饰键、CJKV 修复等，纳入产品范围。
3. **可靠性优先**：输入法切换失败、误切换、浮窗抢焦点、浏览器多进程、终端 pane 识别等问题必须有明确处理与诊断。
4. **可迁移**：现有 TypeLock/TypeSwitch 用户升级后规则不丢失；配置可导入导出。
5. **可解释**：新增权限、Indicator、域名/终端规则都要有清晰的产品说明和降级路径。
6. **保留优势**：切换统计、失效 App 清理、输入法诊断、多语本地化、菜单栏快捷操作继续保留。
7. **合规实现**：只借鉴产品行为与公开工程结论，不复制 GPL/无许可证项目的源码与素材。

### 1.5 非目标

- 不做账号体系、云同步、团队策略下发。
- 不做默认遥测；诊断信息只在用户主动复制/导出时离开本机。
- **不上架 Mac App Store**；不为此牺牲辅助功能、Helper、非沙盒能力。
- 不复用 KeyboardHolder 的代码或素材。其仓库当前只有 README、无可见许可证与源码，本 PRD 仅做产品能力调研。
- 不复用 Input Source Pro 的代码、注释、素材或测试。其许可证为 GPL-3.0，与 TypeLock 的 MIT 不兼容；只参考公开行为、文档和架构思路。
- 不改变 `main` 追踪上游、`dev` 开发发布的仓库模型。
- 不把 TypeLock 做成通用键盘映射工具（如 Karabiner）；输入法仍是核心对象。

---

## 2. 竞品调研

### 2.1 KeyboardHolder 能力盘点

调研来源：用户提供的 v1.14.16 设置界面截图、GitHub README、官网、GitHub Releases。

| 模块 | 能力 |
|---|---|
| 产品定位 | 按应用、网站、场景自动切换输入法；记忆每个 App 上次输入法 |
| 通用 | 登录启动、启动后显示配置窗口、状态栏图标显示/隐藏状态保持、显示程序坞图标 |
| 全局输入法 | 应用启动时输入法、应用激活时输入法 |
| 浏览器 | 地址栏定制：地址栏聚焦时切换输入法，支持 Safari/Chrome/Edge/Firefox；后续版本增加 Brave、Zen、Chrome 多通道 |
| 配置 | 导入/导出 |
| 每 App | “启动”和“激活”两套独立输入法规则 |
| 排除 | 应用排除，分为“应用切换”和“输入法提示”两栏 |
| HUD | 开关、仅变化时提示、优先光标位置、仅光标位置、显示时长 1/2/3/5 秒、光标上方/下方/右侧、屏幕/鼠标位置、图标+文字/仅图标/仅文字、正常/中等/超大 |
| 快捷键 | 每个输入法设置全局快捷键 |
| 域名 | 按网站域名匹配输入法规则 |
| 特殊 App | Spotlight、Alfred、Raycast；VNC 远程桌面；浮窗显示/关闭后的输入法恢复 |
| 关于 | 自动检查更新、检查间隔、版本、网站、问题反馈、Star、捐赠 |
| 权限 | 辅助功能权限授权向导（v1.14.2 起） |
| 兼容性 | 官网标注 macOS 11+；持续适配 macOS 26 |

### 2.2 KeyboardHolder 的工程经验（来自 release notes）

这些不是功能，但会直接影响 TypeLock 的实现难度：

- 浏览器多开/自动化实例时，地址栏切换可能只对一个进程生效。
- Raycast 等悬浮窗口显示期间，底层 App 的窗口事件会抢走输入法切换。
- 悬浮窗口隐式关闭、连续弹出时需要恢复原输入法。
- 浏览器地址栏识别在 Firefox、Chrome、Brave、Zen 上存在差异。
- 休眠唤醒后域名规则可能失效；需要监听唤醒并重建状态。
- 辅助功能观察者需要专用线程，避免主线程阻塞与跨线程崩溃。
- 登录启动需要 helper 兜底，降低开机自启失败率。

**结论**：功能对齐不难，难的是这些边界场景。PRD 必须把“特殊 App/浮窗/浏览器多进程/睡眠唤醒”作为一等需求，而不是上线后补丁。

### 2.3 Input Source Pro 能力盘点

调研来源：本地源码 `~/workspace/tmp/KeyboardHolder/InputSourcePro`，以及 GitHub README、release notes。Input Source Pro 为 GPL-3.0，Xcode 27 / Swift 6.4，最新稳定版 2.14.0。

| 模块 | 能力 |
|---|---|
| 设置结构 | General；Rules（App/Browser/Terminal）；Indicator（Position/Appearance/Color Scheme）；Keyboard（Hot Keys）；Others（Troubleshooting） |
| 全局输入法 | 所有 App 和网站的统一默认输入法；恢复策略（恢复上次 / 使用默认） |
| App Rules | 每 App 默认输入法、恢复策略覆盖、隐藏 Indicator、强制英文标点、功能键模式（标准/媒体/跟随全局） |
| Browser Rules | 地址栏默认输入法；`DOMAIN-SUFFIX`、`DOMAIN`、`URL-REGEX` 三种匹配；每规则恢复策略/隐藏 Indicator/启停；21 个浏览器变体 |
| Terminal Rules | 按终端当前前台程序切换输入法；支持 Ghostty、iTerm2、Terminal、WezTerm、Alacritty；识别 tmux/zellij pane；支持终端浮窗 |
| Indicator | 切换 App/输入法、聚焦变化、长按鼠标、Caps Lock 触发；跟随鼠标/相对 App/相对屏幕；9 向对齐；XS–XL 间距；图标/文字/两者；小中大；浅色/深色；每输入法配色；Always-on 跟随光标 |
| Hot Keys | 每输入法快捷键；快捷键组循环；普通快捷键或纯修饰键组合；按一次/连按两次；功能键模式切换快捷键；冲突检测 |
| 可靠性 | CJKV 输入法失效修复（焦点切换/快捷键模拟/私有 API 直接激活）；Cursor Lag Fix；睡眠/锁屏恢复 |
| 配置 | 导出/导入 JSON；`inputsourcepro://import?path=...` 脚本化导入 |
| 更新 | 自动检查、Beta 通道、Sparkle |
| 权限 | Accessibility（Enhanced Mode）、Input Monitoring（纯修饰键）、Apple Events（终端 pane） |
| 本地化 | en、zh-Hans、zh-Hant、ja、ko、fa |
| 分发 | 官网直链、公证 DMG、stable/beta 双通道 |

### 2.4 三方能力对比

说明：TypeLock 依据当前 `dev` 代码；KeyboardHolder 依据截图、README、Release Notes；Input Source Pro 依据源码。“未见”表示公开资料或源码中未发现，不代表绝对没有。

| 能力 | TypeLock | KeyboardHolder | Input Source Pro |
|---|---|---|---|
| 独立设置窗口 | 无 | 有 | 有 |
| 每 App 默认输入法 | 有（单一策略） | 有 | 有 |
| 每 App 启动/激活双规则 | 无 | **有** | 无 |
| 全局启动/激活默认输入法 | 无（只有激活默认） | **有** | 只有全局默认 + 恢复策略 |
| 输入法记忆/恢复上次 | 有（显式跟随上次） | 有 | 有（全局策略 + 每 App 覆盖） |
| 强制英文标点 | 无 | 未见 | **有** |
| 每 App 功能键模式 | 无 | 未见 | **有** |
| 浏览器地址栏规则 | 无 | 有 | 有 |
| 域名规则 | 无 | 有 | 有（含正则） |
| 浏览器覆盖 | 0 | 6 类 | **21 个变体** |
| 终端前台程序规则 | 无 | 未见 | **有，5 终端 + tmux/zellij** |
| 切换提示 HUD | 无 | 有 | 有 |
| Always-on Indicator | 无 | 未见 | **有** |
| Indicator 9 向对齐/间距/配色 | 无 | 未见 | **有** |
| Caps Lock 状态提示 | 无 | 未见 | **有** |
| 每输入法快捷键 | 无 | 有 | 有 |
| 快捷键组/循环 | 无 | 未见 | **有** |
| 纯修饰键/连按两次 | 无 | 未见 | **有** |
| Spotlight/Alfred/Raycast | 无 | 有 | 有（Enhanced Mode） |
| VNC 等特殊 App | 无 | 有（release notes） | 未单独验证 |
| 应用排除（切换/HUD 分列） | 部分（Ignore） | **有** | 无独立列表，只有每 App 隐藏 Indicator |
| 配置导入/导出 | 无 | 有 | 有（含脚本化导入） |
| 更新间隔设置 | 无 | 有 | 自动检查 + Beta 通道 |
| CJKV 输入法失效修复 | 无 | 未见 | **有，3 种策略** |
| 切换统计 | **有** | 未见 | 未见 |
| 失效 App 清理 | **有** | 未见 | 未见 |
| 输入法异常诊断/重试 | **有** | 未见 | 有 Troubleshooting |
| 本地化 | 3 语 | 截图为中文 | **6 语** |
| 辅助功能权限 | 不需要 | 需要 | Enhanced Mode 可选；浏览器/光标需要 |
| Input Monitoring | 不需要 | 未见 | 纯修饰键快捷键需要 |
| 私有 API | 无 | 未知 | 有（实验性 Direct Activation） |
| App Store | 否 | 未知 | 否（官网/DMG） |
| 许可证 | MIT | 仓库无可见许可证 | **GPL-3.0** |

### 2.5 Input Source Pro 的工程经验

- 光标跟随不是简单读一次 AX：需要专用 Cursor Helper、AX focused element/bounds、坐标过滤和重试。
- 浏览器地址栏识别必须在每个浏览器上单独适配；标签页/窗口/多进程/睡眠唤醒都会影响结果。
- 终端规则依赖 AppleScript 询问终端当前 pane，再读 tty 的前台进程；tmux/zellij 需要额外的 multiplexer 解析。
- 浮窗/启动器需要维护前台场景栈，处理显示、隐式关闭、连续弹出和底层窗口事件抢占。
- 纯修饰键快捷键需要 Input Monitoring；普通组合键可用 Carbon，不需要 AX。
- macOS 存在“图标已切换但实际输入法未生效”的 CJKV 问题，需要独立的可靠性修复策略。
- 私有 API 直接激活输入法被标注为实验性，说明其收益与风险并存。
- Core Data + UserDefaults 适合大量规则与迁移，但引入模型版本管理成本；TypeLock 当前 JSON 方案需要重新评估规模上限。

### 2.6 其他参考

- **TypeSwitch（上游）**：菜单栏形态、低权限、规则与统计、诊断能力，是 TypeLock 的现有基础。
- **SwitchKey**：早期同类产品，作为交互参考。
- **Input Source Pro**：高阶能力与工程边界参考，不纳入代码复用范围。

### 2.7 竞品启示

1. KeyboardHolder 的核心不是“指定输入法”，而是**默认记忆 + 可覆盖**；双时机规则是它最独特的产品抽象。
2. Input Source Pro 的核心是**上下文 + 恢复策略**，并用终端规则、Indicator、快捷键组把“输入法场景管理”做得更深。
3. TypeLock 的最佳组合是：KeyboardHolder 的双时机规则 + Input Source Pro 的 Indicator/终端/快捷键/可靠性修复 + 自有的统计与诊断。
4. HUD、快捷键、域名/终端规则都依赖复杂系统集成，必须按“场景解析 → 统一切换 → 反馈 → 诊断”的链路设计。
5. 权限不是一次性弹窗，而是需要向导、状态检查、失败降级和重新授权入口。
6. 竞品 release notes 已经暴露大量边界条件，TypeLock 应在设计阶段覆盖，而不是上线后补丁。

### 2.8 实现借鉴与许可证边界

**结论：可以阅读源码理解行为，不可以复制源码。**

| 项目 | 许可证 | 允许 | 禁止 |
|---|---|---|---|
| TypeSwitch / TypeLock 上游 | MIT | 修改、分发、再许可 | 删除原版权声明 |
| KeyboardHolder | 仓库无可见许可证、无源码 | 参考公开行为、截图、release notes | 复制素材、二进制逆向抄袭 |
| Input Source Pro | GPL-3.0 | 阅读源码理解行为、算法思路、系统 API 用法 | 复制代码/注释/测试/素材；把 GPL 代码链接进 MIT 项目 |

**独立实现规范**

1. 需求文档只描述“做什么”和“验收标准”，不粘贴第三方源码。
2. 实现前由工程侧独立设计数据结构、函数命名和测试；不得逐行对照翻译。
3. 需要参考某个系统 API 用法时，优先查 Apple 官方文档；确需阅读第三方实现时，只记录“使用了哪个 API/解决了什么边界”，不保留代码片段。
4. 代码审查增加许可证检查：新增文件不得包含第三方版权头、相同注释、相同测试夹具或相同 UI 素材。
5. 不复制第三方 App 图标、截图、文案、颜色方案和设置界面布局；交互可以借鉴，视觉必须独立。
6. 如未来确需使用 GPL 代码，必须单独评估并取得授权，不能默默并入 `dev`。

---

---

## 3. 用户与场景

### 3.1 目标用户

| 用户 | 特征 | 核心诉求 |
|---|---|---|
| 双语开发者 | 终端、IDE、浏览器、IM 频繁切换 | 终端/IDE 英文，聊天中文；切换后立即可输入 |
| 多输入法重度用户 | 简中、繁中、英文、日文、韩文 | 每个 App/网站记住上次输入法 |
| 浏览器工作者 | 同一浏览器访问中外文网站 | 按域名或地址栏自动切换 |
| 快捷键用户 | 不愿频繁点菜单栏 | 每个输入法一个全局快捷键 |
| 多任务用户 | 大量 App、浮窗启动器、远程桌面 | 浮窗/远程桌面也能正确切换并恢复 |

### 3.2 核心用户故事

1. 作为开发者，我切到 iTerm2 时希望自动使用英文输入法，切回飞书时恢复中文。
2. 作为双语用户，我希望每个 App 默认记住上次输入法，不需要逐个配置。
3. 作为浏览器用户，我希望地址栏聚焦时自动切英文，点击网页正文后恢复该域名的输入法。
4. 作为 Raycast 用户，我希望唤起 Raycast 时用英文，关闭后回到原 App 的输入法。
5. 作为多输入法用户，我希望给拼音、ABC、日文分别设置快捷键。
6. 作为换机用户，我希望导出配置并在新机器导入，不用重新配置几十个 App。
7. 作为新用户，我希望知道为什么需要辅助功能权限，以及拒绝后哪些功能不可用。

### 3.3 关键旅程

**首次启动**
安装 → 欢迎页说明核心能力 → 权限向导（可跳过）→ 选择默认激活策略 → 进入设置窗口/菜单栏 → 试切换。

**日常使用**
App 激活 → 解析场景（浮窗/浏览器/域名/App）→ 计算目标输入法 → 切换 → HUD 提示 → 记录统计与失败诊断。

**换机/重装**
导出配置 → 新机导入 → 校验兼容性 → 合并/替换 → 重新授权辅助功能 → 验证规则。

---

## 4. 产品范围与优先级

### 4.1 优先级定义

- **P0**：没有它就无法称为 KeyboardHolder 同级产品；核心闭环。
- **P1**：主要差异化能力；决定用户是否长期留存。
- **P2**：完善度与边缘能力；可在核心能力之后补齐。

### 4.2 功能清单

| ID | 功能 | 优先级 | 阶段 |
|---|---|---|---|
| F-01 | 设置窗口与侧边栏导航 | P0 | Phase 0 |
| F-02 | 通用设置（登录、启动窗口、状态栏、Dock） | P0 | Phase 1 |
| F-03 | 全局启动/激活输入法策略 | P0 | Phase 1 |
| F-04 | 每 App 双时机规则 | P0 | Phase 1 |
| F-05 | 输入法记忆/跟随上次 | P0 | Phase 1 |
| F-06 | 应用排除（切换/提示分栏） | P0 | Phase 1 |
| F-07 | 配置导入/导出 | P0 | Phase 1 |
| F-08 | 更新设置与关于页 | P0 | Phase 1 |
| F-09 | 菜单栏快捷入口 | P0 | Phase 1 |
| F-10 | 数据迁移与兼容 | P0 | Phase 0/1 |
| F-11 | 输入法 HUD/Indicator 基础 | P1 | Phase 2 |
| F-12 | 输入法全局快捷键 | P1 | Phase 2 |
| F-13 | 特殊 App 与浮窗 | P1 | Phase 2 |
| F-14 | 浏览器地址栏规则 | P1 | Phase 3 |
| F-15 | 域名规则 | P1 | Phase 3 |
| F-16 | 权限向导（AX / Input Monitoring / Apple Events） | P1 | Phase 0/2 |
| F-17 | 状态栏/程序坞图标控制 | P2 | Phase 2 |
| F-18 | 统计与诊断增强 | P2 | Phase 4 |
| F-19 | 本地化与无障碍 | P2 | Phase 4 |
| F-20 | 终端规则（按终端前台程序切换） | P1 | Phase 3 |
| F-21 | 每 App 强制英文标点 | **不做（已禁用）** | — |
| F-22 | 每 App 功能键模式 | **暂缓** | — |
| F-23 | Indicator 进阶（Always-on/9 向/间距/配色/Caps Lock） | P1 | Phase 2 |
| F-24 | 快捷键组、纯修饰键、连按两次 | P1 | Phase 2 |
| F-25 | 浏览器规则扩展（正则、21 个浏览器变体） | P2 | Phase 3 |
| F-26 | 输入法切换可靠性修复（CJKV） | P1 | Phase 4 |
| F-27 | 光标体验修复与 Cursor Helper | P2 | Phase 4 |
| F-28 | Beta 更新通道 | P2 | Phase 4 |
| F-29 | 脚本化导入（URL Scheme） | P2 | Phase 1 |
| F-30 | 本地化扩展（ja / ko / fa） | P2 | Phase 4 |
| F-31 | 直链分发、签名与公证 | P1 | Phase 4 |
| F-32 | 独立实现与许可证合规审查 | P0 | 全阶段 |

> **范围决策（2026-11-18）**：F-21 永久禁用；F-22 暂缓，不进入本期；F-13 暂缓，先不处理。

---

## 5. 信息架构与交互

### 5.1 设置窗口

左侧导航融合 KeyboardHolder 的规则模型与 Input Source Pro 的模块划分：

1. **通用**：登录、启动窗口、状态栏、Dock、全局启动/激活输入法、恢复策略、默认功能键、配置导入导出、更新通道。
2. **自定义 App**：App 列表 + 启动/激活双规则 + 隐藏 Indicator + 恢复策略覆盖。
3. **输入法提示**：触发条件、位置、Always-on、9 向对齐、间距、样式、尺寸、颜色、Caps Lock。
4. **输入法快捷键**：每输入法快捷键、快捷键组、纯修饰键、冲突检测。
5. **浏览器与域名**：地址栏默认输入法、域名/后缀/正则规则、浏览器开关。
6. **终端规则**：终端启用开关、前台程序 → 输入法映射。
7. **应用排除**：应用切换 / 输入法提示两栏。
8. **故障排查**：权限状态、CJKV 修复、Cursor Lag、诊断导出。
9. **关于**：更新、版本、链接、反馈、隐私说明。

窗口要求：

- 独立 `NSWindow`，可调整大小，记住位置与尺寸。
- 菜单栏保留“打开设置…”入口；设置窗口与菜单共享同一状态。
- 无程序坞图标时，窗口仍可正常前置与聚焦；显示程序坞图标时切换为 `.regular`。
- 关闭窗口不退出 App；`⌘,` 打开设置。

### 5.2 菜单栏

保留现有快速操作，新增：

- 打开设置…
- Indicator 开关（快捷）
- 当前 App 加入排除（切换/提示）
- 当前 App 的启动/激活规则快捷入口
- 当前浏览器域名快捷加入规则（辅助功能可用时）
- 当前终端程序快捷加入终端规则（终端可用时）
- 修复当前输入法（CJKV Fix）
- 打开故障排查

### 5.3 首次启动与权限

- 欢迎页说明：App 规则、网站规则、终端规则、启动/激活、Indicator。
- 权限向导：
  - **辅助功能 / Enhanced Mode**：光标定位、地址栏、域名、Spotlight 类浮窗。
  - **Input Monitoring**：纯修饰键快捷键。
  - **Apple Events**：向终端查询当前 pane。
  - **登录项**：登录时启动。
- 每项权限显示：用途、影响的功能、当前状态、打开系统设置、重新检查。
- 拒绝辅助功能时：核心 App 切换仍可用；光标定位、地址栏、域名、浮窗能力降级并明确标注。
- 拒绝 Input Monitoring 时：普通组合键快捷键仍可用，纯修饰键模式禁用。
- 拒绝 Apple Events 时：终端规则禁用，不影响其他规则。

### 5.4 状态栏与 Dock 的兜底

- 状态栏图标和程序坞图标允许分别隐藏，但**不允许同时不可达**：
  - 两者都关闭时，设置页阻止保存并提示“至少保留一个入口”。
  - 若通过升级/导入产生该状态，启动时自动恢复状态栏图标。
- 状态栏隐藏后，仍可通过重新打开 App 或 `⌘,`（窗口存在时）进入设置。

### 5.5 分发形态

- **不上架 Mac App Store**。
- 通过 GitHub Releases / 官网直链分发 `.dmg` 或 `.zip`，Sparkle 负责更新。
- 默认保持非沙盒，以便使用辅助功能、Apple Events、Input Monitoring、Helper 与系统级快捷键。
- 签名与公证策略：
  - 短期：沿用当前未签名 Universal Binary，用户手动放行。
  - 目标：使用 Developer ID Application 签名并公证，降低 Gatekeeper 摩擦。
  - Helper / Cursor Helper 必须与主 App 同一 Team ID 并一起签名。
- 不因 App Store 审核限制而放弃产品能力；但仍需避免不必要的私有 API，实验性能力必须可关闭。

---

## 6. 功能需求

### F-01 设置窗口与导航

**需求**

- 新增独立设置窗口，包含上述 9 个栏目。
- 窗口状态、栏目选中状态持久化。
- 所有设置修改即时生效，不需要“保存”按钮。
- 危险操作（替换导入、清空规则）二次确认。

**验收**

- 菜单栏与 Dock 均可打开设置。
- 关闭/重开窗口保留栏目与尺寸。
- 无程序坞图标时窗口仍能获得焦点。
- 各语言切换后栏目与文案正确。

### F-02 通用设置

**需求**

| 设置项 | 行为 |
|---|---|
| 登录时启动 | 复用现有 Login Items + LaunchAgent 兜底；显示系统审批状态 |
| 启动后显示配置窗口 | 默认关闭；开启后冷启动打开设置窗口 |
| 启动时保持状态栏图标显示/隐藏状态 | 关闭时每次启动强制显示；开启时沿用上次状态 |
| 显示程序坞图标 | 切换 `NSApplication` 激活策略；默认关闭 |
| 配置导入/导出 | 见 F-07 |

**验收**

- 登录项被系统禁用时，设置页给出“前往系统设置”入口。
- 切换 Dock 图标后无需重启 App。
- 状态栏与 Dock 同时隐藏时被阻止。

### F-03 全局输入法策略

**需求**

- **启动策略**：App 进程启动后首次进入前台时使用。
- **激活策略**：App 从后台切回前台时使用。
- 策略选项：
  - 不切换
  - 跟随上次（推荐默认）
  - 固定输入法
- 两种策略互不影响；每 App 可覆盖。

**验收**

- 首次安装默认激活策略为“跟随上次”，启动策略为“不切换”（见开放问题 Q1）。
- 固定输入法不可用时给出诊断，不静默失败。
- 修改全局策略后，未单独配置的 App 立即生效。

### F-04 每 App 双时机规则

**需求**

- 自定义 App 列表：添加、删除、搜索、显示图标/名称/Bundle ID。
- 每行两个规则：
  - 启动：继承全局 / 不切换 / 跟随上次 / 固定输入法
  - 激活：继承全局 / 不切换 / 跟随上次 / 固定输入法
- 支持批量恢复默认、清理失效 App。
- 忽略 App 语义迁移为“应用切换排除”，同时保留原规则以便恢复。

**数据模型**

`AppRuleRecord` 从单一 `strategy` 扩展为：

```swift
struct AppRuleRecord {
    let bundleId: String
    var lastKnownPath: String?
    var lastKnownName: String
    var launchStrategy: AppLaunchStrategy      // inherit / none / fixed / followLast
    var activationStrategy: InputMethodStrategy // none / fixed / followLast / ignored
    var strategyBeforeIgnoring: InputMethodStrategy?
    var createdAt: Date
    var updatedAt: Date
}
```

迁移规则：

- 旧 `strategy` → `activationStrategy`。
- `launchStrategy` 统一设为 `inherit`，保持升级前后行为一致。
- `ignored` 与 `strategyBeforeIgnoring` 保留，并同步到应用切换排除列表。
- 写入 schema 版本；迁移前备份旧文件。

**验收**

- 升级后现有规则完全保留。
- 启动规则只在进程启动后的首次前台触发；后续前台使用激活规则。
- 忽略/恢复行为与旧版本一致。
- 双规则在菜单栏与设置窗口显示一致。

### F-05 输入法记忆/跟随上次

**需求**

- 默认记忆每个 App 上次手动使用的输入法。
- 程序切换自身触发的选择不能被记录为“用户手动选择”，避免污染记忆。
- 记忆按 App 隔离；浏览器场景按 App + 域名隔离（见 F-15）。
- 用户可在每 App 规则中选择“跟随上次”或覆盖为固定值。

**验收**

- 在 App A 手动切到拼音，切到 B 再回 A，恢复拼音。
- 程序自动切换不改变记忆值。
- 输入法被删除后，记忆失效并回退到全局策略。

### F-06 应用排除

**需求**

- 两栏独立列表：
  - 应用切换排除：不执行任何自动切换。
  - 输入法提示排除：正常切换，但不显示 HUD。
- 支持添加运行中 App、手动输入 Bundle ID、删除。
- 排除优先级最高，优先于 App/域名/地址栏规则。
- 与“忽略 App”合并或明确映射，避免两套语义并存。

**验收**

- 同一 App 可只排除 HUD 而保留切换。
- 排除后菜单栏和设置页状态一致。
- 添加/删除立即生效，无需重启。

### F-07 配置导入/导出

**需求**

- 导出格式：JSON，包含 `schemaVersion`、导出时间、App 版本、偏好、App 规则、域名规则、快捷键、排除列表；统计默认不导出，可选。
- 导入模式：合并 / 替换。
- 替换前自动备份当前配置；导入失败不修改现有配置。
- 路径不写入导出文件（或导入时忽略），使用 Bundle ID 重新解析。
- 导入校验：版本、字段类型、重复项、非法输入法 ID、非法快捷键。

**验收**

- 导出 → 清空 → 导入，规则与偏好完全一致。
- 合并导入时冲突项按明确规则处理（建议导入覆盖本地，并在结果页列出变更）。
- 非法 JSON/未知版本给出可读错误，不崩溃。
- 导入 1 万条规则在 1 秒内完成（目标值，需实测）。

### F-08 更新设置与关于页

**需求**

- 自动检查更新开关。
- 检查间隔：每次启动 / 每天 / 每周 / 手动。
- 版本号、构建号、网站、问题反馈、更新日志入口。
- 保留“复制诊断信息”。
- Star/捐赠入口：作为可选 P2；fork 使用自己的链接，不复用上游收款方式。

**验收**

- 间隔设置持久化并实际影响 Sparkle 调度。
- 关闭自动检查后不再后台请求 appcast。
- 版本信息与 Info.plist 一致。

### F-09 菜单栏快捷入口

**需求**

- 保留现有菜单结构与快捷操作。
- 新增“打开设置…”、HUD 开关、排除快捷入口。
- 菜单项状态与设置窗口双向同步。

**验收**

- 菜单修改后设置页即时反映，反之亦然。
- 无设置窗口时菜单功能完整可用。

### F-10 数据迁移与兼容

**需求**

- 旧版 `app-rules.json`、`fallback-rule.json`、`app-switch-statistics.json` 自动迁移到 schema v2。
- 旧 `strategy` 映射为 `activationStrategy`；`launchStrategy` 设为继承，保持升级前后行为一致。
- 迁移前写入 `backups/`；迁移失败进入只读安全模式，不覆盖旧文件。
- 导入的旧格式配置按同一规则迁移。
- 记录迁移版本，避免重复迁移。

**验收**

- 升级后现有规则、忽略状态、统计不丢失。
- 迁移失败可回滚到旧文件。
- 重复启动不重复迁移。
- 导出 schema 版本与当前版本一致。

### F-11 输入法 Indicator 基础（HUD）

**需求**

| 设置 | 选项 |
|---|---|
| 启用提示 | 开/关 |
| 仅在输入法变化时提示 | 开/关 |
| 优先在文本光标位置显示 | 开/关 |
| 仅在文本光标位置显示 | 开/关 |
| 显示时间 | 1 / 2 / 3 / 5 秒 |
| 光标提示位置 | 上方 / 下方 / 右侧 |
| 提示窗口位置 | 基于屏幕 / 鼠标位置 |
| 提示样式 | 图标+文字 / 仅图标 / 仅文字 |
| 提示尺寸 | 正常 / 中等 / 超大 |

**行为定义**

- 优先级：光标位置（需辅助功能）> 鼠标位置 > 屏幕位置。
- “仅在光标位置显示”开启且辅助功能不可用时：不显示 HUD，并在设置页提示原因。
- HUD 不抢焦点、不接收鼠标事件、不进入任务切换。
- 支持多显示器、Retina/非 Retina、全屏 App、浅色/深色。
- 程序切换失败时不显示成功提示；显示失败状态或诊断入口。
- 相同输入法的重复切换不重复弹窗（除非关闭“仅变化时提示”）。

**验收**

- 6 种位置组合均不超出屏幕边界。
- 全屏 App 上可见；切换 Space 后不残留。
- HUD 出现/消失无明显闪烁，显示时长误差在可接受范围。
- 辅助功能被撤销后自动降级到屏幕/鼠标位置或停止光标模式。

### F-12 输入法全局快捷键

**需求**

- 为每个已启用输入法设置一个全局快捷键。
- 支持设置、修改、清除、禁用。
- 快捷键冲突检测：系统快捷键、App 内快捷键、其他输入法已占用。
- 默认不设置快捷键，避免与用户现有习惯冲突。
- 使用 Carbon `RegisterEventHotKey`，避免依赖辅助功能。
- 快捷键触发后直接切换到目标输入法，并遵守 HUD/统计/诊断逻辑。

**验收**

- 重启后快捷键保留并生效。
- 冲突时阻止保存并提示冲突项。
- 输入法被删除后快捷键自动失效并标记。
- 全屏 App、远程桌面下仍可触发（需实测）。

### F-13 特殊 App 与浮窗

**需求**

- 支持 Spotlight、Alfred、Raycast 等启动器/浮窗。
- 支持 VNC/远程桌面类 App 的激活切换。
- 浮窗显示时应用其规则；关闭后恢复底层 App 的输入法。
- 处理连续弹窗、隐式关闭、底层窗口事件抢占。
- 检测策略优先事件驱动；无法获取事件时才使用低频窗口轮询，并限制 CPU。

**验收**

- Spotlight 唤起/关闭后输入法正确切换与恢复。
- Raycast 连续打开/关闭 20 次不残留错误状态。
- 浮窗显示期间底层 App 的窗口事件不会抢占切换。
- 未授权辅助功能时，特殊 App 能力明确标记为不可用，不影响普通 App。

### F-14 浏览器地址栏规则

**需求**

- 地址栏聚焦时切换到指定输入法。
- 支持浏览器：Safari、Chrome（含 Beta/Dev/Canary）、Edge、Firefox、Brave、Zen。
- 地址栏失焦、回到网页正文时重新评估域名/App 规则。
- 浏览器多进程/多开时，识别当前前台窗口所属进程。
- 无法识别地址栏时回退到 App 规则，并记录诊断。

**验收**

- Safari/Chrome/Edge/Firefox 地址栏聚焦切换正确。
- 地址栏聚焦时不会因为页面加载被误判。
- 多开浏览器时只影响当前窗口。
- 辅助功能被拒绝时功能禁用并有明确提示。

### F-15 域名规则

**需求**

- CRUD：域名模式、输入法、启用状态、备注。
- 匹配类型：精确、后缀（含子域名）、通配符。
- URL 归一化：大小写、端口、IPv6、查询参数、片段、IDN/Punycode。
- 优先级：地址栏聚焦规则 > 域名规则 > App 激活规则 > 全局激活规则。
- 同一域名多条规则时按“最具体匹配”优先。
- 支持测试输入框：输入 URL 即时显示命中的规则。
- 浏览器标签页切换、页面内导航、前进后退都要重新评估。
- 休眠唤醒后重建状态。

**验收**

- `example.com` 与 `sub.example.com` 的匹配符合规则定义。
- 含端口、IPv6、大小写、查询参数的 URL 不误判。
- 标签页切换与地址栏聚焦切换行为符合优先级。
- 域名规则可导入导出。
- 不保存浏览历史，只保存用户录入的域名规则。

### F-16 辅助功能权限向导

**需求**

- 检测 `AXIsProcessTrusted`。
- 解释每项能力与权限的对应关系：
  - 光标位置 HUD
  - 浏览器地址栏/域名
  - 浮窗/特殊 App
- 提供打开系统设置、重新检查、跳过。
- 权限被撤销时运行时检测并降级。
- 不使用私有 API；不请求屏幕录制权限（除非未来明确需要）。

**验收**

- 首次启动可完成授权并返回 App。
- 拒绝后核心切换功能仍可用。
- 重新授权后无需重启即可恢复相关能力。
- 设置页始终显示当前权限状态。

### F-17 状态栏/程序坞图标控制

**需求**

- 状态栏图标显示/隐藏，记住上次状态（受 F-02 控制）。
- 程序坞图标显示/隐藏，默认隐藏。
- 两者互斥兜底：至少保留一个入口。
- 改变 Dock 图标时切换 `NSApplication` 激活策略，不重启 App。

**验收**

- 隐藏状态栏后仍可从 Dock/重新启动进入设置。
- 显示 Dock 图标后 App 出现在 Dock 与 `⌘Tab`。
- 导入产生“双隐藏”配置时自动修复。

### F-18 统计与诊断增强

**需求**

- 保留每 App/总切换成功次数。
- 新增：
  - 最近切换失败原因分类（输入法不存在、权限、目标进程不可用、超时）。
  - 当前场景解析结果（App/启动/激活/域名/地址栏/浮窗）。
  - 导出诊断包（文本/JSON，不含用户输入内容与浏览历史）。
- 统计与诊断入口在菜单栏和设置页都可访问。

**验收**

- 失败后能看到“为什么没切”的可读原因。
- 诊断包不包含 App 内容、URL 历史、输入文本。
- 统计清零不影响规则。

### F-19 本地化与无障碍

**需求**

- 简中、繁中、英文完整覆盖新增界面。
- HUD、权限向导、导入导出错误全部本地化。
- VoiceOver 可读取设置项与 HUD 状态。
- 键盘可达：Tab 导航、快捷键、焦点环。
- 浅色/深色/高对比度适配。

**验收**

- 简中、繁中、英文截图检查无截断；日/韩/波斯见 F-30。
- VoiceOver 能完成核心设置流程。
- 仅键盘可完成规则配置。

### F-20 终端规则

**需求**

- 按终端当前前台程序切换输入法，例如 `claude`、`nvim`、`ssh`、`git`。
- 支持终端：Ghostty、iTerm2、Terminal、WezTerm、Alacritty；后续可扩展。
- 规则字段：程序名、目标输入法、启用开关、备注。
- 程序名匹配：忽略大小写与首尾空白；同时匹配进程 key 与进程名。
- 识别聚焦 pane；支持 tmux、zellij 等 multiplexer。
- 支持终端浮窗（floating panel）焦点。
- 优先级：终端规则 > 终端 App 规则 > 全局激活规则。
- 终端探针失败时回退到 App 规则，并记录诊断，不阻塞切换。
- 终端查询只读取 pane/tty/前台进程信息，不读取终端内容、不执行用户 shell 命令。

**验收**

- 在 iTerm2 运行 `nvim`，切到该 pane 使用配置的英文输入法；退出后回到终端 App 规则。
- tmux/zellij 内切换 pane 时规则跟随当前 pane。
- 终端浮窗显示/关闭时规则正确应用与恢复。
- 终端未安装/未启用/Apple Events 被拒绝时，规则禁用且有明确提示。
- 探针失败不影响其他 App 的切换。

### F-21 每 App 强制英文标点（已禁用）

**产品决策（2026-11-18）**：不做。

**原因**

- macOS 没有公开的“按 App 改写标点”API，必须使用 CGEventTap 或等价的事件拦截。
- 事件拦截需要 Input Monitoring/辅助功能权限，会引入输入延迟、与输入法/快捷键冲突、权限撤销后的降级等稳定性风险。
- 该功能对核心输入法切换价值有限，不符合当前投入产出比。

**约束**

- 不再设计、不再排期、不进入任何 Phase。
- 相关事件拦截代码和权限申请不得进入实现。

### F-22 每 App 功能键模式（暂缓）

**产品决策（2026-11-18）**：本期不做，保留设计草案供后续评估。


**需求**

- 每 App 可选择：
  - 标准功能键（F1–F12）
  - 媒体键（亮度、音量、播放）
  - 跟随全局
- 提供“切换功能键模式”快捷键。
- 全局默认值可在通用设置中配置。
- 不改变系统键盘设置，除非用户显式选择“写入系统设置”。
- 需要技术预研：macOS 的功能键模式偏全局，按 App 切换可能需要事件拦截或 HID 层能力；若不可靠，降级为全局切换 + 明确说明。

**验收**

- 在 IDE 中 F1–F12 为标准功能键，在普通 App 中为媒体键。
- 切换快捷键立即生效，菜单/Indicator 可选显示当前模式。
- App 退出后不残留全局状态。
- 无法可靠实现时，产品明确降级而不是静默失效。

### F-23 Indicator 进阶

**需求**

在 F-11 基础上增加：

- **触发条件**（可分别开关）：
  - 切换 App
  - 切换输入法
  - 聚焦输入框变化
  - 长按鼠标左键
  - Caps Lock 变化
- **位置**：
  - 跟随鼠标
  - 相对当前 App
  - 相对屏幕
  - 9 向对齐（四角、四边中点、中心）
  - 6 档间距（无、XS、S、M、L、XL）
- **样式**：
  - 图标+文字 / 仅图标 / 仅文字
  - 小 / 中 / 大
  - 浅色 / 深色 / 跟随系统
  - 每个输入法可配置背景色、文字色、标签
- **Always-on Indicator**：跟随文本光标常驻显示，独立于默认 Indicator 的触发与位置。
- **Caps Lock 状态**：可选在 Indicator 中显示。
- **隐藏规则**：每 App、每浏览器规则可隐藏 Indicator；排除列表可整体隐藏。
- 光标定位失败时按配置回退到鼠标/屏幕位置。

**验收**

- 5 种触发条件可独立生效，关闭后不再触发。
- 9 向对齐与 6 档间距在所有屏幕边缘不溢出。
- Always-on 在文本输入框聚焦时跟随光标，失焦后按配置隐藏或跟随鼠标。
- 每输入法配色在浅色/深色下可读。
- 多显示器、全屏 Space、屏幕缩放切换后位置正确。

### F-24 快捷键组、纯修饰键、连按两次

**需求**

- 每个输入法可绑定一个普通键盘快捷键。
- 快捷键组：一个快捷键在 2 个以上输入法之间循环切换。
- 触发模式：
  - 普通键盘快捷键
  - 纯修饰键组合（左/右 Shift、Control、Option、Command 的任意组合）
- 纯修饰键支持“按一次 / 连按两次”。
- 功能键模式切换支持独立快捷键。
- 冲突检测：系统快捷键、应用快捷键、其他输入法/组。
- 纯修饰键模式需要 Input Monitoring；权限缺失时禁用该模式，普通快捷键仍可用。

**验收**

- 快捷键组按顺序循环，不跳项、不重复。
- 纯修饰键单击/双击触发稳定，不误触普通修饰键操作。
- 冲突时阻止保存并指出冲突项。
- 睡眠唤醒、外接键盘切换后快捷键仍有效。

### F-25 浏览器规则扩展

**需求**

- 匹配类型：
  - `DOMAIN-SUFFIX`（含子域名）
  - `DOMAIN`（精确域名）
  - `URL-REGEX`（完整 URL 正则）
- 每条规则可配置：目标输入法、恢复策略、隐藏 Indicator、启用/禁用。
- 浏览器开关：按已安装浏览器显示。
- 首批浏览器：Safari、Chrome、Edge、Firefox、Brave、Zen。
- 扩展浏览器：Safari Technology Preview、Chromium、Arc、Vivaldi、Opera、Thorium、Firefox Developer Edition/Nightly、Dia、Helium、Comet、Aside、Whale，共 21 个变体。
- 正则规则必须校验、限制复杂度，避免灾难性回溯；非法正则阻止保存。
- 浏览器适配失败时回退到 App 规则，不影响其他浏览器。

**验收**

- 三种匹配类型符合示例语义。
- 非法正则/空域名/非法端口被拒绝。
- 浏览器多开、多进程、标签页切换、前进后退、睡眠唤醒后规则正确。
- 一个浏览器适配失败不影响其他浏览器。

### F-26 输入法切换可靠性修复（CJKV）

**需求**

- 提供“修复输入法切换问题”开关，解决“图标已切换但实际输入仍是旧输入法”的 macOS 问题。
- 策略：
  1. **切换焦点**：短暂切换焦点迫使系统落定输入法；适用于 macOS 26，但对浮窗无效。
  2. **快捷键模拟**：模拟系统“选择上一个输入法”快捷键；适用于 macOS 26 之前，但要求系统快捷键已启用。
  3. **直接激活（实验性）**：使用私有 API 在目标进程直接激活输入法；默认关闭，需用户显式开启并接受风险。
- 默认策略按系统版本自动选择：macOS 26+ 优先切换焦点，旧版本优先快捷键模拟。
- 私有 API 路径必须隔离在独立模块，失败时回退到前两种策略，不得导致主流程崩溃。
- 设置页显示当前策略、系统版本、所需系统快捷键状态和回退结果。
- 该能力不改变用户规则，只影响“切换是否真正生效”。

**验收**

- 开启后，中文/日文/韩文输入法切换后立即输入，不再出现图标与输入不一致。
- 三种策略可手动选择；不可用策略显示原因。
- 私有 API 策略关闭/失败时自动回退，主流程不受影响。
- 切换失败仍进入既有诊断与统计链路。

### F-27 光标体验修复与 Cursor Helper

**需求**

- Cursor Helper：独立 helper，用于在更多 App 中可靠获取文本光标位置。
- 与主 App 同签名、同 Team ID；可单独安装/卸载。
- 仅在 Enhanced Mode 开启且用户授权时运行。
- “Fix Typing/Cursor Lag”：macOS 14 实验性光标导致卡顿时，可选禁用实验光标，恢复经典 I-beam。
- Helper 崩溃/被杀后主 App 自动降级，不阻塞输入法切换。
- 不采集输入内容、不记录按键。

**验收**

- 在浏览器、Electron、JetBrains、Office 等 App 中光标定位成功率明显提升。
- Helper 未安装/未授权时，Indicator 仍可用（回退位置）。
- 禁用 Cursor Lag Fix 后系统行为恢复。
- Helper 退出后主 App 无崩溃、无持续高 CPU。

### F-28 Beta 更新通道

**需求**

- 设置页提供“接收 Beta 更新”开关。
- Stable 与 Beta 使用独立 appcast 或同一 appcast 的 channel 标记。
- Beta 版本号必须高于当前 Stable；用户关闭 Beta 后，只有更新的 Stable 才会替换。
- Beta 构建需在关于页显示 `Beta (build)`，避免误认为正式版。
- 更新失败可回退，不破坏当前安装。

**验收**

- 开启 Beta 后能收到 Beta 更新；关闭后不再收到 Beta。
- Beta 升到 Stable 的规则正确，不发生降级循环。
- 更新后配置、规则、权限状态保留。

### F-29 脚本化导入

**需求**

- 支持 URL Scheme，例如 `typelock://import?path=/absolute/path/settings.json&silent=true`。
- 仅接受绝对路径；校验文件存在、schema 版本、字段合法性。
- 导入前自动备份；导入失败不修改现有配置。
- `silent=true` 时隐藏成功提示，失败仍提示。
- URL Scheme 不执行任意脚本、不读取非配置文件。

**验收**

- 命令行可完成导入。
- 非法路径/非法 JSON/未知版本被拒绝且不破坏配置。
- 导入成功后设置窗口立即刷新。

### F-30 本地化扩展与无障碍

**需求**

- 在简中、繁中、英文基础上增加日文、韩文、波斯文（fa）。
- 波斯文需要 RTL 布局检查。
- 新增文案全部本地化；不得硬编码中文/英文。
- VoiceOver：设置项、Indicator 状态、权限向导、错误提示可读。
- 键盘导航完整。

**验收**

- 6 语言下无截断、无重叠、无未翻译键。
- RTL 布局方向正确。
- VoiceOver 完成核心配置流程。

### F-31 直链分发、签名与公证

**需求**

- 不上架 App Store。
- 发布 `.dmg` 与 zip；Sparkle appcast 指向 TypeLock Releases。
- 使用 Developer ID Application 签名；主 App、Helper、Cursor Helper 同一 Team ID。
- 公证并 staple；未签名版本仍可作为开发构建。
- 更新说明中明确 Gatekeeper 放行步骤（未签名阶段）。
- 发布产物包含 SHA-256、attestation、appcast。

**验收**

- 下载 → 安装 → 首次启动 → 授权 → 更新全流程可用。
- Helper 与主 App 签名一致。
- 公证失败时阻止正式发布。
- 不依赖 App Store 审核能力。

### F-32 独立实现与许可证合规

**需求**

- 所有参考竞品的功能，必须独立设计实现。
- 禁止复制 GPL-3.0 代码、注释、测试、素材、UI 布局。
- 禁止把 GPL 代码链接进主 App 或 Helper。
- 新增依赖必须通过许可证扫描；GPL/AGPL 依赖默认拒绝。
- 代码审查检查：版权头、相同注释、逐行翻译、相同测试夹具。
- 记录每项竞品能力的“行为来源”和“独立实现说明”。

**验收**

- 依赖许可证扫描无 GPL/AGPL 污染。
- 代码审查清单包含许可证项。
- 发布前完成一次独立实现审计。

---

## 7. 数据模型与存储

### 7.1 存储布局

延续现有 Application Support 目录：

```
~/Library/Application Support/io.github.zbl-jerry.TypeLock/
├── app-rules.json
├── fallback-rule.json
├── app-switch-statistics.json
├── preferences.json          # 新增：通用设置、更新通道、仪表盘默认值
├── browser-rules.json        # 新增：地址栏 + 域名/后缀/正则规则
├── terminal-rules.json       # 新增：终端前台程序规则
├── hotkey-groups.json        # 新增：快捷键与快捷键组
├── indicator.json            # 新增：Indicator 触发、位置、样式、颜色
├── exclusions.json           # 新增：切换排除 / Indicator 排除
├── reliability.json          # 新增：CJKV 修复策略、Cursor Lag 开关
└── backups/                  # 导入/迁移前备份
```

### 7.2 版本与迁移

- 所有文件增加 `schemaVersion`。
- 启动时按版本顺序迁移；失败时保留旧文件并进入只读安全模式。
- 迁移前写入 `backups/`。
- 导出文件同样带 `schemaVersion` 与 App 版本。

### 7.3 数据约束

- 域名/正则规则只保存模式与输入法，不保存浏览历史、页面内容或 URL 样本（测试样本可保存为可选字段，默认不导出）。
- 终端规则只保存程序名与输入法，不保存终端输出、命令内容或 pane 内容。
- 快捷键保存 keyCode + modifiers，不保存字符。
- Indicator 颜色保存十六进制值，不保存截图。
- 路径仅用于定位 App；导入时忽略或重新解析。
- 统计与诊断不包含用户输入内容、URL 历史、终端内容。

### 7.4 新增数据模型

```swift
struct BrowserRuleRecord: Codable, Identifiable {
    var id: UUID
    var matchType: MatchType          // domainSuffix / domain / urlRegex
    var pattern: String
    var inputMethodId: String
    var restoreStrategy: RestoreStrategy? // nil = 跟随全局
    var hideIndicator: Bool
    var enabled: Bool
    var sampleURL: String?
    var createdAt: Date
    var updatedAt: Date
}

struct TerminalRuleRecord: Codable, Identifiable {
    var id: UUID
    var program: String               // 例如 claude / nvim / ssh
    var inputMethodId: String
    var enabled: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct HotkeyBindingRecord: Codable {
    var inputMethodId: String?
    var groupId: UUID?
    var mode: TriggerMode             // keyboardShortcut / modifierCombo
    var keyCode: UInt16?
    var modifiers: UInt32?
    var modifierKeys: [String]?
    var trigger: PressTrigger         // singlePress / doublePress
}

struct IndicatorPreferences: Codable {
    var enabled: Bool
    var triggers: Set<Trigger>        // appSwitch / inputSourceChange / focusChange / longMousePress / capsLock
    var position: Position            // nearMouse / windowCorner / screenCorner
    var alignment: Alignment          // 9 向
    var spacing: Spacing              // none / xs / s / m / l / xl
    var size: Size                    // small / medium / large
    var info: Info                    // iconAndTitle / iconOnly / titleOnly
    var alwaysOn: Bool
    var showCapsLock: Bool
    var colors: [String: InputMethodColor]
}

struct ReliabilityPreferences: Codable {
    var cjkvFixEnabled: Bool
    var cjkvStrategy: CJKVStrategy    // focusSwitch / shortcutSimulation / directActivation
    var cursorLagFixEnabled: Bool
    var cursorHelperEnabled: Bool
}
```

### 7.5 存储方案选择

- 短期继续使用 JSON：规则量小、调试容易、迁移简单。
- 当 App 规则、域名规则、终端规则、快捷键合计超过约 1 万条，或需要复杂查询时，再评估 SQLite/Core Data。
- 不因为 Input Source Pro 使用 Core Data 就照搬；以 TypeLock 的实际规模和测试成本为准。
- 所有文件写入必须原子化，避免崩溃导致半写。

---

## 8. 技术方案要点

### 8.1 架构

- 继续使用 TCA 与 Dependencies。
- 新增 Feature：
  - `SettingsFeature`
  - `PreferencesFeature`
  - `BrowserRulesFeature`
  - `TerminalRulesFeature`
  - `HotkeyFeature`
  - `IndicatorFeature` / `IndicatorCoordinator`
  - `ReliabilityFeature`（CJKV / Cursor Lag）
  - `BackupFeature`
  - `PermissionFeature`
  - `SpecialAppCoordinator`
- 规则解析集中到单一 `SwitchResolver`：输入场景 → 目标输入法 + 原因。
- 所有切换路径（激活、启动、快捷键、域名、终端、浮窗）统一走 `SwitchResolver`，避免多套逻辑。
- `IndicatorFeature` 独立订阅切换结果，不参与目标输入法计算；隐藏规则只影响展示。
- 解析优先级（从高到低）：
  1. 应用切换排除
  2. 地址栏默认输入法（地址栏聚焦）
  3. 域名/正则规则
  4. 终端程序规则
  5. 每 App 启动/激活规则
  6. 全局启动/激活策略
  7. 不切换
- 每级解析失败时记录原因并进入下一级，不直接放弃。

### 8.2 窗口与激活策略

- 设置窗口使用 SwiftUI + `NSWindow` 承载。
- Dock 图标开关控制 `NSApp.setActivationPolicy(.regular/.accessory)`。
- `.accessory` 下显示窗口时调用 `NSApp.activate` 并 `orderFrontRegardless`。
- 窗口关闭不退出 App；`applicationShouldTerminateAfterLastWindowClosed = false`。

### 8.3 HUD / Indicator

- `NSPanel`：`styleMask = [.borderless, .nonactivatingPanel]`，`isFloatingPanel = true`，`ignoresMouseEvents = true`。
- 层级：`.statusBar` 或 `.floating`，按全屏场景选择。
- 多显示器：按目标屏幕计算坐标，处理缩放、刘海/安全区域、全屏 Space。
- 光标定位：AX `kAXFocusedUIElementAttribute` + `kAXBoundsAttribute`；失败回退到鼠标/屏幕位置。
- 文本/图标渲染：SwiftUI 或 AppKit；缓存输入法图标与颜色，避免每次切换重新加载。
- 显示时长与淡入淡出使用可取消的定时任务，避免旧任务关闭新 HUD。
- 位置模型：跟随鼠标 / 相对 App / 相对屏幕 + 9 向对齐 + 间距。
- Always-on Indicator 使用独立窗口与独立生命周期，不共享默认 Indicator 的定时器。
- Caps Lock 状态变化复用同一渲染管线，避免第二个窗口抖动。
- 触发条件独立开关；关闭某触发后不得再唤醒窗口。
- 睡眠/锁屏/显示器重配后重建窗口与坐标系。

### 8.4 快捷键

- 普通组合键：Carbon `RegisterEventHotKey` + `InstallEventHandler`。
- 纯修饰键：需要 Input Monitoring；使用事件监听，按“按一次/连按两次”识别，处理漏掉 key-up 的情况。
- 快捷键组：维护有序输入法列表与轮转索引；组内输入法被删除时自动跳过。
- 快捷键 ID 与输入法 ID / 组 ID 映射持久化。
- 冲突检测优先本地已知绑定；系统级冲突无法完全枚举，保存时提示“可能冲突”。
- 快捷键回调切回主线程，走统一切换路径。
- 权限缺失时禁用纯修饰键模式，普通快捷键保持可用。

### 8.5 浏览器地址栏与域名

- 每种浏览器一个 Adapter：
  - 识别地址栏 AX 元素。
  - 读取当前 URL（`AXValue`）。
  - 处理多进程/多窗口/多 profile。
- URL 归一化与匹配独立为纯函数，便于单元测试：
  - 小写、去端口、去查询/片段、处理 IPv6、IDN/Punycode。
  - `DOMAIN-SUFFIX`、`DOMAIN`、`URL-REGEX` 三种匹配。
  - 正则限制长度与复杂度，拒绝灾难性回溯。
- 匹配优先级：地址栏聚焦规则 > 最具体域名规则 > 通用域名规则 > App 规则。
- 浏览器版本更新导致 AX 结构变化时，Adapter 隔离失败，不影响其他浏览器。
- 监听标签页/窗口/焦点变化；睡眠唤醒后重建观察者。
- 域名规则只匹配用户录入模式，不做网络请求。
- 浏览器 Adapter 注册表按 Bundle ID 路由；新增浏览器只增加 Adapter，不改核心解析。

### 8.6 特殊 App/浮窗

- 维护“前台场景栈”：普通 App、浮窗、地址栏、启动器。
- 浮窗出现：记录底层 App 与输入法，应用浮窗规则。
- 浮窗关闭：恢复底层 App 的规则结果，而不是简单恢复旧输入法。
- 事件仲裁：浮窗存在时忽略底层 App 的窗口事件，避免抢占。
- 低频窗口轮询仅作为兜底，默认关闭或限制频率。

### 8.7 登录启动

- 优先 `SMAppService`/Login Items。
- 保留 LaunchAgent 兜底与清理逻辑。
- 记录最近一次失败原因，设置页可见。
- 参考 KeyboardHolder 的 helper 兜底思路，但独立实现。

### 8.8 权限

- **辅助功能 / Enhanced Mode**：`AXIsProcessTrustedWithOptions` + 系统设置深链；用于光标定位、地址栏、域名、Spotlight 类浮窗。
- **Input Monitoring**：纯修饰键快捷键。
- **Apple Events**：终端 pane 查询；现有 automation entitlement 扩展使用。
- **登录项**：现有 LaunchAtLoginService。
- 非沙盒分发，不请求 App Store 审核能力。
- 不请求屏幕录制；如未来需要窗口截图再单独立项。
- 权限被撤销时运行时检测并降级，不崩溃、不静默失效。

### 8.9 兼容性

- 最低 macOS 14.0。
- macOS 14.0–14.3：菜单副标题可能不显示，按上游 issue #50 做单行回退（`Safari（ABC）`）。
- macOS 14.4+ / 15 / 26：保留双行副标题。
- Universal Binary（arm64 + x86_64）。

### 8.10 终端规则实现

- 终端 Adapter：Ghostty、iTerm2、Terminal、WezTerm、Alacritty。
- 通过 Apple Events 询问终端当前聚焦 pane 的 tty；不在 TypeLock 内执行用户 shell 命令。
- 通过 tty 查询前台进程组与程序名；只读进程元数据，不读取终端输出。
- tmux/zellij：解析 pane 的 tty 或 session/pane 标识，映射到当前前台程序。
- 终端浮窗：维护 panel focus 状态，浮窗关闭后重新评估底层 App。
- 探针失败、Apple Events 拒绝、终端未安装时：规则禁用并记录诊断，回退 App 规则。
- 终端规则优先级高于终端 App 规则，低于地址栏/域名规则。
- 轮询只在终端前台时进行；失焦后停止，避免持续 CPU。
- 所有 AppleScript 字符串必须参数化，禁止拼接用户输入执行。

### 8.11 输入法可靠性修复（CJKV / Cursor Lag）

- CJKV 修复独立为 `ReliabilityFeature`，不侵入 `SwitchResolver`。
- 策略：
  - 焦点切换：创建临时焦点窗口，切换后销毁；对浮窗无效。
  - 快捷键模拟：模拟系统“选择上一个输入法”快捷键；启动时检测该快捷键是否启用。
  - 直接激活：私有 API，独立模块、显式开关、默认关闭；失败回退。
- 默认策略按 macOS 版本选择；用户可手动覆盖。
- 每次切换后可选验证“实际输入源”是否等于目标值；不一致时记录诊断并触发修复。
- Cursor Lag Fix：可选关闭 macOS 14 实验性光标，恢复经典 I-beam；修改前提示需要重启。
- 所有修复行为必须可关闭、可回退，不改变用户规则与统计。

### 8.12 Cursor Helper 与 Indicator 性能

- Cursor Helper 为独立可执行文件，与主 App 同 Team ID、同签名。
- 主 App 通过 XPC 或受限 IPC 请求光标位置；Helper 不接收输入内容。
- Helper 不可用/崩溃时，主 App 回退到 AX 直读或鼠标位置。
- Indicator 渲染限制在 60fps 以内；无变化时不重绘。
- 光标跟随使用节流与坐标过滤，避免抖动和主线程阻塞。
- 多显示器/缩放变化时重建坐标系；锁屏/睡眠时暂停更新。

### 8.13 分发、签名与公证

- 不走 App Store；产物为 `.dmg` / `.zip` + Sparkle appcast。
- 签名：
  - 主 App、Helper、Cursor Helper 使用同一 Developer ID Application 证书。
  - Hardened Runtime 开启；按需声明 entitlements。
  - 公证并 staple；公证失败阻止发布。
- 未签名开发构建可在 README 标注 Gatekeeper 放行步骤。
- Sparkle EdDSA 私钥仅存 CI secret，不进仓库。
- 发布流程继续使用 `dev` tag、CHANGELOG、checksums、attestation。

### 8.14 独立实现与代码审查

- 参考竞品只记录行为、系统 API、边界条件，不保留代码片段。
- 新实现由工程侧独立设计数据结构、命名、测试；禁止逐行翻译。
- 代码审查清单增加：
  - 是否包含第三方版权头/相同注释。
  - 是否复制测试夹具、UI 素材、颜色方案。
  - 是否引入 GPL/AGPL 依赖。
- 依赖许可证扫描纳入 CI；GPL/AGPL 默认拒绝。
- 如确需引入第三方实现，先完成许可证评估并记录决策。

---

## 9. 非功能需求

| 维度 | 目标 | 验证方式 |
|---|---|---|
| 切换延迟 | App 激活到输入法切换完成 P95 < 100ms | 本地埋点/诊断日志时间戳 |
| Indicator 延迟 | 切换完成到 Indicator 可见 P95 < 50ms | 同上 |
| 终端探针 | 终端前台时读取 pane P95 < 80ms；失焦后停止 | 诊断日志 |
| 光标定位成功率 | 支持 App 内 ≥ 95%，失败自动回退 | 手动矩阵 + 诊断 |
| 空闲 CPU | 平均 < 0.5%，无持续轮询 | Activity Monitor / Instruments |
| 内存 | 稳态 < 200MB，Helper 单独统计 | Instruments |
| 主线程 | 无 > 100ms 的阻塞 | Instruments / Hang 检测 |
| 设置窗口 | 打开 < 300ms | 手动测量 |
| 崩溃隔离 | Helper 崩溃不影响主 App | 故障注入 |
| 崩溃率 | crash-free sessions > 99.5% | 本地诊断汇总（无默认遥测） |
| 导入性能 | 1 万条规则 < 1s | 单元/性能测试 |
| 兼容性 | macOS 14.0+、双架构 | CI + 手动矩阵 |
| 权限降级 | 任一权限撤销后核心切换仍可用 | 手动矩阵 |
| 隐私 | 默认无网络请求（除 Sparkle） | 代码审查/抓包 |
| 分发 | 签名/公证构建可安装、可更新 | 发布检查单 |

> 以上为验收目标，不是当前实测值；需在 Phase 4 建立基准。

### 9.1 技术预研清单

以下能力在排期前必须先做技术验证，避免承诺无法实现的产品行为：

| 预研项 | 目标 | 决策门槛 |
|---|---|---|
| 每 App 功能键模式 | 验证能否在不改变全局系统设置的情况下按 App 切换 F1–F12/媒体键 | 无法可靠实现则降级为全局切换 |
| 终端规则 | 验证 5 种终端 + tmux/zellij 的 pane 识别与失败回退 | 至少 3 种主流终端稳定 |
| 浏览器 Adapter | 验证 AX 地址栏识别在 Safari/Chrome/Edge/Firefox 的稳定性 | 首批 4 个浏览器通过 |
| Cursor Helper | 验证 XPC/IPC、签名、崩溃隔离、公证 | Helper 崩溃不影响主 App |
| CJKV Fix | 验证三种策略在 macOS 14/15/26 的实际效果 | 至少一种策略稳定；私有 API 默认关闭 |
| 21 浏览器变体 | 评估维护成本与复用度 | 先做 6 个，其余按需求分批 |
| 私有 API 直接激活 | 评估系统版本兼容性、崩溃率、审核/合规影响 | 默认关闭，仅实验性开放 |

---

## 10. 路线图

### Phase 0：基础重构

- F-01 设置窗口骨架
- F-10 数据模型 v2 与迁移
- `SwitchResolver` 统一场景解析
- F-16 权限服务骨架
- F-32 独立实现规范与依赖许可证扫描
- 测试基架与快照/夹具

**出口条件**：旧功能全部通过；新旧存储可迁移；设置窗口可打开；许可证扫描接入 CI。

### Phase 1：KeyboardHolder 核心对齐

- F-02 通用设置
- F-03 全局启动/激活策略
- F-04 每 App 双时机规则
- F-05 输入法记忆
- F-06 应用排除
- F-07 导入/导出
- F-29 脚本化导入
- F-08 更新/关于
- F-09 菜单栏入口

**出口条件**：KeyboardHolder 核心规则能力对齐；升级无损；导入导出往返一致。

### Phase 2：Indicator 与输入增强

- F-11 Indicator 基础
- F-23 Indicator 进阶（Always-on/9 向/间距/配色/Caps Lock）
- F-12 输入法快捷键
- F-24 快捷键组、纯修饰键、连按两次
- F-13 特殊 App/浮窗
- F-16 权限向导完善
- F-17 状态栏/Dock 图标

**出口条件**：Indicator/快捷键/浮窗场景验收通过；权限拒绝时降级明确。

### Phase 3：上下文规则

- F-14 浏览器地址栏规则
- F-15 域名规则
- F-25 浏览器规则扩展（正则、21 个变体）
- F-20 终端规则
- 多浏览器 Adapter、多进程、终端 pane、休眠唤醒

**出口条件**：Safari/Chrome/Edge/Firefox 矩阵通过；域名优先级与恢复行为正确；终端规则在 5 种终端 + tmux/zellij 下通过。

### Phase 4：可靠性、分发与硬化

- F-26 CJKV 修复
- F-27 Cursor Helper / Cursor Lag Fix
- F-18 统计/诊断增强
- F-19 本地化/无障碍
- F-30 日/韩/波斯语扩展
- F-28 Beta 更新通道
- F-31 签名、公证、直链分发
- F-32 发布前独立实现审计
- macOS 14 副标题回退
- 性能、崩溃、内存、睡眠唤醒、长稳测试

**出口条件**：P0/P1 验收全绿；签名/公证构建可安装可更新；许可证审计通过；`dev` tag 发布成功。

> 阶段按依赖排序，不承诺具体日期；排期需在技术评审后确认。终端规则、CJKV、Cursor Helper 均需先完成技术预研再排期。

---

## 11. 验收与测试策略

### 11.1 自动化

- 单元测试：数据迁移、URL 归一化/三种匹配、终端程序匹配、规则优先级、导入校验、快捷键冲突、Indicator 位置计算、恢复策略、CJKV 策略选择。
- Reducer 测试：启动/激活/浮窗/地址栏/域名/终端/快捷键事件序列。
- 快照/夹具：设置页各语言、Indicator 各样式/位置。
- 故障注入：Helper 崩溃、权限撤销、Apple Events 拒绝、终端探针超时、浏览器 AX 失败。
- 许可证扫描：依赖与源码版权头；GPL/AGPL 默认失败。
- 发布脚本测试：现有 `script/test_release_scripts.sh` 继续通过，并覆盖签名/公证检查。
- 备份测试：导出 → 清空 → 导入 → 规则/快捷键/Indicator/终端规则一致。

### 11.2 手动矩阵

| 维度 | 覆盖 |
|---|---|
| macOS | 14.0、14.3、14.4、14.6、15.x、26.x |
| 架构 | Apple Silicon（实机）、Intel（可用时） |
| 外观 | 浅色、深色、高对比度 |
| 语言 | 简中、繁中、英文、日文、韩文、波斯文（RTL） |
| 显示器 | 单屏、双屏、不同缩放、全屏 Space、刘海屏 |
| 浏览器 | 首批 6 个 + 扩展 15 个变体；多开、多进程、多 profile |
| 终端 | Ghostty、iTerm2、Terminal、WezTerm、Alacritty；tmux、zellij；终端浮窗 |
| 特殊 App | Spotlight、Alfred、Raycast、VNC、全屏 App |
| 输入法 | ABC、拼音、五笔、日文、韩文、第三方输入法；CJKV 场景 |
| 快捷键 | 普通组合键、纯修饰键、单击/双击、快捷键组 |
| Indicator | 5 种触发、3 种位置、9 向对齐、6 档间距、3 种样式、3 种尺寸 |
| 权限 | 首次授权、拒绝、撤销、重新授权、Input Monitoring、Apple Events |
| 生命周期 | 安装、升级、导入、睡眠唤醒、锁屏、注销/重启 |
| 分发 | 未签名开发构建、签名构建、公证构建、Sparkle 更新 |

### 11.3 发布门禁

- `just check` 通过。
- 所有 P0 验收通过，P1 无阻塞缺陷。
- 升级迁移与导入导出往返验证通过。
- 6 语言本地化检查通过。
- 依赖许可证扫描无 GPL/AGPL 污染。
- 独立实现审计完成。
- Build workflow 产物为 Universal Binary。
- 主 App 与 Helper 签名一致；公证通过（正式发布）。
- CHANGELOG 含对应 `## vX.Y.Z`。
- 仅从 `dev` 打 annotated tag 发布。

---

## 12. 风险与开放问题

### 12.1 风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| 辅助功能权限被拒绝/撤销 | HUD 光标、域名、地址栏、浮窗不可用 | 权限向导、运行时降级、核心功能不依赖 AX |
| 浏览器 AX 结构变化 | 地址栏/域名识别失败 | Adapter 隔离、诊断、灰度顺序 |
| 浮窗误判 | 切错输入法 | 场景栈 + 事件仲裁 + 回归用例 |
| 多进程浏览器 | 规则只对一个进程生效 | 按窗口/进程识别，参考竞品问题清单 |
| 睡眠唤醒状态丢失 | 域名/浮窗规则失效 | 监听唤醒并重建观察者 |
| 主线程阻塞 | 菜单卡顿/崩溃 | AX 观察者专用线程，禁止同步等待 |
| 功能膨胀导致回归 | 现有稳定性下降 | 统一 SwitchResolver、分阶段、特性开关 |
| 上游分叉加剧 | 无法合并上游修复 | `main` 持续镜像，关键修复手工 cherry-pick |
| 竞品实现参考边界 | 许可证/合规风险 | 只参考公开行为与 release notes，不复制代码/素材 |
| GPL 污染 | TypeLock 被迫 GPL 化 | 独立实现、依赖扫描、代码审查、禁止链接 GPL 代码 |
| 私有 API 失效/崩溃 | CJKV 直接激活不可用 | 默认关闭、独立模块、失败回退、版本检测 |
| Input Monitoring 被拒绝 | 纯修饰键快捷键不可用 | 普通组合键保留，明确降级 |
| Apple Events 权限摩擦 | 终端规则不可用 | 首次使用引导、失败回退 App 规则 |
| 终端/多路复用适配复杂 | tmux/zellij 规则误判 | 终端 Adapter 隔离、诊断、按 pane 回归 |
| 21 个浏览器维护成本 | 版本更新导致识别失败 | Adapter 注册表、分批上线、失败回退 |
| Helper 签名/公证失败 | 光标定位不可用 | 同一 Team ID、CI 校验、回退 AX |
| 功能键按 App 切换可行性 | 可能无法可靠实现 | 先技术预研，不可靠则降级为全局切换 |
| 不走 App Store | 用户信任与更新链自主 | 公证、checksums、attestation、清晰安装文档 |

### 12.2 开放问题

1. **首次安装默认策略**：是否默认“跟随上次”（KeyboardHolder 风格）？推荐是；需确认是否改变现有用户预期。
2. **Indicator 默认值**：新安装默认开启、升级用户默认关闭，还是统一默认开启？推荐新安装开启、升级用户保持关闭。
3. **“忽略 App”与“应用排除”是否合并**：推荐合并为“应用切换排除”，保留原规则恢复能力。
4. **Star/捐赠**：是否在关于页保留？推荐保留“项目主页/反馈”，捐赠换成 fork 维护者自己的链接或省略。
5. **浏览器优先级**：Safari/Chrome 先行，Edge/Firefox 次之，Brave/Zen 最后。
6. **最低系统版本**：是否跟随 KeyboardHolder 支持 macOS 11–13？推荐维持 14.0，缩小测试矩阵。
7. **是否兼容导入 KeyboardHolder 配置**：本期不做；如需迁移工具另立需求。
8. **统计是否纳入导出**：默认不导出，提供选项。
9. **Dock 图标默认值**：推荐关闭，保持菜单栏工具气质，但允许开启。
10. **HUD 是否支持 VoiceOver 播报**：推荐支持，但需避免频繁打扰。
11. **Input Source Pro 能力是否全部进入 v1.0**：推荐分阶段；终端规则、CJKV、Cursor Helper 先做技术预研，再决定是否阻塞 v1.0。
12. **私有 API 策略**：推荐默认关闭，仅作为“实验性修复”显式开启；是否允许进入正式版需评审。
14. **每 App 功能键模式可行性**：macOS 功能键状态偏全局，需先验证能否可靠按 App 切换。
15. **Cursor Helper 是否首版内置**：推荐先做 AX 直读 + 回退，Helper 作为增强项。
16. **6 语言是否首版齐全**：推荐简中/繁中/英/日先行，韩/波斯随后。
17. **Beta 通道何时开放**：推荐在 Phase 4 与签名/公证一起上线。
18. **签名/公证时间表**：是否在 v1.0 前完成 Developer ID 签名，还是先继续未签名分发。
19. **谁负责许可证审计**：需要明确代码审查与发布前的责任人。

---

## 13. 发布与版本规划

- 所有开发在 `dev`；`main` 只镜像上游。
- 建议版本节奏：
  - `v0.11.0`：Phase 0 + Phase 1，设置窗口、双时机规则、排除、导入导出。
  - `v0.12.0`：Phase 2，Indicator、快捷键；特殊 App 暂缓。
  - `v0.13.0`：Phase 3，浏览器/域名、终端规则。
  - `v0.14.0`：Phase 4，CJKV/Cursor Helper、Beta 通道、本地化扩展。
  - `v1.0.0`：KeyboardHolder + Input Source Pro 核心能力验收完成、签名/公证、稳定性达标。
- 每个版本必须更新 `CHANGELOG.md` 的 `## vX.Y.Z` 双语段落。
- 发布由 annotated tag 触发，仅接受包含于 `dev` 的 tag。
- **分发：不对 App Store 发布。** 继续使用 GitHub Releases / 官网直链 + Sparkle。
- 发布产物：
  - Universal Binary `.zip`（及后续 `.dmg`）
  - checksums、appcast、GitHub Artifact Attestation
  - 主 App、Helper、Cursor Helper 同签名；正式版公证并 staple
- 更新通道：
  - Stable：默认
  - Beta：设置页显式开启；Beta 版本号高于 Stable，关闭后只接受更新的 Stable
- 发布门禁包含依赖许可证扫描与独立实现审计。
- Sparkle EdDSA 私钥只存 CI secret，继续使用 TypeLock 自己的密钥。

---

## 14. 附录

### A. 能力 → 功能 ID 对照

| 能力 | KeyboardHolder | Input Source Pro | TypeLock 功能 |
|---|---|---|---|
| 设置窗口 | 有 | 有 | F-01 |
| 登录启动 | 有 | 有 | F-02 |
| 启动显示窗口 | 有 | 首次/新版本 | F-02 |
| 状态栏图标 | 有 | 有 | F-02/F-17 |
| 程序坞图标 | 有 | 无 | F-17 |
| 全局启动/激活输入法 | 有 | 全局默认 + 恢复策略 | F-03 |
| 每 App 启动/激活双规则 | 有 | 无 | F-04 |
| 输入法记忆 | 有 | 有 | F-05 |
| 应用排除（切换/提示） | 有 | 每 App 隐藏 Indicator | F-06 |
| 配置导入导出 | 有 | 有 + 脚本化 | F-07/F-29 |
| 更新设置/关于 | 有 | 有 + Beta | F-08/F-28 |
| 菜单栏快捷入口 | 有 | 有 | F-09 |
| 数据迁移 | 未验证 | Core Data 迁移 | F-10 |
| Indicator/HUD | 基础 | 完整 | F-11/F-23 |
| 输入法快捷键 | 每输入法 | 每输入法 + 组 + 修饰键 | F-12/F-24 |
| 特殊 App/浮窗 | Spotlight/Alfred/Raycast/VNC | Spotlight 类浮窗 | F-13 |
| 浏览器地址栏 | 有 | 有 | F-14 |
| 域名规则 | 有 | 有 + 正则 | F-15/F-25 |
| 权限向导 | 有 | Enhanced Mode | F-16 |
| 终端规则 | 未见 | 有 | F-20 |
| 强制英文标点 | 未见 | 有 | 已禁用 |
| 每 App 功能键 | 未见 | 有 | 暂缓 |
| CJKV 修复 | 未见 | 有 | F-26 |
| Cursor Helper/Lag | 未见 | 有 | F-27 |
| 本地化 | 中文（截图） | 6 语 | F-19/F-30 |
| 签名/公证分发 | 未验证 | 有 | F-31 |
| 独立实现/许可证 | 无可见许可证 | GPL-3.0 | F-32 |

### B. 资料来源

- 用户提供的 KeyboardHolder v1.14.16 设置界面截图（2026-11-18）。
- [KeyboardHolder GitHub](https://github.com/leaves615/KeyboardHolder)（README、Releases）。
- [KeyboardHolder 官网](https://keyboardholder.leavesc.com/zh-cn)。
- [KeyboardHolder Releases](https://github.com/leaves615/KeyboardHolder/releases)。
- [Input Source Pro GitHub](https://github.com/runjuu/InputSourcePro)（README、Release Notes、GPL-3.0）。
- 本地 Input Source Pro 源码：`~/workspace/tmp/KeyboardHolder/InputSourcePro`。
- 上游 TypeSwitch issue #39、#50，以及 TypeLock 当前 `dev` 代码。
- Input Source Pro 官网（产品行为与工程参考）。

### C. 术语

| 术语 | 定义 |
|---|---|
| 启动策略 | App 进程启动后首次进入前台时应用的输入法规则 |
| 激活策略 | App 从后台回到前台时应用的输入法规则 |
| 跟随上次 | 恢复该 App（或该域名）上一次用户选择的输入法 |
| 恢复策略 | 切换回 App/网站时恢复上次输入法，还是使用默认输入法 |
| 场景 | 解析切换目标时的上下文：普通 App、启动、浮窗、地址栏、域名、终端 |
| 排除 | 对某 App 禁用自动切换或 Indicator 的配置 |
| HUD / Indicator | 输入法切换时显示的短暂提示窗口 |
| Enhanced Mode | 需要辅助功能权限的增强能力集合：光标定位、地址栏、域名、Spotlight 类浮窗 |
| 终端规则 | 按终端当前前台程序（如 claude、nvim）选择输入法 |
| CJKV Fix | 修复“输入法图标已切换但实际输入未生效”的系统问题 |
| Cursor Helper | 辅助主 App 获取文本光标位置的独立 helper |
| AX | macOS Accessibility API，用于读取光标、地址栏、窗口等 UI 信息 |
| 场景栈 | 维护浮窗/底层 App 等前台层级的状态结构 |
| Clean-room | 只依据行为与公开文档独立实现，不复制第三方源码 |

---

## 15. 实现状态（2026-11-18）

### 15.1 已实现

| 范围 | 状态 |
|---|---|
| Phase 0：设置窗口、权限、schema v2、迁移、`SwitchResolver`、许可证扫描 | 完成 |
| Phase 1：双时机规则、配置导入导出、App Rules、排除列表 | 完成 |
| Phase 2：Indicator 基础、光标锚定、9 向对齐/间距、Caps Lock、Always-on、每输入法配色/标签、全局快捷键 | 完成 |
| Phase 3：浏览器域名/后缀/正则规则、前台浏览器 URL、终端规则 | 完成 |
| Phase 4：CJKV 焦点落定、Cursor Helper、Cursor Lag Fix、Beta 通道、ja/ko/fa 本地化 | 完成 |
| F-19 本地化 | 四语言完整；ja/ko/fa 常用界面已翻译，技术/错误文案暂以英文兜底 |
| F-27 Cursor Helper | 已提供可选独立 helper、AX 直读与回退；helper 未签名时按 best-effort 处理 |

### 15.2 终端与浏览器范围

- 终端：Terminal、iTerm2（AppleScript + tty + 前台进程组）；tmux（client tty → pane tty）；WezTerm（CLI active pane）。
- 终端未适配：Ghostty、Alacritty、zellij。没有稳定脚本接口，回退到终端 App 规则。
- 浏览器：精确域名、域名后缀、URL 正则；通过前台浏览器 AX URL 匹配。
- 浏览器不做“地址栏聚焦”独立规则，按产品决策只做域名匹配。

### 15.3 已禁用 / 暂缓

| 功能 | 决策 |
|---|---|
| F-21 每 App 强制英文标点 | 永久禁用 |
| F-22 每 App 功能键模式 | 暂缓，不进入本期 |
| F-13 Spotlight/Alfred/Raycast 浮窗仲裁 | 暂缓，先不处理 |
| F-31 Developer ID 签名与公证 | 暂缓，当前无证书；继续未签名分发 |

### 15.4 本地验证

- 使用临时 SwiftPM 包（不污染仓库）完成整包编译。
- 纯逻辑断言覆盖迁移、Resolver、备份、排除、Indicator 布局、快捷键、浏览器/终端匹配。
- 设置 UI 通过 TCA/SwiftUI stub 类型检查。
- 本机只有 Command Line Tools，缺少 XCTest 模块，完整 XCTest 仅在 CI 执行。

---

*本文档为产品规划草案，所有技术方案需在实现前完成技术评审；功能范围与默认值以评审结论为准。*
