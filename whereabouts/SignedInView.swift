import SwiftUI
import MapKit
import CoreLocation


struct SignedInView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var locationManager = UserLocationManager()
    
    
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.systemBackground
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
    
    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {
            PeopleView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("People")
                }.tag(0)
            
            MapView(locationManager: locationManager)
                .environmentObject(appViewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }.tag(1)
            
            
            SettingsView(appViewModel: appViewModel)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }.tag(2)
        }
    }
}




struct SignedInView_Previews: PreviewProvider {
    static var previews: some View {
        SignedInView()
            .environmentObject(AppViewModel())
    }
}
