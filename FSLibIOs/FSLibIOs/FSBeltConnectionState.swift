//
//  BeltConnectionState.swift
//  FSLibIOs
//
//  Created by David on 16.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation

/**
 Enumeration of connection states with a belt.
 */
@objc public enum FSBeltConnectionState: Int {
    
    /**
     No belt is connected
     */
    case disconnected;
    
    /**
     Scanning for a belt
     */
    case scanning;
    
    /**
     Connecting to a belt
     */
    case connecting;
    
    /**
     Reconnecting to a belt after unexpected disconnection
     */
    case reconnecting;
    
    /**
     Discovering the GATT services
     */
    case discoveringServices;
    
    /**
     Handshake procedure ongoing
     */
    case handshake;
    
    /**
     Connected to a belt
     */
    case connected;

}
