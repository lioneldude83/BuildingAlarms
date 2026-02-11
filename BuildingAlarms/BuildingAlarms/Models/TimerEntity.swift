//
//  TimerEntity.swift
//  BuildingAlarms
//
//  Created by Claude Agent on 11/2/26.
//

import Foundation
import SwiftData

/// Represents the current state of a timer
enum TimerState: String, Codable {
    case idle
    case running
    case paused
    case completed
    case cancelled
}

/// SwiftData model representing a countdown timer
/// Persists timer state across app launches and terminations
@Model
final class TimerEntity {
    /// Unique identifier for the timer
    var id: UUID
    
    /// When the timer was created
    var createdAt: Date
    
    /// Total duration of the timer in seconds
    var duration: TimeInterval
    
    /// Remaining time when paused or idle
    var remainingTime: TimeInterval
    
    /// The date when the timer should fire (nil when paused/idle)
    var fireDate: Date?
    
    /// Current state of the timer
    var state: TimerState
    
    /// AlarmKit identifier for managing the alarm
    /// Format: "timer-{uuid}" for deterministic tracking
    var alarmIdentifier: String?
    
    init(duration: TimeInterval) {
        self.id = UUID()
        self.createdAt = Date()
        self.duration = duration
        self.remainingTime = duration
        self.fireDate = nil
        self.state = .idle
        self.alarmIdentifier = nil
    }
    
    /// Computed property to get the stable alarm identifier
    var stableAlarmID: UUID {
        // Use the timer's UUID as the alarm ID for deterministic tracking
        return id
    }
    
    /// Calculate current remaining time based on fire date
    /// Returns 0 if timer has expired
    func calculateRemainingTime() -> TimeInterval {
        guard let fireDate = fireDate, state == .running else {
            return remainingTime
        }
        
        let remaining = fireDate.timeIntervalSinceNow
        return max(0, remaining)
    }
    
    /// Format remaining time as HH:MM:SS string
    func formattedRemainingTime() -> String {
        let time = calculateRemainingTime()
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
