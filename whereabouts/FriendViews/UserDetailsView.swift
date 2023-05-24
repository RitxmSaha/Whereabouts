import SwiftUI
import Foundation
import CoreLocation

struct UserDetailsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let user: User
    
    var defaultPersonIconURL = URL(string: "https://icons.veryicon.com/png/o/internet--web/prejudice/user-128.png")
    
    
    var body: some View {
        VStack {
            if let urlString = user.profilePictureURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Text("Loading...")
                            .frame(width: 120, height: 120)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    case .failure:
                        Text("Error")
                            .frame(width: 120, height: 120)
                    @unknown default:
                        Text("Unknown")
                            .frame(width: 120, height: 120)
                    }
                }
            }
            Text(user.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            Text(user.email)
                .font(.headline)
                .padding(.top, 4)
            
            Spacer()
            Button(action: {
                appViewModel.drawRouteToUserByEmail(email: user.email)
                appViewModel.toggleCancelButton()
                appViewModel.selectedTab = 1
            }) {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.white)
                        .padding(.all, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    
                    Text("Get Directions")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 16)
        }
        .navigationBarTitle("User Details", displayMode: .inline)
        .padding()
    }
}
