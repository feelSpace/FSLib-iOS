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
    
    /**
     Default timeout for scanning.
     */
    public static let SCAN_DEFAULT_TIMEOUT_SEC = 15
    
    /**
     Default timeout for connection, service discovery, and handshake.
     This timeout also includes a possible pairing request presented to the
     user.
     */
    public static let CONNECTION_HANDSHAKE_TIMEOUT_SEC = 20
    
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
    public static let BELT_NAME_PREFIX = "NaviGuertel"
    
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
    
    // List of scanned deviced to avoid duplicates
    // Notes: Although an option is used to avoid duplicates, scan sometimes
    // returns duplicates.
    private var scannedPeripheralIdentifers = Set<UUID>()
    
    // Pending connection when BT is powered-on
    private var pendingConnection: Bool = false;
    
    // The belt device (connected or pending for connection)
    private var beltDevice: CBPeripheral? = nil
    
    // Scan timer
    private var scanTimer: Timer?
    
    // Connection timer
    private var connectionTimer: Timer?
    
    //MARK: Methods
    
    // Private initialization for singleton
    private override init() {
        super.init()
        btManager = CBCentralManager(delegate: self, queue: nil)
        privateCommandManager = FSCommandManager(self)
    }
    
    /**
     Retrieves a belt already connected.
     
     It might occur that the belt is connected for another app. In this case,
     the method `connectBelt` still have to be called for being available in
     the current app.
     
     - Returns:
     An array with a connected belt or an empty array if no belt is connected.
     */
    public func retrieveConnectedBelt() -> [CBPeripheral] {
        return btManager.retrieveConnectedPeripherals(
            withServices: [FSConnectionManager.ADVERTISED_SERVICE_UUID])
    }
    
    /**
     Returns the last connected belt.
     This method returns only successfully connected belt, i.e. a device for
     which the connection state reached the `connected` state.
     
     - Returns:
     The last connected belt or `nil` if no belt was previously connected.
     */
    public func retrieveLastConnectedBelt() -> CBPeripheral? {
        // TODO Retrieve the belt with its UUID
        // TODO Use UserDefault to store UUID
        var knownDevices = btManager.retrievePeripherals(withIdentifiers: [])
        if knownDevices.count == 1 {
            if (knownDevices[0].name?.hasPrefix(
                FSConnectionManager.BELT_NAME_PREFIX)) != nil {
                return knownDevices[0]
            }
        }
        return nil
    }
    
    /**
     Scans for advertising belts.
     
     Scan results are returned through the delegate's method `onBeltFound`. When
     the scan procedure terminates or fails, the delegate's method
     `onBeltScanFinished` is called.
     */
    public func scanForBelt(timeoutSec: Int = SCAN_DEFAULT_TIMEOUT_SEC){
        
        // Reset current and pending scan
        resetScan()
        
        // Check current connection state
        if (state != .notConnected) {
            delegate?.onBeltScanFinished(cause: .alreadyConnected)
            return
        }
        
        // Check BT manager state
        switch btManager.state {
        case .poweredOff:
            // Abort scan (BT not active)
            delegate!.onBeltScanFinished(cause: .btNotActive)
            return
        case .unauthorized, .unsupported:
            // Abort scan (BT not available)
            delegate!.onBeltScanFinished(cause: .btNotAvailable)
            return
        case .unknown, .resetting:
            // Wait for manager state update (with timer)
            pendingScan = true
        case .poweredOn:
            // Continue with scan
            break
        }
        
        // Start scan timer
        scanTimer = Timer.scheduledTimer(timeInterval: TimeInterval(timeoutSec),
                                         target: self,
                                         selector: #selector(scanTimeout),
                                         userInfo: nil,
                                         repeats: false)
        
        // Start scan if BT ready
        
        // Note: Condition for scan is on btManager.state and not
        // pendingScan. This may result in an obsolete scan timer
        // but solve a synchronization problem when reading the manager's state
        // before setting pendingScan value.
        if (btManager.state == .poweredOn) {
            btManager.scanForPeripherals(withServices:
                [FSConnectionManager.ADVERTISED_SERVICE_UUID], options:
                [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    /**
     Stops the scan procedure.
     If a scan procedure is effectively stopped, the delegate should receive a
     notification `onBeltScanFinished` with `Canceled` as a cause.
     */
    public func stopScan() {
        // Inform delegate
        if (scanTimer != nil) {
            delegate?.onBeltScanFinished(cause: .canceled)
        }
        // Stop scan
        resetScan()
    }
    
    // Stops the scan procedure and send a delegate notification
    private func resetScan() {
        // Reset pending scan
        pendingScan = false
        // Clear scanned device list
        scannedPeripheralIdentifers.removeAll()
        // Clear scan timer
        scanTimer?.invalidate()
        scanTimer = nil
        // Stop scan
        if btManager.isScanning {
            btManager.stopScan()
        }
    }
    
    // Callback of the scan timeout timer
    @objc internal func scanTimeout() {
        // Stop scan
        resetScan()
        // Inform delegate
        if (state == .notConnected) {
            delegate?.onBeltScanFinished(cause: .timeout)
        }
    }
    
    /**
     Attemps to connect the belt given in parameter.
     
     Connection events are notified through the delegate's method
     `onConnectionStateChange`.
     If a scan procedure is ongoing, it is canceled before connecting the belt
     and the delegate should receive a notification `onBeltScanFinished` with
     `canceled` as argument.
     - Important:
     This method should be called only when in `notConnected` state.
     - Parameters:
        - device: The belt to connect to.
        - timeoutSec: The desired timeout, in seconds, for the whole connection,
     service discovery and handshake procedure. This timeout is also running for
     a possible pairing request presented to the user.
     */
    public func connectBelt(_ device: CBPeripheral,
                            timeoutSec: Int = CONNECTION_HANDSHAKE_TIMEOUT_SEC){
        
        // Check connection state
        if (state != .notConnected) {
            // Cannot connect when already connecting or connected
            setState(newState: state, cause: .connectionFailed,
                     forceNotification: true)
            return
        }
        
        // Change connection state
        setState(newState: .connecting, cause: .connectionStarted)
        
        // Stop scan (with delegate notification)
        if (scanTimer != nil) {
            stopScan()
        }
        
        // Check BT manager state
        switch btManager.state {
        case .poweredOff, .unauthorized, .unsupported:
            // Abort connection (BT not active or not available)
            setState(newState: .notConnected, cause: .connectionFailed)
            beltDevice = nil
            pendingConnection = false
            return
        case .unknown, .resetting:
            // Wait for manager state update (with timer)
            beltDevice = device
            pendingConnection = true
        case .poweredOn:
            // Continue with connection
            beltDevice = device
            pendingConnection = false
        }
        
        // Start connection timer
        connectionTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(timeoutSec),
            target: self,
            selector: #selector(connectionTimeout),
            userInfo: nil,
            repeats: false)
        
        // Connection if BT ready
        
        // Note: Condition for connection is on btManager.state and not
        // pendingConnection. This may result in an obsolete connection timer
        // but solve a synchronization problem when reading the manager's state
        // before setting pendingConnection value.
        if (btManager.state == .poweredOn) {
            btManager.connect(beltDevice!, options: nil)
        }
    }
    
    // Callback of the connection timeout timer
    @objc internal func connectionTimeout() {
        switch state {
        case .notConnected, .scanning, .connected:
            // Obsolete timer, do nothing
            connectionTimer?.invalidate()
            connectionTimer = nil
            break
        case .connecting:
            clearConnection(.connectionFailed)
            break
        case .discoveringServices:
            clearConnection(.serviceDiscoveryFailed)
            break
        case .handshake:
            clearConnection(.handshakeFailed)
            break
        }
    }
    
    // Set the connection state and inform delegate
    internal func setState(newState: FSConnectionState, cause: FSConnectionEvent,
                           forceNotification: Bool = false) {
        if (!forceNotification && newState == state) {
            // No state change
            return
        }
        // Change state
        let previousState = state
        state = newState
        // TODO if cause is handshakeFinished, save belt UUID
        // Inform delegate
        delegate?.onConnectionStateChanged(previousState: previousState,
                                           newState: newState,
                                           event: cause)
    }
    
    /**
     Disconnects the belt or cancels ongoing connection.
     */
    public func disconnectBelt() {
        clearConnection(.connectionClosed)
    }
    
    // Disconnects the belt, clears the pending connection and connection timer
    internal func clearConnection(_ cause: FSConnectionEvent) {
        // Clear pending connection and connection timer
        pendingConnection = false
        connectionTimer?.invalidate()
        connectionTimer = nil
        // Clear GATT references
        commandManager.clearGattReference()
        // Close connection
        if (beltDevice != nil) {
            btManager.cancelPeripheralConnection(beltDevice!)
            beltDevice = nil
        }
        // Set state
        setState(newState: .notConnected, cause: cause)
    }
    
    // *** CBCentralManagerDelegate ***
    
    // BT Manager initialized or state changed
    final public func centralManagerDidUpdateState(_ central: CBCentralManager){
        
        // Check for pending scan
        if (pendingScan) {
            if (state != .notConnected || scanTimer == nil) {
                // Obsolete pending scan
                resetScan()
                return
            }
            switch btManager.state {
            case .poweredOff:
                // Abort scan (BT not active)
                pendingScan = false
                delegate!.onBeltScanFinished(cause: .btNotActive)
            case .unauthorized, .unsupported:
                // Abort scan (BT not available)
                pendingScan = false
                delegate!.onBeltScanFinished(cause: .btNotAvailable)
            case .unknown, .resetting:
                // Still wait for manager state update (timer already active)
                break;
            case .poweredOn:
                // Start scan (timer already active)
                pendingScan = false
                btManager.scanForPeripherals(withServices:
                    [FSConnectionManager.ADVERTISED_SERVICE_UUID], options: nil)
            }
            return
        }
        
        // Check for pending connection
        if (pendingConnection) {
            if (state != .connecting) {
                // Obsolete pending connection
                pendingConnection = false
                return
            }
            if (connectionTimer == nil) {
                // Should not occur
                clearConnection(.connectionFailed)
                return
            }
            switch btManager.state {
            case .poweredOff, .unauthorized, .unsupported:
                // Abort connection (BT not active or not available)
                clearConnection(.connectionFailed)
            case .unknown, .resetting:
                // Still wait for manager state update (timer already active)
                break;
            case .poweredOn:
                // Start connection (timer already active)
                pendingConnection = false
                btManager.connect(beltDevice!, options: nil)
            }
            return
        }
    }
    
    // A device has been found
    final public func centralManager(_ central: CBCentralManager,
                                     didDiscover peripheral: CBPeripheral,
                                     advertisementData: [String : Any],
                                     rssi RSSI: NSNumber) {
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
        // Change state
        setState(newState: .discoveringServices, cause: .connectionEstablished)
        // Continue with service discovery
        beltDevice = peripheral
        commandManager.discoverServices(peripheral);
    }
    
    // Connection failed
    final public func centralManager(_ central: CBCentralManager,
                                     didFailToConnect peripheral: CBPeripheral,
                                     error: Error?) {
        clearConnection(.connectionFailed)
    }
    
    // Connection lost
    final public func centralManager(_ central: CBCentralManager,
                                     didDisconnectPeripheral peripheral: CBPeripheral,
                                     error: Error?) {
        clearConnection(.connectionLost)
    }
}
