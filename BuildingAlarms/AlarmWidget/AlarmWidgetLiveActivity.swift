//
//  AlarmWidgetLiveActivity.swift
//  AlarmWidget
//
//  Created by Lionel Ng on 11/2/26.
//

import AlarmKit
import WidgetKit
import SwiftUI
import AppIntents

/// Metadata for timer alarms - must match the one in the main app
struct TimerMetadata: AlarmMetadata {
    let timerID: UUID
}

/// Widget extension for AlarmKit countdown presentations
/// Displays countdown timers in Lock Screen and Dynamic Island
struct AlarmWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // Use ActivityConfiguration with AlarmAttributes for AlarmKit integration
        ActivityConfiguration(for: AlarmAttributes<TimerMetadata>.self) { context in
            // Lock screen/banner UI for countdown
            VStack(spacing: 12) {
                Text("Timer")
                    .font(.headline)
                
                // Display live countdown timer or paused time from AlarmPresentationState
                switch context.state.mode {
                case .countdown(let countdownState):
                    // Use Text with timer style for automatic countdown
                    Text(countdownState.fireDate, style: .timer)
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                        .monospacedDigit()
                    
                case .paused(let pausedState):
                    // Show remaining time when paused
                    let remainingTime = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                    Text(formattedTime(remainingTime))
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                    
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                default:
                    EmptyView()
                }
                
                // Control buttons
                if let timerID = context.attributes.metadata?.timerID {
                    HStack(spacing: 12) {
                        switch context.state.mode {
                        case .countdown:
                            // Pause button when running
                            Button(intent: PauseTimerIntent(timerID: timerID)) {
                                Label("Pause", systemImage: "pause.fill")
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            
                            // Cancel button
                            Button(intent: CancelTimerIntent(timerID: timerID)) {
                                Label("Cancel", systemImage: "xmark")
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                        case .paused:
                            // Resume button when paused
                            Button(intent: ResumeTimerIntent(timerID: timerID)) {
                                Label("Resume", systemImage: "play.fill")
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            
                            // Cancel button
                            Button(intent: CancelTimerIntent(timerID: timerID)) {
                                Label("Cancel", systemImage: "xmark")
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.2))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI for countdown in Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.mode.isPaused ? "pause.circle.fill" : "timer")
                        .foregroundStyle(context.state.mode.isPaused ? .orange : .blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    switch context.state.mode {
                    case .countdown(let countdownState):
                        Text(countdownState.fireDate, style: .timer)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        
                    case .paused(let pausedState):
                        let remainingTime = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                        Text(formattedTime(remainingTime))
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundStyle(.orange)
                        
                    default:
                        EmptyView()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(context.state.mode.isPaused ? "Timer Paused" : "Timer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        // Control buttons
                        if let timerID = context.attributes.metadata?.timerID {
                            HStack(spacing: 8) {
                                switch context.state.mode {
                                case .countdown:
                                    // Pause button when running
                                    Button(intent: PauseTimerIntent(timerID: timerID)) {
                                        Image(systemName: "pause.fill")
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                    
                                    Spacer()
                                    
                                    // Cancel button
                                    Button(intent: CancelTimerIntent(timerID: timerID)) {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    
                                case .paused:
                                    // Resume button when paused
                                    Button(intent: ResumeTimerIntent(timerID: timerID)) {
                                        Image(systemName: "play.fill")
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    
                                    Spacer()
                                    
                                    // Cancel button
                                    Button(intent: CancelTimerIntent(timerID: timerID)) {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.mode.isPaused ? "pause.circle.fill" : "timer")
                    .foregroundStyle(context.state.mode.isPaused ? .orange : .blue)
            } compactTrailing: {
                switch context.state.mode {
                case .countdown(let countdownState):
                    Text(countdownState.fireDate, style: .timer)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .monospacedDigit()
                    
                case .paused(let pausedState):
                    let remainingTime = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                    Text(formattedTime(remainingTime))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                    
                default:
                    EmptyView()
                }
            } minimal: {
                Image(systemName: context.state.mode.isPaused ? "pause.circle.fill" : "timer")
                    .foregroundStyle(context.state.mode.isPaused ? .orange : .blue)
            }
            .keylineTint(context.state.mode.isPaused ? Color.orange : Color.blue)
        }
    }
    
    // Helper to format time as HH:MM:SS
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let time = max(0, timeInterval)
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// Extension to check alarm presentation mode
extension AlarmPresentationState.Mode {
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }
}

// MARK: - App Intents for Live Activity Controls
/// Intent to pause a timer from Live Activity
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    init() {
        self.timerID = ""
    }
    
    init(timerID: UUID) {
        self.timerID = timerID.uuidString
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else {
            return .result()
        }
        
        // Pause the alarm via AlarmKit
        try AlarmManager.shared.pause(id: uuid)
        
        return .result()
    }
}

/// Intent to resume a timer from Live Activity
struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    init() {
        self.timerID = ""
    }
    
    init(timerID: UUID) {
        self.timerID = timerID.uuidString
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else {
            return .result()
        }
        
        // Resume the alarm via AlarmKit
        try AlarmManager.shared.resume(id: uuid)
        
        return .result()
    }
}

/// Intent to cancel a timer from Live Activity
struct CancelTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel Timer"
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    init() {
        self.timerID = ""
    }
    
    init(timerID: UUID) {
        self.timerID = timerID.uuidString
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: timerID) else {
            return .result()
        }
        
        // Cancel the alarm via AlarmKit
        try AlarmManager.shared.cancel(id: uuid)
        
        // Notify the app to update timer state
        NotificationCenter.default.post(
            name: Notification.Name("cancelTimerFromIntent"),
            object: nil,
            userInfo: ["timerID": uuid]
        )
        
        return .result()
    }
}


