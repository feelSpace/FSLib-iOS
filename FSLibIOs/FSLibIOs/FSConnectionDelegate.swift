//
//  FSConnectionDelegate.swift
//  FSLibIOs
//
//  Created by David on 21/05/17.
//  Copyright © 2017-2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Callbacks of the `FSConnectionManager`.
 */
public protocol FSConnectionDelegate {
    
    /**
     Indicates that a belt has been found during the scan procedure.
     
     This function is called when a Bluetooth device that advertises as a 
     'naviGuertel' is found. If multiple belts are available this function is
     called for each belt.
     
     - Parameters:
        - device: The belt found.
     */
    func onBeltFound(device: CBPeripheral)
    
    /**
     Indicates that the connection state has changed or an error occurs.
     
     - Parameters:
        - previousState: The previous state.
        - newState: The new state.
        - error: The error in case the state change is unexpected.
     */
    func onConnectionStateChanged(previousState: FSConnectionState,
                                 newState: FSConnectionState,
                                 error: FSConnectionError?)
    
}

/**
 Values representing the different states of the connection with the belt.
 The states `CONNECTING`, `DISCOVER_SERVICES`, and `HANDSHAKE` can be considered
 identical for the app.
 */
@objc public enum FSConnectionState: Int {
    /** No belt is conected. */
    case notConnected
    /** Initializing BLE interface */
    case initializing
    /** Scanning for a belt. */
    case scanning
    /** Connecting to the belt. */
    case connecting
    /** Discovery of the services and characteristics. */
    case discoveringServices
    /** Handshake procedure. */
    case handshake
    /** The belt is connected and ready to receive commands. */
    case connected
    /** An attempt to reconnect the belt is made */
    case reconnecting
}

public enum FSConnectionError: Error {
    /** BT is not active. */
    case btPoweredOff
    /** The application is not autorized to use BT. */
    case btUnauthorized
    /** BT is not supported on this device. */
    case btUnsupported
    /** The state of the BT was not correctly been notified to the app. */
    case btStateNotificationFailed
    /** The state of the BT manager didn"t updated within the timeout time. */
    case btStateUnknown
    /** The BT manager is resetting. */
    case btStateResetting
    /** Timeout when establishing connection */
    case connectionTimeout
    /** Timeout when discovering services */
    case serviceDiscoveryTimeout
    /** Timeout during service discovery */
    case handshakeTimeout
    /** Timeout when reconnecting */
    case reconnectionTimeout
    /** Connection failed */
    case connectionFailed
    /** Maximum number of connections reached */
    case connectionLimitReached
    /** The belt probably initiated the disconnection */
    case peripheralDisconnected
    /** The belt has been switched-off */
    case powerOff
    /** Unexpected disconnetion, maybe out of range */
    case unexpectedDisconnection
    /** Disconnection probably due to pairing/bonding not performed */
    case pairingFailed
    /** Service discovery failed due to a permission problem on GATT profile */
    case gattDiscoveryPermissionError
    /** Service discovery failed for an unknown reason */
    case serviceDiscoveryFailed
    /** Handshake faile due to GATT permission problem */
    case handshakePermissionError
    /** Handshake failed for an unknown reason */
    case handshakeFailed
}
