import Foundation
import CoreLocation

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    let profilePictureURL: String?
    let fcmToken: String?
}
