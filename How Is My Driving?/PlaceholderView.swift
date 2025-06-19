//
//  PlaceholderView.swift
//  How Is My Driving?
//


import SwiftUI
import CoreLocation // For location permissions
import CoreMotion // For motion permissions
import PhotosUI // For Photo Picker

struct AwardsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "trophy.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.orange)
                    .padding()
                Text("Awards & Challenges")
                    .font(.largeTitle)
                Text("Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Unlock achievements and participate in driving challenges to earn rewards.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Awards")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingResetConfirmation = false


    var body: some View {
        NavigationView {
            Form {
                Section("Profile") {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(scoreManager.userProfile.name.isEmpty ? "Not Set" : scoreManager.userProfile.name)
                    }
                    HStack {
                        Text("Age:")
                        Spacer()
                        Text(scoreManager.userProfile.age.isEmpty ? "Not Set" : scoreManager.userProfile.age)
                    }
                     NavigationLink("Edit Profile") {
                        BasicInfoView(hasCompletedOnboarding: .constant(true))
                            .environmentObject(scoreManager)
                            .navigationTitle("Edit Profile")
                    }
                }
                
                Section("App Data") {
                    Button("Reset All App Data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }
                .alert("Confirm Reset", isPresented: $showingResetConfirmation) {
                    Button("Reset All Data", role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "userProfile")
                        UserDefaults.standard.removeObject(forKey: "currentScore")
                        UserDefaults.standard.removeObject(forKey: "drivingEvents")
                        scoreManager.userProfile = UserProfile()
                        scoreManager.currentScore = 100
                        scoreManager.drivingEvents = []
                        // Important: Trigger UI update for onboarding status
                        DispatchQueue.main.async {
                             hasCompletedOnboarding = false
                        }
                        print("All app data reset.")
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will erase your profile, score history, and all recorded driving events. This action cannot be undone. Are you sure you want to proceed?")
                }


                Section("About") {
                    Text("How Is My Driving? App")
                    Text("Version 1.0.1 (Concept)")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
