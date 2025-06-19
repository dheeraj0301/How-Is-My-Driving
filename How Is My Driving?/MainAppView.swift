//
//  MainAppView.swift
//  How Is My Driving?
//


import SwiftUI
import CoreLocation // For location permissions
import CoreMotion // For motion permissions
import PhotosUI // For Photo Picker

struct MainAppView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.medium")
                }
                .environmentObject(scoreManager)

            ScoreInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "list.star")
                }
                .environmentObject(scoreManager)

            AwardsView()
                .tabItem {
                    Label("Awards", systemImage: "star.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .environmentObject(scoreManager)
        }
        .onAppear {
            scoreManager.updatePermissionStatus()
        }
    }
}
