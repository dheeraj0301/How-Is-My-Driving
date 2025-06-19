//
//  How_Is_My_Driving_App.swift
//  How Is My Driving?
//


import SwiftUI
import SwiftData

@main
struct HowIsMyDrivingApp: App {
    @StateObject private var scoreManager = DrivingScoreManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainAppView()
                    .environmentObject(scoreManager)
            } else {
                WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(scoreManager)
            }
        }
    }
}
