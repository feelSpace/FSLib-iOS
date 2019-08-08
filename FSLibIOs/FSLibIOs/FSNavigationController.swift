//
//  FSNavigationSignalController.swift
//  FSLibIOs
//
//  Created by David on 11/09/17.
//  Copyright © 2017-2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A belt controller for navigation-oriented app.
 */
@objc public class FSNavigationController: NSObject, FSConnectionDelegate,
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
     Unique instance of `FSNavigationController` (singleton).
     */
    public static let instance: FSNavigationController = FSNavigationController()
    
    /**
     The state of the scan/connection with the belt.
     */
    @objc public var connectionState: FSConnectionState {
        return connectionManager.state
    }
    
    /**
     The mode of the belt.
     */
    @objc public var beltMode: FSBeltMode {
        return commandManager.mode
    }
    
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
     */
    @objc public var beltCompassInaccurate: NSNumber? {
        if let inaccurate = commandManager.beltOrientation?.beltCompassInaccurate {
            return NSNumber(value: inaccurate)
        } else {
            return nil
        }
    }
    
    /**
     Last known value of the belt battery level.
     */
    @objc public var beltBatteryLevel: Double {
        return commandManager.beltBatteryStatus.batteryLevel
    }
    
    /**
     Last known value of the belt power status.
     */
    @objc public var beltPowerStatus: FSPowerStatus {
        return commandManager.beltBatteryStatus.powerStatus
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
    @objc public var delegate: FSNavigationDelegate?
    
    
    //MARK: Private methods
    
    /** Checks the name of a device to know if it is a belt. */
    internal func isBelt(_ device: CBPeripheral) -> Bool {
        if let name = device.name {
            return name.lowercased().contains(
                FSConnectionManager.BELT_NAME_PREFIX.lowercased())
        }
        return false
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
                        signal: .navigation)) {
                        print("Fail to send navigation command.")
                    }
                case .approachingDestination:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        signal: .approachingDestination)) {
                        print("Fail to send navigation command.")
                    }
                case .destinationReached:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        signal: .destinationReachedRepeated)) {
                        print("Fail to send navigation command.")
                    }
                case .ongoingTurn:
                    if (!commandManager.vibrateAtMagneticBearing(
                        direction: direction.floatValue,
                        signal: .ongoingTurn)) {
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
    
    // Private initialization for singleton
    private override init() {
        connectionManager = FSConnectionManager.instance
        commandManager = connectionManager.commandManager
        super.init()
        // Register as delegate
        connectionManager.delegate = self
        commandManager.delegate = self
    }
    
    //MARK: Public methods
    
    /**
     Singleton accessor. Only for objective-c.
     */
    @objc class public func getInstance() -> FSNavigationController {
        return FSNavigationController.instance
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
        disconnectBelt()
    
        // Look for connected belt
        let connected = connectionManager.retrieveConnectedBelt()
        if (connected.count > 0) {
            // Start connection
            connectionManager.connectBelt(connected[0])
            return
        }
        
        // Start scan
        connectionManager.scanForBelt()
    }
    
    /**
     Disconnects or stop the scan/connection procedure.
     
     The delegate is informed when connection events are received.
     */
    @objc public func disconnectBelt() {
        // Stop scan/connection
        connectionManager.stopScan()
        connectionManager.disconnectBelt()
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
            direction: direction, signal: .directionNotification)) {
            print("Fail to notify direction.")
        }
    }
    
    /**
     Starts the vibration signal that indicates the belt battery level.
     */
    @objc public func notifyBeltBatteryLevel() {
        if (!commandManager.signal(signalType: .battery)) {
            print("Fail to start battery signal.")
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
        // Check device
        if (isBelt(device)) {
            // Connect to the belt
            connectionManager.connectBelt(device)
        }
    }
    
    public func onBeltScanFinished(cause: FSScanTerminationCause) {
        // TODO This will be removed
    }
    
    
    /** Indicates that the connection state has changed. */
    final public func onConnectionStateChanged(previousState: FSConnectionState,
                                  newState: FSConnectionState,
                                  event: FSConnectionEvent) {
        // Register to orientation notifications when connected
        if (newState == .connected) {
            if (!commandManager.startOrientationNotifications(
                minPeriod: FSNavigationController.ORIENTATION_NOTIF_MIN_PERIOD,
                minHeadingVariation: FSNavigationController.ORIENTATION_NOTIF_MIN_HEADING_VARIATION)) {
                print("Fail to register to orientation notifications.")
            }
        }
        // Inform delegate only for main connection events
        if let d = delegate {
            if (newState == .notConnected || newState == .connected ||
                previousState == .notConnected) {
                d.onConnectionStateChanged(previousState: previousState,
                                           newState: connectionState)
            }
        }
    }
    
    /** Informs that the mode of the belt has changed. */
    final public func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
        // Send vibration command when in app mode
        if (newBeltMode == .app) {
            sendNavigationCommand()
        }
        // Inform delegate
        if let d = delegate {
            d.onBeltModeChanged(beltMode: newBeltMode,
                                buttonPressed: false)
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
        // Check for pause/resume navigation
        if (button == .pause) {
            if (previousMode == .pause && newMode == .pause) {
                // Resume navigation
                if (!commandManager.changeBeltMode(.app)) {
                    print("Fail to change belt mode.")
                }
            } else if (previousMode == .app && newMode == .app) {
                // Pause navigation
                if (!commandManager.changeBeltMode(.pause)) {
                    print("Fail to change belt mode.")
                }
            }
        }
        // Inform delegate if mode changed
        if (newMode != previousMode) {
            delegate?.onBeltModeChanged(beltMode: newMode, buttonPressed: true)
        }
        // Check if Home request
        if (newMode == .wait || newMode == .app || newMode == .compass ||
            newMode == .crossing) {
            delegate?.onBeltRequestHome()
        }
    }
    
    /** Informs about an update of the battery status. */
    final public func onBeltBatteryStatusUpdated(_ status: FSBatteryStatus) {
        // Inform delegate
        delegate?.onBeltBatteryStatusNotified?(
            batteryLevel: status.batteryLevel, powerStatus: status.powerStatus)
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
    /** Repetitive vibration signal to indicate the direction at a crossing. */
    case ongoingTurn;
}
