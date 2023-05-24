import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseMessaging
import CoreLocation


class AppViewModel: ObservableObject {
    
    static let shared = AppViewModel()
    
    @Published var isAuthenticated = false
    @Published var selectedTab = 1
    @Published var currentUserProfilePicture: UIImage? = nil
    @Published var currentUserName: String? = nil
    @Published var friendRequests: [QueryDocumentSnapshot] = []
    @Published var pendingFriendRequests: [FriendRequest] = []
    @Published var sentFriendRequests: [FriendRequest] = []
    @Published var friendsLocations: [FriendAnnotation] = []
    @Published var users: [User] = []
    @Published var friends: [User] = []
    @Published var cancelButton = false
    @Published var locationManager = UserLocationManager()
        
    
    var customMapView: CustomMapView?
    var timer: Timer?
    
    private let friendRequestsRef = Firestore.firestore().collection("friendRequests")
    private let usersRef = Firestore.firestore().collection("users")
    private let friendsRef = Firestore.firestore().collection("friends")
    private var friendLocationListeners: [ListenerRegistration] = []
    private lazy var locationUpdater: LocationUpdater = {
        return LocationUpdater(appViewModel: self)
    }()
    
    init() {
        locationManager.locationManager.delegate = locationUpdater
        locationManager.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.locationManager.requestAlwaysAuthorization()
        locationManager.locationManager.allowsBackgroundLocationUpdates = true
        locationManager.locationManager.pausesLocationUpdatesAutomatically = false
        startUpdatingLocation(every: 2)
        
        
        checkIfAuthenticated()
        updateFCMToken() 
        reset()
        
    }
    
