//
//  TimerStore.swift
//  BuildingAlarms
//
//  Created by Claude Agent on 11/2/26.
//

import Foundation
import SwiftData
import AlarmKit

/// Observable store managing all timer operations
/// Acts as the single source of truth for timer state
@Observable
final class TimerStore {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let alarmScheduler = AlarmScheduler.shared
    
    // Track if authorization has been requested
    private var isAuthorized = false
    
    // Store observer tokens for cleanup
    private var observers: [NSObjectProtocol] = []
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // Use the main context from the container to match SwiftUI's @Query
        self.modelContext = modelContainer.mainContext
        
        // Set up notification observers
        setupNotificationObservers()
        
        // Request alarm authorization on init
        Task {
            await requestAlarmAuthorization()
        }
    }
    
    deinit {
        // Clean up observers when TimerStore is deallocated
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Authorization
    
    /// Request AlarmKit authorization
    private func requestAlarmAuthorization() async {
        isAuthorized = await alarmScheduler.requestAuthorization()
        if !isAuthorized {
            print("Alarm authorization denied")
        }
    }
    
    // MARK: - Timer Creation
    
    /// Create a new timer with specified duration
    /// - Parameter duration: Timer duration in seconds
    func createTimer(duration: TimeInterval) {
        guard duration > 0 else { return }
        
        let timer = TimerEntity(duration: duration)
        modelContext.insert(timer)
        saveContext()
    }
    
    // MARK: - Timer Control
    
    /// Start a timer
    /// Computes fire date, registers alarm, and updates state
    /// - Parameter timer: The timer to start
    func startTimer(_ timer: TimerEntity) {
        guard timer.state == .idle || timer.state == .paused else { return }
        
        // Compute fire date
        let fireDate = Date().addingTimeInterval(timer.remainingTime)
        let duration = timer.remainingTime
        let alarmID = timer.stableAlarmID
        
        timer.fireDate = fireDate
        timer.state = .running
        timer.alarmIdentifier = alarmID.uuidString // Set optimistically
        
        // Save once before async operation
        saveContext()
        
        // Register alarm with AlarmKit asynchronously
        // Don't modify timer state here to avoid race conditions with SwiftUI List
        Task { @MainActor in
            let success = await alarmScheduler.scheduleCountdownAlarm(
                for: alarmID,
                duration: duration
            )
            
            if !success {
                print("Failed to register alarm for timer: \(alarmID)")
                // AlarmKit registration failed - alarm state sync will handle cleanup
            }
        }
    }
    
    /// Pause a running timer
    /// Cancels alarm, computes remaining time, and updates state
    /// - Parameter timer: The timer to pause
    func pauseTimer(_ timer: TimerEntity) {
        guard timer.state == .running else { return }
        
        // Compute remaining time before pausing
        timer.remainingTime = timer.calculateRemainingTime()
        timer.fireDate = nil
        timer.state = .paused
        
        saveContext()
        
        // Cancel alarm asynchronously
        Task { @MainActor in
            await alarmScheduler.pauseAlarm(for: timer.stableAlarmID)
        }
    }
    
    /// Resume a paused timer
    /// Similar to start but for already-started timers
    /// - Parameter timer: The timer to resume
    func resumeTimer(_ timer: TimerEntity) {
        guard timer.state == .paused else { return }
        
        // Compute new fire date
        let fireDate = Date().addingTimeInterval(timer.remainingTime)
        timer.fireDate = fireDate
        timer.state = .running
        
        saveContext()
        
        // Resume alarm with AlarmKit asynchronously
        Task { @MainActor in
            await alarmScheduler.resumeAlarm(for: timer.stableAlarmID)
        }
    }
    
    /// Cancel a timer
    /// Cancels alarm and updates state
    /// - Parameter timer: The timer to cancel
    func cancelTimer(_ timer: TimerEntity) {
        timer.state = .cancelled
        timer.fireDate = nil
        
        saveContext()
        
        // Cancel alarm asynchronously
        Task { @MainActor in
            await alarmScheduler.cancelAlarm(for: timer.stableAlarmID)
        }
    }
    
    /// Mark timer as completed
    /// Called when alarm fires or timer naturally completes
    /// - Parameter timer: The timer to complete
    func completeTimer(_ timer: TimerEntity) {
        timer.state = .completed
        timer.fireDate = nil
        timer.remainingTime = 0
        
        saveContext()
    }
    
    /// Delete a timer
    /// - Parameter timer: The timer to delete
    func deleteTimer(_ timer: TimerEntity) {
        let alarmID = timer.stableAlarmID
        let shouldCancelAlarm = timer.state == .running || timer.state == .paused
        
        modelContext.delete(timer)
        saveContext()
        
        // Cancel alarm if still active (after deleting from context)
        if shouldCancelAlarm {
            Task { @MainActor in
                await alarmScheduler.cancelAlarm(for: alarmID)
            }
        }
    }
    
    // MARK: - Timer Restoration
    
    /// Restore timers on app launch
    /// Syncs with AlarmKit to determine which timers are still active
    /// AlarmKit persists alarms, so we don't re-register - we just sync state
    func restoreTimers() {
        // First, ensure AlarmScheduler has synced with AlarmKit
        Task {
            await alarmScheduler.syncWithAlarmKit()
        }
        
        let descriptor = FetchDescriptor<TimerEntity>()
        
        do {
            let timers = try modelContext.fetch(descriptor)
            
            for timer in timers {
                // Only process running timers
                guard timer.state == .running else { continue }
                
                // Recalculate remaining time based on fire date
                let remainingTime = timer.calculateRemainingTime()
                
                if remainingTime <= 0 {
                    // Timer has expired, mark as completed
                    completeTimer(timer)
                } else {
                    // Timer still valid, update remaining time
                    // The alarm already exists in AlarmKit (persisted automatically)
                    // We just need to update our local state
                    timer.remainingTime = remainingTime
                }
            }
            
            saveContext()
            
        } catch {
            print("Error restoring timers: \(error)")
        }
    }
    
    // MARK: - Fetching
    
    /// Fetch all timers
    func fetchTimers() -> [TimerEntity] {
        let descriptor = FetchDescriptor<TimerEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching timers: \(error)")
            return []
        }
    }
    
    /// Fetch active timers (running or paused)
    func fetchActiveTimers() -> [TimerEntity] {
        let descriptor = FetchDescriptor<TimerEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let timers = try modelContext.fetch(descriptor)
            return timers.filter { $0.state == .running || $0.state == .paused }
        } catch {
            print("Error fetching active timers: \(error)")
            return []
        }
    }
    
    // MARK: - Notification Handling
    
    /// Set up observers for alarm state changes and intents
    private func setupNotificationObservers() {
        let alarmStateObserver = NotificationCenter.default.addObserver(
            forName: .alarmStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAlarmStateChanged(notification)
        }
        observers.append(alarmStateObserver)
        
        let stopTimerObserver = NotificationCenter.default.addObserver(
            forName: .stopTimerFromIntent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleStopTimerIntent(notification)
        }
        observers.append(stopTimerObserver)
        
        let cancelTimerObserver = NotificationCenter.default.addObserver(
            forName: .cancelTimerFromIntent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCancelTimerIntent(notification)
        }
        observers.append(cancelTimerObserver)
    }
    
    /// Handle alarm state changes from AlarmKit
    /// This is called whenever AlarmKit's alarm state changes
    private func handleAlarmStateChanged(_ notification: Notification) {
        guard let alarms = notification.userInfo?["alarms"] as? [Alarm] else { return }
        
        // Get all current alarm IDs that exist in AlarmKit
        let existingAlarmIDs = Set(alarms.map { $0.id })
        
        let timers = fetchActiveTimers()
        
        // Sync timer state with AlarmKit
        for timer in timers where timer.state == .running {
            let timerAlarmID = timer.stableAlarmID
            
            // Check if this timer's alarm still exists in AlarmKit
            if !existingAlarmIDs.contains(timerAlarmID) {
                // Alarm no longer exists in AlarmKit - it was completed or cancelled
                let remainingTime = timer.calculateRemainingTime()
                
                if remainingTime <= 0 {
                    // Timer expired naturally
                    completeTimer(timer)
                } else {
                    // Alarm was cancelled externally or failed
                    timer.state = .paused
                    timer.fireDate = nil
                    saveContext()
                }
            } else {
                // Alarm still exists, update remaining time
                let remainingTime = timer.calculateRemainingTime()
                if remainingTime <= 0 {
                    completeTimer(timer)
                } else {
                    timer.remainingTime = remainingTime
                    saveContext()
                }
            }
        }
    }
    
    /// Handle stop timer intent from alarm UI
    private func handleStopTimerIntent(_ notification: Notification) {
        guard let timerID = notification.userInfo?["timerID"] as? UUID else { return }
        
        let descriptor = FetchDescriptor<TimerEntity>(
            predicate: #Predicate { $0.id == timerID }
        )
        
        do {
            let timers = try modelContext.fetch(descriptor)
            if let timer = timers.first {
                completeTimer(timer)
            }
        } catch {
            print("Error fetching timer for intent: \(error)")
        }
    }
    
    /// Handle cancel timer intent from Live Activity
    private func handleCancelTimerIntent(_ notification: Notification) {
        guard let timerID = notification.userInfo?["timerID"] as? UUID else { return }
        
        let descriptor = FetchDescriptor<TimerEntity>(
            predicate: #Predicate { $0.id == timerID }
        )
        
        do {
            let timers = try modelContext.fetch(descriptor)
            if let timer = timers.first {
                cancelTimer(timer)
            }
        } catch {
            print("Error fetching timer for cancel intent: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    /// Save model context
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
