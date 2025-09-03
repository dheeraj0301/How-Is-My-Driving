//
//  ScoreInsightsView.swift
//  How Is My Driving?
//

import SwiftUI

struct ScoreInsightsView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @State private var selectedPeriod: Period = .currentTrip

    enum Period: String, CaseIterable, Identifiable {
        case currentTrip = "Current Trip"
        case allRecorded = "All Events"
        var id: String { self.rawValue }
    }
    
    var filteredEvents: [DrivingEvent] {
        switch selectedPeriod {
        case .currentTrip:
            return scoreManager.drivingEvents
        case .allRecorded:
            if let savedEventsData = UserDefaults.standard.data(forKey: "drivingEvents"),
               let decodedEvents = try? JSONDecoder().decode([DrivingEvent].self, from: savedEventsData) {
                return decodedEvents.sorted(by: { $0.timestamp > $1.timestamp })
            }
            return scoreManager.drivingEvents
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
        }
    }
}

