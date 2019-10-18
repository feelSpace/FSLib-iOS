//
//  PowerStatus.swift
//  FSLibIOs
//
//  Created by David on 16.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation

/**
 Enumeration of possible power status for a belt.
 */
@objc public enum PowerStatus: Int {
    
    /**
     Unknown power status
     */
    case unknown;
    
    /**
     The belt is powered by its internal battery
     */
    case onBattery;
    
    /**
     The battery of the belt is charging
     */
    case charging;
    
    /**
     The battery of the belt is full and the belt is powered by an external power source via USB.
     */
    case externalPower;
}
