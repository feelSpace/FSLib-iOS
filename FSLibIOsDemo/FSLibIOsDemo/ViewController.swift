//
//  ViewController.swift
//  FSLibIOsDemo
//
//  Created by David on 21/05/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import UIKit
import CoreBluetooth
import FSLibIOs

class ViewController: UIViewController,
FSConnectionDelegate, FSCommandDelegate {

    //MARK: Properties
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var searchBeltButton: UIButton!
    @IBOutlet weak var outputTextView: UITextView!
    
    var connectionManager: FSConnectionManager = FSConnectionManager.instance
    var commandManager: FSCommandManager?
    var orientation: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // *** Initializations ***
        connectionManager.delegate = self
        commandManager = connectionManager.commandManager
        connectionManager.commandManager.delegate = self
        updateStatusLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    // UI updates status label
    func updateStatusLabel() {
        switch connectionManager.state {
        case .notConnected:
            statusLabel.text = "Not connected"
        case .connecting:
            statusLabel.text = "Connecting"
        case .discoveringServices:
            statusLabel.text = "Discover services"
        case .handshake:
            statusLabel.text = "Handshake"
        case .connected:
            statusLabel.text = "Connected"
            outputTextView.text.append("Firmware version: ")
            outputTextView.text.append(
                (commandManager?.firmwareVersion.description)!)
            outputTextView.text.append("\n")
            let level = (commandManager?.beltBatteryStatus.batteryLevel)!
            outputTextView.text.append("Battery level: \(level)%\n");
        case .scanning:
            statusLabel.text = "Scanning"
        }
    }
    
    // Pops an info dialog
    func infoMessage(_ message: String) {
        let alert = UIAlertController(title: "Info", message: message,
                                      preferredStyle:
            UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Click on search and connect button
    @IBAction func searchBeltButtonClick(_ sender: UIButton) {
        
        // Check state
        if (connectionManager.state != .notConnected) {
            infoMessage("The belt is already connected or connecting.")
            return
        }
        
        // Clear output text
        outputTextView.text = "Search belt...\n"
        
        // Search for connected belt
        // Note: This is not yet managed
        let connected = connectionManager.retrieveConnectedBelt()
        if (connected.count == 0) {
            outputTextView.text.append("No connected belt.\n")
        } else {
            outputTextView.text.append("\(connected.count) connected belt.\n")
            // Continue with connection
            connectionManager.connectBelt(connected[0])
            return
        }
        
        // Search for known belt
        // Note: This is not yet managed
        
        if let known = connectionManager.retrieveLastConnectedBelt() {
            outputTextView.text.append("Known belt retrieved.\n")
            // Connect to the last connected device
            connectionManager.connectBelt(known)
            return
        } else {
            outputTextView.text.append("No known belt.\n")
        }
        
        // Scan for belt
        outputTextView.text.append("Start scan...\n")
        connectionManager.scanForBelt()
    }
    
    // Click on disconnect button
    @IBAction func disconnectButtonClick(_ sender: UIButton) {
        if (connectionManager.state == .notConnected) {
            return
        }
        outputTextView.text.append("Disconnect.\n")
        connectionManager.disconnectBelt()
    }
    
    // Switch to app mode
    @IBAction func switchToAppModeButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Switch to App mode.\n")
        let ret = commandManager?.changeBeltMode(.app)
        if ret == nil || !ret! {
            infoMessage("The mode cannot be changed in the current state.")
        }
    }
    
    // Switch to wait mode
    @IBAction func switchToWaitModeButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Switch to Wait mode.\n")
        let ret = commandManager?.changeBeltMode(.wait)
        if ret == nil || !ret! {
            infoMessage("The mode cannot be changed in the current state.")
        }
    }
    
    // Click on button for warning signal
    @IBAction func startWarningSignalButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Start warning signal.\n")
        let ret = commandManager?.signal(signalType: .warning)
        if ret == nil || !ret! {
            infoMessage("The signal cannot be sent in the current state.")
        }
    }
    
    // Click on button to start batterz signal
    @IBAction func startBatterySignal(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Start battery signal.\n")
        let ret = commandManager?.signal(signalType: .battery)
        if ret == nil || !ret! {
            infoMessage("The signal cannot be sent in the current state.")
        }
    }
    
    // Augment intensity
    @IBAction func augmentIntensityButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Change intensity.\n")
        if let intensity = commandManager?.defaultIntensity {
            let ret = commandManager?.changeDefaultIntensity(
                (intensity>95) ? 100 : (intensity+5))
            if ret == nil || !ret! {
                infoMessage("The intensity cannot be changed in the current state.")
            }
        }
    }
    
    // Reduce intensity
    @IBAction func reduceIntensityButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Change intensity.\n")
        if let intensity = commandManager?.defaultIntensity {
            let ret = commandManager?.changeDefaultIntensity(
                (intensity<5) ? 0 : (intensity-5))
            if ret == nil || !ret! {
                infoMessage("The intensity cannot be changed in the current state.")
            }
        }
    }
    
    // Start a vibration with +90° for every call
    @IBAction func startVibrationButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Set vibration.\n")
        orientation = (orientation+90)%360
        let ret = commandManager?.vibrateAtMagneticBearing(
            direction: Float(orientation))
        if ret == nil || !ret! {
            infoMessage("The vibration cannot be started in the current state.")
        }
    }
    
    // Stop the vibration on all channels
    @IBAction func stopVibrationButtonClick(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Stop vibration.\n")
        let ret = commandManager?.stopVibration()
        if ret == nil || !ret! {
            infoMessage("Failed to send stop command.")
        }
    }
    
    // Start a custom vibration: 5 pulses on left
    @IBAction func customVibration01(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Start custom vibration.\n")
        let ret = commandManager?.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.singleLong,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.angle,
            orientation: 270,
            patternIterations: 5,
            patternPeriod: 1000,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true)
        if ret == nil || !ret! {
            infoMessage("Failed to send vibration-channel configuration.")
        }
    }
    
    // Start a custom vibration: 3 seconds continuous on East
    @IBAction func customVibration02(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Start custom vibration.\n")
        let ret = commandManager?.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.continuous,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.magneticBearing,
            orientation: 90,
            patternIterations: 1,
            patternPeriod: 3000,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true)
        if ret == nil || !ret! {
            infoMessage("Failed to send vibration-channel configuration.")
        }
    }
    
    // Start a custom vibration: Continuous pulse on front and back
    @IBAction func customVibration03(_ sender: UIButton) {
        if (connectionManager.state != .connected) {
            return
        }
        outputTextView.text.append("Start custom vibration.\n")
        let ret = commandManager?.configureVibrationChannel(
            channelIndex: 0,
            pattern: FSVibrationPattern.singleShort,
            intensity: -1, // Default intensity
            orientationType: FSOrientationType.binaryMask,
            orientation: 0b0000000100000001,
            patternIterations: -1,
            patternPeriod: 750,
            patternStartTime: 0,
            exclusiveChannel: false,
            clearOtherChannels: true)
        if ret == nil || !ret! {
            infoMessage("Failed to send vibration-channel configuration.")
        }
    }
    
    // *** FSConnectionDelegate ***
    
    func onBeltFound(device: CBPeripheral) {
        outputTextView.text.append("Belt found.\n")
        // Stop scan
        connectionManager.stopScan()
        // Connect the belt
        outputTextView.text.append("Connect to belt.\n")
        connectionManager.connectBelt(device)
    }
    
    func onBeltScanFinished(cause: FSScanTerminationCause) {
        switch cause {
        case .timeout:
            outputTextView.text.append("Scan timeout.\n")
        case .canceled:
            outputTextView.text.append("Scan stopped.\n")
        case .alreadyConnected:
            outputTextView.text.append(
                "Scan canceled (already connected or connecting).\n")
        case .btNotActive:
            outputTextView.text.append(
                "Scan canceled (Bluetooth not active).\n")
        case .btNotAvailable:
            outputTextView.text.append(
                "Scan canceled (Bluetooth not available).\n")
        }
    }
    
    func onConnectionStateChanged(previousState: FSConnectionState,
                                 newState: FSConnectionState,
                                 event: FSConnectionEvent) {
        updateStatusLabel()
    }
    
    // *** FSCommandDelegate ***
    
    func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
        outputTextView.text.append("Belt mode changed to ")
        switch newBeltMode {
        case .app:
            outputTextView.text.append("'App'.\n")
        case .calibration:
            outputTextView.text.append("'Calibration'.\n")
        case .compass:
            outputTextView.text.append("'Compass'.\n")
        case .crossing:
            outputTextView.text.append("'Crossing'.\n")
        case .pause:
            outputTextView.text.append("'Pause'.\n")
        case .standby:
            outputTextView.text.append("'Standby'.\n")
        case .unknown:
            outputTextView.text.append("'Unknown'.\n")
        case .wait:
            outputTextView.text.append("'Wait'.\n")
        }
    }
    
    func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        outputTextView.text.append(
            "New default intensity: \(defaultIntensity).\n")
    }
    
    func onBeltButtonPressed(button: FSBeltButton,
                             pressType: FSPressType,
                             previousMode: FSBeltMode,
                             newMode: FSBeltMode) {
        outputTextView.text.append("Button press: ")
        switch button {
        case .compass:
            outputTextView.text.append("'compass'")
        case .home:
            outputTextView.text.append("'home'")
        case .pause:
            outputTextView.text.append("'pause'")
        case .power:
            outputTextView.text.append("'power'")
        }
        switch pressType {
        case .shortPress:
            outputTextView.text.append(" short press, mode: ")
        case .longPress:
            outputTextView.text.append(" long press, mode: ")
        }
        switch newMode {
        case .app:
            outputTextView.text.append("'App'.\n")
        case .calibration:
            outputTextView.text.append("'Calibration'.\n")
        case .compass:
            outputTextView.text.append("'Compass'.\n")
        case .crossing:
            outputTextView.text.append("'Crossing'.\n")
        case .pause:
            outputTextView.text.append("'Pause'.\n")
        case .standby:
            outputTextView.text.append("'Standby'.\n")
        case .unknown:
            outputTextView.text.append("'Unknown'.\n")
        case .wait:
            outputTextView.text.append("'Wait'.\n")
        }
    }
    
    public func onBeltBatteryStatusUpdated(status: FSBatteryStatus) {
        outputTextView.text.append("New battery status: ")
        switch status.powerStatus {
        case .unknown:
            outputTextView.text.append("Unknown power supply.\n")
        case .charging:
            outputTextView.text.append("Charging, \(status.batteryLevel)%.\n")
        case .onBattery:
            outputTextView.text.append("On battery, \(status.batteryLevel)%.\n")
        case .external:
            outputTextView.text.append("External power supply (no charge).\n")
        }
    }
    
    public func onBeltOrientationNotified(beltOrientation: FSBeltOrientation) {
        // No orientation notification in this demo
    }
}

