//
//  FSBeltDataPacket.swift
//  FSLibIOs
//
//  Created by David on 08/09/17.
//  Copyright © 2017-2019 feelSpace. All rights reserved.
//

import Foundation

/**
 Definition of data packet to be used by the command manager.
 */
class FSCommandDataPacket {
    
    //MARK: Properties
    
    /** Data packet for a single warning signal. */
    static let WARNING_SIGNAL_DATA_PACKET = Data([
        0x20,  // System signal request
        0x00   // Warning signal
        ])
    
    /** Data packet for a battery signal. */
    static let BATTERY_SIGNAL_DATA_PACKET = Data([
        0x20,  // System signal request
        0x02   // Battery signal
        ])
    
    static let GOAL_REACHED_SIGNAL_DATA_PACKET = Data([
        0x20,  // System signal request
        0x01   // Battery signal
        ])
    
    /** Data packet for stoppng all channels in app mode. */
    static let STOP_ALL_CHANNEL_DATA_PACKET = Data([
        0x30,  // Stop channel command
        0xFF   // All channels
        ])
    
    /** Returns the LByte of the intensity. */
    internal static func getIntensityLByte(_ intensity: Int) -> UInt8 {
        if (intensity == -1) {
            return 0xAA
        }
        if (intensity > 100) {
            return 0x64
        }
        return UInt8(intensity)
    }
    
    //MARK: Private methods
    
    /** Returns the MByte of the intensity. */
    internal static func getIntensityMByte(_ intensity: Int) -> UInt8 {
        if (intensity == -1) {
            return 0xAA
        }
        return 0x00
    }
    
    /** Returns the direction LByte from the direction value. */
    internal static func getDirectionLByte(_ direction: Float) -> UInt8 {
        if (direction < 0) {
            return UInt8(UInt16((Int(direction)%360)+360) & 0x00FF)
        } else {
            return UInt8(UInt16(Int(direction)%360) & 0x00FF)
        }
    }
    
    /** Returns the direction MByte from the direction value. */
    internal static func getDirectionMByte(_ direction: Float) -> UInt8 {
        if (direction < 0) {
            return UInt8(UInt16((Int(direction)%360)+360) >> 8)
        } else {
            return UInt8(UInt16(Int(direction)%360) >> 8)
        }
    }
    
    //MARK: Public methods
    
    /**
     Generates a data packet for stopping the vibration in app mode.
     
     - Parameters:
        - channelIndex: The channel index to stop or -1 for stopping all
     channels.
     */
    static func getStopChannelDataPacket(_ channelIndex: Int = -1) -> Data {
        if (channelIndex == -1) {
            return STOP_ALL_CHANNEL_DATA_PACKET
        } else {
            return Data([
                0x30,  // Stop channel command
                UInt8(channelIndex)   // Channel
                ])
        }
    }
    
    /**
     Generates a data packet for a vibration signal.
     */
    static func getVibrationSignalDataPacket(
        signal: FSVibrationSignal,
        direction: Float, isBearing: Bool,
        intensity: Int = -1, channelIndex: Int = 1,
        stopOtherChannels: Bool = false) -> Data {
        
        switch signal {
            
        case .continuous:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .continuous,
                intensity: intensity,
                orientationType: (isBearing ?
                    FSOrientationType.magneticBearing :
                    FSOrientationType.angle),
                orientation: Int(direction),
                patternIterations: -1,
                patternPeriod: 500,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        case .navigation:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .continuous,
                intensity: intensity,
                orientationType: (isBearing ?
                    FSOrientationType.magneticBearing :
                    FSOrientationType.angle),
                orientation: Int(direction),
                patternIterations: -1,
                patternPeriod: 500,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        case .destinationReachedRepeated:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .goalReached,
                intensity: intensity,
                orientationType: .vibromotorIndex,
                orientation: 0,
                patternIterations: -1,
                patternPeriod: 5000,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        case .destinationReached:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .goalReached,
                intensity: intensity,
                orientationType: .vibromotorIndex,
                orientation: 0,
                patternIterations: 1,
                patternPeriod: 2500,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        case .approachingDestination:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .singleLong,
                intensity: intensity,
                orientationType: (isBearing ?
                    FSOrientationType.magneticBearing :
                    FSOrientationType.angle),
                orientation: Int(direction),
                patternIterations: -1,
                patternPeriod: 1000,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        case .directionNotification:
            return getVibrationChannelConfigurationDataPacket(
                channelIndex: channelIndex,
                pattern: .continuous,
                intensity: intensity,
                orientationType: (isBearing ?
                    FSOrientationType.magneticBearing :
                    FSOrientationType.angle),
                orientation: Int(direction),
                patternIterations: 1,
                patternPeriod: 1000,
                patternStartTime: 0,
                exclusiveChannel: false,
                clearOtherChannels: stopOtherChannels)
            
        }
    }
    
    /**
     Generates a vibration-channel configuration packet.
     */
    static func getVibrationChannelConfigurationDataPacket(
        channelIndex: Int,
        pattern: FSVibrationPattern,
        intensity: Int,
        orientationType: FSOrientationType,
        orientation: Int,
        patternIterations: Int,
        patternPeriod: Int,
        patternStartTime: Int,
        exclusiveChannel: Bool,
        clearOtherChannels: Bool) -> Data {
        var patternByte: UInt8
        patternByte = pattern.rawValue
        var orientationLByte: UInt8
        var orientationMByte: UInt8
        switch orientationType {
        case .binaryMask:
            orientationLByte = UInt8(orientation & 0xFF)
            orientationMByte = UInt8((orientation>>8) & 0xFF)
        case .vibromotorIndex:
            var index = orientation%16
            if (index < 0) {
                index += 16
            }
            orientationLByte = UInt8(index & 0xFF)
            orientationMByte = 0x00
        case .angle, .magneticBearing:
            var angle = orientation%360
            if (angle < 0) {
                angle += 360
            }
            orientationLByte = UInt8(angle & 0xFF)
            orientationMByte = UInt8((angle>>8) & 0xFF)
        }
        var iterationsByte: UInt8
        if (patternIterations < 0) {
            iterationsByte = 0xFF
        } else {
            iterationsByte = UInt8(patternIterations & 0xFF)
        }
        let periodLByte = UInt8(patternPeriod & 0xFF)
        let periodMByte = UInt8((patternPeriod>>8) & 0xFF)
        var start = patternStartTime%patternPeriod
        if (start < 0) {
            start += patternPeriod
        }
        let startLByte = UInt8(start & 0xFF)
        let startMByte = UInt8((start>>8) & 0xFF)
        return Data([
            UInt8(channelIndex),    // Channel
            patternByte,            // Pattern
            getIntensityLByte(intensity), // Intensity L
            getIntensityMByte(intensity), // Intensity M
            0x00,                   // RFU
            0x00,                   // RFU
            orientationType.rawValue, // Orientation type
            orientationLByte,       // Orientation L
            orientationMByte,       // Orientation M
            0x00,                   // RFU
            0x00,                   // RFU
            iterationsByte,         // Iterations
            periodLByte,            // Period L
            periodMByte,            // Period M
            startLByte,             // Delay L
            startMByte,             // Delay M
            (exclusiveChannel ? 0x01 : 0x00), // Channel combination
            (clearOtherChannels ? 0x01 : 0x00) // Clear other channels
            ])
    }
    
}
