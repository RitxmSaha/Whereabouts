import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseInteractions {
    
    static let shared = FirebaseInteractions()
    
    private init() {}
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            print("Error signing out: \(error)")
            return false
        }
    }
    
    // MARK: - Firestore
    
    func addUserToFirestore(uid: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.setData(["email": email]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchUser(uid: String, completion: @escaping (Result<DocumentSnapshot, Error>) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let documentSnapshot = documentSnapshot {
                completion(.success(documentSnapshot))
            }
        }
    }
}
