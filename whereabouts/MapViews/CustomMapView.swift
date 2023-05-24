import SwiftUI
import MapKit
import CoreLocation


struct CustomMapView: UIViewRepresentable {
    @EnvironmentObject var appViewModel: AppViewModel
    @ObservedObject var locationManager: UserLocationManager
    @State var timer: Timer?
    @State var route: MKRoute?
    var mapView = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }


    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator

        // Make the map completely plain
        mapView.mapType = .standard
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsUserLocation = true // Show user's location

        locationManager.onLocationUpdate = { location in
            DispatchQueue.main.async {
                self.centerMapOnUserLocation(coordinate: location.coordinate)
            }
        }
        initTimer()
        return mapView
    }
    
    func initTimer() {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    self.mapView.removeAnnotations(self.mapView.annotations.filter { !($0 is MKUserLocation) })
                    // Add friendsLocations as annotations on the map
                    self.mapView.addAnnotations(self.appViewModel.friendsLocations)
                }
            }
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }

    func centerMapOnUserLocation(coordinate: CLLocationCoordinate2D) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    

    func drawRouteToDestination(destinationCoordinate: CLLocationCoordinate2D) {
            let userLocation = locationManager.userLocation!
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate, addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        
        if (findDistance(destinationCoordinate: destinationCoordinate, userLocation: userLocation) < 1000) {
            request.transportType = .walking
        } else {
            request.transportType = .automobile
        }
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else {
                    return
                }
                let currentOverlays = self.mapView.overlays.filter { $0 is MKPolyline }
                self.mapView.removeOverlays(currentOverlays)
                
                self.mapView.addOverlay(route.polyline)
                
                //self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    


    func removeRoute() {
        let currentOverlays = self.mapView.overlays.filter { $0 is MKPolyline }
        self.mapView.removeOverlays(currentOverlays)
    }
    
    func findDistance(destinationCoordinate: CLLocationCoordinate2D, userLocation: CLLocation) -> CLLocationDistance {
        let userCLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let destinationCLLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)

        let distanceInMeters = userCLLocation.distance(from: destinationCLLocation)
        return distanceInMeters
    }
    

        class Coordinator: NSObject, MKMapViewDelegate {
            var parent: CustomMapView

            init(_ parent: CustomMapView) {
                self.parent = parent
            }
            
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if overlay is MKPolyline {
                    let renderer = MKPolylineRenderer(overlay: overlay)
                    renderer.strokeColor = UIColor.blue
                    renderer.lineWidth = 5
                    
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                    
                    return renderer
                }
                return MKOverlayRenderer()
            }
        }
}
