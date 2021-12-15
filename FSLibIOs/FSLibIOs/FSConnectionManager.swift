//
//  FSConnectionManager.swift
//  FSLibIOs
//
//  Created by David on 21/05/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Manages the connection with the belt.
 */
public class FSConnectionManager: NSObject, CBCentralManagerDelegate {
    
    //MARK: Public properties
    
    public static let BT_WAKEUP_TIMEOUT_SEC: Double = 3.0
    
    /**
     Default timeout for scanning.
     */
    public static let SCAN_DEFAULT_TIMEOUT_SEC: Double = 15.0
    
    /**
     Default timeout for connection, service discovery, and handshake.
     This timeout also includes a possible pairing request presented to the
     user.
     */
    public static let CONNECTION_HANDSHAKE_TIMEOUT_SEC: Double = 20.0
    
    /**
     Service UUID advertised by a belt.
     This service UUID is used to identify a belt.
     */
    public static let ADVERTISED_SERVICE_UUID =
        CBUUID(string: "65333333-A115-11E2-9E9A-0800200CA100")
    
    /**
     Name prefix of a belt.
     This prefix is used to identify a belt.
     */
    public static let BELT_NAME_PREFIX = "naviGuertel"
    
    /**
     Unique instance of `FSConnectionManager` (singleton).
     */
    public static let instance = FSConnectionManager()
    
    /**
     Delegate of the connection manager.
     
     The delegate receives callbacks from the connection manager when searching
     for a belt and when the connection state changes.
     */
    public var delegate: FSConnectionDelegate? = nil
    
    /**
     The state of the connection.
     */
    public private(set) var state: FSConnectionState = .notConnected;
    
    /**
     The command manager.
     */
    public var commandManager: FSCommandManager {
        return privateCommandManager
    }
    
    //MARK: Private properties
    
    // Central manager
    private var btManager: CBCentralManager!
    
    // Command manager
    // Note: Use of computed property with private attribute because of 
    // initialization.
    private var privateCommandManager: FSCommandManager!
    
    // Pending scan when BT is powered-on
    private var pendingScan: Bool = false;
    private var pendingScanTimeoutSec: Double = 0.0
    
    // List of scanned devices to avoid duplicates
    // Notes: Although an option is used to avoid duplicates, scan sometimes
    // returns duplicates.
    private var scannedPeripheralIdentifers = Set<UUID>()
    
    // Pending connection when BT is powered-on
    private var pendingConnection: Bool = false;
    private var pendingConnectionTimeoutSec: Double = 0.0
    
    // The belt device (connected or pending for connection)
    private var beltDevice: CBPeripheral? = nil
    
    // Keys to store previously connected belts
    private static let lastConnectedBeltsKey =
        "lastConnectedBeltsKey"
    private static let maxLastConnectedBelts = 10
    
    // BT manager wakeup timer
    private var btWakeupTimer: Timer?
    
    // Scan timer
    private var scanTimer: Timer?
    
    // Connection timer
    private var connectionTimer: Timer?
    
    //MARK: Methods
    
    // Private initialization for singleton
    private override init() {
        super.init()
        btManager = CBCentralManager(
            delegate: self, queue: nil)
        privateCommandManager = FSCommandManager(self)
    }
    
    /**
     Retrieves belts already connected.
     
     It might occur that belts are connected from another app. In this case,
     the method `connectBelt` still have to be called for being available in
     the current app.
     
     - Returns:
     An array with connected belts or an empty array if no belt is connected.
     */
    public func retrieveConnectedBelt() -> [CBPeripheral] {
        var connectedBelts: [CBPeripheral] = []
        let connectedPeriphs = btManager.retrieveConnectedPeripherals(
            withServices: [FSConnectionManager.ADVERTISED_SERVICE_UUID])
        for periph in connectedPeriphs {
            if let name = periph.name,
               name.lowercased().hasPrefix(
                FSConnectionManager.BELT_NAME_PREFIX.lowercased()) {
                connectedBelts.append(periph)
            }
        }
        return connectedBelts
    }
    
