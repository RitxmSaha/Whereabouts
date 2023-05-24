import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(appViewModel.friendRequests, id: \.documentID) { request in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(request.get("sender") as? String ?? "")
                                .font(.headline)
                        }
                        Spacer()
                        Button(action: {
                            appViewModel.updateFriendRequestStatus(documentID: request.documentID, status: "accepted")
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.trailing, 10)
                        Button(action: {
                            appViewModel.updateFriendRequestStatus(documentID: request.documentID, status: "rejected")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
        .onAppear {
            appViewModel.fetchFriendRequests()
        }
    }
}
