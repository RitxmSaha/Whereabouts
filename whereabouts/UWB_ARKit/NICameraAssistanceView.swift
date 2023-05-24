/*
Abstract:
Views and utilities for Nearby Interaction's Camera Assistance feature.
*/

import SwiftUI
import NearbyInteraction
import ARKit
import RealityKit
import os
import Combine

// The main view for the Camera Assistance feature.
struct NICameraAssistanceView: View {
    @StateObject var sessionManager = NISessionManager()
    var body: some View {
        GeometryReader { reader in
            VStack {
                Spacer()
                NIARView(sessionManager: sessionManager)
                    .frame(width: reader.size.width, height: reader.size.height * 0.95,
                       alignment: .center)
                    .overlay(NICoachingOverlay(horizontalAngle: sessionManager.latestNearbyObject?.horizontalAngle,
                                               distance: sessionManager.latestNearbyObject?.distance,
                                               convergenceContext: sessionManager.convergenceContext), alignment: .center)
                Spacer()
            }
        }
    }
}

// Previews the view.
struct NICameraAssistanceView_Previews: PreviewProvider {
    static var previews: some View {
        NICameraAssistanceView()
    }
}

// A subview with the AR view.
struct NIARView: UIViewRepresentable {

    var sessionManager = NISessionManager()

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Set the AR session into the interaction session prior to
        // running the interaction session so that the framework doesn't
        // create its own AR session.
        sessionManager.session?.setARSession(arView.session)
        
        // Monitor ARKit session events.
        arView.session.delegate = sessionManager

        // Create a world-tracking configuration to Nearby Interaction's
        // AR session requirements. For more information,
        // see the `setARSession` function of `NISession`.
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = false
        configuration.userFaceTrackingEnabled = false
        configuration.initialWorldMap = nil
        configuration.environmentTexturing = .automatic

        // Run the view's AR session.
        arView.session.run(configuration)

        // Add the blurred view by default at the start when creating the view.
        blurView.frame = arView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(blurView)

