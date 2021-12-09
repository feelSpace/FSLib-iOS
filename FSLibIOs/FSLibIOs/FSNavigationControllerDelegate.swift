//
//  NavigationControllerDelegate.swift
//  FSLibIOs
//
//  Created by David on 15.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Callbacks of the `FSNavigationController`.
 */
@objc public protocol FSNavigationControllerDelegate {
    
    /**
     Called when the navigation state changed.
     
     The state may be changed by the application or with a button press on the
     belt.
     - Parameters:
        - state: The new state of the navigation controller.
     */
    func onNavigationStateChange(state: FSNavigationState)
    
    /**
     Called when the home button on the belt has been pressed and does not
     result in resuming the navigation.
     
     - Parameters:
        - navigating: `true` if the navigation state was `.navigating` when the
     button was pressed.
     */
    func onBeltHomeButtonPressed(navigating: Bool)
    
    /**
     Called when the default vibration intensity of the belt has been changed.
     
     The intensity can be changed by the application or using buttons on the
     belt.
     
     - Parameters:
        - intensity: The new default vibration intensity.
     */
    func onBeltDefaultVibrationIntensityChanged(intensity: Int)
    
    /**
     Called when the orientation of the belt has been updated.
     
     - Parameters:
        - beltHeading: The belt magnetic heading in degrees. Angles are
     clockwise.
        - accurate: The orientation acuracy flag.
     */
    func onBeltOrientationUpdated(beltHeading: Int, accurate: Bool)
    
    /**
     Called when the value of the battery level of the belt has been updated.
     
     - Parameters:
        - batteryLevel: The battery level of the belt in percent.
        - status: The power status of the belt.
     */
    func onBeltBatteryLevelUpdated(batteryLevel: Int, status: FSPowerStatus)
    
    /**
     Called when the state of the compass accuracy signal has been retrieved or
     changed.
     
     - Parameters:
        - enabled: `true` if the compass accuracy signal is enabled, `false`
     otherwise.
     */
    func onCompassAccuracySignalStateUpdated(enabled: Bool)
    
    /**
     Indicates that a belt has been found.
     
     - Parameters:
        - belt: The belt found.
        - status: The status of the belt.
     */
    func onBeltFound(belt: CBPeripheral, status: FSBeltConnectionStatus)
    
    /**
     Indicates that the connection state has changed.
     
     - Parameters:
        - state: The new state.
        - error: The error or `.noError`.
     */
    func onConnectionStateChanged(
        state: FSBeltConnectionState,
        error: FSBeltConnectionError)
    
}
