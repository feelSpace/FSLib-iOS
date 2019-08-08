//
//  ViewController.swift
//  FSLibIOsNaviDemo
//
//  Created by David on 12/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import UIKit
import CoreBluetooth
import FSLibIOs

class ViewController: UIViewController, FSNavigationDelegate {

    //MARK: UI components references
    
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var beltModeLabel: UILabel!
    @IBOutlet weak var navigationDirectionLabel: UILabel!
    @IBOutlet weak var navigationSignalTypeLabel: UILabel!
    @IBOutlet weak var beltHeadingLabel: UILabel!
    
    //MARK: Private properties
    
    // Controller for belt signals
    var beltNavigationController = FSNavigationController.instance
    
    //MARK: Private methods
    
    /** Updates the labels. */
    internal func updateUILabels() {
        // Connection state
        switch beltNavigationController.connectionState {
        case .notConnected:
            connectionStateLabel.text = "Connection state: Not connected"
        case .scanning:
            connectionStateLabel.text = "Connection state: Scanning"
        case .connecting, .discoveringServices, .handshake:
            connectionStateLabel.text = "Connection state: Connecting"
        case .connected:
            connectionStateLabel.text = "Connection state: Connected"
        }
        // Belt mode
        switch beltNavigationController.beltMode {
        case .unknown:
            beltModeLabel.text = "Belt mode: Unknown"
        case .wait:
            beltModeLabel.text = "Belt mode: Wait"
        case .compass:
            beltModeLabel.text = "Belt mode: Compass"
        case .crossing:
            beltModeLabel.text = "Belt mode: Crossing"
        case .pause:
            beltModeLabel.text = "Belt mode: Pause"
        case .app:
            beltModeLabel.text = "Belt mode: Navigation"
        case .standby:
            beltModeLabel.text = "Belt mode: Standby"
        case .calibration:
            beltModeLabel.text = "Belt mode: Calibration"
        }
        // Navigation direction and signal type
        if let direction = beltNavigationController.activeNavigationDirection
        {
            navigationDirectionLabel.text = "Navigation direction: \(direction)"
            switch beltNavigationController.activeNavigationSignalType {
            case .navigating:
                navigationSignalTypeLabel.text =
                "Signal type: Navigating"
            case .approachingDestination:
                navigationSignalTypeLabel.text =
                "Signal type: Approaching destination"
            case .destinationReached:
                navigationSignalTypeLabel.text =
                "Signal type: Destination reached"
            case .ongoingTurn:
                navigationSignalTypeLabel.text =
                "Signal type: Ongoing turn"
            }
        } else {
            navigationDirectionLabel.text = "Navigation direction: -"
            navigationSignalTypeLabel.text = "Navigation signal type: -"
        }
        // Belt heading
        if (beltNavigationController.connectionState != .connected) {
            beltHeadingLabel.text = "Belt heading: -"
            // Note: Heading value updated in notification callback
        }
    }
    
    /** Displays a Toast message.
     Code from: https://stackoverflow.com/a/35130932 */
    internal func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(
            x: self.view.frame.size.width/2 - 75,
            y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1,
                       options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    //MARK: ViewController overrided methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register as delegate
        beltNavigationController.delegate = self
        // Update UI
        updateUILabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: UI actions
    
    @IBAction func searchAndConnectClick(_ sender: UIButton) {
        print("Search and connect belt.")
        beltNavigationController.searchAndConnectBelt()
    }
    
    @IBAction func disconnectClick(_ sender: UIButton) {
        print("Disconnect belt.")
        beltNavigationController.disconnectBelt()
    }
    
    @IBAction func startNavigationClick(_ sender: UIButton) {
        print("Start navigation.")
        beltNavigationController.startNavigation()
        updateUILabels()
    }
    
    @IBAction func stopNavigationClick(_ sender: UIButton) {
        print("Stop navigation.")
        beltNavigationController.stopNavigation()
        updateUILabels()
    }
    
    @IBAction func pauseNavigationClick(_ sender: UIButton) {
        print("Pause navigation.")
        beltNavigationController.pauseNavigation()
        updateUILabels()
    }
    
    @IBAction func navigationEastClick(_ sender: UIButton) {
        print("Navigation East.")
        beltNavigationController.setNavigationDirection(
            90, signalType: .navigating)
        updateUILabels()
    }
    
    @IBAction func navigationNorthEastClick(_ sender: UIButton) {
        print("Navigation North-East.")
        beltNavigationController.setNavigationDirection(
            45, signalType: .navigating)
        updateUILabels()
    }
    
    @IBAction func ongoingTurnClick(_ sender: UIButton) {
        print("Ongoing turn West.")
        beltNavigationController.setNavigationDirection(
            270, signalType: .ongoingTurn)
        updateUILabels()
    }
    
    @IBAction func approachingDestinationNorthClick(_ sender: UIButton) {
        print("Approaching destination North.")
        beltNavigationController.setNavigationDirection(
            0, signalType: .approachingDestination)
        updateUILabels()
    }
    
    @IBAction func destinationReachedClick(_ sender: UIButton) {
        print("Destination reached.")
        beltNavigationController.setNavigationDirection(
            0, signalType: .destinationReached)
        updateUILabels()
    }
    
    @IBAction func notifyDestinationReachedClick(_ sender: UIButton) {
        print("Notify destination reached.")
        beltNavigationController.notifyDestinationReached(
            shouldStopNavigation: true)
    }
    
    @IBAction func notifyWarningClick(_ sender: UIButton) {
        print("Notify warning.")
        beltNavigationController.notifyWarning()
    }
    
    @IBAction func notifyDirectionSouthClick(_ sender: UIButton) {
        print("Notify direction South.")
        beltNavigationController.notifyDirection(180)
    }

    //MARK: Delegate methods
    
    /** Callback that informs about connection state changes. */
    func onConnectionStateChanged(previousState: FSConnectionState,
                                      newState: FSConnectionState) {
        print("Connection state changed.")
        updateUILabels()
    }
    
    /** Callback that informs about a mode change. */
    func onBeltModeChanged(beltMode: FSBeltMode,
                                 buttonPressed: Bool) {
        print("Belt mode changed.")
        updateUILabels()
    }
    
    /** Informs that the user has press the Home button. */
    func onBeltRequestHome() {
        print("Home request received.")
        showToast(message:
            "Home request received. Start navigation signal to West.")
        // Start navigation to West
        beltNavigationController.setNavigationDirection(
            -90, signalType: .navigating)
        beltNavigationController.startNavigation()
    }
    
    /** Notifies that the belt orientation has been updated. */
    func onBeltOrientationNotified(beltMagHeading: Int,
                                   beltCompassInaccurate: Bool) {
        if (beltCompassInaccurate) {
            beltHeadingLabel.text = "Belt heading: \(beltMagHeading) " +
                                    "(Inaccurate!)"
        } else {
            beltHeadingLabel.text = "Belt heading: \(beltMagHeading)"
        }
    }
}

