import SwiftUI
import Foundation

struct PeopleView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isAddFriendsViewPresented = false
    @State private var isFriendRequestsViewPresented = false
    
    var defaultPersonIconURL = URL(string: "https://icons.veryicon.com/png/o/internet--web/prejudice/user-128.png")

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(appViewModel.friends) { user in
                        NavigationLink(destination: UserDetailsView(user: user)) {
                            HStack {
                                if let profilePictureURL = user.profilePictureURL,
                                   let url = URL(string: profilePictureURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 48, height: 48)
                                                .clipShape(Circle())
                                        case .failure, .empty:
                                            Text("Loading...")
                                        @unknown default:
                                            fatalError()
                                        }
                                    }
                                }
                                Text(user.name)
                                    .font(.headline)
                            }
                        }
                    }
                }
                .navigationBarTitle("Friends")
                .navigationBarItems(trailing: Button(action: {
                    isAddFriendsViewPresented = true
                }, label: {
                    Image(systemName: "person.badge.plus")
                }))
                .sheet(isPresented: $isAddFriendsViewPresented, content: {
                    AddFriendsView(isPresented: $isAddFriendsViewPresented)
                        .environmentObject(appViewModel)
                })
                .sheet(isPresented: $isFriendRequestsViewPresented, content: {
                    FriendRequestsView(isPresented: $isFriendRequestsViewPresented)
                        .environmentObject(appViewModel)
                })
                
                Spacer()
                
                Button(action: {
                    isFriendRequestsViewPresented = true
                }) {
                    Text("Friend Requests")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

struct PeopleView_Previews: PreviewProvider {
    static var previews: some View {
        PeopleView()
    }
}