    func updateFCMToken() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error updating FCM token: User is not authenticated.")
            return
        }
        
        guard let fcmToken = Messaging.messaging().fcmToken else {
            print("Error updating FCM token: FCM token is nil.")
            return
        }
        
        let userRef = usersRef.document(currentUserID)
        userRef.updateData(["fcmToken": fcmToken]) { error in
            if let error = error {
                print("Error updating FCM token in Firestore: \(error.localizedDescription)")
            } else {
                print("FCM token updated successfully.")
            }
        }
    }
    
    func sendEmergencyNotification() {
        guard let email = Auth.auth().currentUser?.email else { return }
        guard let name = self.currentUserName else {
                print("Current user or name not found")
                return
            }
        
        let emergencyMessage = "\(name) is in an emergency!"
        //let emergencyMessage = "test_name is in an emergency!" // Replace 'name' with the user's name
        
        for friend in friends {
            if let fcmToken = friend.fcmToken {
                sendNotification(to: fcmToken, title: "whereabouts", body: emergencyMessage, data: email)
            }
        }
    }
    
    private func sendNotification(to token: String, title: String, body: String, data: String) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AAAAyUUjLQE:APA91bGO6hbhk62EjA1dXdT-huHWRud91bYLQMOOpc3haDeucXwelmcyAVxc3cXc1xQ6cz1930g994EpKZdZrfbbmbf9e9gqbyXcrj3-5IAb_lzdVKK44GG1rYZGTYMSOR4UrBUR4r5S", forHTTPHeaderField: "Authorization") // Replace 'YOUR_SERVER_KEY' with your Firebase server key
        
        let notification: [String: Any] = [
            "to": token,
            "notification": [
                "title": title,
                "body": body
            ],
            "data": [
                "email": data
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: notification, options: [])
            request.httpBody = data
        } catch {
            print("Error serializing notification JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification: \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Notification sent successfully, response: \(dataString)")
            }
        }
        task.resume()
    }
    
    
    func toggleCancelButton() {
        cancelButton.toggle()
    }
    func startUpdatingLocation(every seconds: TimeInterval) {
        locationManager.locationManager.stopUpdatingLocation()
        let locationUpdateInterval = DispatchTimeInterval.seconds(Int(seconds))
        DispatchQueue.main.asyncAfter(deadline: .now() + locationUpdateInterval) { [weak self] in
            self?.locationManager.locationManager.startUpdatingLocation()
            self?.startUpdatingLocation(every: seconds)
        }
    }
    
    
    func drawRouteToUserByEmail(email: String) {
        guard let mapView = customMapView else { return }
        
        // Invalidate the old timer
        timer?.invalidate()
        timer = nil
        
        // Find the user with the given email
        if let user = friends.first(where: { $0.email == email }),
           // Find the corresponding annotation in the friendsLocations array using the user's id
           let friendAnnotation = friendsLocations.first(where: { $0.id == user.id }) {
            
            // Call the method once immediately
            mapView.drawRouteToDestination(destinationCoordinate: friendAnnotation.coordinate)
            // Start a new timer to call the method every 5 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                if let friendAnnotation = self.friendsLocations.first(where: { $0.id == user.id }) {
                    mapView.drawRouteToDestination(destinationCoordinate: friendAnnotation.coordinate)
                }
            }
        }
    }
    
    func cancelDirections() {
        guard let mapView = customMapView else { return }
        timer?.invalidate()
        timer = nil

        
        mapView.removeRoute()
    }
    
    
    func removeAllFriendLocationListeners() {
        for listener in friendLocationListeners {
            listener.remove()
        }
        friendLocationListeners.removeAll()
    }
    
    func fetchFriendsLocations() {
        removeAllFriendLocationListeners()
        friendsLocations.removeAll()
        
        for friend in friends {
            let userID = friend.id
            let listener = Firestore.firestore().collection("userLocations").document(userID).addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error fetching friend's location: \(error.localizedDescription)")
                    return
                }
                
                if let document = documentSnapshot, document.exists,
                   let data = document.data(),
                   let geoPoint = data["location"] as? GeoPoint {
                    
                    let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    let friendAnnotation = FriendAnnotation(id: userID, coordinate: coordinate, title: friend.name)
                    
                    if let existingIndex = self.friendsLocations.firstIndex(where: { $0.id == userID }) {
                        DispatchQueue.main.async {
                            guard existingIndex >= 0 && existingIndex < self.friendsLocations.count else {
                                print("Index out of bounds. Skipping update.")
                                return
                            }
                            
                            self.friendsLocations[existingIndex] = friendAnnotation
                        }
                    } else {
                            self.friendsLocations.append(friendAnnotation)
                    }
                }
            }
            friendLocationListeners.append(listener)
        }
    }
    
    func fetchCollection<T: Codable>(collectionName: String, decode: @escaping ([String: Any]) -> T?, completion: @escaping (Result<[T], Error>) -> Void) {
        let collectionRef = Firestore.firestore().collection(collectionName)

        collectionRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = querySnapshot?.documents else {
                completion(.failure(NSError(domain: "No documents found", code: -1, userInfo: nil)))
                return
            }

            let items = documents.compactMap { (document) -> T? in
                let data = document.data()
                return decode(data)
            }
            completion(.success(items))
        }
    }

    
    
    class LocationUpdater: NSObject, CLLocationManagerDelegate {
        weak var appViewModel: AppViewModel?
        
        init(appViewModel: AppViewModel) {
            self.appViewModel = appViewModel
            super.init()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                appViewModel?.updateLocationInFirestore(location: location)
            }
        }
    }
    
    func reset() {
        friends.removeAll()
        users.removeAll()
        sentFriendRequests.removeAll()
        pendingFriendRequests.removeAll()
        fetchUsers()
        fetchPendingFriendRequests()
        fetchSentFriendRequests()
        fetchFriends()
        fetchFriendsLocations()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            updateLocationInFirestore(location: location)
        }
    }
    
    func updateLocationInFirestore(location: CLLocation) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        db.collection("userLocations").document(userID).setData(["location": geoPoint, "timestamp": FieldValue.serverTimestamp()])
    }
    
    func fetchFriends() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        friendsRef.whereField("user1", isEqualTo: currentUserEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let userEmail = document["user2"] as? String {
                        self.addFriendIfExists(email: userEmail)
                    }
                }
            }
        }
        
        friendsRef.whereField("user2", isEqualTo: currentUserEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let userEmail = document["user1"] as? String {
                        self.addFriendIfExists(email: userEmail)
                    }
                }
            }
        }
    }
    
    private func addFriendIfExists(email: String) {
        if let friend = users.first(where: { $0.email == email }) {
            DispatchQueue.main.async {
                self.friends.append(friend)
            }
        } else {
            usersRef.whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching friend: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents, let document = documents.first {
                    let data = document.data()
                    if let name = data["name"] as? String,
                       let email = data["email"] as? String,
                       let fcmToken = data["fcmToken"] as? String,
                       let profilePictureURL = data["profilePictureURL"] as? String {
                        DispatchQueue.main.async {
                            self.friends.append(User(id: document.documentID, name: name, email: email, profilePictureURL: profilePictureURL, fcmToken: fcmToken))
                        }
                    }
                }
            }
        }
    }
    
    func uploadProfilePicture(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let profilePicturesRef = storageRef.child("profilePictures/\(UUID().uuidString).jpg")
        
        profilePicturesRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading profile picture: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            profilePicturesRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    
    
    
    
    func fetchUsers() {
        usersRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.users = documents.compactMap { document in
                    let data = document.data()
                    if let name = data["name"] as? String,
                       let email = data["email"] as? String,
                       let profilePictureURL = data["profilePictureURL"] as? String,
                       let fcmToken = data["fcmToken"] as? String {
                        return User(id: document.documentID, name: name, email: email, profilePictureURL: profilePictureURL, fcmToken: fcmToken)
                    }
                    return nil
                }
            }
        }
    }
    
    
    
    // Fetch the friend requests sent by the current user and add them to the sentFriendRequests array
    func fetchSentFriendRequests() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        friendRequestsRef.whereField("sender", isEqualTo: currentUserEmail).addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else { return }
            self.sentFriendRequests = documents.compactMap { queryDocumentSnapshot -> FriendRequest? in
                let data = queryDocumentSnapshot.data()
                guard let sender = data["sender"] as? String,
                      let receiver = data["receiver"] as? String,
                      let status = data["status"] as? String else { return nil }
                return FriendRequest(id: queryDocumentSnapshot.documentID, sender: sender, receiver: receiver, status: status)
            }
        }
    }
    
    
    
    
    func searchUsers(email: String) -> [User] {
        let friendIds = Set(friends.map { $0.id })
        let currentUserId = Auth.auth().currentUser?.email
        
        let filteredUsers = users.filter { user in
            let isFriend = friendIds.contains(user.id)
            let emailMatchesSearch = user.email.lowercased().contains(email.lowercased())
            let isCurrentUser = user.email == currentUserId
            
            return !isFriend && emailMatchesSearch && !isCurrentUser
        }
        return filteredUsers
    }
    
    func checkIfAuthenticated() {
        if let currentUser = Auth.auth().currentUser {
            isAuthenticated = true
            
            let userRef = usersRef.document(currentUser.uid)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    self.currentUserName = data?["name"] as? String
                    
                    if let profilePictureURL = data?["profilePictureURL"] as? String {
                        URLSession.shared.dataTask(with: URL(string: profilePictureURL)!) { data, response, error in
                            if let data = data {
                                DispatchQueue.main.async {
                                    self.currentUserProfilePicture = UIImage(data: data)
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    
    func fetchPendingFriendRequests() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        friendRequestsRef.whereField("receiver", isEqualTo: currentUserEmail).whereField("status", isEqualTo: "pending").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else { return }
            self.pendingFriendRequests = documents.compactMap { queryDocumentSnapshot -> FriendRequest? in
                let data = queryDocumentSnapshot.data()
                guard let sender = data["sender"] as? String,
                      let receiver = data["receiver"] as? String,
                      let status = data["status"] as? String else { return nil }
                return FriendRequest(id: queryDocumentSnapshot.documentID, sender: sender, receiver: receiver, status: status)
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.reset()
            }
        }
    }
    
    
    func cancelFriendRequest(to email: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        friendRequestsRef.whereField("receiver", isEqualTo: email).whereField("sender", isEqualTo: currentUser.email).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            if let requests = snapshot?.documents, let requestDocument = requests.first {
                self.friendRequestsRef.document(requestDocument.documentID).delete { error in
                    if let error = error {
                        print("Error canceling friend request: \(error.localizedDescription)")
                        return
                    }
                    print("Friend request canceled")
                }
            } else {
                print("Friend request not found")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            
            // Clear the arrays
            friends.removeAll()
            users.removeAll()
            sentFriendRequests.removeAll()
            pendingFriendRequests.removeAll()
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func sendFriendRequest(to email: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        friendRequestsRef.whereField("receiver", isEqualTo: email).whereField("sender", isEqualTo: currentUser.email).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            if let requests = snapshot?.documents, requests.isEmpty {
                let data: [String: Any] = [
                    "sender": currentUser.email,
                    "receiver": email,
                    "status": "pending"
                ]
                self.friendRequestsRef.addDocument(data: data) { error in
                    if let error = error {
                        print("Error sending friend request: \(error.localizedDescription)")
                        return
                    }
                    print("Friend request sent")
                    
                    // Create a new FriendRequest object and append it to the sentFriendRequests array
                    let sentRequest = FriendRequest(id: "", sender: currentUser.email!, receiver: email, status: "pending")
                    self.sentFriendRequests.append(sentRequest)
                }
            } else {
                print("Friend request already exists")
            }
        }
    }
    
    
    func createAccount(name: String, email: String, password: String, profilePicture: UIImage? = nil) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                return
            }
            
            // Set the display name of the user
            let changeRequest = authResult?.user.createProfileChangeRequest()
            changeRequest?.displayName = name
            changeRequest?.commitChanges { error in
                if let error = error {
                    print("Error updating display name: \(error.localizedDescription)")
                    return
                }
                print("Display name updated")
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.reset()
                }
            }
            
            // Add user to Firestore
            if let user = authResult?.user {
                if let image = profilePicture, let imageData = image.jpegData(compressionQuality: 0.8) {
                    self.uploadProfilePicture(image) { url in
                        let newUser: [String: Any] = [
                            "uid": user.uid,
                            "name": name,
                            "email": email,
                            "profilePictureURL": url ?? "",
                            "fcmToken": Messaging.messaging().fcmToken ?? ""
                        ]
                        print("fcmToken: "+Messaging.messaging().fcmToken!)
                        self.usersRef.document(user.uid).setData(newUser) { error in
                            if let error = error {
                                print("Error adding user to Firestore: \(error.localizedDescription)")
                            } else {
                                print("User added to Firestore")
                            }
                        }
                    }
                } else {
                    let newUser: [String: Any] = [
                        "uid": user.uid,
                        "name": name,
                        "email": email,
                        "fcmToken": Messaging.messaging().fcmToken ?? "",
                        "profilePictureURL": "https://icons.veryicon.com/png/o/internet--web/prejudice/user-128.png"
                    ]
                    self.usersRef.document(user.uid).setData(newUser) { error in
                        if let error = error {
                            print("Error adding user to Firestore: \(error.localizedDescription)")
                        } else {
                            print("User added to Firestore")
                        }
                    }
                }
            }
        }
    }
    
    func fetchFriendRequests() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        friendRequestsRef.whereField("receiver", isEqualTo: currentUserEmail).whereField("status", isEqualTo: "pending").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching friend requests: \(error.localizedDescription)")
                return
            }
            
            self.friendRequests = querySnapshot?.documents ?? []
        }
    }
    
    func updateFriendRequestStatus(documentID: String, status: String) {
        friendRequestsRef.document(documentID).getDocument { snapshot, error in
            guard let snapshot = snapshot else {
                print("Error fetching friend request: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            guard let data = snapshot.data(),
                  let sender = data["sender"] as? String,
                  let receiver = data["receiver"] as? String else {
                print("Error getting friend request data")
                return
            }
            if status == "accepted" {
                let friendsRef = Firestore.firestore().collection("friends")
                friendsRef.addDocument(data: ["user1": sender, "user2": receiver])
                self.reset()
            }
            // Delete the friend request document
            self.friendRequestsRef.document(documentID).delete { error in
                if let error = error {
                    print("Error deleting friend request: \(error.localizedDescription)")
                } else {
                    print("Friend request deleted.")
                    self.reset()
                }
            }
        }
    }
}
