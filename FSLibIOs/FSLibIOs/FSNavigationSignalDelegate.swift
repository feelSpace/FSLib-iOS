//
//  FSNavigationSignalDelegate.swift
//  FSLibIOs
//
//  Created by David on 11/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Callbacks of the navigation signal controller.
 */
@objc public protocol FSNavigationSignalDelegate {
    
    /**
     Callback that informs about connection state changes.
     
     - Parameters:
        - previousState: The previous connection state.
        - newState: The new connection state.
     */
    func onScanConnectionStateChanged(previousState: FSScanConnectionState,
                                      newState: FSScanConnectionState)
    
    /**
     Callback that informs about a mode change.
     
     - Parameters:
        - beltMode: The new operating mode of the belt.
        - buttonPressed: `true` if the mode has been changed after the user 
     pressed a button on the belt.
     */
    func onBeltSignalModeChanged(beltMode: FSBeltSignalMode,
                                 buttonPressed: Bool)
    
    /**
     Informs that the user has press the Home button on the belt to start the
     navigation or request an app feature.
     */
    func onBeltRequestHome()
    
    /**
     Notifies that the belt orientation has been updated.
     
     - Important: Heading values from the belt are relative to the magnetic
     North. If a magnetic heading is used in conjunction with map data, the
     magnetic declination must be taking into account.
     
     - Parameters:
        - beltMagHeading: The new magnetic heading value of the belt.
        - beltCompassInaccurate: `true` if the belt compass is inaccurate.
     */
    @objc optional func onBeltOrientationNotified(beltMagHeading: Int,
                                                  beltCompassInaccurate: Bool)
    
    /**
     Informs that the heading offset value has been changed on the belt.
     
     - Parameters:
     - headingOffset: The new heading offset value.
     */
    @objc optional func onHeadingOffsetChanged(_ headingOffset: Int)
    
}

