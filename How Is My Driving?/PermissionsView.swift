//
//  PermissionsView.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation // For location permissions
import CoreMotion // For motion permissions
import PhotosUI // For Photo Picker

struct PermissionsView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Permissions Needed")
                .font(.title2).bold()
                .padding(.bottom)

            PermissionRow(
                title: "Location Services (GPS)",
                description: "To track speed, routes, and detect driving events like speeding. Your location data is processed on your device.",
                status: scoreManager.locationPermissionStatus.description, // Uses the CLAuthorizationStatus extension
                granted: scoreManager.locationPermissionStatus == .authorizedWhenInUse || scoreManager.locationPermissionStatus == .authorizedAlways
            ) {
                scoreManager.requestLocationPermission()
            }

            PermissionRow(
                title: "Motion & Fitness Activity",
                description: "To detect maneuvers like sudden turns, acceleration, and braking using device sensors.",
                // CORRECTED LINE: Use .customDescription
                status: scoreManager.isMotionActivityAvailable ? scoreManager.motionPermissionStatus.customDescription : "Not Available",
                granted: scoreManager.isMotionActivityAvailable && scoreManager.motionPermissionStatus == .authorized
            ) {
                if scoreManager.isMotionActivityAvailable {
                    scoreManager.requestMotionPermission()
                } else {
                    print("Motion activity not available on this device to request permission.")
                }
            }
            
            Text("Why these permissions? We need them to analyze your driving behavior accurately and provide your score. Your data is handled responsibly.")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
            
            Button(action: {
                if allPermissionsGrantedOrMotionUnavailable() {
                    hasCompletedOnboarding = true
                } else {
                     print("Permissions not fully granted. Some features might be limited.")
                     hasCompletedOnboarding = true
                }
            }) {
                Text(allPermissionsGrantedOrMotionUnavailable() ? "Start Driving!" : "Continue (Limited Features)")
                    .modifier(PrimaryButtonModifier())
            }
            
            if !allPermissionsGrantedOrMotionUnavailable() && (scoreManager.locationPermissionStatus == .denied || (scoreManager.isMotionActivityAvailable && scoreManager.motionPermissionStatus == .denied)) {
                Button("Open Settings to Grant Permissions") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .modifier(SecondaryButtonModifier())
                .padding(.top)
            }
        }
        .padding()
        .navigationTitle("App Permissions")
        .onAppear {
            scoreManager.updatePermissionStatus()
        }
    }

    func allPermissionsGrantedOrMotionUnavailable() -> Bool {
        let locationOK = scoreManager.locationPermissionStatus == .authorizedWhenInUse || scoreManager.locationPermissionStatus == .authorizedAlways
        let motionOK = (!scoreManager.isMotionActivityAvailable || scoreManager.motionPermissionStatus == .authorized)
        return locationOK && motionOK
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let status: String
    let granted: Bool
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text(description).font(.caption).foregroundColor(.gray)
            HStack {
                Text("Status: \(status)")
                    .font(.footnote)
                    .foregroundColor(granted ? .green : (status == "Not Available" ? .gray : .orange))
                Spacer()
                if !granted && status != "Not Available" { // Don't show grant button if not available
                    Button("Grant", action: onRequest)
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
        }
        .padding(.vertical, 5)
    }
}
