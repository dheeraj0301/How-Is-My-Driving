//
//  WelcomeView.swift
//  How Is My Driving?
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                Image(systemName: "car.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)

                Text("How Is My Driving?")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Welcome! Let's help you understand and improve your driving.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                NavigationLink(destination: BasicInfoView(hasCompletedOnboarding: $hasCompletedOnboarding).environmentObject(scoreManager)) {
                    Text("Get Started")
                        .modifier(PrimaryButtonModifier())
                }
                Spacer()
            }
            .padding()
        }
    }
}

