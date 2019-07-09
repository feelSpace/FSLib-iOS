//
//  FSNavigationSignalController.swift
//  FSLibIOs
//
//  Created by David on 11/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A belt controller for navigation-oriented app.
 */
@objc public class FSNavigationSignalController: NSObject, FSConnectionDelegate,
        FSCommandDelegate {
    
    //MARK: Private properties
    
    /** Connection manager */
    var connectionManager: FSConnectionManager
    
    /** Command manager. */
    var commandManager: FSCommandManager
    
    /** Minimum period for orientation notifications. */
    static let ORIENTATION_NOTIF_MIN_PERIOD: Double = 2.0
    
    /** Minimum heading variation for orientation notifications. */
    static let ORIENTATION_NOTIF_MIN_HEADING_VARIATION: Int = 11
    
    //MARK: Public properties
    
    /**
     The state of the scan/connection with the belt.
     */
    @objc public private(set) var connectionState: FSScanConnectionState =
        .notConnected;
    
    /**
     The mode of the belt.
     */
    @objc public private(set) var beltMode: FSBeltSignalMode = .unknown
    
    /**
     The active navigation direction to be signaled by the belt in navigation 
     mode.
     */
    @objc public private(set) var activeNavigationDirection: NSNumber?
    
    /**
     The type of signal to be used for indicating the navigation direction.
     */
    @objc public private(set) var activeNavigationSignalType: FSNavigationSignalType =
        .navigating
    
    /**
     Last known value of the belt magnetic heading.
     
     This property is updated only if orientation notifications are enabled.
     */
    @objc public var beltMagHeading: NSNumber? {
        if let heading = commandManager.beltOrientation?.beltMagHeading {
            return NSNumber(value: heading)
        } else {
            return nil
        }
    }
    
    /**
     Last known value of the inaccurate-compass flag of the belt.
     
     This property is updated only if orientation notifications are enabled.
     */
    @objc public var beltCompassInaccurate: NSNumber? {
        if let inaccurate = commandManager.beltOrientation?.beltCompassInaccurate {
            return NSNumber(value: inaccurate)
        } else {
            return nil
        }
    }
    
    /**
     Heading offset of the belt in degrees.
     
     This value, stored in the belt, represents the angle difference between the
     heading of the belt and the heading of the belt's control box. The default
     value on the belt is 45°.
     */
    @objc public var beltHeadingOffset: NSNumber? {
        if let headingOffset = commandManager.beltHeadingOffset {
            return NSNumber(value: headingOffset)
        } else {
            return nil
        }
    }
    
    /**
     Delegate that receives callbacks from the navigation signal controller.
     */
    @objc public var delegate: FSNavigationSignalDelegate?
    
    
    //MARK: Private methods
    
    /** Sets the connection state and inform the delegate. */
    internal func setScanConnectionState(_ state: FSScanConnectionState) {
        let previousState = connectionState
        connectionState = state
        if let d = delegate {
            d.onScanConnectionStateChanged(previousState: previousState,
                                           newState: connectionState)
        }
    }
    
    /** Checks the name of a device to know if it is a belt. */
    internal func isBelt(_ device: CBPeripheral) -> Bool {
        if let name = device.name {
            return name.lowercased().contains(
                FSConnectionManager.BELT_NAME_PREFIX.lowercased())
        }
        return false
    }
    
    /** Sets the belt mode and inform the delegate. */
    internal func setBeltMode(_ mode: FSBeltSignalMode, buttonPressed: Bool,
                              notifyDelegate: Bool) {
        if (mode == beltMode) {
            return
        }
        beltMode = mode
        if (connectionState == .connected && notifyDelegate) {
            if let d = delegate {
                d.onBeltSignalModeChanged(beltMode: mode,
                                          buttonPressed: buttonPressed)
            }
        }
    }
    
    /** Sends the navigation command using the active direction and signal 
     type (if in app mode). */
    internal func sendNavigationCommand() {
        if (connectionManager.state != .connected) {
            return
        }
        if (commandManager.mode == .app) {
            if let direction = activeNavigationDirection {
                switch activeNavigationSignalType {
                case .navigating:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        pattern: .navigation)) {
                        print("Fail to send navigation command.")
                    }
                case .approachingDestination:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        pattern: .approachingDestination)) {
                        print("Fail to send navigation command.")
                    }
                case .destinationReached:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        pattern: .destinationReached)) {
                        print("Fail to send navigation command.")
                    }
                }
            } else {
                if (!commandManager.stopVibration()) {
                    print("Fail to send navigation command.")
                }
            }
        }
    }
    
    //MARK: Public methods
    
    public override init() {
        connectionManager = FSConnectionManager.instance
        commandManager = connectionManager.commandManager
        super.init()
        // Register as delegate
        connectionManager.delegate = self
        commandManager.delegate = self
    }
    
    /**
     Searches for a nearby belt and connects to it.
     
     Calling this method cancels any scan or connection before starting the
     scan procedure.
     The delegate is informed of the scan and connection progress via 
     `onScanConnectionStateChanged`.
     */
    @objc public func searchAndConnectBelt() {
        
        // Cancel any scan/connection
        if (connectionState != .notConnected) {
            setScanConnectionState(.notConnected)
        }
        disconnectBelt()
    
        // Look for connected belt
        let connected = connectionManager.retrieveConnectedBelt()
        if (connected.count > 0) {
            // Start connection
            setScanConnectionState(.connecting)
            connectionManager.connectBelt(connected[0])
            return
        }
        
        // Start scan
        setScanConnectionState(.scanning)
        connectionManager.scanForBelt()
    }
    
    /**
     Disconnects or stop the scan/connection procedure.
     
     The delegate is informed of the scan disconnection via
     `onScanConnectionStateChanged`.
     */
    @objc public func disconnectBelt() {
        // Stop scan/connection
        connectionManager.stopScan()
        connectionManager.disconnectBelt()
        // Set state and inform delegate
        if (connectionState != .notConnected) {
            let previousState = connectionState
            connectionState = .notConnected
            if let d = delegate {
                d.onScanConnectionStateChanged(previousState: previousState,
                                               newState: .notConnected)
            }
        }
    }
    
    /**
     Starts or resumes the navigation.
     
     If a navigation direction has been set, the navigation signal is 
     automatically started. In case the navigation direction is `nil`, the belt 
     is set in navigation mode with no vibration signal.
     The delagate is informed of the mode change via the method
     `onBeltSignalModeChange`.
     */
    @objc public func startNavigation() {
        if (connectionState != .connected) {
            // Ignore when not connected
            return
        }
        if (commandManager.mode == .app) {
            // Re-send navigation signal
            sendNavigationCommand()
        } else {
            if (!commandManager.changeBeltMode(.app)) {
                print("Fail to change belt mode.")
            }
        }
    }
    
    /**
     Stops the navigation and clears the navigation direction.
     
     If the belt is in navigation or pause mode, the belt will switch to the 
     `wait` mode.
     The delagate is informed of the mode change via the method
     `onBeltSignalModeChange`.
     */
    @objc public func stopNavigation() {
        if (connectionState != .connected) {
            // Ignore when not connected
            return
        }
        // Clear navigation direction
        activeNavigationDirection = nil
        activeNavigationSignalType = .navigating
        // Switch to wait mode
        if (commandManager.mode == .app || commandManager.mode == .pause) {
            if (!commandManager.changeBeltMode(.wait)) {
                print("Fail to change belt mode.")
            }
        }
    }
    
    /**
     Pauses the navigation.
     
     If the belt is in navigation, the belt sill switch to the `pause` mode.
     The delagate is informed of the mode change via the method
     `onBeltSignalModeChange`.
     */
    @objc public func pauseNavigation() {
        if (connectionState != .connected) {
            // Ignore when not connected
            return
        }
        // Switch to pause mode if in app mode
        if (commandManager.mode == .app) {
            if(!commandManager.changeBeltMode(.pause)) {
                print("Fail to change belt mode.")
            }
        }
    }
    
    /**
     Sets the direction and type of signal to be used for the navigation.
     
     If the direction is `nil`, the belt will provide no navigation signal 
     in navigation mode.
     
     - Parameters:
        - direction: The direction to follow, or `nil` for no navigation signal.
        - signalType: The signal type for the navigation.
     */
    @objc public func setNavigationDirection(_ direction: NSNumber?,
            signalType: FSNavigationSignalType = .navigating) {
        activeNavigationDirection = direction
        activeNavigationSignalType = signalType
        sendNavigationCommand()
    }
    
    /**
     Starts a signal to notify that the destination has been reached, and stops
     the navigation if requested.
     
     - Parameters:
        - shouldStopNavigation: `true` to stop the navigation and return to wait
     mode after the destination-reached signal. If the belt is in compass mode,
     the mode is not changed.
     */
    @objc public func notifyDestinationReached(shouldStopNavigation: Bool) {
        if (shouldStopNavigation) {
            stopNavigation()
        }
        if (!commandManager.signal(signalType: .goalReached)) {
            print("Fail to notify destination reached.")
        }
    }
    
    /**
     Starts a warning vibration signal.
     
     The warning signal can be used in all modes except `pause`.
     */
    @objc public func notifyWarning() {
        if (!commandManager.signal(signalType: .warning)) {
            print("Fail to start warning signal.")
        }
    }
    
    /**
     Starts a signal to notify a direction.
     
     The direction notification can be used in all modes except `pause`.
     */
    @objc public func notifyDirection(_ direction: Float) {
        if (!commandManager.vibrateAtMagneticBearing(
            direction: direction, pattern: .directionNotification)) {
            print("Fail to notify direction.")
        }
    }
    
    /**
     Sends a request to the belt for changing the heading offset.
     
     The heading offset value will be changed asynchronously. The delegate
     receives a notification through `onHeadingOffsetChanged` when the new
     offset is effective. The belt may reject or adjust the offset value.
     
     A request is not sent if no belt is connected, or if the offset is not in
     range [0 - 359].
     
     - Parameters:
        - requestedHeadingOffset: The requested heading offset in degrees in
     range [0 - 359].
     */
    @objc public func changeHeadingOffset (_ requestedHeadingOffset: Int) {
        // Call command manager method
        if (!commandManager.changeHeadingOffset(requestedHeadingOffset)) {
            print("Fail to request new heading offset.")
        }
    }
    
    // MARK: Delegate methods
    
    /** Indicates that a belt has been found during the scan procedure. */
    final public func onBeltFound(device: CBPeripheral) {
        if (connectionState != .scanning) {
            // Ignore when not scanning
            connectionManager.stopScan()
            return
        }
        // Check device
        if (isBelt(device)) {
            // Connect to the belt
            setScanConnectionState(.connecting)
            connectionManager.connectBelt(device)
        }
    }
    
    /** Indicates that the search procedure for finding a belt is finished. */
    final public func onBeltScanFinished(cause: FSScanTerminationCause) {
        if (connectionState == .scanning) {
            // Failed to find a belt
            setScanConnectionState(.notConnected)
            disconnectBelt()
        }
    }
    
    /** Indicates that the connection state has changed. */
    final public func onConnectionStateChanged(previousState: FSConnectionState,
                                  newState: FSConnectionState,
                                  event: FSConnectionEvent) {
        // Update belt mode (without notification)
        switch commandManager.mode {
        case .unknown, .standby, .calibration:
            setBeltMode(.unknown, buttonPressed: false, notifyDelegate: false)
        case .wait:
            setBeltMode(.wait, buttonPressed: false, notifyDelegate: false)
        case .pause:
            setBeltMode(.pause, buttonPressed: false, notifyDelegate: false)
        case .compass:
            setBeltMode(.compass, buttonPressed: false, notifyDelegate: false)
        case .app:
            setBeltMode(.navigation, buttonPressed: false,
                        notifyDelegate: false)
        case .crossing:
            setBeltMode(.crossing, buttonPressed: false, notifyDelegate: false)
        }
        
        // Register to orientation notifications when connected
        if (newState == .connected) {
            if (!commandManager.startOrientationNotifications(
                minPeriod: FSNavigationSignalController.ORIENTATION_NOTIF_MIN_PERIOD,
                minHeadingVariation: FSNavigationSignalController.ORIENTATION_NOTIF_MIN_HEADING_VARIATION)) {
                print("Fail to register to orientation notifications.")
            }
        }
        
        // Update connection state with notification
        switch connectionState {
            
        case .notConnected, .scanning:
            if (newState != .notConnected) {
                disconnectBelt()
            }
            
        case .connecting:
            if (newState == .notConnected) {
                // Connection failed
                setScanConnectionState(.notConnected)
                disconnectBelt()
            } else if (newState == .connected) {
                // Connection successful
                setScanConnectionState(.connected)
            }
            
        case .connected:
            if (newState == .notConnected) {
                // Connection lost
                setScanConnectionState(.notConnected)
                disconnectBelt()
            } else if (newState != .connected) {
                // Re-connection
                setScanConnectionState(.connecting)
            }
            
        }
    }
    
    /** Informs that the mode of the belt has changed. */
    final public func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
        switch newBeltMode {
        case .unknown, .standby, .calibration:
            setBeltMode(.unknown, buttonPressed: false, notifyDelegate: true)
        case .wait:
            setBeltMode(.wait, buttonPressed: false, notifyDelegate: true)
        case .pause:
            setBeltMode(.pause, buttonPressed: false, notifyDelegate: true)
        case .compass:
            setBeltMode(.compass, buttonPressed: false, notifyDelegate: true)
        case .crossing:
            setBeltMode(.crossing, buttonPressed: false, notifyDelegate: true)
        case .app:
            // Send navigation command
            sendNavigationCommand()
            setBeltMode(.navigation, buttonPressed: false, notifyDelegate: true)
        }
    }
    
    /** Informs that the default vibration intensity has been changed. */
    final public func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        // Ignore vibration intensity notifications
    }
    
    /** Informs that the heading offset value has been changed on the belt. */
    final public func onHeadingOffsetChanged(_ headingOffset: Int) {
        // Transfer notification to navigation delegate
        delegate?.onHeadingOffsetChanged?(headingOffset)
    }
    
    /** Informs that a button on the belt has been pressed. */
    final public func onBeltButtonPressed(button: FSBeltButton,
                             pressType: FSPressType,
                             previousMode: FSBeltMode,
                             newMode: FSBeltMode) {
        switch newMode {
        case .unknown, .standby, .calibration:
            setBeltMode(.unknown, buttonPressed: true, notifyDelegate: true)
        case .wait:
            setBeltMode(.wait, buttonPressed: true, notifyDelegate: true)
            if (button == .home) {
                // Home navigation requested
                if let d = delegate {
                    d.onBeltRequestHome()
                }
            }
        case .pause:
            setBeltMode(.pause, buttonPressed: true, notifyDelegate: true)
            if (previousMode == .pause && button == .pause) {
                // Resume navigation on pause button press
                if (!commandManager.changeBeltMode(.app)) {
                    print("Fail to change belt mode.")
                }
            }
            if (button == .home) {
                // Home navigation requested
                if let d = delegate {
                    d.onBeltRequestHome()
                }
            }
        case .compass:
            setBeltMode(.compass, buttonPressed: true, notifyDelegate: true)
            if (button == .home) {
                // Home navigation requested
                if let d = delegate {
                    d.onBeltRequestHome()
                }
            }
        case .crossing:
            setBeltMode(.crossing, buttonPressed: true, notifyDelegate: true)
            if (button == .home) {
                // Home navigation requested
                if let d = delegate {
                    d.onBeltRequestHome()
                }
            }
        case .app:
            setBeltMode(.navigation, buttonPressed: true, notifyDelegate: true)
            if (previousMode == .app && button == .pause) {
                // Pause navigation on pause button press
                setBeltMode(.pause, buttonPressed: true, notifyDelegate: true)
                if (!commandManager.changeBeltMode(.pause)) {
                    print("Fail to change belt mode.")
                }
            }
            if (button == .home) {
                // Home navigation requested
                if let d = delegate {
                    d.onBeltRequestHome()
                }
            }
        }
    }
    
    /** Informs about an update of the battery status. */
    final public func onBeltBatteryStatusUpdated(_ status: FSBatteryStatus) {
        // Ignore belt battery status
    }
    
    /** Notifies that the belt orientation has been updated. */
    final public func onBeltOrientationNotified(
        beltOrientation: FSBeltOrientation) {
        // Transfer notification to navigation delegate
        delegate?.onBeltOrientationNotified?(
            beltMagHeading: beltOrientation.beltMagHeading,
            beltCompassInaccurate: beltOrientation.beltCompassInaccurate)
    }
    
}

/**
 States used for informing about the scan and connection progress and events.
 */
@objc public enum FSScanConnectionState: Int {
    /** No belt is connected. */
    case notConnected;
    /** The scan procedure has been started. */
    case scanning;
    /** A belt has been found and the connection procedure is running. */
    case connecting;
    /** The belt is connected and ready. */
    case connected;
}

/**
 Navigation state of the belt.
 */
@objc public enum FSBeltSignalMode: Int {
    /** The belt is not yet connected and the mode is unkown. */
    case unknown;
    /** The belt is waiting for starting the navigation. */
    case wait;
    /** The belt is in compass mode. */
    case compass;
    /** The belt is in crossing mode. */
    case crossing;
    /** The belt is in navigation mode. */
    case navigation;
    /** The belt is in pause mode. */
    case pause;
}

/**
 Types of signal for the navigation.
 */
@objc public enum FSNavigationSignalType: Int {
    /** The standard signal to be used when in navigation. */
    case navigating;
    /** The signal to be used when the final destination is in proximity. */
    case approachingDestination;
    /** Vibration signal to indicate continuously that the destination has been
     reached. */
    case destinationReached;
}
