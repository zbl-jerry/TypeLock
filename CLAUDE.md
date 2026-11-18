# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TypeLock is a native macOS input-method manager built with SwiftUI and The Composable Architecture (TCA), generated with Tuist. It switches input sources by app launch/activation, browser domain, and terminal program, and adds an optional caret-following indicator, per-input-method hotkeys, exclusions, backup, and reliability repairs.

- Minimum macOS: 14.0
- Swift language mode: 5.9
- Toolchain: Xcode 26.3+
- Distribution: GitHub Releases + Sparkle; unsigned, not notarized, not on the App Store

## Commands

Always select Xcode 26.3+ first. `xcode-select` currently may point at Command Line Tools, so either switch it or export `DEVELOPER_DIR`:

```bash
sudo xcode-select -s /Applications/Xcode-26.3.0.app
# or:
export DEVELOPER_DIR=/Applications/Xcode-26.3.0.app/Contents/Developer
```

Install local tools:

```bash
brew install just tuist
# SwiftFormat must match .swiftformat-version (0.62.1)
```

Generate the project:

```bash
tuist generate --no-open
open TypeLock.xcworkspace
```

Primary development commands:

```bash
just test                  # tuist generate + full XCTest suite
just check                 # lint + tests + release-script tests + license checks
just lint                  # SwiftFormat lint
just format                # SwiftFormat all Swift files
just format-staged         # format staged Swift files (pre-commit hook)
just test-release-scripts  # workflow/release script tests
just test-license-checks   # GPL/AGPL guard tests
```

Run one test class or method after generating the project:

