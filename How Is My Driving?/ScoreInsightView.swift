//
//  ScoreInsightView.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation
import CoreMotion

struct ScoreInsightsView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @State private var selectedPeriod: Period = .currentTrip // Default to current trip

    // Define periods for filtering events
    // Note: "CurrentTrip" will show events from the `drivingEvents` array which is cleared
    // when a new trip starts in the current implementation.
    // For true historical trip data, DrivingScoreManager and persistence would need to be enhanced.
    enum Period: String, CaseIterable, Identifiable {
        case currentTrip = "Current Trip" // Shows events from the active/last completed trip session
        case allRecorded = "All Events" // Shows all events currently in UserDefaults (can grow large)
        // Add more specific filters if needed, e.g., Today, This Week, if data isn't cleared per trip
        var id: String { self.rawValue }
    }
    
    var filteredEvents: [DrivingEvent] {
        // In the current setup, `scoreManager.drivingEvents` holds events for the
        // ongoing or most recently completed trip (until a new one starts and clears it).
        // If you implement saving distinct trips, this logic would change to fetch
        // events based on the selected trip or a broader historical range.
        switch selectedPeriod {
        case .currentTrip:
            // This will show events from the current `drivingEvents` array.
            // If a trip is stopped, these are the events of that last trip.
            // If a new trip is started, this array is cleared.
            return scoreManager.drivingEvents
        case .allRecorded:
            // To show "all recorded" from UserDefaults, we'd need to load them here
            // This is a simplified example assuming they are not cleared from UserDefaults elsewhere
            // or that `scoreManager.drivingEvents` is the source of truth for "all" if not cleared.
            // For a robust "all events" from multiple trips, a different storage/retrieval is needed.
            // For now, let's assume it shows the same as currentTrip due to current data handling.
            // A more correct implementation would load all historical events if they were stored that way.
            // This is a placeholder to show how one might structure it.
            if let savedEventsData = UserDefaults.standard.data(forKey: "drivingEvents"),
               let decodedEvents = try? JSONDecoder().decode([DrivingEvent].self, from: savedEventsData) {
                return decodedEvents.sorted(by: { $0.timestamp > $1.timestamp }) // Ensure sorted
            }
            return scoreManager.drivingEvents // Fallback to current manager's events
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if filteredEvents.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable().scaledToFit().frame(width: 80, height: 80)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Driving Events")
                            .font(.title2).foregroundColor(.gray)
                        Text(selectedPeriod == .currentTrip ? "Events for the current trip will appear here." : "No events recorded for the selected period.")
                            .font(.subheadline).foregroundColor(.gray)
                            .multilineTextAlignment(.center).padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
            .navigationTitle("Score Insights")
            .onAppear {
                // This view might benefit from its own data refresh if not relying solely on @EnvironmentObject
                // For instance, if "All Events" truly loaded from a separate historical store.
            }
        }
    }
}

struct EventRow: View {
    let event: DrivingEvent

    var iconName: String {
        switch event.type {
        // Negative
        case .harshBraking: return "arrow.down.to.line.compact"
        case .rapidAcceleration: return "arrow.up.to.line.compact"
        case .aggressiveLeftTurn: return "arrow.turn.up.left" // Changed icon
        case .aggressiveRightTurn: return "arrow.turn.up.right" // Changed icon
        case .aggressiveSpeeding: return "gauge.badge.plus"
        case .prolongedSpeeding: return "timer" // New icon for prolonged
        case .suddenLaneChange: return "arrow.left.arrow.right.circle" // Placeholder icon
        case .phoneUsage: return "iphone.slash"
        // Positive
        case .smoothDriving: return "leaf.fill"
        case .adherenceToSpeedLimit: return "checkmark.shield.fill"
        case .gentleManeuver: return "figure.walk" // Could be more specific
        case .maintainingSafeDistance: return "car.2.fill" // Placeholder
        case .efficientAcceleration: return "bolt.badge.a.fill" // Placeholder
        // Informational
        case .tripStart: return "play.fill"
        case .tripEnd: return "stop.fill"
        case .tripPause: return "pause.fill"
        case .tripResume: return "play.fill" // Same as start for resume
        }
    }

    var iconColor: Color {
        if event.points < 0 { return .red }
        if event.points > 0 { return .green }
        return .gray // For neutral events (trip start/end etc.)
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 25, alignment: .center)
                .padding(.top, 2) // Align icon better with multi-line text

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.rawValue)
                    .font(.headline)
                
                HStack {
                    Text(event.timestamp, style: .time)
                    Text("|")
                    Text(event.timestamp, style: .date)
                }
                .font(.caption)
                .foregroundColor(.gray)

                // Display magnitude or duration if available
                if let magnitude = event.magnitude {
                    let formattedMagnitude = String(format: "%.1f", magnitude)
                    Text("Severity: \(formattedMagnitude)") // Customize label based on event type
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                if let duration = event.duration {
                     let formattedDuration = String(format: "%.1fs", duration)
                     Text("Duration: \(formattedDuration)")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            Spacer()
            if event.type != .tripStart && event.type != .tripEnd && event.type != .tripPause && event.type != .tripResume { // Don't show points for info events
                Text("\(event.points > 0 ? "+" : "")\(event.points) pts")
                    .font(.headline)
                    .foregroundColor(iconColor)
                    .padding(.leading, 5)
            }
        }
        .padding(.vertical, 6)
    }
}