        // Return the AR view.
        return arView
    }

    // A coordinator for updating AR content.
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // A coordinator class.
    @MainActor
    class Coordinator: NSObject {
        // A parent Nearby Interaction AR view.
        var parent: NIARView
        // An anchor entity for placing AR content in the AR world.
        var peerAnchor: AnchorEntity?

        init( _ parent: NIARView) {
            self.parent = parent
            self.animationUpdates = []
        }

        // The constants.
        let sphereSeparation = Float(0.6)

        // The animation objects.
        var animationUpdates: [Cancellable?]

        // Animates an anchor entity.
        func animate(entity: HasTransform,
                     reference: Entity?,
                     height: Float,
                     scale: Float,
                     duration: TimeInterval,
                     arView: ARView,
                     index: Int) {

            // Update the location by adding the height and scaling by a factor.
            var transform = entity.transform
            transform.scale *= scale
            transform.translation.y += height

            // Move the entity over a duration.
            entity.move(to: transform.matrix,
                        relativeTo: reference,
                        duration: duration,
                        timingFunction: .default)

            // Add the animation completion monitor, if necessary.
            guard animationUpdates.count < (index + 1)
            else { return }

            // Add a monitor for the completed animation to execute it again.
            animationUpdates.append(arView.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self,
                                                     on: entity, { _ in
                // Restore the original location and scale.
                entity.position = [0, Float(index) * self.sphereSeparation, 0]
                entity.scale = entity.scale(relativeTo: entity.parent) / scale

                // Animate again to repeat.
                self.animate(entity: entity,
                             reference: reference,
                             height: height,
                             scale: scale,
                             duration: duration,
                             arView: arView,
                             index: index)
            }))
        }

        func placeSpheresInView(_ arView: ARView, _ worldTransform: simd_float4x4) {
            // Create or update the anchor entity.
            if self.peerAnchor != nil {
                // Update the world transform.
                self.peerAnchor!.transform.matrix = worldTransform
            } else {
                // Create the peer anchor only once.
                self.peerAnchor = AnchorEntity(.world(transform: worldTransform))

                // Add multiple spheres.
                for index in 0...3 {
                    // Increase the size of each sphere.
                    let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.15 + Float(index) * 0.1),
                                             materials: [SimpleMaterial(color: .systemPink,
                                                                         isMetallic: true)])

                    // Add the model entity to the anchor entity.
                    self.peerAnchor!.addChild(sphere)

                    // Update the position for each sphere by moving up the y-axis.
                    sphere.position = [0, Float(index) * sphereSeparation, 0]

                    // Add the anchor entity to the AR world.
                    arView.scene.addAnchor(self.peerAnchor!)

                    // The animation of spheres.
                    self.animate(entity: sphere,
                                 reference: self.peerAnchor!,
                                 height: Float(index + 1) * sphereSeparation,
                                 scale: 2.0,
                                 duration: 2.0,
                                 arView: arView,
                                 index: index)
                    }
            }
        }

        // Updates the peer anchor.
        func updatePeerAnchor(arView: ARView, currentNearbyObject: NINearbyObject, currentConvergenceContext: NIAlgorithmConvergence) {

            // Check whether the framework fully resolves the world transform.
            if currentConvergenceContext.status == .converged {
                // Hide the blur view.
                parent.blurView.isHidden = true

                // Compute the world transform and ensure it's present.
                guard let worldTransform = parent.sessionManager.session?.worldTransform(for: currentNearbyObject) else { return }

                // Place spheres into the view.
                placeSpheresInView(arView, worldTransform)

            } else {
                // Show the blur view when the status isn't fully converged.
                parent.blurView.isHidden = false

                // Remove any previously shown spheres.
                if self.peerAnchor != nil {
                    // Remove the peer anchor.
                    arView.scene.removeAnchor(self.peerAnchor!)

                    // Cancel all the pending animations.
                    for animations in animationUpdates {
                        animations?.cancel()
                    }

                    // Remove all the animations.
                    animationUpdates.removeAll()

                    // Reset the peer anchor.
                    self.peerAnchor = nil
                }
                return
            }

        }
    }

    // Updates the AR view.
    func updateUIView(_ uiView: ARView, context: Context) {
        // Ensure the session manager has the latest nearby-object update.
        guard let currentNearbyObject = sessionManager.latestNearbyObject else { return }
        // Ensure the session manager has the latest convergence status.
        guard let currentConvergenceContext = sessionManager.convergenceContext else { return }

        // Use the coordinator to update the AR view as needed based on the updated nearby object and convergence context.
        context.coordinator.updatePeerAnchor(arView: uiView,
                                             currentNearbyObject: currentNearbyObject,
                                             currentConvergenceContext: currentConvergenceContext)
    }
}

// An overlay view for coaching or directing the user.
struct NICoachingOverlay: View {
    // Variables for horizontal angle, distance, and convergence.
    var horizontalAngle: Float?
    var distance: Float?
    var convergenceContext: NIAlgorithmConvergence?

    var body: some View {
        VStack {
            // Scale the image based on distance, if available.
            let distanceScale = distance == nil ? 0.5 : distance!.scale(minRange: 0.15, maxRange: 1.0, minDomain: 0.5, maxDomain: 2.0)
            let imageScale = (horizontalAngle == nil) ? 0.5 : distanceScale
            // Text to display that guides the user to move the phone up and down.
            let upDownText = (convergenceContext != nil && convergenceContext!.status != .converged) ? "" : ""
            // The final guidance text.
            let guidanceText = distance == nil ? "Searching for other peers..." : (horizontalAngle == nil ? "Move side to side" : "Located Peer!")

            // Display an image to help guide the user.
            Image(systemName: distance == nil ? "sparkle.magnifyingglass" : (horizontalAngle == nil ? "move.3d" : "arrow.up.circle"))
                    .resizable()
                    .frame(width: 200 * CGFloat(imageScale), height: 200 * CGFloat(imageScale), alignment: .center)
            // Rotate the image by the horizontal angle, when available.
                .rotationEffect(.init(radians: Double(horizontalAngle ?? 0.0)))
            Text(guidanceText).frame(alignment: .center)
            if let distance = distance {
                Text("Distance: \(distance, specifier: "%.2f") meters").frame(alignment: .center)
            }
            Text(upDownText).frame(alignment: .center).opacity(
                horizontalAngle != nil && (convergenceContext != nil && convergenceContext!.status != .converged) ? 0.85 : 0)
        }
        // Remove the overlay if the status is converged.
        .opacity(convergenceContext != nil && convergenceContext!.status == .converged ? 0 : 1)
        .foregroundColor(.white)
    }
}


