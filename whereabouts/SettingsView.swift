import SwiftUI


struct SettingsView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            Text("Settings View")
            HStack {
                if let profilePicture = appViewModel.currentUserProfilePicture,
                   let name = appViewModel.currentUserName {
                    Image(uiImage: profilePicture)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    
                    Text(name)
                        .font(.headline)
                        .padding(.leading, 4)
                }
            }
            
            Button(action:  {
                appViewModel.signOut()
                appViewModel.isAuthenticated = false
            }) {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
        }
    }
}
