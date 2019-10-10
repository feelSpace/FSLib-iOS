//
//  VibrationSignal.swift
//  FSLibIOs
//
//  Created by David on 10.10.19.
//  Copyright © 2019 feelSpace. All rights reserved.
//

import Foundation

/**
 Enumeration of predefined vibration signals.
 
 This enumeration contains all types of signal. A vibration signal can be
 either repeated indefinitely or temporary, and it can be oriented or
 non-oriented. The functions `isRepeated(...)` and `isDirectional(...)` allow to
 test the type of signal.
 */
@objc public enum BeltVibrationSignal: Int {
    
    /**
     Continuous vibration.
     */
    case continuous;
    
    /**
     Continuous vibration for the navigation.
     */
    case navigation;
    
    /**
     Fast vibration pulse indicating that the destination is nearby. This signal
     must be oriented to the destination.
     */
    case approachingDestination;
    
    /**
     Fast vibration pulse indicating the direction during a maneuver.
     */
    case turnOngoing;
    
    /**
     A vibration signal to indicate a direction for a short period of time.
     */
    case directionNotification;
    
    /**
     A slow vibration pulse to indicate the direction when the next waypoint is
     far away.
     */
    case nextWaypointLongDistance;
    
    /**
     A vibration pulse to indicate the navigation direction when the next
     waypoint is at medium distance.
     */
    case nextWaypointMediumDistance;
    
    /**
     A vibration pulse to indicate the navigation direction when the next
     waypoint is at short distance.
     */
    case nextWaypointShortDistance;
    
    /**
     A fast vibration pulse to indicate the navigation direction when in the
     close area of a waypoint.
     */
    case nextWaypointAreaReached;
    
    /**
     A non-oriented vibration pattern indicating that the destination has been
     reached. The signal is repeated indefinitely.
     */
    case destinationReachedRepeated;
    
    /**
     A non-oriented vibration pattern indicating that the destination has been
     reached. The signal pattern is performed only one time.
     */
    case destinationReachedSingle;
    
    /**
     A light warning signal to use when an operation is not permitted or cannot
     be performed. It is recommended to use channel 0 and an intensity of 25 for
     this signal.
     */
    case operationWarning;
    
    /**
     A strong warning signal to indicate a critical problem such as compass
     inaccuracy during navigation. It is recommended to use channel 0 for this
     signal.
     */
    case criticalWarning;
    
    /**
     A system signal that indicates with a vibration the level of the belt's
     battery. Any customization of this signal (intensity, channel and stop
     other channel flag) will be ignored. The signal use the channel 0 and the
     default intensity. Other channels are not stopped when the signal is
     started.
     */
    case batteryLevel;
    
}

/**
 Returns `true` if the vibration signal is repeated indefinitly or `false` if
 the signal is temporary.
 - Returns: `true` if the vibration signal is repeated indefinitly or `false` if
 the signal is temporary.
 - Parameters:
    - signal: The vibration signal.
 */
func isRepeated(_ signal: BeltVibrationSignal) -> Bool {
    switch signal {
    case .continuous, .navigation, .approachingDestination,
         .turnOngoing, .nextWaypointLongDistance, .nextWaypointMediumDistance,
         .nextWaypointShortDistance, .nextWaypointAreaReached,
         .destinationReachedRepeated:
        return true
    default:
        return false
    }
}

/**
 Returns `true` if the vibration signal is directional, i.e. it can be oriented
 in a direction.
 - Returns: `true` if the vibration signal is directional, i.e. it can be
 oriented in a direction.
 */
func isDirectional(_ signal: BeltVibrationSignal) -> Bool {
    switch signal {
    case .continuous, .navigation, .approachingDestination,
         .turnOngoing, .directionNotification, .nextWaypointLongDistance,
         .nextWaypointMediumDistance, .nextWaypointShortDistance,
         .nextWaypointAreaReached:
        return true
    default:
        return false
    }
}
