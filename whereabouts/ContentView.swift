import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            if appViewModel.isAuthenticated {
                SignedInView()
            } else {
                AuthenticationView()
                    .environmentObject(appViewModel)
            }
        }
        .onChange(of: appViewModel.isAuthenticated) { _ in
            appViewModel.checkIfAuthenticated()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}
