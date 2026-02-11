//
//  AlarmScheduler.swift
//  BuildingAlarms
//
//  Created by Claude Agent on 11/2/26.
//

import Foundation
import SwiftUI
import AlarmKit

/// Service responsible for managing AlarmKit integration
/// Handles alarm registration, cancellation, and authorization
/// Ensures no duplicate alarms are registered
@Observable
final class AlarmScheduler {
    // Singleton instance for app-wide access
    static let shared = AlarmScheduler()
    
    private let alarmManager = AlarmManager.shared
    
    // Track currently registered alarm IDs to prevent duplicates
    private var registeredAlarmIDs: Set<UUID> = []
    
    // Track if we've synced with AlarmKit on launch
    private var hasInitializedFromAlarmKit = false
    
    private init() {
        // Start observing alarm updates from AlarmKit
        Task {
            await observeAlarmUpdates()
        }
    }
    
    /// Initialize registered alarm IDs from AlarmKit's current state
    /// This ensures we don't duplicate alarms that already exist
    func syncWithAlarmKit() async {
        guard !hasInitializedFromAlarmKit else { return }
        
        // Query current alarms from AlarmKit via the alarmUpdates stream
        // The first emission contains all currently scheduled alarms
        hasInitializedFromAlarmKit = true
    }
    
    // MARK: - Authorization
    
    /// Request permission to schedule alarms
    /// Must be called before scheduling any alarms
    func requestAuthorization() async -> Bool {
        do {
            let state = try await alarmManager.requestAuthorization()
            return state == .authorized
        } catch {
            print("Error requesting alarm authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Alarm Registration
    
    /// Schedule a countdown timer alarm
    /// Prevents duplicate registrations using the timer's UUID
    /// - Parameters:
    ///   - timerID: The UUID of the timer (used as alarm ID)
    ///   - duration: The countdown duration in seconds
    /// - Returns: Success status
    func scheduleCountdownAlarm(for timerID: UUID, duration: TimeInterval) async -> Bool {
        // Prevent duplicate registration
        guard !registeredAlarmIDs.contains(timerID) else {
            print("Alarm already registered for timer: \(timerID)")
            return true
        }
        
        do {
            // Create countdown duration
            let countdownDuration = Alarm.CountdownDuration(
                preAlert: duration,
                postAlert: nil
            )
            
            // Configure alarm presentation for countdown
            let pauseButton = AlarmButton(
                text: "Pause",
                textColor: .blue,
                systemImageName: "pause.circle"
            )
            
            let countdownPresentation = AlarmPresentation.Countdown(
                title: "Timer",
                pauseButton: pauseButton
            )
            
            let resumeButton = AlarmButton(
                text: "Resume",
                textColor: .blue,
                systemImageName: "play.circle"
            )
            
            let pausedPresentation = AlarmPresentation.Paused(
                title: "Timer Paused",
                resumeButton: resumeButton
            )
            
            // Alert presentation uses system-provided stop button (iOS 26.1+)
            let alertPresentation = AlarmPresentation.Alert(
                title: "Timer Complete!",
                secondaryButton: nil,
                secondaryButtonBehavior: nil
            )
            
            let presentation = AlarmPresentation(
                alert: alertPresentation,
                countdown: countdownPresentation,
                paused: pausedPresentation
            )
            
            // Create alarm attributes with metadata
            let attributes = AlarmAttributes(
                presentation: presentation,
                metadata: TimerMetadata(timerID: timerID),
                tintColor: .blue
            )
            
            // Create alarm configuration
            let configuration = AlarmManager.AlarmConfiguration(
                countdownDuration: countdownDuration,
                schedule: nil,
                attributes: attributes,
                stopIntent: StopTimerIntent(timerID: timerID),
                secondaryIntent: nil
            )
            
            // Schedule the alarm with AlarmKit
            let _ = try await alarmManager.schedule(id: timerID, configuration: configuration)
            
            // Track registration
            registeredAlarmIDs.insert(timerID)
            
            print("Successfully scheduled alarm for timer: \(timerID)")
            return true
            
        } catch {
            print("Error scheduling alarm: \(error)")
            return false
        }
    }
    
    /// Cancel an alarm for a specific timer
    /// - Parameter timerID: The UUID of the timer
    func cancelAlarm(for timerID: UUID) async {
        do {
            try alarmManager.cancel(id: timerID)
            registeredAlarmIDs.remove(timerID)
            print("Successfully cancelled alarm for timer: \(timerID)")
        } catch {
            print("Error cancelling alarm: \(error)")
        }
    }
    
    /// Pause an alarm for a specific timer
    /// - Parameter timerID: The UUID of the timer
    func pauseAlarm(for timerID: UUID) async {
        do {
            try alarmManager.pause(id: timerID)
            print("Successfully paused alarm for timer: \(timerID)")
        } catch {
            print("Error pausing alarm: \(error)")
        }
    }
    
    /// Resume a paused alarm
    /// - Parameter timerID: The UUID of the timer
    func resumeAlarm(for timerID: UUID) async {
        do {
            try alarmManager.resume(id: timerID)
            print("Successfully resumed alarm for timer: \(timerID)")
        } catch {
            print("Error resuming alarm: \(error)")
        }
    }
    
    // MARK: - Alarm Observation
    
    /// Observe alarm state changes from AlarmKit
    /// This ensures we have the latest state even when app isn't running
    private func observeAlarmUpdates() async {
        for await alarms in alarmManager.alarmUpdates {
            handleAlarmUpdates(alarms)
        }
    }
    
    /// Process alarm updates from AlarmKit
    /// - Parameter alarms: Array of current alarms
    private func handleAlarmUpdates(_ alarms: [Alarm]) {
        // Update our tracking of registered alarms based on what AlarmKit reports
        let currentAlarmIDs = Set(alarms.map { $0.id })
        
        // Sync our tracked IDs with AlarmKit's state
        // This is the source of truth for which alarms are actually scheduled
        registeredAlarmIDs = currentAlarmIDs
        
        // Notify TimerStore of updates so it can sync timer state
        NotificationCenter.default.post(
            name: .alarmStateChanged,
            object: nil,
            userInfo: ["alarms": alarms]
        )
    }
}

// MARK: - Alarm Metadata

/// Metadata associated with each alarm
/// Conforms to AlarmMetadata protocol required by AlarmKit
struct TimerMetadata: AlarmMetadata {
    let timerID: UUID
}

// MARK: - App Intents

import AppIntents

/// Intent for stopping a timer from the alarm UI
struct StopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"
    
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
        // Parse UUID from string
        guard let uuid = UUID(uuidString: timerID) else {
            return .result()
        }
        
        // Notify the app to stop the timer
        NotificationCenter.default.post(
            name: .stopTimerFromIntent,
            object: nil,
            userInfo: ["timerID": uuid]
        )
        return .result()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let alarmStateChanged = Notification.Name("alarmStateChanged")
    static let stopTimerFromIntent = Notification.Name("stopTimerFromIntent")
    static let cancelTimerFromIntent = Notification.Name("cancelTimerFromIntent")
}