```bash
xcodebuild test \
  -project TypeLock.xcodeproj \
  -scheme TypeLock \
  -destination 'platform=macOS' \
  -only-testing:TypeLockTests/SwitchResolverTests \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Add `/testLaunchInheritsGlobalFixedStrategy` to the `-only-testing` value to run a single method. The helper executable `TypeLockCursorHelper` is built as a Tuist target and copied into `TypeLock.app/Contents/Helpers` by a post-build script.

## Architecture

### TCA and event flow

- `AppFeature` is the root reducer. It owns rule stores, exclusions, indicator/hotkey/reliability preferences, app availability, and `SwitchingFeature.State`.
- `SwitchingFeature` owns the input-method catalog, foreground events, launch candidates, switch attempts, statistics, and indicator triggering.
- `SwitchResolver` is pure logic for activation/launch strategy selection and fallback normalization.
- External capabilities are injected as `DependencyKey` clients: workspace events, input methods, browser URL, terminal program, hotkeys, indicator, reliability, launch-at-login, app availability.
- Event flow: `NSWorkspace` launch/activation → `AppFeature` → `SwitchingFeature` → `SwitchResolver` → `InputMethodClient` → `programmaticSwitchFinished` → statistics / indicator / diagnostics.

### Switching precedence

1. `ExclusionsStore.switchingBundleIds`
2. `BrowserRuleMatcher` against the frontmost browser URL
3. `TerminalRulesStore` against the focused terminal program
4. Per-app launch rule (first foreground after launch) or activation rule
5. Global launch/activation strategy
6. `.none`

A launch candidate is valid for only a short window after `didLaunchApplicationNotification`; after that, activation rules apply. All switch paths should go through `SwitchResolver` and the existing switching reducer rather than duplicating precedence logic.

### Persistence

`Sharing` `@Shared` stores persist JSON under `~/Library/Application Support/io.github.zbl-jerry.TypeLock/`:

- `app-rules.json`, `fallback-rule.json`, `app-switch-statistics.json`
- `browser-rules.json`, `terminal-rules.json`, `exclusions.json`
- `indicator.json`, `hotkeys.json`, `reliability.json`

`MigrationVersion.current = 2`. `AppRuleRecord` keeps legacy `strategy` as the activation strategy and defaults missing `launchStrategy` to `.inherit`. Any schema change needs a migration and defaults for old records. `SettingsBackup` includes rules/preferences, normalizes dates to whole seconds, and uses epoch-second JSON dates so encode/decode round-trips remain equal.

### Services and permissions

- `InputMethodService`: TIS enumeration, switching, verification; accessed through `InputMethodClient`.
- `BrowserURLService`: Accessibility read of the frontmost browser window/document URL; matching is pure in `BrowserRuleMatcher`.
- `TerminalProgramService`: Terminal/iTerm2 AppleScript → tty → `ps` foreground process group; tmux client-tty → pane-tty; WezTerm CLI active pane. External commands use fixed arguments, never interpolated user input.
- `IndicatorWindowController`: non-activating `NSPanel`; `IndicatorLayout` computes positions; `CaretLocator` reads AX focused element bounds and falls back to the optional `CursorHelperClient`.
- `GlobalHotkeyService`: Carbon `RegisterEventHotKey`; `HotkeyRecorder` captures shortcuts and checks conflicts.
- `InputMethodRepairService`: brief focus-settling CJKV repair. `CursorLagFixService`: administrator-approved `osascript` fix for the macOS 14 experimental cursor.
- Permissions: Accessibility (browser URL, caret, terminal pane, always-on), Automation/Apple Events (Terminal/iTerm2 tty), Login Items. No Screen Recording. Denied/revoked permissions must degrade with a visible state, not crash.

### UI

`TypeLockApp` exposes a `MenuBarExtra` plus a `Settings` scene. `SettingsRootView` has nine sections: General, App Rules, Indicator, Hot Keys, Browser & Domains, Terminal Rules, Exclusions, Troubleshooting, About. The menu bar keeps quick access to current/running/configured/missing/ignored apps, statistics, and settings. The indicator is an independent panel, not part of the main window lifecycle.

## Toolchain and Dependency Pins

- CI pins Xcode 26.3 on `macos-26` runners.
- All direct packages in `Project.swift` use exact versions. `swift-dependencies` is pinned to **1.12.0** and transitive `swift-syntax` to **602.0.0** because newer releases require Swift 6.3.
- `.package.resolved` is the effective pin file; `tuist generate` must not rewrite it. Do not bump these pins without moving the CI toolchain.
- Do not use Xcode <26.3, `swift-dependencies` 1.13+, or package versions whose manifests require Swift 6.3/6.4.

## Testing

- XCTest suite: 225 tests, run by `just test`.
- Pure-logic coverage: migrations, `SwitchResolver`, settings backup, exclusions, indicator layout, hotkeys, browser/terminal matching.
- Reducer tests use `TestStore`; inject `testValue` dependencies and a constant `date` whenever a reducer accesses `now`.
- `just test` rejects Xcode <26.3 via the `check-xcode` recipe.
- There is no `Package.swift`; use `just test` / `xcodebuild`, not `swift test`.

## Branch and Release Model

- `main` is a read-only history mirror.
- `dev` carries all development and releases. Build workflow runs on `dev` pushes and manual dispatch.
- Release workflow runs only for annotated `vX.Y.Z` tags contained in `dev`. It tests, archives a Universal Binary, packages the zip/checksums, signs the Sparkle appcast, attests, and publishes.
- Keep `CHANGELOG.md` release sections in the `## vX.Y.Z` format expected by the release workflow.

## Scope Constraints

Do not implement these without an explicit product decision:

- Per-app forced English punctuation (event tap; deliberately excluded).
- Per-app function-key mode.
- Spotlight/Alfred/Raycast floating-window arbitration.
- Browser address-bar-focus rules; browser matching is URL/domain only.
- Ghostty/Alacritty/zellij terminal program detection; they fall back to app rules.
- Developer ID signing/notarization or App Store distribution.

Localization files: `Base`, `zh-Hans`, `zh-Hant`, `en`, `ja`, `ko`, `fa`. Keep keys and format placeholders identical across all files; common UI is translated, some technical/error strings fall back to English.

## Project Rules

From `.cursorrules` and `Documentation/Architecture.md`:

- Use Tuist; do not hand-edit `.xcodeproj`.
- New switching scenarios must go through `SwitchResolver`.
- New persistence files must be wired into backup/import and tests.
- Use atomic file writes.
- No TODO comments, stub implementations, mock production data, or marketing language in code/docs.
- Run formatting and tests before declaring work complete.
