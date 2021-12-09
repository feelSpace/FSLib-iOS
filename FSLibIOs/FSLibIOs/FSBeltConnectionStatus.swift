//
//  FSBeltConnectionStatus.swift
//  FSLibIOs
//
//  Created by David Meignan on 28.10.21.
//  Copyright © 2021 feelSpace. All rights reserved.
//

import Foundation

@objc public enum FSBeltConnectionStatus: Int {
    
    /** The connection status of the belt is unknown. */
    case unknown
    
    /** The belt is already connected, and is used by an application. */
    case connected
    
    /** The belt was previously connected and should already be paired. */
    case known
    
    /** The belt is known, is advertising, and should already be paired. */
    case knownAdvertising
    
    /** The belt is advertising and is probably not yet paired. */
    case advertising
    
}
