import MapKit

class FriendAnnotation: NSObject, Identifiable, MKAnnotation {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String?

    init(id: String, coordinate: CLLocationCoordinate2D, title: String?) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
    }
}
