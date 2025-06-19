//
//  WelcomeView.swift
//  How Is My Driving?
//

import SwiftUI
import CoreLocation // For location permissions
import CoreMotion // For motion permissions
import PhotosUI // For Photo Picker

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

struct BasicInfoView: View {
    @EnvironmentObject var scoreManager: DrivingScoreManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?

    let avatarOptions = ["avatar1", "avatar2", "avatar3", "avatar4", "avatar5", "avatar6"]
    @State private var selectedAvatarName: String?


    var body: some View {
        VStack(spacing: 20) {
            Text("Tell Us About You (Optional)")
                .font(.title2).bold()
                .padding(.top)

            TextField("Name (e.g., Sarah, John's Car)", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Age (helps with relevant tips)", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)

            Text("Choose Your Avatar")
                .font(.headline)
                .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(avatarOptions, id: \.self) { avatarName in
                        // Ensure these images are in your Assets, otherwise use SFSymbols or placeholders
                        Image(avatarName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(selectedAvatarName == avatarName ? Color.blue : Color.gray, lineWidth: 2))
                            .onTapGesture {
                                selectedAvatarName = avatarName
                                if let uiImage = UIImage(named: avatarName) {
                                    profileImageData = uiImage.pngData()
                                } else {
                                    // Fallback if image not found (e.g., use a system image)
                                    print("Avatar image '\(avatarName)' not found in Assets.")
                                    // Example: profileImageData = UIImage(systemName: "person.fill")?.pngData()
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                Text("Upload Your Own")
                    .modifier(SecondaryButtonModifier())
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                        selectedAvatarName = nil
                    }
                }
            }
            
            if let data = profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .padding(.top, 5)
            }


            Text("We respect your privacy. This information stays on your device.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()

            NavigationLink(destination: PermissionsView(hasCompletedOnboarding: $hasCompletedOnboarding).environmentObject(scoreManager)) {
                Text("Next")
                    .modifier(PrimaryButtonModifier())
            }
            .simultaneousGesture(TapGesture().onEnded {
                scoreManager.userProfile.name = name
                scoreManager.userProfile.age = age
                scoreManager.userProfile.profileImageData = profileImageData
                scoreManager.saveUserProfile()
            })
        }
        .padding()
        .navigationTitle("Profile Setup")
        .onAppear {
            name = scoreManager.userProfile.name
            age = scoreManager.userProfile.age
            profileImageData = scoreManager.userProfile.profileImageData
        }
    }
}
