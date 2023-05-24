import SwiftUI
import Foundation

struct FriendsScrollView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(appViewModel.users) { user in
                    FriendCardView(user: user)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FriendCardView: View {
    let user: User
    
    var body: some View {
        VStack {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .foregroundColor(.gray)
                .clipShape(Circle())
            
            Text(user.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: 64)
        }
    }
}

struct FriendsScrollView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsScrollView()
            .environmentObject(AppViewModel())
    }
}
