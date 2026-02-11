//
//  TimerRowView.swift
//  BuildingAlarms
//
//  Created by Claude Agent on 11/2/26.
//

import SwiftUI
import SwiftData

/// Row view for displaying a single timer
/// Shows live countdown, state indicator, and control buttons
struct TimerRowView: View {
    @Bindable var timer: TimerEntity
    let timerStore: TimerStore
    
    // Timer for live countdown updates (only active when timer is running)
    @State private var updateTimer: Timer?
    @State private var currentRemainingTime: TimeInterval
    
    init(timer: TimerEntity, timerStore: TimerStore) {
        self.timer = timer
        self.timerStore = timerStore
        _currentRemainingTime = State(initialValue: timer.calculateRemainingTime())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timer duration and state
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedTime())
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                    
                    Text(stateDescription)
                        .font(.caption)
                        .foregroundStyle(stateColor)
                }
                
                Spacer()
                
                // State indicator badge
                Circle()
                    .fill(stateColor)
                    .frame(width: 12, height: 12)
            }
            
            // Control buttons
            HStack(spacing: 12) {
                // Start/Resume/Pause button
                if timer.state == .idle || timer.state == .paused {
                    Button(action: startOrResumeTimer) {
                        Label(timer.state == .idle ? "Start" : "Resume", systemImage: "play.fill")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.green)
                } else if timer.state == .running {
                    Button(action: pauseTimer) {
                        Label("Pause", systemImage: "pause.fill")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.orange)
                }
                
                // Cancel button (only show for active timers)
                if timer.state == .running || timer.state == .paused {
                    Button(action: cancelTimer) {
                        Label("Cancel", systemImage: "xmark")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            startLiveUpdate()
        }
        .onDisappear {
            stopLiveUpdate()
        }
        .onChange(of: timer.state) {
            updateTimerState()
        }
    }
    
    // MARK: - Timer Actions
    
    /// Start or resume the timer
    private func startOrResumeTimer() {
        if timer.state == .idle {
            timerStore.startTimer(timer)
        } else if timer.state == .paused {
            timerStore.resumeTimer(timer)
        }
        startLiveUpdate()
    }
    
    /// Pause the timer
    private func pauseTimer() {
        timerStore.pauseTimer(timer)
        stopLiveUpdate()
    }
    
    /// Cancel the timer
    private func cancelTimer() {
        timerStore.cancelTimer(timer)
        stopLiveUpdate()
    }
    
    // MARK: - Live Updates
    
    /// Start live countdown updates (only for running timers)
    private func startLiveUpdate() {
        guard timer.state == .running else { return }
        
        stopLiveUpdate()
        
        // Update every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentRemainingTime = timer.calculateRemainingTime()
            
            // Check if timer completed
            if currentRemainingTime <= 0 && timer.state == .running {
                timerStore.completeTimer(timer)
                stopLiveUpdate()
            }
        }
    }
    
    /// Stop live countdown updates
    private func stopLiveUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Update timer state when it changes
    private func updateTimerState() {
        currentRemainingTime = timer.calculateRemainingTime()
        
        if timer.state == .running {
            startLiveUpdate()
        } else {
            stopLiveUpdate()
        }
    }
    
    // MARK: - Formatting
    
    /// Format remaining time as HH:MM:SS
    private func formattedTime() -> String {
        let time = currentRemainingTime
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// State description text
    private var stateDescription: String {
        switch timer.state {
        case .idle:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    /// State color indicator
    private var stateColor: Color {
        switch timer.state {
        case .idle:
            return .gray
        case .running:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .cancelled:
            return .red
        }
    }
}

#Preview("Timer Row") {
    do {
        // Create a preview container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TimerEntity.self, configurations: config)
        let store = TimerStore(modelContainer: container)
        
        // Create a sample timer
        let timer = TimerEntity(duration: 300)
        timer.state = .running
        timer.fireDate = Date().addingTimeInterval(300)
        
        return List {
            TimerRowView(timer: timer, timerStore: store)
        }
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
