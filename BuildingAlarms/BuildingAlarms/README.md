# Building Alarms

A sample iOS app demonstrating how to use **AlarmKit** to schedule countdown timers with Live Activities and Dynamic Island integration.

Built with **iOS 26+** and **Xcode 26 Beta**.

## Overview

This app showcases AlarmKit's capabilities for creating persistent countdown timers that continue running even when the app is terminated. Timers are displayed in Live Activities on the Lock Screen, StandBy mode, and Dynamic Island, with interactive controls for pause, resume, and cancel actions.

## Features

- ✅ **Multiple Concurrent Timers** - Run multiple countdown timers simultaneously
- ✅ **SwiftData Persistence** - Timers persist across app launches and terminations
- ✅ **Live Activities** - Real-time countdown display in Lock Screen and StandBy
- ✅ **Dynamic Island** - Compact, minimal, and expanded timer views on iPhone 14 Pro+
- ✅ **Interactive Controls** - Pause, resume, and cancel timers directly from Live Activities
- ✅ **Modern Swift Architecture** - Uses @Observable, SwiftData, and AlarmKit
- ✅ **Liquid Glass Design** - Glass prominent buttons with semantic colors

## Architecture

### Core Components

**Models**
- `TimerEntity.swift` - SwiftData model for timer persistence with state management

**Services**
- `AlarmScheduler.swift` - AlarmKit integration service handling alarm registration, pause/resume, and state synchronization
- `TimerStore.swift` - Observable store managing timer operations as single source of truth

**Views**
- `ContentView.swift` - Main list view with sections for Active, Completed, Ready, and Cancelled timers
- `AddTimerView.swift` - Timer creation UI with horizontal time picker wheel
- `TimerRowView.swift` - Individual timer row with live countdown and control buttons

**Widget Extension**
- `AlarmWidgetLiveActivity.swift` - Live Activity widget with pause/resume/cancel intents

### Data Flow

1. User creates timer → `TimerStore` saves to SwiftData
2. `AlarmScheduler` registers alarm with AlarmKit
3. AlarmKit manages countdown and displays Live Activity
4. Widget intents (pause/resume/cancel) call AlarmKit APIs directly
5. AlarmKit's `alarmUpdates` stream syncs state back to `TimerStore`
6. SwiftUI views update via `@Query` observation

### Key Technical Decisions

**SwiftData with Shared Container**
- Main app and widget extension use `modelContainer.mainContext` for synchronization
- Eliminates need for NotificationCenter-based data sync
- TimerEntity serves as single source of truth

**AlarmKit Integration**
- Uses `AlarmAttributes<TimerMetadata>` for Live Activity integration
- Configures countdown, paused, and alert presentations
- Leverages AlarmKit's persistence instead of re-registering alarms on launch

**Live Activity Intents**
- `PauseTimerIntent`, `ResumeTimerIntent`, `CancelTimerIntent` all conform to `LiveActivityIntent`
- All intents marked with `@MainActor` to avoid background thread publishing errors
- Intents call AlarmKit APIs directly for immediate response

**Race Condition Prevention**
- Single `saveContext()` call before async operations
- No timer modifications inside async Task blocks
- Prevents UICollectionView inconsistency crashes

## Requirements

- iOS 26.0 or later
- Xcode 26 Beta or later
- AlarmKit framework (introduced at WWDC25)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/BuildingAlarms.git
cd BuildingAlarms
```

### 2. Add NSAlarmKitUsageDescription

Add the following key to your `Info.plist` to enable AlarmKit authorization:

```xml
<key>NSAlarmKitUsageDescription</key>
<string>We schedule alerts for timers you create within our app.</string>
```

**Important:** Without this key or if the value is empty, the app cannot schedule alarms with AlarmKit.

### 3. Configure App Groups (Optional)

For production apps sharing data between main app and widget extension:

1. Add App Groups capability to both targets
2. Use the same group identifier (e.g., `group.com.yourcompany.buildingalarms`)
3. Update ModelContainer initialization to use the shared container:

```swift
let config = ModelConfiguration(
    groupContainer: .identifier("group.com.yourcompany.buildingalarms")
)
```

### 4. Build and Run

1. Open `BuildingAlarms.xcodeproj` in Xcode 26 Beta
2. Select your development team in Signing & Capabilities
3. Build and run on a device running iOS 26+ (Simulator supported for development)

## Usage

### Creating a Timer

1. Tap the **+** button in the navigation bar
2. Use the time picker wheel to select hours, minutes, and seconds
3. Tap **Create Timer** to start the countdown

### Controlling Timers

**In the App:**
- Tap **Start/Resume** to begin or continue the countdown
- Tap **Pause** to pause a running timer
- Tap **Cancel** to cancel an active timer
- Swipe to delete any timer

**From Live Activity:**
- Tap **Pause** button to pause the countdown
- Tap **Resume** button to continue from where you left off
- Tap **Cancel** button to stop and cancel the timer
- All controls work even when the app is terminated

### Timer States

- **Ready** - Timer created but not started
- **Running** - Countdown in progress with Live Activity
- **Paused** - Timer paused, shows remaining time in orange
- **Completed** - Timer finished, alarm alerted
- **Cancelled** - Timer manually cancelled

## Code Highlights

### Live Activity with Paused State

```swift
switch context.state.mode {
case .countdown(let countdownState):
    Text(countdownState.fireDate, style: .timer)
        .font(.system(.largeTitle, design: .monospaced))

case .paused(let pausedState):
    let remainingTime = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
    Text(formattedTime(remainingTime))
        .font(.system(.largeTitle, design: .monospaced))
        .foregroundStyle(.orange)
}
```

### Interactive Intent Buttons

```swift
Button(intent: PauseTimerIntent(timerID: timerID)) {
    Label("Pause", systemImage: "pause.fill")
        .foregroundStyle(.white)
}
.buttonStyle(.borderedProminent)
.tint(.orange)
```

### Observer Cleanup Pattern

```swift
private var observers: [NSObjectProtocol] = []

deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
}
```

## Known Limitations

- AlarmKit is currently in beta and APIs may change
- Live Activities require a physical device for full testing
- Dynamic Island features require iPhone 14 Pro or later
- Timer accuracy depends on system resources and background limitations

## Known Issues

- **Widget to App Sync**: Timer state changes made through the Live Activity widget (pause/resume/cancel) do not currently sync back to the main app in real-time. The app will show updated state after relaunch or when triggering a SwiftData context refresh. This is due to limitations in cross-process data synchronization between the widget extension and main app.

## Resources

- [AlarmKit Documentation](https://developer.apple.com/documentation/AlarmKit)
- [WWDC25 Session 230: Wake up to the AlarmKit API](https://developer.apple.com/wwdc25/230)
- [Live Activities Documentation](https://developer.apple.com/documentation/ActivityKit)
- [SwiftData Documentation](https://developer.apple.com/documentation/SwiftData)

## License

This project is available under the MIT license. See the LICENSE file for more info.

## Author

Created as a sample project demonstrating AlarmKit integration with modern Swift concurrency, SwiftData, and Live Activities.

## Acknowledgments

This implementation incorporates best practices from:
- Apple's official AlarmKit sample code
- WWDC25 session materials
- Community feedback on Live Activity intents
