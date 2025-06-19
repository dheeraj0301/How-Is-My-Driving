//
//  DashboardView.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation
import CoreMotion

struct DashboardView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @State private var showingResetTripAlert = false // For resetting current trip data if needed, distinct from app data reset

    var scoreColor: Color {
        let score = scoreManager.currentScore
        if score >= 85 { return .green }
        else if score >= 65 { return .yellow }
        else { return .red }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 15) { // Reduced spacing a bit
                // MARK: - User Profile Header
                HStack {
                    if let data = scoreManager.userProfile.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFill()
                            .frame(width: 50, height: 50).clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable().scaledToFit()
                            .frame(width: 50, height: 50).foregroundColor(.gray)
                    }
                    VStack(alignment: .leading) {
                        Text(scoreManager.userProfile.name.isEmpty ? "Driver" : scoreManager.userProfile.name)
                            .font(.title2)
                        Text("Current Score: \(scoreManager.currentScore)") // Show score here
                            .font(.caption)
                            .foregroundColor(scoreColor)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top])

                // MARK: - Speedometer
                SpeedometerView(
                    currentSpeed: $scoreManager.currentSpeedMPH,
                    postedLimit: $scoreManager.postedSpeedLimitMPH, // Assuming this is also in MPH
                    unit: .constant("mph") // Explicitly pass unit
                )
                .frame(width: 230, height: 230) // Slightly smaller
                .padding(.bottom, 10)

                // MARK: - Trip Status Message
                Text(scoreManager.tripStatusMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(height: 40) // Ensure space for two lines

                // MARK: - Last Event
                if scoreManager.tripState == .active || scoreManager.tripState == .paused {
                    if let lastEvent = scoreManager.drivingEvents.first(where: { $0.type != .tripStart && $0.type != .tripPause && $0.type != .tripResume }) {
                        Text("Last Event: \(lastEvent.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal)
                    } else {
                        Text("No driving events recorded for this trip yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }


                // MARK: - Trip Controls
                HStack(spacing: 15) {
                    Spacer()
                    // Start Button
                    if scoreManager.tripState == .idle || scoreManager.tripState == .stopped {
                        Button {
                            scoreManager.startTrip()
                        } label: {
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                Text("Start Trip")
                                    .font(.caption)
                            }
                        }
                        .modifier(TripControlButtonModifier(color: .green))
                    }

                    // Pause Button
                    if scoreManager.tripState == .active {
                        Button {
                            scoreManager.pauseTrip()
                        } label: {
                            VStack {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title)
                                Text("Pause Trip")
                                    .font(.caption)
                            }
                        }
                        .modifier(TripControlButtonModifier(color: .orange))
                    }

                    // Resume Button
                    if scoreManager.tripState == .paused {
                        Button {
                            scoreManager.resumeTrip()
                        } label: {
                            VStack {
                                Image(systemName: "play.circle.fill") // Or "arrow.clockwise.circle.fill"
                                    .font(.title)
                                Text("Resume Trip")
                                    .font(.caption)
                            }
                        }
                        .modifier(TripControlButtonModifier(color: .blue))
                    }

                    // Stop Button
                    if scoreManager.tripState == .active || scoreManager.tripState == .paused {
                        Button {
                            scoreManager.stopTrip()
                        } label: {
                            VStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title)
                                Text("Stop Trip")
                                    .font(.caption)
                            }
                        }
                        .modifier(TripControlButtonModifier(color: .red))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 60) // Ensure consistent height for controls

                Spacer() // Pushes controls up if content is less
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Changed to "Reset Current Trip Data" to be more specific
                    // This button is useful if a trip was started by mistake or needs a quick reset
                    // without affecting overall app data or past trips (if they were stored separately)
                    Button {
                        showingResetTripAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("Reset Trip Data")
                    }
                    .disabled(scoreManager.tripState == .idle || scoreManager.tripState == .stopped) // Disable if no active/paused trip
                }
            }
            .alert("Reset Current Trip Data?", isPresented: $showingResetTripAlert) {
                Button("Reset Data", role: .destructive) {
                    scoreManager.resetCurrentTripDataAndScore()
                    // If the trip was active or paused, stopping it might be a good idea,
                    // or resetting it to 'stopped' state to allow starting a fresh one.
                    // For now, resetCurrentTripDataAndScore only clears data, doesn't change tripState.
                    // User would then press "Start Trip" again.
                    // Or, we could make resetCurrentTripDataAndScore also set tripState to .stopped
                    // scoreManager.stopTrip() // Optionally stop the trip fully
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset the score and events for the current trip session to their initial state. Are you sure?")
            }
            .onAppear {
                // If coming back to the dashboard, ensure UI reflects the latest state
                scoreManager.updatePermissionStatus() // Good to check permissions
            }
        }
    }
}

// MARK: - Speedometer Sub-View
struct SpeedometerView: View {
    @Binding var currentSpeed: Double
    @Binding var postedLimit: Double
    @Binding var unit: String // "mph" or "km/h"

    private let maxSpeedDisplayMPH: Double = 120 // Max speed for the gauge display

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(lineWidth: 20) // Thicker line
                .opacity(0.1)
                .foregroundColor(.gray)

            // Current speed arc
            Circle()
                .trim(from: 0.0, to: CGFloat(min(currentSpeed / maxSpeedDisplayMPH, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(currentSpeed > postedLimit && postedLimit > 0 ? .red : .blue)
                .rotationEffect(Angle(degrees: 270)) // Start from the top
                .animation(.linear(duration: 0.5), value: currentSpeed)

            // Speed limit marker
            if postedLimit > 0 && postedLimit <= maxSpeedDisplayMPH {
                 SpeedLimitMarkerView(limit: postedLimit, maxSpeed: maxSpeedDisplayMPH, gaugeRadius: 115 - 10) // radius - half_linewidth
            }

            // Speed text
            VStack(spacing: 2) {
                Text("\(Int(currentSpeed))")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                Text(unit.uppercased())
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                if postedLimit > 0 {
                    Text("Limit: \(Int(postedLimit)) \(unit.uppercased())")
                        .font(.caption)
                        .foregroundColor(currentSpeed > postedLimit ? .red : .secondary)
                        .padding(.top, 5)
                } else {
                    Text("Limit: N/A")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .padding(.top, 5)
                }
            }
        }
    }
}

// MARK: - Speed Limit Marker for Speedometer
struct SpeedLimitMarkerView: View {
    let limit: Double
    let maxSpeed: Double
    let gaugeRadius: CGFloat // Radius of the center of the gauge line

    var angle: Angle {
        // Calculate proportion of max speed, then map to 360 degrees
        // The gauge starts at -90 degrees (top) and goes clockwise
        let proportion = limit / maxSpeed
        return Angle(degrees: (proportion * 360) - 90)
    }

    var body: some View {
        // Small rectangle rotated to the speed limit position
        Rectangle()
            .fill(Color.orange)
            .frame(width: 3, height: 15) // Marker size
            .offset(y: -gaugeRadius) // Position it on the gauge circle
            .rotationEffect(angle)
    }
}

// MARK: - Modifier for Trip Control Buttons
struct TripControlButtonModifier: ViewModifier {
    var color: Color
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minWidth: 80) // Ensure buttons have a decent tap area
            .background(isDisabled ? Color.gray.opacity(0.3) : color.opacity(0.2))
            .foregroundColor(isDisabled ? .gray : color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDisabled ? Color.gray.opacity(0.5) : color, lineWidth: 1)
            )
            .disabled(isDisabled)
    }
}
