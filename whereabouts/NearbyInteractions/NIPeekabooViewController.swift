/*
 Abstract:
 DEPRECATED CODE -> REPLACED BY NICAMERAASSISTANCEVIEW
 */

import SwiftUI
import UIKit
import ARKit
import NearbyInteraction
import MultipeerConnectivity

class NIPeekabooViewController: UIViewController, NISessionDelegate {
    
    // MARK: - `IBOutlet` instances.
    private let monkeyLabel = UILabel()
    private let centerInformationLabel = UILabel()
    private let detailContainer = UIView()
    private let detailAzimuthLabel = UILabel()
    private let detailDeviceNameLabel = UILabel()
    private let detailDistanceLabel = UILabel()
    private let detailDownArrow = UIImageView()
    private let detailElevationLabel = UILabel()
    private let detailLeftArrow = UIImageView()
    private let detailRightArrow = UIImageView()
    private let detailUpArrow = UIImageView()
    private let detailAngleInfoView = UIView()
    private let detailElevationArrow = UILabel()
    private let detailXLabel = UILabel()
    private let detailYLabel = UILabel()
    private let detailZLabel = UILabel()
    
    
    
    
    // MARK: - Distance and direction state.
    
    // A threshold, in meters, the app uses to update its display.
    let nearbyDistanceThreshold: Float = 10
    
    enum DistanceDirectionState {
        case closeUpInFOV, notCloseUpInFOV, outOfFOV, unknown
    }
    
