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
@objc public class FSNavigationController: NSObject, FSConnectionDelegate,
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
    private var navigationSignal: FSBeltVibrationSignal?
    
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
    public private(set) var navigationState: FSNavigationState = .stopped
    
    /**
     Connection state with the belt.
     */
    public var connectionState: FSBeltConnectionState {
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
    public var beltPowerStatus: FSPowerStatus? {
        get {
            switch beltController.beltBatteryStatus.powerStatus {
            case .onBattery:
                return .onBattery
            case .charging:
                return .charging
            case .externalPower:
                return .externalPower
            default:
                return nil
            }
        }
    }
    
    /**
     Firmware version of the connected belt.
     
     This property is `nil` when no belt is connected.
     */
    public var beltFirmwareVersion: Int? {
        get {
            let version = beltController.firmwareVersion
            if (version < 0) {
                return nil
            } else {
                return version
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
    public var compassAccuracySignalEnabled: Bool? {
        get {
            let state = beltController.beltCompassAccuracySignalEnabled
            if (beltConnection.state != .connected) {
                return nil
            } else {
                return state
            }
        }
    }
    
    /**
     Delegate of the navigation controller.
     
     A delegate must be defined to handle events of the navigation controller.
     */
    public var delegate: FSNavigationControllerDelegate?
    
    /**
     Channel index used for the navigation signal
     */
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
                                signal: FSBeltVibrationSignal?) -> Bool {
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
            signal: FSBeltVibrationSignal?) -> Bool {
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
    
    /**
     Starts a vibration signal indicating that the destination has been reached.
     
     The destination reached signal is executed only once.
     
     - Parameters:
        - shouldStopNavigation: `true` to stop the navigation when the signal is
     performed.
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func notifyDestinationReached(shouldStopNavigation: Bool) -> Bool {
        if (shouldStopNavigation) {
            stopNavigation()
        }
        if (beltConnection.state == .connected) {
            return beltController.signal(signalType: .goalReached)
        } else {
            return false
        }
    }
    
    /**
     Starts a vibration notification in a given direction.
     
     - Parameters:
        - direction: The direction of the vibration in degrees. The value 0
     represents the magnetic North or heading of the belt, and angles are
     clockwise.
        - isMagneticBearing: `true` if the direction is relative to magnetic
     North, `false` if the direction is relative to the belt itself.
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func notifyDirection(direction: Int,
                                isMagneticBearing: Bool) -> Bool {
        if (beltConnection.state == .connected) {
            if (isMagneticBearing) {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .continuous,
                    orientationType: .angle,
                    orientation: direction,
                    patternIterations: 1,
                    patternPeriod: 1000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            } else {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .continuous,
                    orientationType: .magneticBearing,
                    orientation: direction,
                    patternIterations: 1,
                    patternPeriod: 1000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            }
        } else {
            return false
        }
    }
    
    /**
     Starts a warning vibration signal.
     
     - Parameters:
        - critical: `true` if a strong warning signal must be used.
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func notifyWarning(critical: Bool) -> Bool {
        if (beltConnection.state == .connected) {
            if (critical) {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .singleLong,
                    orientationType: .binaryMask,
                    orientation: 0b0001000100010001,
                    patternIterations: 3,
                    patternPeriod: 700,
                    exclusiveChannel: true,
                    clearOtherChannels: false)
            } else {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .shortShiftWave,
                    intensity: 25,
                    orientationType: .vibromotorIndex,
                    orientation: 0,
                    patternIterations: 2,
                    patternPeriod: 500,
                    exclusiveChannel: true,
                    clearOtherChannels: false)
            }
        } else {
            return false
        }
    }
    
    /**
     Starts a vibration signal to indicate the battery level of the belt.
     
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func notifyBeltBatteryLevel() -> Bool {
        if (beltConnection.state == .connected) {
            return beltController.signal(signalType: .battery)
        } else {
            return false
        }
    }
    
    /**
     Changes the default vibration intensity of the connected belt.
     
     The default vibration intensity can be changed only when a belt is
     connected. The delegate is informed asynchronously of the intensity change
     with the callback `onBeltDefaultVibrationIntensityChanged()`.
     
     - Parameters:
        - intensity: The intensity to set inrange [5-100]. This intensity is
     saved on the belt and used for the navigation and compass mode.
        - vibrationFeedback: `true` if a vibration feedback must be started when
     the intensity has changed.
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func changeDefaultVibrationIntensity(
        intensity: Int, vibrationFeedback: Bool = true) -> Bool {
        if (intensity < 5 || intensity > 100) {
            return false
        }
        if (beltConnection.state == .connected) {
            return beltController.changeDefaultIntensity(
                intensity, feedbackSignal: vibrationFeedback)
        } else {
            return false
        }
    }
    
    /**
     Enables or disables the compass accuracy signal of the belt.
     
     The compass accuracy signal is changed for the navigation, compass and
     crossing modes.
     
     - Important: If the configuration of the compass accuracy signal is saved
     on the belt (i.e. the `persistent` parameter is `true`), the user must be
     informed of this new configuration as it will also impact the compass and
     crossing mode when no app is connected to the belt.
     
     - Parameters:
        - enable: `true` to enable the compass accuracy signal, `false` to
     disable it.
        - persistent: `true` to save the configuration on the belt, `false`
     to set the configuration only for the current power-cycle of the belt
     (i.e. this configuration is reset when the belt is powered off).
     - Returns: `true` if the request has been sent, `false` otherwise.
     */
    public func setCompassAccuracySignal(
        enable: Bool, persistent: Bool) -> Bool {
        if (beltConnection.state == .connected) {
            return beltController.changeCompassAccuracySignalState(
                enable: enable, persistent: persistent)
        } else {
            return false
        }
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
            
        case .btNotAvailable:
            // BT problem
            delegate?.onBluetoothNotAvailable()
            
        case .btNotActive:
            // BT powered off
            delegate?.onBluetoothPoweredOff()
            
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
            if (!beltController.startOrientationNotifications()) {
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
        isPauseModeForNavigation = false
        switch (newBeltMode) {
        case .unknown:
            // Should not happen
            break
        case .standby:
            // Nothing to do, the belt is going to be switched off
            break
        case .wait:
            // The navigation should be in stop state
            if (navigationState != .stopped) {
                print("Navigation state and belt mode out of sync!")
                stopNavigation()
            }
        case .compass, .calibration, .crossing:
            // The navigation should be in pause or stop state
            if (navigationState == .navigating) {
                print("Navigation state and belt mode out of sync!")
                pauseNavigation()
            }
        case .app:
            // The navigation has been started
            if (navigationState != .navigating) {
                print("Navigation state and belt mode out of sync!")
                if (navigationState == .stopped) {
                    _=beltController.changeBeltMode(.wait)
                } else {
                    _=beltController.changeBeltMode(.pause)
                }
            } else {
                scheduleOrSendVibrationCommand()
            }
        case .pause:
            // The navigation has been paused
            if (navigationState != .paused) {
                pauseNavigation()
            } else {
                isPauseModeForNavigation = true
            }
        }
    }
    
    public func onBeltButtonPressed(button: FSBeltButton,
            pressType: FSPressType, previousMode: FSBeltMode,
            newMode: FSBeltMode) {
        isPauseModeForNavigation = false
        if (button == .home && previousMode == newMode) {
            // Home button pressed for application action
            // Note: Home button can be preseed to stop calibration and return
            // to wait mode.
            switch (navigationState) {
            case .stopped:
                // Should not be in app mode
                if (newMode == .app) {
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.wait)
                } else {
                    delegate?.onBeltHomeButtonPressed(navigating: false)
                }
            case .paused:
                // Resume navigation
                _=startNavigation(direction: navigationDirection,
                                isMagneticBearing: isMagneticBearingDirection,
                                signal: navigationSignal)
            case .navigating:
                // Should be in app mode
                if (newMode != .app) {
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.app)
                } else {
                    delegate?.onBeltHomeButtonPressed(navigating: true)
                }
            }
        } else if (button == .pause && previousMode == newMode) {
            // Pause button pressed for pause or resume navigation
            if (newMode == .app) {
                // Pause request from belt
                // Should be navigating
                switch (navigationState) {
                case .stopped:
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.wait)
                case .paused:
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.pause)
                case .navigating:
                    pauseNavigation()
                }
                
            } else if (newMode == .pause) {
                // Resume request from belt
                // Should be in pause state
                switch (navigationState) {
                case .stopped:
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.wait)
                case .paused:
                    _=startNavigation(direction: navigationDirection,
                                      isMagneticBearing: isMagneticBearingDirection,
                                      signal: navigationSignal)
                case .navigating:
                    print("Navigation state and belt mode out of sync!")
                    _=beltController.changeBeltMode(.app)
                }
            }
        } else if (newMode != .app) {
            // Pause navigation if navigating
            // Note: The mode cannot be automatically changed to app mode
            // with a button press
            if (navigationState == .navigating) {
                pauseNavigation()
            }
        }
    }
    
    public func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        delegate?.onBeltDefaultVibrationIntensityChanged(
            intensity: defaultIntensity)
    }
    
    public func onBeltBatteryStatusUpdated(_ status: FSBatteryStatus) {
        delegate?.onBeltBatteryLevelUpdated(
            batteryLevel: Int(status.batteryLevel),
            status: status.powerStatus)
    }
    
    public func onBeltOrientationNotified(beltOrientation: FSBeltOrientation) {
        delegate?.onBeltOrientationUpdated(
            beltHeading: beltOrientation.beltMagHeading,
            accurate: !beltOrientation.beltCompassInaccurate)
    }
    
    public func onBeltCompassAccuracySignalStateNotified(_ enabled: Bool) {
        delegate?.onCompassAccuracySignalStateUpdated(enabled: enabled)
    }
    
    //MARK: Protected methods
    
    /**
     Sends the command to start or update the vibration signal when in
     navigation.
     
     This method is called by the navigation manager when the navigation is
     started or the vibration signal is updated. Note that the navigation
     manager has an mechanism to avoid calling this method too often to
     preserve the Blurtooth service to be flooded.
     This method can be overridden to manage more complexe vibration signals.
     
     - Parameters:
        - beltConnection: The connection to the belt.
        - direction: The navigation direction.
        - isMagneticBearing: `true` if the navigation direction is relative to
     magnetic North.
        - signal: The type of signal for the navigation.
     */
    public func sendVibrationCommand(
        beltConnection: FSConnectionManager,
        direction: Int,
        isMagneticBearing: Bool,
        signal: FSBeltVibrationSignal?) {
        if (navigationState != .navigating) {
            // Not in navigation
            return
        }
        if (beltConnection.state != .connected) {
            // Not connected
            return
        }
        if (beltController.mode != .app) {
            // Not in app mode
            return
        }
        if ((signal == nil) || (!isRepeated(signal!))) {
            // Stop the vibration
            _=beltController.stopVibration()
        } else {
            switch (signal!) {
            case .continuous, .navigation:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .continuous,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 500,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .approachingDestination:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleShort,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 500,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .turnOngoing:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleLong,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 750,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .nextWaypointLongDistance:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleLong,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 3000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .nextWaypointMediumDistance:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleLong,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 1500,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .nextWaypointShortDistance:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleLong,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 1000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .nextWaypointAreaReached:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .singleLong,
                    orientationType: (isMagneticBearing) ? (.magneticBearing) : (.angle),
                    orientation: direction,
                    patternIterations: 0,
                    patternPeriod: 750,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .destinationReachedRepeated:
                _=beltController.configureVibrationChannel(
                    channelIndex: FSNavigationController.NAVIGATION_SIGNAL_CHANNEL,
                    pattern: .goalReached,
                    orientationType: .vibromotorIndex,
                    orientation: 0,
                    patternIterations: 0,
                    patternPeriod: 5000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            case .batteryLevel, .directionNotification,
                 .destinationReachedSingle, .operationWarning, .criticalWarning:
                // Temporary signal
                break
            }
        }
    }
    
    //MARK: Private methods
    
    /**
     Schedules or sends the vibration command for the navigation signal.
     
     The vibration command may be delayed to avoid flooding the BT interface.
     */
    private func scheduleOrSendVibrationCommand() {
        if (beltConnection.state == .connected &&
            beltController.mode == .app &&
            navigationState == .navigating &&
            vibrationCommandTask == nil) {
            if (lastVibrationCommandTime == nil ||
                Date().timeIntervalSince(lastVibrationCommandTime!) >
                FSNavigationController.MINIMUM_VIBRATION_COMMAND_UPDATE_PERIOD_SEC) {
                // Send vibration command
                print("Send vibration command")
                lastVibrationCommandTime = Date()
                sendVibrationCommand(
                    beltConnection: beltConnection,
                    direction: navigationDirection,
                    isMagneticBearing: isMagneticBearingDirection,
                    signal: navigationSignal)
            } else {
                // Schedule update
                print("Schedule vibration command")
                if #available(iOS 10.0, *) {
                    vibrationCommandTask = Timer.scheduledTimer(
                        withTimeInterval: TimeInterval(
                            FSNavigationController.MINIMUM_VIBRATION_COMMAND_UPDATE_PERIOD_SEC),
                        repeats: false,
                        block: { (timer) in
                            print("Send scheduled vibration command")
                            self.vibrationCommandTask = nil
                            self.lastVibrationCommandTime = Date()
                            self.sendVibrationCommand(
                                beltConnection: self.beltConnection,
                                direction: self.navigationDirection,
                                isMagneticBearing: self.isMagneticBearingDirection,
                                signal: self.navigationSignal)
                    })
                } else {
                    vibrationCommandTask = Timer.scheduledTimer(
                        timeInterval: TimeInterval(
                            FSNavigationController.MINIMUM_VIBRATION_COMMAND_UPDATE_PERIOD_SEC),
                        target: self,
                        selector: #selector(self.sendScheduledVibrationCommand),
                        userInfo: nil,
                        repeats: false)
                }
                
            }
        } else {
            // Else, skip update and wait scheduled command
            
            print("Skip update")
        }
    }
    
    /** Scheduled update of the vibration for iOS < 10. */
    @objc private func sendScheduledVibrationCommand() {
        print("Send scheduled vibration command")
        self.vibrationCommandTask = nil
        self.lastVibrationCommandTime = Date()
        self.sendVibrationCommand(
            beltConnection: self.beltConnection,
            direction: self.navigationDirection,
            isMagneticBearing: self.isMagneticBearingDirection,
            signal: self.navigationSignal)
    }

}
    
/**
 Enumeration of navigation states used by the navigation controller.
 
 If the navigation controller is connected to a belt the state of the navigation
 will be synchronized to the mode of the belt. If no belt is connected, the
 navigation controller can still switch between states including
 `NavigationState.navigating`.
 */
@objc public enum FSNavigationState: Int {
    
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
