//
//  DashboardView.swift
//  How Is My Driving?
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @State private var showingResetTripAlert = false
    
    var scoreColor: Color {
        let score = scoreManager.currentScore
        if score >= 85 { return .green }
        else if score >= 65 { return .yellow }
        else { return .red }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // MARK: - User Profile Header
                HStack {
                    if let data = scoreManager.userProfile.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading) {
                        Text(scoreManager.userProfile.name.isEmpty ? "Driver" : scoreManager.userProfile.name)
                            .font(.title2)
                        Text("Current Score: \(scoreManager.currentScore)")
                            .font(.caption)
                            .foregroundColor(scoreColor)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top])
                
                // MARK: - Speedometer
                SpeedometerView(
                    currentSpeed: $scoreManager.currentSpeedMPH,
                    postedLimit: $scoreManager.postedSpeedLimitMPH,
                    unit: .constant("mph")
                )
                .frame(width: 230, height: 230)
                .padding(.bottom, 10)
                
                // MARK: - Trip Status Message
                Text(scoreManager.tripStatusMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(height: 40)
                
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
                                Image(systemName: "play.circle.fill")
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
                .frame(height: 60)
                
                Spacer()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingResetTripAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("Reset Trip Data")
                    }
                    .disabled(scoreManager.tripState == .idle || scoreManager.tripState == .stopped)
                }
            }
            .alert("Reset Current Trip Data?", isPresented: $showingResetTripAlert) {
                Button("Reset Data", role: .destructive) {
                    scoreManager.resetCurrentTripDataAndScore()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset the score and events for the current trip session to their initial state. Are you sure?")
            }
            .onAppear {
                scoreManager.updatePermissionStatus()
            }
        }
    }
}