    // MARK: - Class variables
    var session: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?
    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    var currentDistanceDirectionState: DistanceDirectionState = .unknown
    var mpc: MPCSession?
    var connectedPeer: MCPeerID?
    var sharedTokenWithPeer = false
    var peerDisplayName: String?
    
    
    
    
    // MARK: - View Lifecycle
    override func loadView() {
        super.loadView()
        
        // Create and add subviews to the view hierarchy.
        view.addSubview(monkeyLabel)
        view.addSubview(centerInformationLabel)
        view.addSubview(detailDistanceLabel)
        view.addSubview(detailElevationLabel)
        view.addSubview(detailElevationArrow)
        view.addSubview(detailXLabel)
        view.addSubview(detailYLabel)
        view.addSubview(detailZLabel)
        
        // Configure the subviews.
        monkeyLabel.text = "↑"
        monkeyLabel.textColor = .white
        monkeyLabel.font = UIFont.systemFont(ofSize: 72)
        monkeyLabel.textAlignment = .center
        
        centerInformationLabel.text = "Center information"
        centerInformationLabel.font = UIFont.systemFont(ofSize: 24)
        centerInformationLabel.textColor = .white
        centerInformationLabel.textAlignment = .center
        
        detailDistanceLabel.text = "Distance: --" // Set the initial text or a placeholder
        detailDistanceLabel.font = UIFont.systemFont(ofSize: 18)
        detailDistanceLabel.textColor = .white
        detailDistanceLabel.textAlignment = .center
        
        // Configure the detailElevationLabel and detailElevationArrow subviews
        detailElevationLabel.text = "Elevation: --" // Set the initial text or a placeholder
        detailElevationLabel.font = UIFont.systemFont(ofSize: 18)
        detailElevationLabel.textColor = .white
        detailElevationLabel.textAlignment = .center

        detailElevationArrow.text = "↑" // Set the initial arrow text, it will be updated later
        detailElevationArrow.textColor = .white
        detailElevationArrow.font = UIFont.systemFont(ofSize: 18)
        detailElevationArrow.textAlignment = .center
        
        detailXLabel.text = "X: " // Set the initial text or a placeholder
        detailXLabel.font = UIFont.systemFont(ofSize: 18)
        detailXLabel.textColor = .white
        detailXLabel.textAlignment = .center
        
        detailYLabel.text = "Y: " // Set the initial text or a placeholder
        detailYLabel.font = UIFont.systemFont(ofSize: 18)
        detailYLabel.textColor = .white
        detailYLabel.textAlignment = .center
        
        detailZLabel.text = "Z: " // Set the initial text or a placeholder
        detailZLabel.font = UIFont.systemFont(ofSize: 18)
        detailZLabel.textColor = .white
        detailZLabel.textAlignment = .center
        
        
        // Set the background color.
        view.backgroundColor = .black
        
        // Layout the subviews.
        monkeyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            monkeyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            monkeyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
        ])
        
        centerInformationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerInformationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerInformationLabel.topAnchor.constraint(equalTo: monkeyLabel.bottomAnchor, constant: 20),
        ])
        
        detailDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailDistanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailDistanceLabel.topAnchor.constraint(equalTo: centerInformationLabel.bottomAnchor, constant: 10),
        ])
        
        detailElevationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailElevationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailElevationLabel.bottomAnchor.constraint(equalTo: monkeyLabel.topAnchor, constant: -20),
        ])

        detailElevationArrow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailElevationArrow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailElevationArrow.bottomAnchor.constraint(equalTo: detailElevationLabel.topAnchor, constant: -10),
        ])
        
        detailXLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailXLabel.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            detailXLabel.bottomAnchor.constraint(equalTo: detailElevationArrow.topAnchor, constant: -10),
        ])

        detailYLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailYLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detailYLabel.bottomAnchor.constraint(equalTo: detailElevationArrow.topAnchor, constant: -10),
        ])

        detailZLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailZLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 40),
            detailZLabel.bottomAnchor.constraint(equalTo: detailElevationArrow.topAnchor, constant: -10),
        ])
        
        startup()
    }
    
    
    // MARK: - UI life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startup() {
        print("Startup method called")
        // Create the NISession.
        session = NISession()
        
        // Set the delegate.
        session?.delegate = self
        
        // Because the session is new, reset the token-shared flag.
        sharedTokenWithPeer = false
        
        // If `connectedPeer` exists, share the discovery token, if needed.
        if connectedPeer != nil && mpc != nil {
            if let myToken = session?.discoveryToken {
                updateInformationLabel(description: "Initializing ...")
                if !sharedTokenWithPeer {
                    shareMyDiscoveryToken(token: myToken)
                }
                guard let peerToken = peerDiscoveryToken else {
                    return
                }
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                config.isCameraAssistanceEnabled = true
                session?.run(config)
            } else {
                fatalError("Unable to get self discovery token, is this session invalidated?")
            }
        } else {
            updateInformationLabel(description: "Discovering Peer ...")
            startupMPC()
            
            // Set the display state.
            currentDistanceDirectionState = .unknown
        }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return false
    }
    
    // MARK: - `NISessionDelegate`.
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }
        
        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }
        
        guard let nearbyObjectUpdate = peerObj else {
            return
        }
        
        // Update the the state and visualizations.
        let nextState = getDistanceDirectionState(from: nearbyObjectUpdate)
        updateVisualization(from: currentDistanceDirectionState, to: nextState, with: nearbyObjectUpdate)
        currentDistanceDirectionState = nextState
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }
        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }
        
        if peerObj == nil {
            return
        }
        
        currentDistanceDirectionState = .unknown
        
        switch reason {
        case .peerEnded:
            // The peer token is no longer valid.
            peerDiscoveryToken = nil
            
            // The peer stopped communicating, so invalidate the session because
            // it's finished.
            session.invalidate()
            
            // Restart the sequence to see if the peer comes back.
            startup()
            
            // Update the app's display.
            updateInformationLabel(description: "Peer Ended")
        case .timeout:
            
            // The peer timed out, but the session is valid.
            // If the configuration is valid, run the session again.
            if let config = session.configuration {
                session.run(config)
            }
            updateInformationLabel(description: "Peer Timeout")
        default:
            fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        currentDistanceDirectionState = .unknown
        updateInformationLabel(description: "Session suspended")
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        // Session suspension ended. The session can now be run again.
        if let config = self.session?.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            startup()
        }
        
        centerInformationLabel.text = peerDisplayName
        detailDeviceNameLabel.text = peerDisplayName
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        currentDistanceDirectionState = .unknown
        
        // If the app lacks user approval for Nearby Interaction, present
        // an option to go to Settings where the user can update the access.
        if case NIError.userDidNotAllow = error {
            if #available(iOS 15.0, *) {
                // In iOS 15.0, Settings persists Nearby Interaction access.
                updateInformationLabel(description: "Nearby Interactions access required. You can change access for NIPeekaboo in Settings.")
                // Create an alert that directs the user to Settings.
                let accessAlert = UIAlertController(title: "Access Required",
                                                    message: """
                                                    NIPeekaboo requires access to Nearby Interactions for this sample app.
                                                    Use this string to explain to users which functionality will be enabled if they change
                                                    Nearby Interactions access in Settings.
                                                    """,
                                                    preferredStyle: .alert)
                accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
                    // Send the user to the app's Settings to update Nearby Interactions access.
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }))
                
                // Display the alert.
                present(accessAlert, animated: true, completion: nil)
            } else {
                // Before iOS 15.0, ask the user to restart the app so the
                // framework can ask for Nearby Interaction access again.
                updateInformationLabel(description: "Nearby Interactions access required. Restart NIPeekaboo to allow access.")
            }
            
            return
        }
        
        // Recreate a valid session.
        startup()
    }
    
    // MARK: - Discovery token sharing and receiving using MPC.
    
    func startupMPC() {
        if mpc == nil {
            // Prevent Simulator from finding devices.
#if targetEnvironment(simulator)
            mpc = MPCSession(service: "nisample", identity: "com.example.ritam", maxPeers: 1)
#else
            mpc = MPCSession(service: "nisample", identity: "com.example.ritam", maxPeers: 1)
#endif
            mpc?.peerConnectedHandler = connectedToPeer
            mpc?.peerDataHandler = dataReceivedHandler
            mpc?.peerDisconnectedHandler = disconnectedFromPeer
        }
        mpc?.invalidate()
        mpc?.start()
    }
    
    func connectedToPeer(peer: MCPeerID) {
        guard let myToken = session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }
        
        if connectedPeer != nil {
            fatalError("Already connected to a peer.")
        }
        
        if !sharedTokenWithPeer {
            shareMyDiscoveryToken(token: myToken)
        }
        
        connectedPeer = peer
        peerDisplayName = peer.displayName
        
        centerInformationLabel.text = peerDisplayName
        detailDeviceNameLabel.text = peerDisplayName
    }
    
    func disconnectedFromPeer(peer: MCPeerID) {
        if connectedPeer == peer {
            connectedPeer = nil
            sharedTokenWithPeer = false
        }
    }
    
    func dataReceivedHandler(data: Data, peer: MCPeerID) {
        guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            fatalError("Unexpectedly failed to decode discovery token.")
        }
        peerDidShareDiscoveryToken(peer: peer, token: discoveryToken)
    }
    
    func shareMyDiscoveryToken(token: NIDiscoveryToken) {
        guard let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        mpc?.sendDataToAllPeers(data: encodedData)
        sharedTokenWithPeer = true
    }
    
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        if connectedPeer != peer {
            fatalError("Received token from unexpected peer.")
        }
        // Create a configuration.
        peerDiscoveryToken = token
        
        let config = NINearbyPeerConfiguration(peerToken: token)
        config.isCameraAssistanceEnabled = true
        
        // Run the session.
        session?.run(config)
    }
    
    // MARK: - Visualizations
    func isNearby(_ distance: Float) -> Bool {
        return distance < nearbyDistanceThreshold
    }
    
    func isPointingAt(_ angleRad: Float) -> Bool {
        // Consider the range -15 to +15 to be "pointing at".
        return abs(angleRad.radiansToDegrees) <= 15
    }
    
    func getDistanceDirectionState(from nearbyObject: NINearbyObject) -> DistanceDirectionState {
        if nearbyObject.distance == nil && nearbyObject.direction == nil {
            return .unknown
        }
        
        let isNearby = nearbyObject.distance.map(isNearby(_:)) ?? false
        let directionAvailable = nearbyObject.direction != nil
        
        if isNearby && directionAvailable {
            return .closeUpInFOV
        }
        
        if !isNearby && directionAvailable {
            return .notCloseUpInFOV
        }
        
        return .outOfFOV
    }
    
    private func animate(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        if let directionVector = peer.direction, let distance = peer.distance {
            let xDistance = distance * directionVector.x
            let yDistance = distance * directionVector.y
            let zDistance = distance * directionVector.z
            detailXLabel.text = String(format: "X: %0.2f m", xDistance)
            detailYLabel.text = String(format: "Y: %0.2f m", yDistance)
            detailZLabel.text = String(format: "Z: %0.2f m", zDistance)
        } else {
            print("Error: Direction vector or distance is nil.")
        }
        
        let azimuth = peer.direction.map(azimuth(from:))
        let elevation = peer.direction.map(elevation(from:))
        
        centerInformationLabel.text = peerDisplayName
        detailDeviceNameLabel.text = peerDisplayName
        
        // If the app transitions from unavailable, present the app's display
        // and hide the user instructions.
        if currentState == .unknown && nextState != .unknown {
            monkeyLabel.alpha = 1.0
            centerInformationLabel.alpha = 1.0
            detailContainer.alpha = 1.0
        }
        
        if nextState == .unknown {
            monkeyLabel.alpha = 0.0
            centerInformationLabel.alpha = 1.0
            detailContainer.alpha = 0.0
        }
        
        if nextState == .outOfFOV || nextState == .unknown {
            detailAngleInfoView.alpha = 0.0
        } else {
            detailAngleInfoView.alpha = 1.0
        }
        
        // Set the app's display based on peer state.
        switch nextState {
        case .closeUpInFOV:
            monkeyLabel.text = "↑"
        case .notCloseUpInFOV:
            monkeyLabel.text = "↑"
        case .outOfFOV:
            monkeyLabel.text = "↑"
        case .unknown:
            monkeyLabel.text = "↑"
        }
        
        if peer.distance != nil {
            detailDistanceLabel.text = String(format: "%0.2f m", peer.distance!)
        }
        if let directionVector = peer.direction {
            let peerDirectionX = directionVector.x
            let peerDirectionY = directionVector.y
            let rotationAngle = atan2(peerDirectionX, peerDirectionY)

            monkeyLabel.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
        }



        // Don't update visuals if the peer device is unavailable or out of the
        // U1 chip's field of view.
        if nextState == .outOfFOV || nextState == .unknown {
            return
        }
        
        if let directionVector = peer.direction, let distance = peer.distance {
            let yDistance = distance * directionVector.y
            detailElevationLabel.text = String(format: "Height: %0.2f m", yDistance)
            if elevation! < 0 {
                detailDownArrow.alpha = 1.0
                detailUpArrow.alpha = 0.0
                detailElevationArrow.text = "↓"
            } else {
                detailDownArrow.alpha = 0.0
                detailUpArrow.alpha = 1.0
                detailElevationArrow.text = "↑"
            }
            if isPointingAt(elevation!) {
                detailElevationLabel.alpha = 1.0
            } else {
                detailElevationLabel.alpha = 0.5
            }
        }
        
        if azimuth != nil {
            if isPointingAt(azimuth!) {
                detailAzimuthLabel.alpha = 1.0
                detailLeftArrow.alpha = 0.25
                detailRightArrow.alpha = 0.25
            } else {
                detailAzimuthLabel.alpha = 0.5
                if azimuth! < 0 {
                    detailLeftArrow.alpha = 1.0
                    detailRightArrow.alpha = 0.25
                } else {
                    detailLeftArrow.alpha = 0.25
                    detailRightArrow.alpha = 1.0
                }
            }
            detailAzimuthLabel.text = String(format: "% 3.0f°", azimuth!.radiansToDegrees)
        }
    }
    
    func updateVisualization(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        // Invoke haptics on "peekaboo" or on the first measurement.
        if currentState == .notCloseUpInFOV && nextState == .closeUpInFOV || currentState == .unknown {
            impactGenerator.impactOccurred()
        }
        
        // Animate into the next visuals.
        UIView.animate(withDuration: 0.3, animations: {
            self.animate(from: currentState, to: nextState, with: peer)
        })
    }
    
    func updateInformationLabel(description: String) {
        UIView.animate(withDuration: 0.3, animations: {
            self.monkeyLabel.alpha = 0.0
            self.detailContainer.alpha = 0.0
            self.centerInformationLabel.alpha = 1.0
            self.centerInformationLabel.text = description
        })
    }
}
