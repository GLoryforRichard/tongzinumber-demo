# tongzinumber-demo

iOS 定时提醒 Demo，支持在系统通知中显示滑块让用户选择下一次提醒时间。这是一个功能演示项目，最终需要整合到完整应用中。

## 功能概述

1. 用户在主界面通过滑块设置 N 秒后的提醒
2. 系统通知弹出时，用户可以**长按/下拉**通知展开自定义 UI
3. 展开的通知中包含滑块，用户可以实时选择下一次提醒的秒数
4. 确认后自动调度下一次通知，形成循环提醒

## 技术架构

```
┌─────────────────────────┐      App Groups       ┌──────────────────────────────┐
│       Main App          │◄─────────────────────►│  Notification Content Ext    │
│       (SwiftUI)         │                       │        (UIKit)               │
│                         │                       │                              │
│  - 秒数输入滑块 (10-300) │                       │  - UISlider (10-300秒)       │
│  - 设置提醒按钮          │                       │  - 实时显示选择秒数的 Label   │
│  - 通知权限管理          │                       │  - 确认按钮                   │
│                         │                       │  - 调度下一次通知             │
└─────────────────────────┘                       └──────────────────────────────┘
```

## 关键技术决策

### 为什么使用 Notification Content Extension？

iOS 标准通知只支持按钮和文本输入，**不支持滑块等自定义控件**。要实现滑块必须使用 Notification Content Extension：

- 扩展使用 **UIKit**（SwiftUI 在通知扩展中支持有限）
- 必须设置 `UNNotificationExtensionUserInteractionEnabled = true` 才能响应用户交互
- 通知的 `categoryIdentifier` 必须与扩展 Info.plist 中的 `UNNotificationExtensionCategory` 匹配

### App Groups 数据共享

主应用和扩展是**独立的进程**，无法直接共享数据。使用 App Groups 通过 `UserDefaults(suiteName:)` 实现数据共享：

- Group ID: `group.cupicelemon.tongzinumber-demo`
- 两个 target 都需要添加相同的 App Groups capability

## 文件结构

```
tongzinumber-demo/
├── tongzinumber_demoApp.swift    # 应用入口，配置 AppDelegate
├── ContentView.swift              # 主界面 UI (SwiftUI)
├── Services/
│   └── NotificationManager.swift  # 通知权限、category 注册、调度
├── Models/
│   └── ReminderData.swift         # App Groups 共享数据模型
└── tongzinumber-demo.entitlements # App Groups 权限

NotificationContent/
├── NotificationViewController.swift  # 通知扩展 UI (UIKit)
├── Base.lproj/MainInterface.storyboard
├── Info.plist                        # 扩展配置（category、交互开关）
└── NotificationContent.entitlements  # App Groups 权限
```

## 核心代码说明

### 1. NotificationManager.swift

负责通知的核心逻辑：

```swift
// 注册通知 category，必须与扩展 Info.plist 中的配置一致
func registerCategory() {
    let category = UNNotificationCategory(
        identifier: "TIMER_REMINDER",  // 关键：必须匹配
        actions: [...],
        intentIdentifiers: [],
        options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
}

// 调度通知时必须设置 categoryIdentifier
func scheduleNotification(seconds: Int) async throws {
    let content = UNMutableNotificationContent()
    content.categoryIdentifier = "TIMER_REMINDER"  // 关键：触发扩展
    // ...
}
```

### 2. NotificationViewController.swift

通知扩展的核心，使用 UIKit 构建 UI：

```swift
class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let slider = UISlider()
    private let valueLabel = UILabel()

    // 滑块值变化时实时更新标签
    @objc func sliderValueChanged(_ sender: UISlider) {
        valueLabel.text = "\(Int(sender.value)) 秒"
    }

    // 确认按钮：保存到 App Groups + 调度下一次通知
    @objc func confirmTapped() {
        let seconds = Int(slider.value)
        userDefaults?.set(seconds, forKey: "nextReminderSeconds")
        scheduleNextNotification(seconds: seconds)
        extensionContext?.dismissNotificationContentExtension()
    }
}
```

### 3. Info.plist 关键配置

```xml
<key>NSExtensionAttributes</key>
<dict>
    <!-- 必须与主应用注册的 category 一致 -->
    <key>UNNotificationExtensionCategory</key>
    <string>TIMER_REMINDER</string>

    <!-- 必须为 true 才能响应滑块交互 -->
    <key>UNNotificationExtensionUserInteractionEnabled</key>
    <true/>
</dict>
```

## 整合到完整应用的注意事项

### 1. Bundle ID 配置

当前配置：
- 主应用: `cupicelemon.tongzinumber-demo`
- 扩展: `cupicelemon.tongzinumber-demo.NotificationContent`

整合时需要：
- 扩展的 Bundle ID 必须以主应用的 Bundle ID 为前缀
- 更新 App Groups ID 并确保两个 target 都使用相同的值

### 2. 需要复制的文件

1. **Services/NotificationManager.swift** → 合并到主应用的通知管理逻辑
2. **Models/ReminderData.swift** → 如果已有 App Groups 数据层，合并键名
3. **NotificationContent/** 整个目录 → 作为新 target 添加到项目

### 3. 项目配置步骤

1. **添加 Notification Content Extension target**
   - File → New → Target → Notification Content Extension

2. **配置 App Groups**（两个 target 都需要）
   - Signing & Capabilities → + Capability → App Groups

3. **配置 Info.plist**
   - `UNNotificationExtensionCategory`: 与代码中注册的一致
   - `UNNotificationExtensionUserInteractionEnabled`: `YES`

4. **在 AppDelegate 中注册 category**
   - 调用 `NotificationManager.shared.registerCategory()`

### 4. 测试要点

- **必须在真机上测试**，模拟器对 Notification Content Extension 支持不完整
- 通知到达后需要**长按或下拉**才能看到自定义 UI
- 确认滑块交互正常、数值实时更新
- 确认点击确认后能调度下一次通知

## 已知限制

1. 模拟器上 Notification Content Extension 可能无法正常显示自定义 UI
2. 扩展中无法使用 SwiftUI（或支持非常有限）
3. 扩展的内存限制较严格，避免加载大资源

## 依赖

- iOS 17.0+
- Xcode 15.0+
- 无第三方依赖
