<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Design/AppIcon/Previews/typelock-icon-dark.png">
    <source media="(prefers-color-scheme: light)" srcset="Design/AppIcon/Previews/typelock-icon-default.png">
    <img src="Design/AppIcon/Previews/typelock-icon-default.png" width="160" alt="TypeLock icon">
  </picture>
</p>

<h1 align="center">TypeLock</h1>

<p align="center">TypeLock is a native macOS menu bar utility for switching input methods per app. Choose how each app should behave, set the rule for unconfigured apps, and let TypeLock switch to the right input method when the frontmost app changes.</p>

<p align="center">
  <a href="https://swift.org"><img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-orange.svg"></a>
  <a href="https://www.apple.com/macos/"><img alt="Platform" src="https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <a href="https://github.com/zbl-jerry/TypeLock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/zbl-jerry/TypeLock?include_prereleases"></a>
  <a href="https://github.com/zbl-jerry/TypeLock/pulls"><img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"></a>
</p>

<p align="center">🇨🇳 <a href="README.zh-CN.md">简体中文</a> · 🇺🇸 <strong>English</strong></p>

> **Fork notice:** TypeLock is an independent fork of [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch), maintained by [zbl-jerry](https://github.com/zbl-jerry). The `main` branch mirrors upstream; the `dev` branch is where TypeLock development, builds, and releases happen.

## ✨ Highlights

- **Switch automatically by app.** TypeLock watches the frontmost app and applies its saved input method rule as you move between apps, except for apps you choose to ignore.
- **Choose the behavior that fits.** Let an app inherit the default rule, remember its `Last Switch`, select a `Specific Input Method`, or ignore apps you do not want TypeLock to manage.
- **Configure apps where you find them.** Set a rule for the current app, review running apps by configuration status, or manage every saved rule without leaving the menu bar.
- **Keep rules and results tidy.** Find rules for missing apps, remove stale settings, review successful switch counts, and clear statistics when needed.
- **Fit TypeLock into your workflow.** Launch it at login, let Sparkle check silently for updates, open project and support links from `Help & About`, or press `Command + Q` to quit.

## 🪶 Native and Lightweight

- **Truly native.** TypeLock's app business code is written in Swift and built with SwiftUI and The Composable Architecture (TCA). It uses `MenuBarExtra` and `LSUIElement` instead of an Electron runtime or embedded WebView.
- **Focused and lightweight.** TypeLock runs as a menu bar utility without shipping a browser engine or server component. App rules, the default rule, and switch statistics stay on your Mac.
- **At home on macOS.** The interface follows Light and Dark Mode automatically. On macOS 26, native SwiftUI controls use the system-provided Liquid Glass appearance where appropriate, while macOS 14 and macOS 15 retain their native system styling. TypeLock does not simulate Liquid Glass with custom visual effects.
- **Built for modern Macs.** The release workflow uses Xcode 26.3 and verifies every release as a Universal Binary for both Apple Silicon and Intel Macs.

## 💻 System Requirements

- macOS 14.0 or later
- Enabled macOS keyboard layouts or input methods
- macOS permissions needed for app activation monitoring, system input method switching, and optional Login Items

## 📦 Installation

TypeLock is distributed as a Universal Binary `.zip` from [GitHub Releases](https://github.com/zbl-jerry/TypeLock/releases). Every release is built and published from the `dev` branch. This fork has no Homebrew cask, and its releases are unsigned and not notarized.

### Manual Installation

1. Download the latest build from [Releases](https://github.com/zbl-jerry/TypeLock/releases).
2. Drag `TypeLock.app` to the Applications folder.
3. In Applications, Control-click or right-click `TypeLock.app`, choose `Open`, then confirm that you want to open it.
4. If macOS still blocks the app, open System Settings → Privacy & Security, find the TypeLock security message, and choose `Open Anyway`.
5. Grant any system permissions macOS requests.
6. TypeLock checks GitHub Releases silently. When a new version is available, the menu shows its version; click it to open the update window.

## 🧭 Usage

1. Launch TypeLock. Its keyboard icon appears in the menu bar.
2. Open the menu and use `Current App` to configure the frontmost app.
3. Use `Running · Unconfigured` to assign rules to running apps that do not have one yet.
4. Use `Running · Configured` and `All Configured Apps` to review and change existing app rules.
5. For each app, choose `Default` to inherit the fallback, `Last Switch`, or a specific input method.
6. Choose `Ignore This App` to stop automatic switching and hide the app from the regular lists. Restore one or all apps from `Ignored Apps` to recover their previous rules.
7. Use `Default Rule for Unconfigured Apps` to set the fallback behavior for apps without their own rule.
8. Check `Missing Apps` and `Switches` when you want to clean missing rules or review successful switches.

## 🔒 Privacy and Permissions

- App rules, the Default Rule for Unconfigured Apps, and switch statistics are stored locally.
- TypeLock has no server-side component in this repository.
- TypeLock contacts its GitHub appcast at startup and periodically while running to check for updates. Background checks only update the menu status and never present UI, download, or install automatically; the Sparkle update window opens only after you click `Check for Updates…` or `New Version … Available…`.
- Input method switching uses macOS system input sources.
- Launch at Login uses macOS Login Items, with a LaunchAgent fallback when needed.

## 🧰 Tech Stack

This project uses:

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) `1.26.0` for app architecture and state management
- [Sharing](https://github.com/pointfreeco/swift-sharing) `2.9.1` for file-backed shared state
- [Sparkle](https://github.com/sparkle-project/Sparkle) `2.9.4` for silent automatic checks, manual updates, and appcast support
- Point-Free support libraries: CasePaths, Dependencies, and PerceptionCore
- [Tuist](https://github.com/tuist/tuist) for project generation and build configuration

## 🧪 Development

### Requirements

- Xcode 26.3+
- Swift 5.9+
- macOS 14.0+
- [just](https://github.com/casey/just)
- [Tuist](https://github.com/tuist/tuist)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) (version pinned in `.swiftformat-version`)
- [ImageMagick](https://imagemagick.org/)
- RTK (`rtk`, required by the screenshot generation script)

### Build Steps

Install the required development tools:

```bash
brew install just swiftformat
brew tap tuist/tuist
brew install --formula tuist
```

Clone and generate the Xcode project:

```bash
git clone https://github.com/zbl-jerry/TypeLock.git
cd TypeLock
git checkout dev
tuist generate
open TypeLock.xcworkspace
```

The `main` branch tracks upstream TypeSwitch, so development and release work should happen on `dev`.

Run the same formatting and test checks required by pull requests:

```bash
just check
```

To regenerate the deterministic, privacy-safe README screenshots, grant your terminal or Codex Screen Recording and Accessibility permissions, then run the command below. The script uses an isolated `TypeLockScreenshots` demo copy, so your usual TypeLock can stay running.

```bash
./script/generate_readme_screenshots.sh
```

### Continuous Integration

- The **Build** workflow runs on every push to `dev` and on manual `workflow_dispatch`. It generates the Xcode project, runs the full test suite, archives a Universal Binary, packages `TypeLock-macOS-universal.zip`, and uploads the zip with checksums as a GitHub Actions artifact.
- The **PR Checks** workflow runs release-script tests, workflow linting, SwiftFormat checks, and unit tests on pull requests.

### Release Workflow

Production releases are built by GitHub Actions when a strict, annotated `vX.Y.Z` tag contained in `dev` is pushed:

```bash
git checkout dev
git tag -a v0.10.4 -m "TypeLock v0.10.4"
git push origin v0.10.4
```

The workflow validates the tag against `origin/dev`, runs tests, builds a universal macOS app, packages a zip, publishes its SHA-256 checksum, signs the Sparkle `appcast.xml` with EdDSA, generates a GitHub Artifact Attestation for the release zip, and publishes a GitHub Release. Add a matching `## vX.Y.Z` section to `CHANGELOG.md` before tagging.

Do not dispatch or rebuild an already published tag. If a release run fails, rerun only its failed jobs from the Actions UI, or use:

```bash
FAILED_RUN_ID=123456789 # Replace with the failed workflow run ID.
gh run rerun "$FAILED_RUN_ID" --failed --repo zbl-jerry/TypeLock
```

If the release guard reports that an incomplete draft Release already exists, inspect it first:

```bash
gh release view v0.10.0 --repo zbl-jerry/TypeLock --json isDraft,url,assets
```

Only after confirming `isDraft` is `true`, delete that draft without deleting the tag, then rerun only the failed jobs:

```bash
gh release delete v0.10.0 --repo zbl-jerry/TypeLock --yes
FAILED_RUN_ID=123456789 # Replace with the failed workflow run ID.
gh run rerun "$FAILED_RUN_ID" --failed --repo zbl-jerry/TypeLock
```

The workflow refuses to rebuild or overwrite a completed, published Release. Publish fixes under a new SemVer tag instead.

After downloading the release zip, verify its build provenance with GitHub CLI:

```bash
gh attestation verify TypeLock-macOS-universal.zip --repo zbl-jerry/TypeLock
```

## 🙏 Acknowledgments

TypeLock is a fork of [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch) and was inspired by:

- [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch), the upstream per-app input method switcher
- [SwitchKey](https://github.com/itsuhane/SwitchKey), an input method switcher for macOS
- The Swift and SwiftUI community
- Contributors and users who shared feedback
