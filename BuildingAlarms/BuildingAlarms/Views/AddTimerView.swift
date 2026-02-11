//
//  AddTimerView.swift
//  BuildingAlarms
//
//  Created by Claude Agent on 11/2/26.
//

import SwiftUI
import SwiftData

/// View for creating a new countdown timer
/// Provides numeric input for hours, minutes, and seconds
struct AddTimerView: View {
    @Environment(\.dismiss) private var dismiss
    let timerStore: TimerStore
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    /// Computed property to check if input is valid
    private var isValid: Bool {
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        return totalSeconds > 0
    }
    
    /// Convert input to total seconds
    private var totalDuration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Timer wheel picker - all three components in one horizontal row
                HStack(spacing: 0) {
                    // Hours picker
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    Text("hours")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    // Minutes picker
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    Text("min")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    // Seconds picker
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    Text("sec")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTimer()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    /// Save the timer and dismiss view
    private func saveTimer() {
        guard isValid else { return }
        
        timerStore.createTimer(duration: totalDuration)
        dismiss()
    }
    
    /// Format the duration for display
    private func formattedDuration() -> String {
        String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview("Add Timer") {
    do {
        // Create a preview container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TimerEntity.self, configurations: config)
        let store = TimerStore(modelContainer: container)
        
        return AddTimerView(timerStore: store)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
