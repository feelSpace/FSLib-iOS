//
//  ViewController.swift
//  FSLibIOsDemo
//
//  Created by David on 18.10.19.
//  Copyright © 2019 feelSpace GmbH. All rights reserved.
//

import UIKit
import FSLibIOs

class ViewController: UIViewController, FSNavigationControllerDelegate {
    
    // Navigation controller
    let beltController: FSNavigationController! = FSNavigationController()
    
    // Selected navigation signal
    var selectedSignalType: FSBeltVibrationSignal? = nil
    
    // References to UI components
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var defaultIntensityLabel: UILabel!
    @IBOutlet weak var defaultIntensitySlider: UISlider!
    @IBOutlet weak var beltHeadingLabel: UILabel!
    @IBOutlet weak var orientationAccurateLabel: UILabel!
    @IBOutlet weak var changeAccuracySignalButton: UIButton!
    @IBOutlet weak var powerStatusLabel: UILabel!
    @IBOutlet weak var batteryLevelLabel: UILabel!
    @IBOutlet weak var startBatterySignalButton: UIButton!
    @IBOutlet weak var navigationDirectionLabel: UILabel!
    @IBOutlet weak var navigationDirectionSlider: UISlider!
    @IBOutlet weak var magneticBearingSwitch: UISwitch!
    @IBOutlet weak var signalTypeButton: UIButton!
    @IBOutlet weak var startNavigationButton: UIButton!
    @IBOutlet weak var pauseNavigationButton: UIButton!
    @IBOutlet weak var stopNavigationButton: UIButton!
    @IBOutlet weak var navigationStateLabel: UILabel!
    @IBOutlet weak var notificationDirectionLabel: UILabel!
    @IBOutlet weak var notificationDirectionSlider: UISlider!
    @IBOutlet weak var startBearingNotificationButton: UIButton!
    @IBOutlet weak var startDirectionNotificationButton: UIButton!
    @IBOutlet weak var startWarningButton: UIButton!
    @IBOutlet weak var startCriticalWarningButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        beltController.delegate = self
        updateUI()
    }

    /** Updates the whole UI. */
    private func updateUI() {
        updateConnectionPanel()
        updateDefaultIntensityPanel()
        updateOrientationPanel()
        updateBatteryPanel()
        updateNavigationSignalTypePanel()
        updateNavigationStatePanel()
    }
    
    /** Updates the connection panel UI. */
    private func updateConnectionPanel() {
        switch beltController.connectionState {
        case .disconnected:
            connectButton.isEnabled = true
            disconnectButton.isEnabled = false
            connectionStateLabel.text = "Disconnected"
        case .scanning:
            connectButton.isEnabled = false
            disconnectButton.isEnabled =  true
            connectionStateLabel.text = "Scanning"
        case .connecting:
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
            connectionStateLabel.text = "Connecting"
        case .reconnecting:
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
            connectionStateLabel.text = "Reconnecting"
        case .discoveringServices:
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
            connectionStateLabel.text = "Discovering services"
        case .handshake:
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
            connectionStateLabel.text = "Handshake"
        case .connected:
            connectButton.isEnabled = false
            disconnectButton.isEnabled = true
            connectionStateLabel.text = "Connected"
        }
    }
    
    /** Updates the default intensity panel UI. */
    private func updateDefaultIntensityPanel() {
        let intensity: Int? = beltController.defaultVibrationIntensity
        if(intensity == nil) {
            defaultIntensityLabel.text = "-"
            defaultIntensitySlider.setValue(50, animated: false)
            defaultIntensitySlider.isEnabled = false
        } else {
            defaultIntensityLabel.text = String(format: "%d%%", intensity!)
            defaultIntensitySlider.value = Float(intensity!)
            defaultIntensitySlider.isEnabled = true
        }
    }
    
    /** Updates the battery panel UI. */
    private func updateBatteryPanel() {
        let status = beltController.beltPowerStatus
        let level = beltController.beltBatteryLevel
        if (status == nil) {
            powerStatusLabel.text = "-"
        } else {
            switch (status!) {
            case .unknown:
                powerStatusLabel.text = "Unknown"
            case .onBattery:
                powerStatusLabel.text = "On battery"
            case .charging:
                powerStatusLabel.text = "Charging"
            case .externalPower:
                powerStatusLabel.text = "External power supply"
            }
        }
        if (level == nil) {
            batteryLevelLabel.text = "-"
        } else {
            batteryLevelLabel.text = String(format: "%d%%", level!)
        }
    }
    
    /** Updates the orientation panel UI. */
    private func updateOrientationPanel() {
        let heading = beltController.beltHeading
        let accurate = beltController.beltOrientationAccurate
        let accuracySignalState = beltController.compassAccuracySignalEnabled
        if (heading == nil) {
            beltHeadingLabel.text = "-"
        } else {
            beltHeadingLabel.text = String(format: "%d°", heading!)
        }
        if (accurate == nil) {
            orientationAccurateLabel.text = "-"
        } else {
            if (accurate!) {
                orientationAccurateLabel.text = "Yes"
            } else {
                orientationAccurateLabel.text = "No"
            }
        }
        if (accuracySignalState == nil) {
            changeAccuracySignalButton.isEnabled = false
            changeAccuracySignalButton.setTitle("Unknown accuracy signal state", for: .normal)
        } else if (accuracySignalState!) {
            changeAccuracySignalButton.isEnabled = true
            changeAccuracySignalButton.setTitle("Disable accuracy signal", for: .normal)
        } else {
            changeAccuracySignalButton.isEnabled = true
            changeAccuracySignalButton.setTitle("Enable accuracy signal", for: .normal)
        }
    }
    
    /** Sets the signal for the navigation. */
    private func setSignalType(_ selected: FSBeltVibrationSignal?) {
        selectedSignalType = selected
        updateNavigationSignalTypePanel()
        _=beltController.updateNavigationSignal(
            direction: Int(navigationDirectionSlider.value),
            isMagneticBearing: magneticBearingSwitch.isOn,
            signal: selectedSignalType)
    }
    
    /** Updates the signal type button label. */
    private func updateNavigationSignalTypePanel() {
        if (selectedSignalType == nil) {
            signalTypeButton.setTitle("No vibration", for: .normal)
        } else {
            switch (selectedSignalType!) {
            case .continuous:
                signalTypeButton.setTitle("Continuous", for: .normal)
            case .navigation:
                signalTypeButton.setTitle("Navigation signal", for: .normal)
            case .approachingDestination:
                signalTypeButton.setTitle("Approaching destination",
                                          for: .normal)
            case .turnOngoing:
                signalTypeButton.setTitle("Ongoing turn", for: .normal)
            case .nextWaypointLongDistance:
                signalTypeButton.setTitle("Next waypoint at long distance",
                                          for: .normal)
            case .nextWaypointMediumDistance:
                signalTypeButton.setTitle("Next waypoint at medium distance",
                                          for: .normal)
            case .nextWaypointShortDistance:
                signalTypeButton.setTitle("Next waypoint at short distance",
                                          for: .normal)
            case .nextWaypointAreaReached:
                signalTypeButton.setTitle("Waypoint area reached", for: .normal)
            case .destinationReachedRepeated:
                signalTypeButton.setTitle("Destination reached", for: .normal)
            case .directionNotification, .destinationReachedSingle,
                 .operationWarning, .criticalWarning, .batteryLevel:
                // Should not happen
                signalTypeButton.setTitle("Illegal signal type", for: .normal)
            }
        }
    }
    
    /** Updates the navigation state panel UI. */
    private func updateNavigationStatePanel() {
        switch beltController.navigationState {
        case .stopped:
            navigationStateLabel.text = "Stopped"
        case .paused:
            navigationStateLabel.text = "Paused"
        case .navigating:
            navigationStateLabel.text = "Navigating"
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
    
    //MARK: Implementation of navigation controller delegate methods
    
    func onNavigationStateChange(state: FSNavigationState) {
        updateUI()
    }
    
    func onBeltHomeButtonPressed(navigating: Bool) {
        showToast(message: "Home button pressed!")
    }
    
    func onBeltDefaultVibrationIntensityChanged(intensity: Int) {
        updateDefaultIntensityPanel()
    }
    
    func onBeltOrientationUpdated(beltHeading: Int, accurate: Bool) {
        updateOrientationPanel()
    }
    
    func onBeltBatteryLevelUpdated(batteryLevel: Int, status: FSPowerStatus) {
        updateBatteryPanel()
    }
    
    func onCompassAccuracySignalStateUpdated(enabled: Bool) {
        updateOrientationPanel()
    }
    
    func onBeltConnectionStateChanged(state: FSBeltConnectionState) {
        updateUI()
    }
    
    func onBluetoothNotAvailable() {
        showToast(message: "No Bluetooth available!")
    }
    
    func onBluetoothPoweredOff() {
        showToast(message: "Please turn on Bluetooth!")
    }
    
    func onBeltConnectionLost() {
        showToast(message: "Connection lost!")
    }
    
    func onBeltConnectionFailed() {
        showToast(message: "Connection failed!")
    }
    
    func onNoBeltFound() {
        showToast(message: "No belt found!")
    }
    
    //MARK: UI event handlers
    
    @IBAction func onConnectButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .disconnected) {
            beltController.searchAndConnectBelt()
        }
    }
    
    @IBAction func onDisconnectButtonTap(_ sender: UIButton) {
        if (beltController.connectionState != .disconnected) {
            beltController.disconnectBelt()
        }
    }
    
    @IBAction func onDefaultIntensitySliderValueChanged(_ sender: UISlider) {
        // Update label
        let intensity = Int(defaultIntensitySlider.value)
        defaultIntensityLabel.text = String(format: "%d%%", intensity)
    }
    
    @IBAction func onDefaultIntensitySliderReleased(_ sender: UISlider) {
        if (beltController.connectionState == .connected) {
            let intensity = Int(defaultIntensitySlider.value)
            _=beltController.changeDefaultVibrationIntensity(
                intensity: intensity)
        }
    }
    
    @IBAction func onDefaultIntensitySliderReleasedOutside(_ sender: UISlider) {
        onDefaultIntensitySliderReleased(sender)
    }
    
    @IBAction func onChangeAccuracySignalButtonTap(_ sender: UIButton) {
        let accuracySignalState = beltController.compassAccuracySignalEnabled
        if (accuracySignalState == nil) {
            // Do nothing, state is unknwon
        } else if (accuracySignalState!) {
            // Disable signal dialog
            let alert = UIAlertController(
                title: "Disable accuracy signal",
                message: "Do you want to disable the accuracy signal of the belt?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                title: "Disable temporarily",
                style: .default,
                handler: {action in
                    _=self.beltController.setCompassAccuracySignal(
                        enable: false, persistent: false)}))
            alert.addAction(UIAlertAction(
                title: "Disable and save",
                style: .default,
                handler: {action in
                    _=self.beltController.setCompassAccuracySignal(
                        enable: false, persistent: true)}))
            alert.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil))
            self.present(alert, animated: true)
        } else {
            // Enable signal dialog
            let alert = UIAlertController(
                title: "Enable accuracy signal",
                message: "Do you want to enable the accuracy signal of the belt?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                title: "Enable temporarily",
                style: .default,
                handler: {action in
                    _=self.beltController.setCompassAccuracySignal(
                        enable: false, persistent: false)}))
            alert.addAction(UIAlertAction(
                title: "Enable and save",
                style: .default,
                handler: {action in
                    _=self.beltController.setCompassAccuracySignal(
                        enable: false, persistent: true)}))
            alert.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func onStartBatterySignalButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .connected) {
            _=beltController.notifyBeltBatteryLevel()
        }
    }
    
    @IBAction func onNavigationDirectionSliderValueChanged(_ sender: UISlider) {
        // Update direction label
        let direction = Int(navigationDirectionSlider.value)
        navigationDirectionLabel.text = String(format: "%d°", direction)
        // Update signal
        _=beltController.updateNavigationSignal(
            direction: direction,
            isMagneticBearing: magneticBearingSwitch.isOn,
            signal: selectedSignalType)
    }
    
    @IBAction func onMagneticBearingSwitchValueChanged(_ sender: UISwitch) {
        // Update signal
        _=beltController.updateNavigationSignal(
            direction: Int(navigationDirectionSlider.value),
            isMagneticBearing: magneticBearingSwitch.isOn,
            signal: selectedSignalType)
    }
    
    @IBAction func onSignalTypeButtonTap(_ sender: UIButton) {
        // Shows signal type dialog
        let alert = UIAlertController(
            title: "Navigation signal",
            message: "Select the signal to use for the navigation.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: "No vibration",
            style: .default,
            handler: {action in
                self.setSignalType(nil)}))
        alert.addAction(UIAlertAction(
            title: "Navigation signal",
            style: .default,
            handler: {action in
                self.setSignalType(.navigation)}))
        alert.addAction(UIAlertAction(
            title: "Approaching destination",
            style: .default,
            handler: {action in
                self.setSignalType(.approachingDestination)}))
        alert.addAction(UIAlertAction(
            title: "Ongoing turn",
            style: .default,
            handler: {action in
                self.setSignalType(.turnOngoing)}))
        alert.addAction(UIAlertAction(
            title: "Next waypoint at long distance",
            style: .default,
            handler: {action in
                self.setSignalType(.nextWaypointLongDistance)}))
        alert.addAction(UIAlertAction(
            title: "Next waypoint at medium distance",
            style: .default,
            handler: {action in
                self.setSignalType(.nextWaypointMediumDistance)}))
        alert.addAction(UIAlertAction(
            title: "Next waypoint at short distance",
            style: .default,
            handler: {action in
                self.setSignalType(.nextWaypointShortDistance)}))
        alert.addAction(UIAlertAction(
            title: "Waypoint area reached",
            style: .default,
            handler: {action in
                self.setSignalType(.nextWaypointAreaReached)}))
        alert.addAction(UIAlertAction(
            title: "Destination reached",
            style: .default,
            handler: {action in
                self.setSignalType(.destinationReachedRepeated)}))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func onStartNavigationButtonTap(_ sender: UIButton) {
        _=beltController.startNavigation(
            direction: Int(navigationDirectionSlider.value),
            isMagneticBearing: magneticBearingSwitch.isOn,
            signal: selectedSignalType)
    }
    
    @IBAction func onPauseNavigationButtonTap(_ sender: UIButton) {
        beltController.pauseNavigation()
    }
    
    @IBAction func onStopNavigationButtonTap(_ sender: UIButton) {
        beltController.stopNavigation()
    }
    
    @IBAction func onNotificationDirectionSliderValueChanged(_ sender: UISlider) {
        // Update direction label
        let direction = Int(notificationDirectionSlider.value)
        notificationDirectionLabel.text = String(format: "%d°", direction)
    }
    
    @IBAction func onStartBearingNotificationButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .connected) {
            let direction = Int(notificationDirectionSlider.value)
            _=beltController.notifyDirection(
                direction: direction, isMagneticBearing: true)
        }
    }
    
    @IBAction func onStartDirectionNotificationButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .connected) {
            let direction = Int(notificationDirectionSlider.value)
            _=beltController.notifyDirection(
                direction: direction, isMagneticBearing: false)
        }
    }
    
    @IBAction func onStartWarningButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .connected) {
            _=beltController.notifyWarning(critical: false)
        }
    }
    
    @IBAction func onStartCriticalWarningButtonTap(_ sender: UIButton) {
        if (beltController.connectionState == .connected) {
            _=beltController.notifyWarning(critical: true)
        }
    }
    
    
}

