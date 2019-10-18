//
//  NavigationController.swift
//  FSLibIOs
//
//  Created by David on 10.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 The navigation controller is an interface to connect and control a feelSpace
 NaviBelt.
 
 The navigation controller is a simplified interface designed for navigation
 applications.
 */
@objc public class NavigationController: NSObject, FSConnectionDelegate,
        FSCommandDelegate {
    
    /** Belt connection */
    private var beltConnection: FSConnectionManager
    
    /** Belt command interface */
    private var beltController: FSCommandManager
    
    /** Flag indicating if a delayed vibration command has been scheduled */
    private var isVibrationCommandScheduled: Bool = false
    
    /** Time of the last vibration command sent */
    private var lastVibrationCommandTime: Date?
    
    /** Scheduled vibration command */
    private var vibrationCommandTask: Timer?
    
    /** Minimum period between two vibration commands in seconds */
    private static let MINIMUM_VIBRATION_COMMAND_UPDATE_PERIOD_SEC = 0.1
    
    /** Vibration signal to use when in navigation */
    private var navigationSignal: BeltVibrationSignal?
    
    /** Direction of the vibration when in navigation */
    private var navigationDirection: Int = 0
    
    /**
     Indicates if the direction of the vibration is relative to magnetic North
     */
    private var isMagneticBearingDirection: Bool = true
    
    /**
     State of the navigation controller.
     
     The state of the navigation controller is independant of the
     connection state, i.e. the state can be `.navigating` even when no belt is
     connected. However, if a belt is connected, the state of the navigation
     controller is synchronized with the belt mode, i.e. the state `.navigating`
     correspond to the `.app` mode.
     */
    public private(set) var navigationState: NavigationState = .stopped
    
    /**
     Connection state with the belt.
     */
    public var connectionState: BeltConnectionState {
        get {
            switch beltConnection.state {
            case .notConnected:
                return .disconnected
            case .scanning:
                return .scanning
            case .connecting:
                return .connecting
            case .discoveringServices:
                return .discoveringServices
            case .handshake:
                return .handshake
            case .connected:
                return .connected
            }
        }
    }
    
    /**
     Default vibration intensity of the connected belt in range [5-100].
     
     This property is `nil` when no belt is connected.
     */
    public var defaultVibrationIntensity: Int? {
        get {
            let intensity = beltController.defaultIntensity
            if (intensity < 0) {
                return nil
            } else {
                return intensity
            }
        }
    }
    
    /**
     Last known orientation of the belt in degrees relative to magnetic North.
     
     Positives angles are clockwise. This property is `nil` when no belt is
     connected and until the first orientation notification is received from
     the belt.
     */
    public var beltHeading: Int? {
        get {
            return beltController.beltOrientation?.beltMagHeading
        }
    }
    
    /**
     Flag indicating if the orientation of the belt is accurate.
     
     This property is `nil` when no belt is connected and until the first
     orientation notification is received from the belt.
     */
    public var beltOrientationAccurate: Bool? {
        get {
            return beltController.beltOrientation?.beltCompassInaccurate
        }
    }
    
    /**
     Battery level of the belt in percent.
     
     This property is `nil` when no belt is connected and until the first
     battery notification is received from the belt.
     */
    public var beltBatteryLevel: Int? {
        get {
            let level = beltController.beltBatteryStatus.batteryLevel
            if (level < 0) {
                return nil
            } else {
                return Int(level)
            }
        }
    }
    
    /**
     Power status of the belt.
     
     This property is `nil` when no belt is connected and until the first
     battery notification is received from the belt.
     */
    public var beltPowerStatus: PowerStatus? {
        get {
            switch beltController.beltBatteryStatus.powerStatus {
            case .onBattery:
                return .onBattery
            case .charging:
                return .charging
            case .external:
                return .externalPower
            default:
                return nil
            }
        }
    }
    
    /**
     Indicates if the pause mode of the belt corresponds to the navigation
     controller being paused.
     
     Note that the pause mode of the belt can correspond to different paused
     modes, i.e. the compass the wait mode and the app mode can all be paused,
     resulting in the same pause mode.
     */
    private var isPauseModeForNavigation: Bool = false
    
    /**
     State of the compass accuracy signal.
     
     If `true` the compass signal accuracy is enabled, if `false` it is
     disabled. This attribute is `nil` when the state of the compass accuracy
     signal is unknown or no belt is connected. Note that the value of this
     attribute is unknown for a short period after a connection to a belt is
     established.
     */
    public private(set) var compassAccuracySignalEnabled: Bool?
    
    /**
     Delegate of the navigation controller.
     
     A delegate must be defined to handle events of the navigation controller.
     */
    public var delegate: NavigationControllerDelegate?
    
    /** Channel index used for the navigation signal */
    public static let NAVIGATION_SIGNAL_CHANNEL: Int = 2
    
    //MARK: Public methods
    
    /**
     Constructor.
     */
    public override init() {
        beltConnection = FSConnectionManager.instance
        beltController = beltConnection.commandManager
        super.init()
        beltConnection.delegate = self
        beltController.delegate = self
    }
    
    /**
     Searches and connects a belt.
     */
    public func searchAndConnectBelt() {
        disconnectBelt()
        // Look for belt connected to other application
        let connected = beltConnection.retrieveConnectedBelt()
        if (connected.count > 0) {
            // Start connection
            beltConnection.connectBelt(connected[0])
        } else {
            // Start scan
            beltConnection.scanForBelt()
        }
    }
    
    /**
     Connects a belt.
     
     - Parameters:
        - device: The belt to connect to.
     */
    public func connectBelt(_ device: CBPeripheral) {
        disconnectBelt()
        beltConnection.connectBelt(device)
    }
    
    /**
     Disconnects the belt or stops the scan and connection procedure.
     */
    public func disconnectBelt() {
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
    }
    
    /**
     Starts or resumes the navigation.
     
     The navigation can be started event when no belt is connected. If the
     navigation is active when a belt is connected, the mode of the belt will
     be automatically changed to app mode with the navigation signal.
     
     - Parameters:
        - direction: The direction of the vibration in degrees. The value 0
     represents the magnetic North or heading of the belt, and angles are
     clockwise.
        - isMagneticBearing: `true` if the direction is relative to magnetic
     North, `false` if the direction is relative to the belt itself.
        - signal: The type of vibration signal to use. If `nil`, there is no
     vibration. Only repeated signals can be used.
     - Returns: `true` if the navigation has been started, `false` if the
     navigation has not been started because a temporary signal has been
     specified.
     */
    public func startNavigation(direction: Int, isMagneticBearing: Bool,
                                signal: BeltVibrationSignal?) -> Bool {
        // Check signal type
        if (signal != nil && !isRepeated(signal!)) {
            return false
        }
        // Set signal and change navigation state
        if (navigationState == .navigating) {
            _ = updateNavigationSignal(direction: direction,
                                   isMagneticBearing: isMagneticBearing,
                                   signal: signal)
        } else {
            navigationState = .navigating
            navigationDirection = direction
            isMagneticBearingDirection = isMagneticBearing
            navigationSignal = signal
            if (beltConnection.state == .connected) {
                if (beltController.mode == .app) {
                    scheduleOrSendVibrationCommand()
                } else {
                    if (!beltController.changeBeltMode(.app)) {
                        print("Fail to change belt mode to app!")
                    }
                }
            }
            delegate?.onNavigationStateChange(state: navigationState)
        }
        return true
    }
    
    /**
     Updates the vibration signal.
     
     - Parameters:
        - direction: The direction of the vibration in degrees. The value 0
     represents the magnetic North or heading of the belt, and angles are
     clockwise.
        - isMagneticBearing: `true` if the direction is relative to magnetic
     North, `false` if the direction is relative to the belt itself.
        - signal: The type of vibration signal to use. If `nil`, there is no
     vibration. Only repeated signals can be used.
     - Returns: `true` if the signal has been updated, `false` if the
     signal has not been updated because a temporary signal has been
     specified or the navigation is not started.
     */
    public func updateNavigationSignal(direction: Int, isMagneticBearing: Bool,
            signal: BeltVibrationSignal?) -> Bool {
        // Check signal type
        if (signal != nil && !isRepeated(signal!)) {
            return false
        }
        // Check navigation state
        if (navigationState != .navigating) {
            return false
        }
        // Update signal parameters
        navigationDirection = direction
        isMagneticBearingDirection = isMagneticBearing
        navigationSignal = signal
        scheduleOrSendVibrationCommand()
        return true
    }
    
    /**
     Pauses the navigation.
     
     If the navigation state is `.navigating` and a belt is connected, the mode
     of the belt is changed to pause mode.
     */
    public func pauseNavigation() {
        if (navigationState != .navigating) {
            return
        }
        navigationState = .paused
        if (beltConnection.state == .connected) {
            if (beltController.mode == .app) {
                if (!beltController.changeBeltMode(.pause)) {
                    print("Fail to change belt mode to pause!")
                }
            } else {
                // Unexpected belt mode
                print("Unexpected belt mode!")
            }
        }
        delegate?.onNavigationStateChange(state: navigationState)
    }
    
    /**
     Stops the navigation.
     
     If the navigation state is `.navigating` and a belt is connected, the mode
     of the belt is changed to wait mode. Also if the connected belt is in pause
     mode for the app, the mode of the belt is changed to wait mode.
     */
    public func stopNavigation() {
        if (navigationState == .stopped) {
            return
        }
        navigationState = .stopped
        if (beltConnection.state == .connected) {
            if (beltController.mode == .app ||
                (beltController.mode == .pause && isPauseModeForNavigation)) {
                if (!beltController.changeBeltMode(.wait)) {
                    print("Fail to change belt mode to wait!")
                }
            }
        }
        delegate?.onNavigationStateChange(state: navigationState)
    }
    
    public func notifyDestinationReached(shouldStopNavigation: Bool) {
        //TODO
    }
    
    public func notifyDirection(direction: Int, isMagneticBearing: Bool) {
        //TODO
    }
    
    public func notifyWarning(critical: Bool) {
        //TODO
    }
    
    public func notifyBeltBatteryLevel() {
        //TODO
    }
    
    public func changeDefaultVibrationIntensity(intensity: Int) {
        //TODO
    }
    
    //MARK: Implementation of delegate methods
    
    public func onBeltFound(device: CBPeripheral) {
        // Connect to the belt
        if (beltConnection.state == .notConnected ||
            beltConnection.state == .scanning) {
            beltConnection.connectBelt(device)
        }
    }
    
    public func onBeltScanFinished(cause: FSScanTerminationCause) {
        switch cause {
        case .timeout:
            // No belt found
            delegate?.onNoBeltFound()
            
        case .btNotAvailable, .btNotActive:
            // BT problem
            delegate?.onBeltConnectionFailed()
            
        case .alreadyConnected:
            // Should not happen
            break
            
        case .canceled:
            // Normal termination
            break
        }
    }
    
    public func onConnectionStateChanged(previousState: FSConnectionState,
            newState: FSConnectionState, event: FSConnectionEvent) {
        isPauseModeForNavigation = false
        compassAccuracySignalEnabled = nil
        switch newState {
        case .notConnected:
            if (event == .connectionLost ||
                event == .reconnectionFailed) {
                delegate?.onBeltConnectionLost()
            } else if (event == .connectionFailed ||
                event == .serviceDiscoveryFailed ||
                event == .handshakeFailed) {
                delegate?.onBeltConnectionFailed()
            }
            delegate?.onBeltConnectionStateChanged(state: .disconnected)
        case .scanning:
            delegate?.onBeltConnectionStateChanged(state: .scanning)
        case .connecting:
            delegate?.onBeltConnectionStateChanged(state: .connecting)
        case .discoveringServices:
            delegate?.onBeltConnectionStateChanged(state: .discoveringServices)
        case .handshake:
            delegate?.onBeltConnectionStateChanged(state: .handshake)
        case .connected:
            // Register to orientation notifications
            if (!beltController.startOrientationNotifications(
                minPeriod: FSNavigationController.ORIENTATION_NOTIF_MIN_PERIOD,
                minHeadingVariation: FSNavigationController.ORIENTATION_NOTIF_MIN_HEADING_VARIATION)) {
                print("Fail to register to orientation notifications!")
            }
            // Request compass accuracy signal state
            if (!beltController.requestCompassAccuracySignalState()) {
                print("Fail to request compass accuracy signal state!")
            }
            // Start navigation signal if in navigating state
            if (navigationState == .navigating) {
                if (beltController.mode == .app) {
                    // Should not happen
                    scheduleOrSendVibrationCommand()
                } else {
                    // Change belt mode to app mode
                    if (!beltController.changeBeltMode(.app)) {
                        print("Fail to change belt mode!")
                    }
                }
            }
            // Inform delegate of state change
            delegate?.onBeltConnectionStateChanged(state: .connected)
        }
    }
    
    public func onBeltModeChanged(_ newBeltMode: FSBeltMode) {
        //TODO
    }
    
    public func onBeltButtonPressed(button: FSBeltButton,
            pressType: FSPressType, previousMode: FSBeltMode,
            newMode: FSBeltMode) {
        //TODO
    }
    
    //MARK: Protected methods
    
    //MARK: Private methods
    
    /**
     Schedules or sends the vibration command for the navigation signal.
     
     The vibration command may be delayed to avoid flooding the BT interface.
     */
    private func scheduleOrSendVibrationCommand() {
        //TODO
    }
}

/**
 Enumeration of navigation states used by the navigation controller.
 
 If the navigation controller is connected to a belt the state of the navigation
 will be synchronized to the mode of the belt. If no belt is connected, the
 navigation controller can still switch between states including
 `NavigationState.navigating`.
 */
@objc public enum NavigationState: Int {
    
    /**
     The navigation is stopped, no direction or signal is defined.
     */
    case stopped;
    
    /**
     The navigation is paused and can be resumed with the current direction
     and signal type.
     */
    case paused;
    
    /**
     The navigation has been started with a direction and signal type.
     */
    case navigating;
    
}
