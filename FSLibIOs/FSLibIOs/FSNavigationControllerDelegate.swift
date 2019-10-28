//
//  NavigationControllerDelegate.swift
//  FSLibIOs
//
//  Created by David on 15.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation

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
     Called when the connection state has changed.
     
     - Parameters:
        - state: The new connection state.
     */
    func onBeltConnectionStateChanged(state: FSBeltConnectionState)
    
    /**
     Called when a connection attempt failed because BLE is not available on
     the device.
     */
    func onBluetoothNotAvailable()
    
    /**
     Called when a connection attempt failed because BLE is not powered on.
     */
    func onBluetoothPoweredOff()
    
    /**
     Called when the connection with the belt has been unexpectedly lost.
     */
    func onBeltConnectionLost()
    
    /**
     Called when the connection with a belt failed.
     */
    func onBeltConnectionFailed()
    
    /**
     Called when no belt has been found to start the connection.
     */
    func onNoBeltFound()
    
}
