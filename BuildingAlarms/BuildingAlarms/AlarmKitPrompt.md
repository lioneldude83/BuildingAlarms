# Build a Multi-Timer SwiftUI App Using AlarmKit (iOS 26+)

## Overview

You are a senior iOS engineer. Build a production-ready SwiftUI app
targeting **iOS 26+** that uses **AlarmKit** to manage multiple
independent countdown timers.

The solution must follow modern Swift architecture and avoid legacy
APIs.

------------------------------------------------------------------------

## Platform Requirements

-   iOS 26+
-   Swift 6
-   SwiftUI
-   AlarmKit (iOS 26)
-   SwiftData for persistence
-   App Intents (if required by AlarmKit integration)
-   Live Activities (strongly preferred)

Do NOT use deprecated APIs.

------------------------------------------------------------------------

## Architectural Constraints

### State Management

Use modern observation:

-   `@Observable`
-   `@Bindable`

Do NOT use:

-   `ObservableObject`
-   `@Published`
-   `@StateObject`
-   `@ObservedObject`

Follow a clean architecture:

-   `TimerEntity` (SwiftData model)
-   `TimerStore` (source of truth, @Observable)
-   `AlarmScheduler` service (isolated AlarmKit integration)
-   SwiftUI Views

Keep AlarmKit logic out of Views.

------------------------------------------------------------------------

## App Behavior

### Core Features

Users must be able to:

1.  Create multiple countdown timers
2.  Input duration (HH / MM / SS)
3.  Start, pause, resume, cancel
4.  Run multiple timers concurrently
5.  Receive system-level alarm when timer finishes
6.  Restore active timers after:
    -   App relaunch
    -   App termination
    -   Scene recreation

------------------------------------------------------------------------

## Data Model

Create a SwiftData model:

    TimerEntity
    - id: UUID
    - createdAt: Date
    - duration: TimeInterval
    - remainingTime: TimeInterval
    - fireDate: Date?
    - state: TimerState (enum)
    - alarmIdentifier: String?

`TimerState`:

-   idle
-   running
-   paused
-   completed
-   cancelled

Persist all timers.

------------------------------------------------------------------------

## AlarmKit Integration Requirements

Create a dedicated `AlarmScheduler` service responsible for:

-   Requesting alarm permission
-   Registering alarms
-   Cancelling alarms
-   Re-registering alarms during restoration
-   Preventing duplicate registrations

Each timer must:

-   Have a stable `alarmIdentifier`
-   Only ever register ONE alarm at a time
-   Cancel existing alarm before re-registering

------------------------------------------------------------------------

## Critical: Duplicate Alarm Prevention

You MUST implement:

-   A deterministic alarm identifier (e.g., based on UUID)
-   A guard to prevent registering the same alarm twice
-   Restoration logic that checks:
    -   If alarm exists
    -   If timer is still valid
    -   If remaining time \> 0

Never blindly re-register alarms on launch.

------------------------------------------------------------------------

## Timer Lifecycle Logic

### When Starting

-   Compute fireDate
-   Store alarmIdentifier
-   Register with AlarmKit
-   Update state to running
-   Persist

### When Pausing

-   Cancel alarm via AlarmScheduler
-   Compute remainingTime
-   Clear fireDate
-   Update state to paused
-   Persist

### When Resuming

-   Compute new fireDate
-   Re-register alarm
-   Update state to running
-   Persist

### When Completing

Triggered by AlarmKit:

-   Update state to completed
-   Clear fireDate
-   End Live Activity (if active)
-   Persist

### When Cancelling

-   Cancel alarm
-   Remove Live Activity
-   Update state to cancelled
-   Persist

------------------------------------------------------------------------

## Restoration Flow (App Launch)

On app startup:

1.  Fetch all timers
2.  For each timer:
    -   If state == running:
        -   Recalculate remainingTime from fireDate
        -   If remainingTime \<= 0:
            -   Mark completed
        -   Else:
            -   Re-register alarm safely
3.  Ensure no duplicate AlarmKit registrations

------------------------------------------------------------------------

## UI Requirements

### Main Screen

-   NavigationStack
-   List of timers
-   Each row shows:
    -   Remaining time (live countdown)
    -   State indicator
    -   Start/Pause/Resume button
    -   Cancel button

Live countdown must be efficient and not create excessive timers.

### Add Timer Screen

-   Duration picker (HH/MM/SS numeric input)
-   Validation (must be \> 0)
-   Save button disabled if invalid

------------------------------------------------------------------------

## Live Activities (Strongly Preferred)

Integrate Live Activities per timer:

-   One Live Activity per running timer
-   Activity identifier linked to timer UUID
-   Update remaining time
-   End activity on completion or cancellation
-   Prevent duplicate activities

------------------------------------------------------------------------

## Concurrency Requirements

-   Use async/await
-   Ensure AlarmScheduler is concurrency-safe
-   Avoid race conditions when rapidly pausing/resuming

------------------------------------------------------------------------

## Edge Cases

Handle:

-   App killed while timers running
-   Device reboot
-   Permission denied
-   Two timers finishing at same second
-   Rapid button taps
-   Background/foreground transitions
-   ScenePhase changes

------------------------------------------------------------------------

## Code Quality Requirements

-   Modular file structure
-   No force unwraps
-   Clear separation of concerns
-   Comments explaining:
    -   AlarmKit registration
    -   Restoration
    -   Duplicate prevention
-   Compile-ready code

------------------------------------------------------------------------

## Deliverables

Provide:

1.  Project structure overview
2.  All Swift files
3.  SwiftData model
4.  AlarmScheduler implementation
5.  Live Activity implementation
6.  App entry point
7.  Detailed explanation of:
    -   Duplicate alarm prevention strategy
    -   Restoration algorithm
    -   Concurrency model

If something is ambiguous, choose the safest production approach and
explain your reasoning.

