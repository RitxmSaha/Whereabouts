import SwiftUI
import MapKit


struct MapView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @ObservedObject var locationManager: UserLocationManager
    @State var customMapView: CustomMapView
    @State var timer: Timer?
    @State var isFollowModeActive: Bool = false
    @State private var isPeekabooViewPresented: Bool = false
    @State private var peekabooViewModel = NIPeekabooViewController()
    
    init(locationManager: UserLocationManager) {
        self.locationManager = locationManager
        self._customMapView = State(initialValue: CustomMapView(locationManager: locationManager))
    }
    
    var body: some View {
        ZStack {
            customMapView
                .environmentObject(appViewModel)
                .onAppear {
                    appViewModel.customMapView = customMapView
                    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                        appViewModel.fetchFriendsLocations()
                    }
                }
                .sheet(isPresented: $isPeekabooViewPresented) {
                    NICameraAssistanceView()
                }
            VStack {
                HStack {
                    Button(action: {
                        
                        isFollowModeActive.toggle()
                        if isFollowModeActive {
                            customMapView.mapView.userTrackingMode = .followWithHeading
                        } else {
                            customMapView.mapView.userTrackingMode = .none
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
                    VStack {
                        Button(action: {
                            appViewModel.sendEmergencyNotification()
                        }) {
                            Text("Emergency")
                                .foregroundColor(.white)
                                .padding(.all, 8)
                                .background(Color.red)
                                .cornerRadius(8)
                                //.fontWeight(.bold)
                        }
                        
                        Button(action: {
                            isPeekabooViewPresented.toggle()
                        }) {
                            Text("NI Tracking")
                                .foregroundColor(.white)
                                .padding(.all, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                                //.fontWeight(.bold)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            VStack {
                Spacer()
                if appViewModel.cancelButton {
                    Button(action: {
                        appViewModel.toggleCancelButton()
                        appViewModel.cancelDirections()
                    }) {
                        Text("Cancel Tracking")
                            .foregroundColor(.white)
                            .padding(.all, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                            //.fontWeight(.bold)
                    }
                    .padding(.bottom, 16)
                }
            }
            
        }
    }
}

