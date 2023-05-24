import SwiftUI
import Foundation
import FirebaseAuth

struct AddFriendsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by email", text: $searchText) {
                    searchResults = appViewModel.searchUsers(email: searchText)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(searchResults) { user in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.headline)
                                        Text(user.email)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // Check if a friend request has been sent to the user
                                    if appViewModel.sentFriendRequests.contains(where: { $0.receiver == user.email }) {
                                        Text("Request Sent")
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .foregroundColor(.white)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                            .font(.subheadline)
                                            .minimumScaleFactor(0.5)
                                    } else {
                                        Button(action: {
                                            appViewModel.sendFriendRequest(to: user.email)
                                        }) {
                                            Text("Add Friend")
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                                .font(.subheadline)
                                                .minimumScaleFactor(0.5)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 24)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Add Friends", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                isPresented.toggle()
            }) {
                Text("Cancel")
            })
        }
    }
