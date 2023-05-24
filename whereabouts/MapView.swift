import SwiftUI
import MapKit
import CoreLocation

struct MapViewtemp: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var locationManager = UserLocationManager()
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: appViewModel.friendsLocations) { friendLocation in
                    MapAnnotation(coordinate: friendLocation.coordinate) {
                        VStack {
                            Text(friendLocation.title ?? "")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .padding(.bottom, 2)
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                Circle()
                                    .stroke(Color(red: 0.8, green: 0.8, blue: 0.8), lineWidth: 3)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                    }
                }
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        if let userLocation = locationManager.userLocation {
                            region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        }
                        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                            appViewModel.fetchFriendsLocations()
                        }
                    }
                    .onDisappear {
                        timer?.invalidate()
                    }
                
                VStack {
                    HStack {
                        Button(action: {
                            if let userLocation = locationManager.userLocation {
                                withAnimation {
                                    region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                    Button(action: {
                        // Button action will be added later
                    }) {
                        Text("Directions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    .padding(.trailing)
                    .padding(.bottom)
                }
            }
        }
        .navigationBarTitle("Map", displayMode: .inline)
    }
    
}

