import SwiftUI
import PhotosUI

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
                                    print("Avatar image '\(avatarName)' not found in Assets.")
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
            .onChange(of: selectedPhoto, initial: false) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                        selectedAvatarName = nil
                    }
                }
            }
            
            if let data = profileImageData,
               let uiImage = UIImage(data: data) {
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