    /**
     Returns the last connected belt.
     This method returns only successfully connected belt, i.e. a device for
     which the connection state reached the `connected` state.
     
     - Returns:
     The last connected belt or `nil` if no belt was previously connected.
     */
    public func retrieveLastConnectedBelt() -> CBPeripheral? {
        let uuids = getLastConnectedBeltUUIDs()
        if !uuids.isEmpty {
            let knownDevices = btManager.retrievePeripherals(
                withIdentifiers: [uuids[0]])
            if !knownDevices.isEmpty,
               let name = knownDevices[0].name,
               name.lowercased().hasPrefix(
                FSConnectionManager.BELT_NAME_PREFIX.lowercased()) {
                return knownDevices[0]
            }
        }
        return nil
    }
    
    /**
     Returns `true` if the UUID corresponds to a belt that was successfully connected.
     
     - Returns:
     `true` if the UUID corresponds to a belt that was successfully connected.
     */
    public func isPreviouslyConnectedBelt(uuid: UUID) -> Bool {
        let uuids = getLastConnectedBeltUUIDs()
        return uuids.contains(uuid)
    }
    
    /**
     Returns the list of UUIDs of the previously connected belts.
     
     Most recent connection UUIDs first.
     
     - Returns: The list of UUIDs of the previously connected belts.
     */
    internal func getLastConnectedBeltUUIDs() -> [UUID] {
        var uuids: [UUID] = []
        if let lastUUIDStrings = UserDefaults.standard.stringArray(
            forKey: FSConnectionManager.lastConnectedBeltsKey) {
            for uuidString in lastUUIDStrings {
                if let uuid = UUID.init(uuidString: uuidString) {
                    uuids.append(uuid)
                }
            }
        }
        return uuids
    }
    
    /**
     Clears the list of UUIDs of the previously connected belts.
     */
    internal func clearLastConnectedBeltUUIDs() {
        UserDefaults.standard.setValue(
            [], forKey: FSConnectionManager.lastConnectedBeltsKey)
    }
    
    /**
     Saves the UUID of the last connected belt in the list of previously connected belts.
     
     There is a limit to the number of belt UUIDs that are saved. When this limit is reached the last connected
     UUID is removed.
     
     - Parameters:
        - beltUUID: The UUID of the belt to save.
     */
    internal func addLastConnectedBeltUUID(beltUUID: UUID) {
        var uuidStrings = UserDefaults.standard.stringArray(
            forKey: FSConnectionManager.lastConnectedBeltsKey) ?? []
        uuidStrings.insert(beltUUID.uuidString, at: 0)
        while uuidStrings.count > FSConnectionManager.maxLastConnectedBelts {
            uuidStrings.removeLast()
        }
        UserDefaults.standard.setValue(
            uuidStrings,
            forKey: FSConnectionManager.lastConnectedBeltsKey)
    }
    
