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
