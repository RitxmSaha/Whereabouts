import SwiftUI
import NearbyInteraction

struct PeekabooView: UIViewControllerRepresentable {
    
    @State var viewModel: NIPeekabooViewController

    func makeUIViewController(context: Context) -> NIPeekabooViewController {
        return viewModel
    }
    
    func updateUIViewController(_ uiViewController: NIPeekabooViewController, context: Context) {
        // Do nothing
    }
}
