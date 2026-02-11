//
//  ContentView.swift
//  BuildingAlarms
//
//  Created by Lionel Ng on 11/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerEntity.createdAt, order: .reverse) private var timers: [TimerEntity]
    
    let timerStore: TimerStore
    
    @State private var showingAddTimer = false
    
    var body: some View {
        NavigationStack {
            Group {
                if timers.isEmpty {
                    emptyStateView
                } else {
                    timerListView
                }
            }
            .navigationTitle("Timers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTimer = true }) {
                        Label("Add Timer", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTimer) {
                AddTimerView(timerStore: timerStore)
            }
        }
    }
    
    // MARK: - Views
    
    /// Empty state when no timers exist
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Timers", systemImage: "timer")
        } description: {
            Text("Create a timer to get started")
        } actions: {
            Button("Add Timer") {
                showingAddTimer = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    /// List of timers
    private var timerListView: some View {
        List {
            // Active timers (running or paused)
            let activeTimers = timers.filter { $0.state == .running || $0.state == .paused }
            if !activeTimers.isEmpty {
                Section("Active") {
                    ForEach(activeTimers) { timer in
                        TimerRowView(timer: timer, timerStore: timerStore)
                    }
                    .onDelete { indexSet in
                        deleteTimers(at: indexSet, from: activeTimers)
                    }
                }
            }
            
            // Completed timers
            let completedTimers = timers.filter { $0.state == .completed }
            if !completedTimers.isEmpty {
                Section("Completed") {
                    ForEach(completedTimers) { timer in
                        TimerRowView(timer: timer, timerStore: timerStore)
                    }
                    .onDelete { indexSet in
                        deleteTimers(at: indexSet, from: completedTimers)
                    }
                }
            }
            
            // Idle timers
            let idleTimers = timers.filter { $0.state == .idle }
            if !idleTimers.isEmpty {
                Section("Ready") {
                    ForEach(idleTimers) { timer in
                        TimerRowView(timer: timer, timerStore: timerStore)
                    }
                    .onDelete { indexSet in
                        deleteTimers(at: indexSet, from: idleTimers)
                    }
                }
            }
            
            // Cancelled timers
            let cancelledTimers = timers.filter { $0.state == .cancelled }
            if !cancelledTimers.isEmpty {
                Section("Cancelled") {
                    ForEach(cancelledTimers) { timer in
                        TimerRowView(timer: timer, timerStore: timerStore)
                    }
                    .onDelete { indexSet in
                        deleteTimers(at: indexSet, from: cancelledTimers)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Delete timers from a specific section
    private func deleteTimers(at offsets: IndexSet, from timers: [TimerEntity]) {
        for index in offsets {
            let timer = timers[index]
            timerStore.deleteTimer(timer)
        }
    }
}

#Preview("Timer List") {
    do {
        // Create a preview container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TimerEntity.self, configurations: config)
        let store = TimerStore(modelContainer: container)
        
        // Add some sample timers
        let timer1 = TimerEntity(duration: 300)
        timer1.state = .running
        timer1.fireDate = Date().addingTimeInterval(300)
        
        let timer2 = TimerEntity(duration: 600)
        timer2.state = .paused
        timer2.remainingTime = 400
        
        container.mainContext.insert(timer1)
        container.mainContext.insert(timer2)
        
        return ContentView(timerStore: store)
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
