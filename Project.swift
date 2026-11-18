import ProjectDescription

// MARK: - Version

let appVersion = Environment.appVersion.getString(default: "0.0.0")
let buildVersion = Environment.buildVersion.getString(default: "0")

let project = Project(
    name: "TypeLock",
    options: .options(
        defaultKnownRegions: ["zh-Hans", "zh-Hant", "en"],
        developmentRegion: "zh-Hans"
    ),
    packages: [
        .remote(url: "https://github.com/pointfreeco/swift-case-paths", requirement: .upToNextMajor(from: "1.8.0")),
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "1.26.0")),
        .remote(url: "https://github.com/pointfreeco/swift-dependencies", requirement: .upToNextMajor(from: "1.14.1")),
        .remote(url: "https://github.com/pointfreeco/swift-perception", requirement: .upToNextMajor(from: "2.0.10")),
        .remote(url: "https://github.com/pointfreeco/swift-sharing", requirement: .upToNextMajor(from: "2.9.1")),
        .remote(url: "https://github.com/sparkle-project/Sparkle", requirement: .upToNextMajor(from: "2.9.4")),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": SettingValue(stringLiteral: "5.9"),
            "DEVELOPMENT_LANGUAGE": SettingValue(stringLiteral: "zh-Hans"),
            "SWIFT_EMIT_LOC_STRINGS": SettingValue(stringLiteral: "YES"),
            "MARKETING_VERSION": SettingValue(stringLiteral: appVersion),
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: buildVersion),
            // 宏定义支持
            "SWIFT_STRICT_CONCURRENCY": SettingValue(stringLiteral: "complete"),
            "ENABLE_MACROS": SettingValue(stringLiteral: "YES"),
            "SWIFT_MACRO_DEBUGGING": SettingValue(stringLiteral: "YES"),
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        .target(
            name: "TypeLock",
            destinations: .macOS,
            product: .app,
            bundleId: "io.github.zbl-jerry.TypeLock",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .dictionary([
                "LSUIElement": true, // 设置为纯菜单栏应用
                "CFBundleExecutable": "$(EXECUTABLE_NAME)",
                "CFBundleDevelopmentRegion": "zh-Hans", // 设置默认开发区域为简体中文
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleInfoDictionaryVersion": "6.0",
                "CFBundleLocalizations": ["zh-Hans", "zh-Hant", "en"], // 支持的语言列表
                "CFBundleName": "$(PRODUCT_NAME)",
                "CFBundlePackageType": "APPL",
                "AppleLanguages": ["zh-Hans"], // 设置默认语言为简体中文
                "NSHumanReadableCopyright": "Copyright © 2026 zbl-jerry. All rights reserved.",
                "LSApplicationCategoryType": "public.app-category.utilities",
                "LSMinimumSystemVersion": "14.0",
                "NSPrincipalClass": "NSApplication",
                "CFBundleShortVersionString": .string(appVersion), // 市场版本号
                "CFBundleVersion": .string(buildVersion), // 构建版本号
                "SUFeedURL": "https://github.com/zbl-jerry/TypeLock/releases/latest/download/appcast.xml",
                "SUPublicEDKey": "DptenP/WN+2Tz4Q6A7M9P2FGM5/rqXfeO1D5i1L6x10=",
                "SUAllowsAutomaticUpdates": false,
                "SUEnableAutomaticChecks": true,
                "SUAutomaticallyUpdate": false,
            ]),
            sources: ["TypeLock/Sources/**"],
            resources: ["TypeLock/Resources/**"],
            entitlements: .file(path: "Tuist/Signing/TypeLock.entitlements"),
            scripts: [
                .post(
                    script: """
                    mkdir -p "${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Helpers"
                    cp "${BUILT_PRODUCTS_DIR}/TypeLockCursorHelper" "${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Helpers/TypeLockCursorHelper"
                    """,
                    name: "Embed Cursor Helper",
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                .package(product: "CasePaths"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .package(product: "PerceptionCore"),
                .package(product: "Sharing"),
                .package(product: "Sparkle"),
                .target(name: "TypeLockCursorHelper"),
            ],
            settings: .settings(
                base: [
                    // 宏定义支持
                    "OTHER_CODE_SIGN_FLAGS": "--deep",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "ENABLE_MACROS": "YES",
                    "SWIFT_MACRO_DEBUGGING": "YES",
                    "SWIFT_MACRO_EXPANSION": "YES",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release"),
                ]
            )
        ),
        .target(
            name: "TypeLockCursorHelper",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "io.github.zbl-jerry.TypeLock.CursorHelper",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["TypeLockCursorHelper/**"],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "5.9",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release"),
                ]
            )
        ),
        .target(
            name: "TypeLockTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.github.zbl-jerry.TypeLockTests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["TypeLockTests/**"],
            dependencies: [
                .package(product: "CasePaths"),
                .target(name: "TypeLock"),
                .package(product: "ComposableArchitecture"),
                .package(product: "Dependencies"),
                .package(product: "Sharing"),
            ],
            settings: .settings(
                base: [
                    "BUNDLE_LOADER": "$(TEST_HOST)",
                    "SWIFT_VERSION": "5.9",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/TypeLock.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TypeLock",
                    "TEST_TARGET_NAME": "TypeLock",
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release"),
                ]
            )
        ),
    ]
)
