//
//  FSConnectionDelegate.swift
//  FSLibIOs
//
//  Created by David on 21/05/17.
//  Copyright © 2017 feelSpace. All rights reserved.
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
     Indicates that the search procedure for finding a belt is finished.
     
     - Parameters:
        - cause: The cause of the termination.
     */
    func onBeltScanFinished(cause: FSScanTerminationCause)
    
    /**
     Indicates that the connection state has changed.
     
     - Parameters:
        - previousState: The previous state.
        - newState: The new state.
        - event: The cause of the state change.
     */
    func onConnectionStateChanged(previousState: FSConnectionState,
                                 newState: FSConnectionState,
                                 event: FSConnectionEvent)
    
}

/**
 Values representing the cause of termination of the scan procedure.
 */
public enum FSScanTerminationCause {
    /** The timeout duration has been reached. */
    case timeout
    /** The Bluetooth is not available. */
    case btNotAvailable
    /** The Bluetooth is powered-off. */
    case btNotActive
    /** When a belt is already connected or connecting. */
    case alreadyConnected
    /**
     Scan has been canceled by either a call to `stopScan` or `connectBelt`. 
     */
    case canceled
}

/**
 Values representing the different states of the connection with the belt.
 The states `CONNECTING`, `DISCOVER_SERVICES`, and `HANDSHAKE` can be considered
 identical for the app.
 */
public enum FSConnectionState {
    /** The belt is not conected. */
    case notConnected
    /** Connecting to the belt. */
    case connecting
    /** Discovery of the services and characteristics. */
    case discoveringServices
    /** Handshake procedure. */
    case handshake
    /** The belt is connected and ready to receive commands. */
    case connected
}

/**
 Values representing the causes of state changes.
 */
public enum FSConnectionEvent {
    /** Connection started. */
    case connectionStarted
    /** Connection established but service not yet discovered. */
    case connectionEstablished
    /** Service discovery finished. */
    case servicesDiscovered
    /** Handshake finished. */
    case handshakeFinished
    /** Connection closed. */
    case connectionClosed
    /** Connection lost. */
    case connectionLost
    /** Connection failed. */
    case connectionFailed
    /** Service discovery failed. */
    case serviceDiscoveryFailed
    /** Handshake failed. */
    case handshakeFailed
    /** Reconnection started. */
    case reconnectionStarted
    /** Reconnection failed. */
    case reconnectionFailed
}

