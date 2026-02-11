//
//  BuildingAlarmsApp.swift
//  BuildingAlarms
//
//  Created by Lionel Ng on 11/2/26.
//

import SwiftUI
import SwiftData

@main
struct BuildingAlarmsApp: App {
    // SwiftData model container for persistence
    let modelContainer: ModelContainer
    
    // Timer store for managing all timer operations
    let timerStore: TimerStore
    
    // Track scene phase for restoration
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize SwiftData model container
        do {
            let schema = Schema([TimerEntity.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        // Initialize timer store
        timerStore = TimerStore(modelContainer: modelContainer)
        
        // Perform timer restoration on app launch
        timerStore.restoreTimers()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(timerStore: timerStore)
                .modelContainer(modelContainer)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Scene Phase Handling
    
    /// Handle scene phase changes
    /// Restores timers when app becomes active
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - restore timers
            // This handles app relaunch, foreground transitions, etc.
            timerStore.restoreTimers()
            
        case .inactive:
            // App is becoming inactive
            break
            
        case .background:
            // App is in background
            // Timers continue via AlarmKit
            break
            
        @unknown default:
            break
        }
    }
}
