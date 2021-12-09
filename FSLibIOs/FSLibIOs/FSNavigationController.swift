//
//  NavigationController.swift
//  FSLibIOs
//
//  Created by David on 10.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log

/**
 The navigation controller is an interface to connect and control a feelSpace
 NaviBelt.
 */
public class FSNavigationController: NSObject, FSConnectionDelegate,
        FSCommandDelegate {
    
    /** Belt connection */
    private var beltConnection: FSConnectionManager
    
    /** Identification of the current connection attempt. */
    private var connectionAttemptBelt: CBPeripheral?
    private var connectionAttemptCount: Int = 0
    private var connectionAttemptStep: FSConnectionAttemptStep = .completed
    
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
    private var navigationSignal: FSBeltVibrationSignal = .noVibration
    
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
     correspond to the `.app` mode of the belt.
     */
    @objc public private(set) var navigationState: FSNavigationState = .stopped
    
    /**
     Connection state with the belt.
     */
    @objc public private(set) var connectionState: FSBeltConnectionState = .notConnected
    
    /**
     Default vibration intensity of the connected belt, in range [5-100].
     
     This value is -1 when no belt is connected and until the first orientation oification is received.
     (Optional type is not used for Objective-C compatibility reasons)
     */
    @objc public var defaultVibrationIntensity: Int {
        get {
            return beltController.defaultIntensity
        }
    }
    
    /**
     Last known orientation of the belt, in degrees relative to magnetic North.
     
     The value is in range [0-360], and -1 if unknown. (Optional type is not used for Objective-C
     compatibility reasons)
     */
    
    @objc public var beltHeading: Int {
        get {
            if let heading = beltController.beltOrientation?.beltMagHeading {
                if (heading < 0) {
                    return (heading%360)+360
                } else {
                    return heading%360
                }
            } else {
                return -1
            }
        }
    }
    
    /**
     Flag indicating if the orientation of the belt is accurate.
     
     The value is -1 when no belt is connected and until the first orientation notification is received from the
     belt. 0 when the orientation is inaccurate, 1 if accurate. (Optional type is not used for Objective-C
     compatibility reasons)
     */
    @objc public var beltOrientationAccurate: Int {
        get {
            if let inaccurate = beltController.beltOrientation?.beltCompassInaccurate {
                if (inaccurate) {
                    return 0
                } else {
                    return 1
                }
            } else {
                return -1
            }
        }
    }
    
    /**
     Battery level of the belt in percent.
     
     The value is in range [0-100], and -1 if unknown. (Optional type is not used for Objective-C
     compatibility reasons)
     */
    @objc public var beltBatteryLevel: Int {
        get {
            if (beltController.beltBatteryStatus.batteryLevel < 0) {
                return -1
            } else {
                return Int(beltController.beltBatteryStatus.batteryLevel)
            }
        }
    }
    
    /**
     Power status of the belt.
     
     The value  is `.unknwon` when no belt is connected and until the first
     battery notification is received from the belt.
     */
    @objc public var beltPowerStatus: FSPowerStatus {
        get {
            return beltController.beltBatteryStatus.powerStatus
        }
    }
    
    /**
     Firmware version of the connected belt.
     
     The value is -1 when no belt is connected.
     */
    @objc public var beltFirmwareVersion: Int {
        get {
            return beltController.firmwareVersion
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
     
     If `1` the compass signal accuracy is enabled, if `0` it is
     disabled. The value is -1 when the state of the compass accuracy
     signal is unknown or no belt is connected. Note that the value of this
     attribute is unknown for a short period after a connection to a belt is
     established.
     */
    @objc public var compassAccuracySignalEnabled: Int {
        get {
            let enabled = beltController.beltCompassAccuracySignalEnabled
            if (beltConnection.state != .connected || enabled == nil) {
                return -1
            } else if (enabled!) {
                return 1
            } else {
                return 0
            }
        }
    }
    
    /**
     Delegate of the navigation controller.
     
     A delegate must be defined to handle events of the navigation controller.
     */
    @objc public var delegate: FSNavigationControllerDelegate?
    
    /**
     Channel index used for the navigation signal
     */
    @objc public static let NAVIGATION_SIGNAL_CHANNEL: Int = 2
    
    /** Logging interface. */
    private let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "de.feelspace.FSLibIOs",
        category: "network")
    
    
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
        // Set connection state
        switch beltConnection.state {
        case .notConnected, .initializing:
            connectionState = .notConnected
        case .scanning:
            connectionState = .searching
        case .connecting, .discoveringServices, .handshake, .reconnecting:
            connectionState = .connecting
        case .connected:
            connectionState = .connected
        }
    }
    
    /**
     Searches and connects a belt.
     */
    @objc public func searchAndConnectBelt() {
        connectionState = .notConnected
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
        connectionAttemptBelt = nil
        connectionAttemptCount = 0
        connectionAttemptStep  = .checkConnected
        // Set state and inform delegate
        connectionState = .searching
        delegate?.onConnectionStateChanged(
            state: connectionState, error: .noError)
        // Start connection attempts
        connectionAttempts()
    }
    
    /**
     Retries to connect the belt used in the last connection attempt.
     */
    @objc public func retryBeltConnection() {
        guard let lastBelt = connectionAttemptBelt else {
            os_log("No belt to retry the connection.", type: .info)
            return
        }
        connectionState = .notConnected
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
        connectionAttemptCount += 1
        connectionAttemptStep = .completed // No more attempt if connection fails
        // Set state and inform delegate
        connectionState = .connecting
        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
        // Start connection
        beltConnection.connectBelt(lastBelt)
        
    }
    
    /**
     Makes a new attempt to search and connect a belt.
     */
    private func connectionAttempts() {
        if connectionState != .searching &&
            connectionState != .connecting {
            os_log("Unexpected connection state to start connection attempt.", type: .debug)
        }
        if connectionAttemptStep == .checkConnected {
            // 1. Check for connected belt
            let connected = beltConnection.retrieveConnectedBelt()
            if (connected.count > 0) {
                connectionAttemptBelt = connected[0]
                connectionAttemptCount = 1
                os_log("Connection attempt with already connected belt", type: .info)
                if connectionState != .connecting {
                    connectionState = .connecting
                    delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
                }
                beltConnection.connectBelt(connectionAttemptBelt!)
                return
            } else {
                connectionAttemptStep = .attemptLastConnected
            }
        }
        if connectionAttemptStep == .attemptLastConnected {
            // 2. Connection attempt with last connected belt
            if let lastConnected = beltConnection.retrieveLastConnectedBelt() {
                connectionAttemptBelt = lastConnected
                connectionAttemptCount = 1
                os_log("Connection attempt with last connected belt", type: .info)
                if connectionState != .connecting {
                    connectionState = .connecting
                    delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
                }
                beltConnection.connectBelt(connectionAttemptBelt!)
                return
            } else {
                connectionAttemptStep = .scan
            }
        }
        if connectionAttemptStep == .scan {
            // 3. Scan for belt and connect to the first belt found
            os_log("Scan for belt.", type: .info)
            if connectionState != .searching {
                connectionState = .searching
                delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
            }
            beltConnection.scanForBelt()
            return
        }
        // Procedure completed
        // connectionAttemptStep == .completed
    }
    
    /**
     Searches for belts.
     */
    @objc public func searchBelt() {
        connectionState = .notConnected
        connectionAttemptStep = .completed // No connection when belt found
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
        // Set state and inform delegate
        connectionState = .searching
        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
        // Return belts that are already connected
        let connectedBelts = beltConnection.retrieveConnectedBelt()
        for belt in connectedBelts {
            delegate?.onBeltFound(belt: belt, status: .connected)
        }
        // Scan for adversiting belts
        beltConnection.scanForBelt()
    }
    
    /**
     Connects a belt.
     
     - Parameters:
        - device: The belt to connect to.
     */
    @objc public func connectBelt(_ device: CBPeripheral) {
        connectionState = .notConnected
        connectionAttemptStep = .completed // No additional connection attempt
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
        if let lastBelt = connectionAttemptBelt,
           lastBelt.identifier == device.identifier {
            connectionAttemptCount += 1
        } else {
            connectionAttemptBelt = device
            connectionAttemptCount = 0
        }
        // Set state and inform delegate
        connectionState = .connecting
        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
        // Connect belt
        beltConnection.connectBelt(device)
    }
    
    /**
     Disconnects the belt or stops the scan and connection procedure.
     */
    @objc public func disconnectBelt() {
        if connectionState == .notConnected {
            return
        }
        connectionAttemptStep = .completed
        // Set state
        connectionState = .notConnected
        // Stop scan and disconnect
        beltConnection.stopScan()
        beltConnection.disconnectBelt()
        // Inform delegate after disconnection to avoid starting a new
        // scan/connection before the effective disconnection
        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
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
    @objc public func startNavigation(direction: Int, isMagneticBearing: Bool,
                                signal: FSBeltVibrationSignal) -> Bool {
        // Check signal type
        if (!FSBeltVibrationSignal.isRepeated(signal)) {
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
    @objc public func updateNavigationSignal(direction: Int, isMagneticBearing: Bool,
            signal: FSBeltVibrationSignal) -> Bool {
        // Check signal type
        if (!FSBeltVibrationSignal.isRepeated(signal)) {
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
    @objc public func pauseNavigation() {
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
    @objc public func stopNavigation() {
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
    @objc public func notifyDestinationReached(shouldStopNavigation: Bool) -> Bool {
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
    @objc public func notifyDirection(direction: Int,
                                isMagneticBearing: Bool) -> Bool {
        if (beltConnection.state == .connected) {
            if (isMagneticBearing) {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .continuous,
                    orientationType: .magneticBearing,
                    orientation: direction,
                    patternIterations: 1,
                    patternPeriod: 1000,
                    exclusiveChannel: false,
                    clearOtherChannels: false)
            } else {
                return beltController.configureVibrationChannel(
                    channelIndex: 0,
                    pattern: .continuous,
                    orientationType: .angle,
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
    @objc public func notifyWarning(critical: Bool) -> Bool {
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
    @objc public func notifyBeltBatteryLevel() -> Bool {
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
    @objc public func changeDefaultVibrationIntensity(
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
    @objc public func setCompassAccuracySignal(
        enable: Bool, persistent: Bool) -> Bool {
        if (beltConnection.state == .connected) {
            return beltController.changeCompassAccuracySignalState(
                enable: enable, persistent: persistent)
        } else {
            return false
        }
    }
    
    //MARK: Implementation of `FSConnectionDelegate` protocol
    
    // A belt has been found during the scan
    public func onBeltFound(device: CBPeripheral) {
        if connectionState == .searching {
            if connectionAttemptStep == .scan {
                // Next step is connection attempt
                connectionAttemptStep = .completed
                connectionState = .connecting
                delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
                beltConnection.connectBelt(device)
            } else {
                // Inform delegate of the belt found
                let known = beltConnection.isPreviouslyConnectedBelt(
                    uuid: device.identifier)
                delegate?.onBeltFound(
                    belt: device,
                    status: known ? .knownAdvertising : .advertising)
            }
        } else {
            os_log("Unexpected state on belt-found callback.", type: .debug)
        }
    }
    
    // The scan failed to start
    public func onScanFailed(error: FSConnectionError) {
        if connectionState != .searching {
            os_log("Unexpected state on scan fail.", type: .debug)
        }
        var retError: FSBeltConnectionError = .btStateError
        switch error {
        case .btPoweredOff:
            retError = .btPoweredOff
        case .btUnauthorized:
            retError = .btUnauthorized
        case .btUnsupported:
            retError = .btUnsupported
        case .btStateNotificationFailed, .btStateUnknown, .btStateResetting:
            retError = .btStateError
        case .connectionTimeout, .serviceDiscoveryTimeout, .handshakeTimeout,
                .reconnectionTimeout, .connectionFailed,
                .connectionLimitReached, .peripheralDisconnected,
                .unexpectedDisconnection, .pairingFailed,
                .gattDiscoveryPermissionError, .serviceDiscoveryFailed,
                .handshakePermissionError, .handshakeFailed:
            os_log("Unexpected scan error.", type: .debug)
        case .powerOff:
            retError = .beltPoweredOff
        }
        connectionAttemptStep = .completed // Stop connection procedure (if any)
        connectionState = .notConnected
        delegate?.onConnectionStateChanged(
            state: .notConnected, error: retError)
    }
    
    // Connection state changed
    public func onConnectionStateChanged(
        previousState: FSConnectionState,
        newState: FSConnectionState,
        error: FSConnectionError?)
    {
        switch newState {
        case .notConnected:
            if let err = error {
                // Error, check for next connection step, except for BT error
                if err == .btPoweredOff {
                    connectionAttemptStep = .completed
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .btPoweredOff)
                    return
                } else if err == .btUnauthorized {
                    connectionAttemptStep = .completed
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .btUnauthorized)
                    return
                } else if err == .btUnsupported {
                    connectionAttemptStep = .completed
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .btUnsupported)
                    return
                } else if err == .btStateNotificationFailed ||
                            err == .btStateUnknown ||
                            err == .btStateResetting {
                    connectionAttemptStep = .completed
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .btStateError)
                    return
                }
                // Check for next connection step
                switch connectionAttemptStep {
                case .checkConnected:
                    // State should be `.connecting`
                    if connectionState != .connecting {
                        os_log("Unexpected state on `.checkConnected` connection step.", type: .debug)
                        connectionState = .connecting
                        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
                    }
                    // Next step is check last connected
                    connectionAttemptStep = .attemptLastConnected
                    connectionAttempts()
                case .attemptLastConnected:
                    // State should be `.connecting`
                    if connectionState != .connecting {
                        os_log("Unexpected state on `.attemptLastConnected` connection step.", type: .debug)
                        connectionState = .connecting
                        delegate?.onConnectionStateChanged(state: connectionState, error: .noError)
                    }
                    // Next step is scan
                    connectionAttemptStep = .scan
                    connectionAttempts()
                case .scan:
                    // Scan failed
                    // `onScanFailed` callback should have already been called
                    if connectionState != .notConnected {
                        os_log("Unexpected state on `.scan` connection step.", type: .debug)
                        onScanFailed(error: err)
                    }
                case .completed:
                    // Final/Single connection attempt failed
                    if connectionState == .notConnected {
                        os_log("Unexpected state on disconnection.", type: .debug)
                    }
                    // Inform delegate about the type of error
                    var retError: FSBeltConnectionError = .unexpectedDisconnection
                    switch err {
                    case .btPoweredOff:
                        retError = .btPoweredOff
                    case .btUnauthorized:
                        retError = .btUnauthorized
                    case .btUnsupported:
                        retError = .btUnsupported
                    case .btStateNotificationFailed, .btStateUnknown, .btStateResetting:
                        retError = .btStateError
                    case .connectionTimeout, .serviceDiscoveryTimeout,
                            .handshakeTimeout, .reconnectionTimeout:
                        retError = .connectionTimeout
                    case .connectionFailed, .serviceDiscoveryFailed,
                            .handshakeFailed:
                        // NOTE: On serviceDiscoveryFailed, maybe a pairing problem
                        retError = .connectionFailed
                    case .connectionLimitReached:
                        retError = .connectionLimitReached
                    case .peripheralDisconnected:
                        retError = .beltDisconnection
                    case .unexpectedDisconnection:
                        retError = .unexpectedDisconnection
                    case .pairingFailed, .gattDiscoveryPermissionError,
                            .handshakePermissionError:
                        retError = .pairingPermissionError
                    case .powerOff:
                        retError = .beltPoweredOff
                    }
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: retError)
                }
            } else {
                // Expected disconnection or no belt found
                if connectionAttemptStep == .scan {
                    // No belt found, end of the connection procedure
                    connectionAttemptStep = .completed
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .noBeltFound)
                } else if connectionAttemptStep == .completed {
                    // End of the search procedure
                    connectionState = .notConnected
                    delegate?.onConnectionStateChanged(
                        state: connectionState, error: .noError)
                } else {
                    // Expected disconnection
                    // State should already be `.notConnected`
                    if connectionState != .notConnected {
                        os_log("Unexpected state when disconnected.", type: .debug)
                        // Set state and inform delegate
                        connectionState = .notConnected
                        delegate?.onConnectionStateChanged(
                            state: connectionState, error: .noError)
                    }
                }
            }
        case .initializing:
            // Nothing to do
            // The state should be searching or connecting
            if connectionState != .searching &&
                connectionState != .connecting {
                os_log("Unexpected state when initializing BT.", type: .debug)
            }
            // No error expected
            if let _ = error {
                os_log("Unexpected error in `.initializing` state.", type: .debug)
            }
        case .scanning:
            // Nothing to do
            // The state should be searching
            if connectionState != .searching {
                os_log("Unexpected state when scanning.", type: .debug)
                connectionState = .searching
                delegate?.onConnectionStateChanged(
                    state: connectionState, error: .noError)
            }
            // No error expected
            if let _ = error {
                os_log("Unexpected error in `.initializing` state.", type: .debug)
            }
        case .connecting, .discoveringServices, .handshake:
            // Nothing to do
            // The state should be connecting
            if connectionState != .connecting {
                os_log("Unexpected state when connecting.", type: .debug)
                connectionState = .connecting
                delegate?.onConnectionStateChanged(
                    state: connectionState, error: .noError)
            }
            // No error expected
            if let _ = error {
                os_log("Unexpected error in `.connecting` state.", type: .debug)
            }
        case .connected:
            // Successful connection
            os_log("Belt connection successful.", type: .info)
            // Register to orientation notifications
            if (!beltController.startOrientationNotifications()) {
                os_log("Fail to register to orientation notifications!", type: .debug)
            }
            // Request compass accuracy signal state
            if (!beltController.requestCompassAccuracySignalState()) {
                os_log("Fail to request compass accuracy signal state!", type: .debug)
            }
            // Start navigation signal if in navigating state
            if (navigationState == .navigating) {
                if (beltController.mode == .app) {
                    // Should not happen
                    scheduleOrSendVibrationCommand()
                } else {
                    // Change belt mode to app mode
                    if (!beltController.changeBeltMode(.app)) {
                        os_log("Fail to change belt mode!", type: .debug)
                    }
                }
            }
            // Set state and inform delegate
            connectionState = .connected
            connectionAttemptStep = .completed
            delegate?.onConnectionStateChanged(
                state: connectionState, error: .noError)
            if let _ = error {
                os_log("Unexpected error in `.connected` state.", type: .debug)
            }
        case .reconnecting:
            if connectionState != .connected &&
                connectionState != .connecting {
                os_log("Unexpected state when reconnecting.", type: .debug)
            }
            connectionState = .connecting
            delegate?.onConnectionStateChanged(
                state: connectionState, error: .unexpectedDisconnection)
        }
    }
    
    // MARK: Implementation of `FSCommandDelegate` protocol
    
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
     preserve the Bluetooth service to be flooded.
     This method can be overridden to manage more complex vibration signals.
     
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
        signal: FSBeltVibrationSignal) {
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
        if (!FSBeltVibrationSignal.isRepeated(signal)) {
            // Stop the vibration
            _=beltController.stopVibration()
        } else {
            switch (signal) {
            case .noVibration:
                _=beltController.stopVibration()
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

/**
 Enumeration of the connection states.
 
 This is a simnplified view of the connection states listed in `FSConnectionState`, and is used only by the
 navigation controller.
 */
@objc public enum FSBeltConnectionState: Int {
    
    /** No belt is connected */
    case notConnected
    
    /** Searching for a belt */
    case searching
    
    /** Connecting to a belt */
    case connecting
    
    /** Connected to a belt */
    case connected
}

/**
 Enumeration of connection errors.
 
 This is a simplified list of `FSConnectionError` only for the navigation controller.
 */
@objc public enum FSBeltConnectionError: Int {
    
    /** No error */
    case noError
    
    /** BT is not active. */
    case btPoweredOff
    
    /** The application is not autorized to use BT. */
    case btUnauthorized
    
    /** BT is not supported on this device. */
    case btUnsupported
    
    /** Unexpected error with the BT interface */
    case btStateError
    
    /** Unexpected disconnetion, maybe out of range */
    case unexpectedDisconnection
    
    /** No belt found during the connection procedure */
    case noBeltFound
    
    /** Connection timeout */
    case connectionTimeout
    
    /** Connection failed unexpectedly */
    case connectionFailed
    
    /** Too many BT devices connected */
    case connectionLimitReached
    
    /** The belt initiated the disconnection */
    case beltDisconnection
    
    /** The belt has been switched-off */
    case beltPoweredOff
    
    /** There is maybe a pairing problem */
    case pairingPermissionError
    
}

/**
 Enumeration of the steps for searching and connecting a belt.
 */
private enum FSConnectionAttemptStep {
    /** Check if a belt is already connected. */
    case checkConnected
    /** Try to reconnect the last connected belt. */
    case attemptLastConnected
    /** Scan and connect to the first found belt. */
    case scan
    /** Connection attempts procedure completed. */
    case completed
}