    /**
     Scans for advertising belts.
     
     Scan results are returned through the delegate's method `onBeltFound`.
     */
    public func scanForBelt(timeoutSec: Double = SCAN_DEFAULT_TIMEOUT_SEC) {
        
        let initialState = state
        state = .notConnected
        clearScan()
        clearConnection()
        
        // Check BT manager state
        switch btManager.state {
        case .poweredOff:
            // Abort
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .btPoweredOff)
            return
        case .unauthorized:
            // Abort
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .btUnauthorized)
            return
        case .unsupported:
            // Abort
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .btUnsupported)
            return
        case .unknown, .resetting:
            // Wait for manager state update (with timer)
            state = .initializing
            pendingScan = true
            pendingScanTimeoutSec = timeoutSec
            btWakeupTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(
                    FSConnectionManager.BT_WAKEUP_TIMEOUT_SEC),
                target: self,
                selector: #selector(btWakeupTimeout),
                userInfo: nil,
                repeats: false)
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: nil)
            }
            return
        case .poweredOn:
            // Continue with scan
            break
        @unknown default:
            // Wait for manager state update (with timer)
            state = .initializing
            pendingScan = true
            pendingScanTimeoutSec = timeoutSec
            btWakeupTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(
                    FSConnectionManager.BT_WAKEUP_TIMEOUT_SEC),
                target: self,
                selector: #selector(btWakeupTimeout),
                userInfo: nil,
                repeats: false)
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: nil)
            }
            return
        }
        
        // Set state
        state = .scanning
        
        // Start scan timer
        var adjustedTimeout = timeoutSec
        if adjustedTimeout <= 0 {
            adjustedTimeout = FSConnectionManager.SCAN_DEFAULT_TIMEOUT_SEC
        }
        scanTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(adjustedTimeout),
            target: self,
            selector: #selector(scanTimeout),
            userInfo: nil,
            repeats: false)
        
        // Start scan
        btManager.scanForPeripherals(withServices:
            [FSConnectionManager.ADVERTISED_SERVICE_UUID], options:
            [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // Notify state change
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: nil)
    }
    
    /**
     Stops the scan procedure.
     */
    public func stopScan() {
        if (state != .scanning && state != .initializing) {
            return
        }
        // Set state
        let initialState = state
        state = .notConnected
        // Stop scan
        clearScan()
        // Inform delegate
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: nil)
    }
    
    /**
     Timeout procedure when waiting for BT initialization.
     */
    @objc internal func btWakeupTimeout() {
        if (state != .initializing) {
            return
        }
        btWakeupTimer = nil
        state = .notConnected
        pendingScan = false
        pendingConnection = false
        var btManagerError: FSConnectionError = .btStateNotificationFailed
        switch btManager.state {
        case .unknown:
            btManagerError = .btStateUnknown
        case .resetting:
            btManagerError = .btStateResetting
        case .unsupported:
            btManagerError = .btUnsupported
        case .unauthorized:
            btManagerError = .btUnauthorized
        case .poweredOff:
            btManagerError = .btPoweredOff
        case .poweredOn:
            break
        @unknown default:
            break
        }
        delegate?.onConnectionStateChanged(
            previousState: .initializing,
            newState: state,
            error: btManagerError)
    }
    
    /**
     Clears any pending or running scan.
     
     The state is not changed, the delegate is not notified.
     */
    private func clearScan() {
        // Reset pending scan
        pendingScan = false
        pendingConnection = false
        // Clear scanned device list
        scannedPeripheralIdentifers.removeAll()
        // Clear BT wakeup timer
        btWakeupTimer?.invalidate()
        btWakeupTimer = nil
        // Clear scan timer
        scanTimer?.invalidate()
        scanTimer = nil
        // Stop scan
        if btManager.isScanning {
            btManager.stopScan()
        }
    }
    
    /**
     Scan timeout procedure.
     */
    @objc internal func scanTimeout() {
        if (state != .scanning) {
            return
        }
        // Set state
        state = .notConnected
        // Stop scan
        clearScan()
        // Inform delegate
        delegate?.onConnectionStateChanged(
            previousState: .scanning,
            newState: .notConnected,
            error: nil)
    }
    
    /**
     Connects the belt given in parameter.
     
     - Important:
     This method should be called only when in `notConnected` state.
     - Parameters:
        - device: The belt to connect to.
        - timeoutSec: The desired timeout, in seconds, for the whole connection,
     service discovery and handshake procedure. This timeout is also running for
     a possible pairing request presented to the user.
     */
    public func connectBelt(
        _ device: CBPeripheral,
        timeoutSec: Double = CONNECTION_HANDSHAKE_TIMEOUT_SEC)
    {
        
        let initialState = state
        state = .notConnected
        clearScan()
        clearConnection()
        
        // Check BT manager state
        switch btManager.state {
        case .poweredOff:
            // Abort
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .btPoweredOff)
            }
            return
        case .unauthorized:
            // Abort
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .btUnauthorized)
            }
            return
        case .unsupported:
            // Abort
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .btUnsupported)
            }
            return
        case .unknown, .resetting:
            // Wait for manager state update (with timer)
            state = .initializing
            pendingConnection = true
            beltDevice = device
            pendingConnectionTimeoutSec = timeoutSec
            btWakeupTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(
                    FSConnectionManager.BT_WAKEUP_TIMEOUT_SEC),
                target: self,
                selector: #selector(btWakeupTimeout),
                userInfo: nil,
                repeats: false)
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: nil)
            }
            return
        case .poweredOn:
            // Continue with connection
            break
        @unknown default:
            // Wait for manager state update (with timer)
            state = .initializing
            pendingConnection = true
            beltDevice = device
            pendingConnectionTimeoutSec = timeoutSec
            btWakeupTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(
                    FSConnectionManager.BT_WAKEUP_TIMEOUT_SEC),
                target: self,
                selector: #selector(btWakeupTimeout),
                userInfo: nil,
                repeats: false)
            if initialState != state {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: nil)
            }
            return
        }
        
        // Set state
        beltDevice = device
        state = .connecting
        
        // Start connection timer
        connectionTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(timeoutSec),
            target: self,
            selector: #selector(connectionTimeout),
            userInfo: nil,
            repeats: false)
        
        // Connection
        btManager.connect(device, options: nil)
        
        // Notify state change
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: nil)
    }
    
    /**
     Timeout procedure for the whole connection process.
     */
    @objc internal func connectionTimeout() {
        switch state {
        case .notConnected, .scanning, .connected, .initializing:
            // Obsolete timer, do nothing
            break
        case .connecting:
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: .connecting,
                newState: state,
                error: .connectionTimeout)
        case .discoveringServices:
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: .connecting,
                newState: state,
                error: .serviceDiscoveryTimeout)
        case .handshake:
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: .connecting,
                newState: state,
                error: .handshakeTimeout)
        case .reconnecting:
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: .connecting,
                newState: state,
                error: .reconnectionTimeout)
        }
    }
    
    /**
     Disconnects the belt or cancels ongoing connection.
     */
    public func disconnectBelt() {
        switch state {
        case .notConnected, .scanning:
            // Nothing to disconnect or continue scan
            return
        case .initializing:
            if pendingScan {
                // Continue scan
                pendingConnection = false
                return
            }
        case
            .connecting,
            .discoveringServices,
            .handshake,
            .connected,
            .reconnecting:
            break
        }
        let initialState = state
        state = .notConnected
        clearConnection()
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: nil)
    }
    
    /**
     Disconnects or clears a pending connection.
     
     The state is not changed, the delegate is not notified.
     */
    internal func clearConnection() {
        // Clear pending connection and connection timer
        connectionTimer?.invalidate()
        connectionTimer = nil
        // Clear BT wakeup timer
        pendingConnection = false
        pendingScan = false
        btWakeupTimer?.invalidate()
        btWakeupTimer = nil
        // Clear GATT references
        commandManager.clearGattReference()
        // Close connection
        if (beltDevice != nil) {
            btManager.cancelPeripheralConnection(beltDevice!)
            beltDevice = nil
        }
    }
    
    // MARK: Callback functions from BT manager
    
    // BT Manager initialized or state changed
    final public func centralManagerDidUpdateState(_ central: CBCentralManager){
        
        // Check for pending scan
        if (pendingScan) {
            if (state != .initializing || btWakeupTimer == nil) {
                // Obsolete pending scan, should not happen
                pendingScan = false
                return
            }
            let btState = btManager.state
            if btState == .unknown || btState == .resetting {
                // Continue waiting for manager updates with timer
                return
            }
            // Start scan or send scan failure notification
            scanForBelt(timeoutSec: pendingScanTimeoutSec)
            return
        }
        
        // Check for pending connection
        if (pendingConnection) {
            if (state != .initializing || btWakeupTimer == nil) {
                // Obsolete pending scan, should not happen
                pendingScan = false
                return
            }
            let belt = beltDevice
            if belt == nil {
                // Missing device, should not happen
                clearConnection()
                state = .notConnected
                delegate?.onConnectionStateChanged(
                    previousState: .initializing,
                    newState: state,
                    error: nil)
                return
            }
            let btState = btManager.state
            if btState == .unknown || btState == .resetting {
                // Continue waiting for manager updates with timer
                return
            }
            // Start connection or send failure notification
            connectBelt(belt!, timeoutSec: pendingConnectionTimeoutSec)
            return
        }
    }
    
    // A device has been found
    final public func centralManager(_ central: CBCentralManager,
                                     didDiscover peripheral: CBPeripheral,
                                     advertisementData: [String : Any],
                                     rssi RSSI: NSNumber) {
        // Check device name
        if let name = peripheral.name {
            if !name.lowercased().contains(
                FSConnectionManager.BELT_NAME_PREFIX.lowercased()) {
                return
            }
        }
        // Check for duplicates
        if !scannedPeripheralIdentifers.contains(peripheral.identifier) {
            // Add in list
            scannedPeripheralIdentifers.insert(peripheral.identifier)
            // Inform delegate
            delegate?.onBeltFound(device: peripheral)
        }
    }
    
    // Connection established
    final public func centralManager(_ central: CBCentralManager,
                                     didConnect peripheral: CBPeripheral) {
        // Set state
        let initialState = state
        state = .discoveringServices
        // Keep belt reference
        beltDevice = peripheral
        // Inform delegate
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: nil)
        // Continue with service discovery
        commandManager.discoverServices(peripheral);
    }
    
    // Connection failed
    final public func centralManager(_ central: CBCentralManager,
                                     didFailToConnect peripheral: CBPeripheral,
                                     error: Error?) {
        if (state == .notConnected ||
                state == .initializing ||
                state == .scanning) {
            // Ignore
            return
        }
        // Set state
        let initialState = state
        state = .notConnected
        // Clear connection
        clearConnection()
        // Inform delegate with specific error
        if let btError = error as? CBError {
            if btError.code == .connectionLimitReached {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .connectionLimitReached)
            } else {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .connectionFailed)
            }
        } else {
            // Generic error
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .connectionFailed)
        }
    }
    
    // Connection lost
    final public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?) {
        if (state == .notConnected ||
                state == .initializing ||
                state == .scanning) {
            // Ignore
            return
        }
        // Set state
        let initialState = state
        state = .notConnected
        // Check if belt was previously connected
        var previouslyConnected = false
        if let beltUUID = beltDevice?.identifier {
            previouslyConnected = getLastConnectedBeltUUIDs().contains(beltUUID)
        }
        // Clear connection
        let beltSwitchedOff = commandManager.mode == .standby
        clearConnection()
        // Inform delegate with specific error
        if (!previouslyConnected &&
                (initialState == .connecting ||
                    initialState == .discoveringServices ||
                    state == .handshake)) {
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .pairingFailed)
        } else if beltSwitchedOff {
            // User initiated power off
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .powerOff)
        } else if let btError = error as? CBError {
            if btError.code == .peripheralDisconnected {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .peripheralDisconnected)
            } else {
                delegate?.onConnectionStateChanged(
                    previousState: initialState,
                    newState: state,
                    error: .unexpectedDisconnection)
            }
        } else {
            // Generic error
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: .unexpectedDisconnection)
        }
        // TODO: Reconnection attempt.
    }
    
    //MARK: Callback functions of command manager
    
    /**
     Informs the connection manager that service discovery is finished.
     
     If service discovery failed, an error is given and the connection manager must close the connection
     or try a reconnection.
     If service discovery succeed, the connection manager initiate the handshake procedure.
     
     - Parameters:
        - error: The error in case service discovery failed.
     */
    internal func onServiceDiscoveryFinished(
        error: FSConnectionError?) {
        if (state == .notConnected ||
            state == .initializing ||
            state == .scanning) {
            // Do nothing
            return
        }
        let initialState = state
        if let e = error {
            // Service discovery failed
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: e)
        } else {
            // Service discovery succeed
            state = .handshake
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: nil)
            commandManager.startHandshake()
        }
    }
    
    /**
     Informs the connection manager that handshake is finished.
     
     If the handshake procedure failed, an error is given and the connection manager must close the
     connection or try a reconnection.
     If handshake succeed, the state is set as `.connected`.
     
     - Parameters:
        - error: The error in case handshake failed.
     */
    internal func onHandshakeFinished(
        error: FSConnectionError?) {
        if (state == .notConnected ||
            state == .initializing ||
            state == .scanning) {
            // Do nothing
            return
        }
        let initialState = state
        // Stop connection timeout procedure
        connectionTimer?.invalidate()
        connectionTimer = nil
        if let e = error {
            // Handshake failed
            state = .notConnected
            clearConnection()
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: e)
        } else {
            // Handshake succeed
            // Set state
            state = .connected
            // Save belt UUID
            if let uuid = beltDevice?.identifier {
                addLastConnectedBeltUUID(beltUUID: uuid)
            }
            // Inform delegate
            delegate?.onConnectionStateChanged(
                previousState: initialState,
                newState: state,
                error: nil)
        }
    }
    
    /**
     Informs the connection manager that the belt is unresponsive.
     
     The connection manager must close the connection or try to reconnect.
     
     - Parameters:
        - error: The related error.
     */
    internal func onBeltUnresponsive(
        error: FSConnectionError) {
        if (state == .notConnected ||
            state == .initializing ||
            state == .scanning) {
            // Do nothing
            return
        }
        let initialState = state
        state = .notConnected
        clearConnection()
        delegate?.onConnectionStateChanged(
            previousState: initialState,
            newState: state,
            error: error)
    }
    
}
