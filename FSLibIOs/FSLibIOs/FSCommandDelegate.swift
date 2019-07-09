//
//  FSCommandDelegate.swift
//  FSLibIOs
//
//  Created by David on 21/05/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Callbacks of the `FSCommandManager`.
 */
public protocol FSCommandDelegate {
    
    /**
     Informs that the mode of the belt has changed.
     
     Mode change can be due to a request sent by the app or the end of the 
     belt's calibration procedure.
     
     - Important:
     This method is NOT called when the mode is changed by a button press (See
     `onBeltButtonPressed`).
     
     - Parameters:
        - newBeltMode: The new mode of the belt.
     */
    func onBeltModeChanged(_ newBeltMode: FSBeltMode)
    
    /**
     Informs that a button on the belt has been pressed and released, and 
     possibly that the mode changed.
     
     - Important:
     If the button press resulted in a mode change, the new mode is given in 
     this callback. The `onBeltModeChanged` is NOT called when the mode is 
     changed by a button press.
     
     - Parameters:
        - button: The button pressed.
        - pressType: The type of button press.
        - previousMode: The mode of the belt before the button press.
        - newMode: The mode of the belt after the button press.
     */
    func onBeltButtonPressed(button: FSBeltButton,
                             pressType: FSPressType,
                             previousMode: FSBeltMode,
                             newMode: FSBeltMode)
    
    /**
     Informs that the default vibration intensity has been changed.
     
     The default intensity can be changed by either button press on the belt or
     by a request sent by the app.
     
     - Parameters:
        - defaultIntensity: The new default intensity.
     */
    func onDefaultIntensityChanged(_ defaultIntensity: Int)
    
    /**
     Informs that the heading offset value has been changed on the belt.
     
     - Parameters:
        - headingOffset: The new heading offset value.
     */
    func onHeadingOffsetChanged(_ headingOffset: Int)
    
    /**
     Informs about an update of the battery status (power-supply, battery level,
     TTE/TTF).
     
     The new battery status is given in parameter and is also accessible from 
     the `beltBatteryStatus` parameter of the command manager.
     
     - Parameters:
        - status: The new battery status of the belt.
     */
    func onBeltBatteryStatusUpdated(_ status: FSBatteryStatus)
    
    /**
     Notifies that the belt orientation has been updated.
     
     - Important: Heading values from the belt are relative to the magnetic
     North. If a magnetic heading is used in conjunction with map data, the
     magnetic declination must be taken into account.
     
     - Parameters:
        - beltOrientation: The new information on belt orientation.
     */
    func onBeltOrientationNotified(beltOrientation: FSBeltOrientation)
}

/**
 Default implementations of optional methods for the `FSCommandDelegate`
 protocol.
 */
public extension FSCommandDelegate {
    
    func onDefaultIntensityChanged(_ defaultIntensity: Int) {
        // Do nothing when not overridden
    }
    
    func onBeltBatteryStatusUpdated(_ status: FSBatteryStatus) {
        // Do nothing when not overridden
    }
    
    func onBeltOrientationNotified(beltOrientation: FSBeltOrientation) {
        // Do nothing when not overridden
    }
    
    func onHeadingOffsetChanged(_ headingOffset: Int) {
        // Do nothing when not overridden
    }
 
}

/**
 Values representing the mode ofthe belt.
 */
public enum FSBeltMode: UInt8 {
    /** The mode is not yet known. */
    case unknown = 0xFF
    /** The belt is in standby (and will disconnect). */
    case standby = 0x00
    /** Wait mode. */
    case wait = 0x01
    /** Compass mode. */
    case compass = 0x02
    /** App mode (controlled by the app).*/
    case app = 0x03
    /** Pause mode (no vibration). */
    case pause = 0x04
    /** Calibration mode. */
    case calibration = 0x05
    /** Crossing mode. */
    case crossing = 0x06
}

/**
 Values representing the buttons on the belt.
 */
public enum FSBeltButton: UInt8 {
    /** Power button. */
    case power = 0x01
    /** Pause button. */
    case pause = 0x02
    /** Compass button. */
    case compass = 0x03
    /** Home button. */
    case home = 0x04
}

/** Values representing the types of button press. */
public enum FSPressType: UInt8 {
    /** Short press. */
    case shortPress = 0x01
    /** Long press. */
    case longPress = 0x02
}
