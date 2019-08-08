//
//  FSCommandManager.swift
//  FSLibIOs
//
//  Created by David on 21/05/17.
//  Copyright © 2017-2019 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 The `FSCommandManager` is an interface for controling the belt.
 */
public class FSCommandManager: NSObject, CBPeripheralDelegate {
    
    //MARK: Public properties
    
    /** Belt control service UUID. */
    public static let BELT_CONTROL_SERVICE_UUID = CBUUID(string: "FE51")
    
    /** Firmware information characteristic UUID. */
    public static let FIRMWARE_INFO_CHAR_UUID = CBUUID(string: "FE01")
    
    /** Keep alive characteristic UUID. */
    public static let KEEP_ALIVE_CHAR_UUID = CBUUID(string: "FE02")
    
    /** Vibration command characteristic UUID. */
    public static let VIBRATION_COMMAND_CHAR_UUID = CBUUID(string: "FE03")
    
    /** Button press notification characteristic UUID. */
    public static let BUTTON_PRESS_NOTIFICATION_CHAR_UUID =
        CBUUID(string: "FE04")
    
    /** Parameter request characteristic UUID. */
    public static let PARAMETER_REQUEST_CHAR_UUID = CBUUID(string: "FE05")
    
    /** Parameter notification characteristic UUID. */
    public static let PARAMETER_NOTIFICATION_CHAR_UUID = CBUUID(string: "FE06")
    
    /** Battery status characteristic UUID. */
    public static let BATTERY_STATUS_CHAR_UUID = CBUUID(string: "FE09")
    
    /** Sensor service UUID. */
    public static let BELT_SENSOR_SERVICE_UUID = CBUUID(string: "FE52")
    
    /** Orientation data notification characteristic UUID. */
    public static let ORIENTATION_DATA_NOTIFICATION_CHAR_UUID = CBUUID(string: "FE0C")
    
    /** Belt debug service UUID. */
    public static let BELT_DEBUG_SERVICE_UUID = CBUUID(string: "FE53")
    
    /** Belt debug input characteristic UUID. */
    public static let BELT_DEBUG_INPUT_CHAR_UUID = CBUUID(string: "FE13")
    
    /** Belt debug output characteristic UUID. */
    public static let BELT_DEBUG_OUTPUT_CHAR_UUID = CBUUID(string: "FE14")
    
    /**
     Delegate of the command manager.
     
     The delegate receives callbacks from the command manager when a parameter
     changed (e.g. default intensity or belt mode) and when a button on the belt
     is pressed.
     */
    public var delegate: FSCommandDelegate? = nil
    
    /**
     The mode of the belt.
     
     The mode can be changed by sending a request to the belt with 
     `requestBeltModeChange`.
     */
    public private(set) var mode: FSBeltMode = .unknown;
    
    /**
     The default vibration intensity.
     
     A value of `-1` indicates that the default intensity is unknown. The 
     default intensity can be changed by sending a request with
     `requestDefaultIntensityChange`.
     */
    public private(set) var defaultIntensity: Int = -1;
    
    /**
     The firmware version of the belt.
     
     This value is only valid when the belt is connected. A value of `-1` 
     indicates that the firmware version has not yet been retrieved.
     */
    public private(set) var firmwareVersion: Int = -1;
    
    /**
     The battery status of the belt.
     */
    public private(set) var beltBatteryStatus: FSBatteryStatus =
        FSBatteryStatus();
    
    /**
     Status of orientation notifications.
     */
    public var orientationNotifEnabled: Bool {
        if (orientationDataNotificationChar == nil) {
            return false
        }
        return orientationDataNotificationChar!.isNotifying
    }
    
    /**
     Minimum period, in seconds, between two notifications of the belt's
     orientation. If the value is negative or null, all notifications received
     from the belt will be transmitted to the delegate.
     */
    public private(set) var orientationNotifMinPeriod: Double = 0
    
    /**
     Minimum variation, in degrees, of the belt heading to notify the delegate
     of an orientation change. If the value is negative or null, all
     notifications received from the belt will be transmitted to the delegate.
     */
    public private(set) var orientationNotifMinHeadingVariation: Int = 0
    
    /**
     Information on the orientation of the belt. This variable is updated only
     when the notifications for orientation are enabled.
     */
    public private(set) var beltOrientation: FSBeltOrientation? = nil
    
    /**
     Heading offset of the belt in degrees.
     
     This value, stored in the belt, represents the angle difference between the
     heading of the belt and the heading of the belt's control box. The default
     value on the belt is 45°.
     */
    public private(set) var beltHeadingOffset: Int? = nil
    
    //MARK: Private properties
    
    // Connection manager
    private var connectionManager: FSConnectionManager!
    
    // Belt
    private var belt: CBPeripheral? = nil
    
    // Belt control service
    private var beltControlService: CBService?
    private var firmwareInfoChar: CBCharacteristic?
    private var keepAliveChar: CBCharacteristic?
    private var vibrationCommandChar: CBCharacteristic?
    private var buttonPressNotificationChar: CBCharacteristic?
    private var parameterRequestChar: CBCharacteristic?
    private var parameterNotificationChar: CBCharacteristic?
    private var batteryStatusChar: CBCharacteristic?
    
    // Sensor service
    private var beltSensorService: CBService?
    private var orientationDataNotificationChar: CBCharacteristic?
    
    // Debug service
    private var beltDebugService: CBService?
    private var beltDebugInputChar: CBCharacteristic?
    private var beltDebugOutputChar: CBCharacteristic?
    
    // Active notifications
    private var keepAliveCharRegistered: Bool = false
    private var parameterNotificationCharRegistered: Bool = false
    private var buttonPressNotificationCharRegistered: Bool = false
    private var beltDebugOutputCharRegistered: Bool = false
    private var batteryStatusCharRegistered: Bool = false
    
    // BLE operation queue
    private var operationQueue: FSBleOperationQueue = FSBleOperationQueue()
    
    // Date of the last notification send to the delegate
    private var orientationLastDelegateNotif: Double = 0
    
    // Last notified belt orientation
    private var orientationLastNotif: Int? = nil
    
    // Heading value of the last orientation notified (for filter)
    private var lastNotifiedBeltMagHeading: Int? = nil
    
    //MARK: Methods
    
    // Can only be instantiated by the connection manager
    private override init() {}
    internal init(_ owner: FSConnectionManager) {
        connectionManager = owner
    }
    
    /**
     Sends a request to the belt for changing the mode.
     
     The mode will be changed asynchronously if the request is accepted by the 
     belt. The change will be effective when the belt acknowledge the request. 
     The delegate is informed of the effective mode change through a call to 
     `onBeltModeChanged`.
     
     - Parameters:
        - requestedBeltMode: The requested mode.
     
     - Returns:
     `true` if the request has been sent, `false` otherwise. A request is not 
     sent if no belt is connected, or if the requested mode is `unknown` or
     `calibration`.
     */
    public func changeBeltMode(_ requestedBeltMode: FSBeltMode) -> Bool {
        if (connectionManager.state != .connected ||
            requestedBeltMode == .unknown ||
            requestedBeltMode == .calibration) {
            return false
        }
        // Send parameter change request
        if let characteristic = parameterRequestChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x01,
                             FSBeltParameter.mode.rawValue | 0x80,
                             requestedBeltMode.rawValue,
                             0x00])
            ))
            return true
        } else {
            return false
        }
    }
    
    /**
     Sends a request to the belt for changing the default vibration intensity.
     
     The default intensity value will be changed asynchronously. The delegate
     receives a notification through `onDefaultIntensityChanged` when the new
     intensity is effective. The belt may reject or adjust the intensity value.
     
     - Parameters:
        - requestedDefaultIntensity: The requested default intensity in range 
     [0 - 100].
        - feedbackSignal: `true` to provide a vibration feedback when the 
     intensity is changed.
     
     - Returns:
     `true` if the request has been sent, `false` otherwise. A request is not
     sent if no belt is connected, or if the intensity is not in range 
     [0 - 100].
     */
    public func changeDefaultIntensity (
        _ requestedDefaultIntensity: Int, feedbackSignal: Bool = true) -> Bool {
        if (connectionManager.state != .connected ||
            requestedDefaultIntensity < 0 ||
            requestedDefaultIntensity > 100) {
            return false
        }
        // Send request for changing intensity
        if let characteristic = parameterRequestChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x01,
                             FSBeltParameter.defaultIntensity.rawValue | 0x80,
                             UInt8(requestedDefaultIntensity),
                             0x00,
                             (feedbackSignal) ? (0x01) : (0x00)])
            ))
            return true
        } else {
            return false
        }
    }
    
    /**
     Sends a request to the belt for changing the heading offset.
     
     The heading offset value will be changed asynchronously. The delegate
     receives a notification through `onHeadingOffsetChanged` when the new
     offset is effective. The belt may reject or adjust the offset value.
     
     - Parameters:
        - requestedHeadingOffset: The requested heading offset in degrees in
     range [0 - 359].
     
     - Returns:
     `true` if the request has been sent, `false` otherwise. A request is not
     sent if no belt is connected, or if the offset is not in range
     [0 - 359].
     */
    public func changeHeadingOffset (_ requestedHeadingOffset: Int) -> Bool {
        if (connectionManager.state != .connected ||
            requestedHeadingOffset < 0 ||
            requestedHeadingOffset > 359) {
            return false
        }
        // Send request for heading offset
        if let characteristic = parameterRequestChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x01,
                             FSBeltParameter.headingOffset.rawValue | 0x80,
                             UInt8(requestedHeadingOffset & 0xFF),
                             UInt8((requestedHeadingOffset >> 8) & 0xFF)])
            ))
            return true
        } else {
            return false
        }
    }
    
    /**
     Makes the belt vibrate toward a direction relative to the magnetic North.
     The vibration will be effective only in app mode.
     
     - Parameters:
        - direction: The relative direction of the vibration in degrees. The 
     value 0 represents the magnetic north and positive angles are considered 
     clockwise.
        - intensity: The intensity of the vibration from 0 to 100 or -1 to
     use the default intensity of the belt.
        - signal: The type of vibration signal.
        - channelIndex The channel of the vibration (to manage multiple 
     vibrations).
        - stopOtherChannels `true` to stop vibration on other channels.
     - Returns: `true` if the command has been sent.
     */
    public func vibrateAtMagneticBearing(direction: Float, intensity: Int = -1,
                signal: FSVibrationSignal = .continuous,
                channelIndex: Int = 1,
                stopOtherChannels: Bool = false
        ) -> Bool {
        if (connectionManager.state != .connected || intensity < -1) {
            return false
        }
        if (intensity == 0) {
            return stopVibration(channelIndex)
        }
        
        if let characteristic = vibrationCommandChar, let peripheral = belt {
            // Generate and send packet
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: FSCommandDataPacket
                    .getVibrationSignalDataPacket(
                        signal: signal,
                        direction: direction, isBearing: true,
                        intensity: intensity, channelIndex: channelIndex,
                        stopOtherChannels: stopOtherChannels)))
            return true
        }
        return false
    }
    
    /**
     Makes the belt vibrate at a specific place (vibro-motor) given by an angle.
     Positive angles are clockwise. The vibration will be effective only in app
     mode.
     
     - Parameters:
        - angle: The angle in degrees at which the belt must vibrate. The value 
     0 represents the 'heading' of the belt, and positive angles are clockwise.
        - intensity: The intensity of the vibration from 0 to 100 or -1 to
     use the default intensity of the belt.
        - signal: The type of vibration signal.
        - channelIndex The channel of the vibration (to manage multiple
     vibrations).
        - stopOtherChannels `true` to stop vibration on other channels.
     - Returns: `true` if the command has been sent.
     */
    public func vibrateAtAngle(angle: Float, intensity: Int = -1,
                               signal: FSVibrationSignal = .continuous,
                               channelIndex: Int = 1,
                               stopOtherChannels: Bool = false
        ) -> Bool {
        if (connectionManager.state != .connected || intensity < -1) {
            return false
        }
        if (intensity == 0) {
            return stopVibration(channelIndex)
        }
        
        if let characteristic = vibrationCommandChar, let peripheral = belt {
            // Generate and send packet
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: FSCommandDataPacket.getVibrationSignalDataPacket(
                    signal: signal,
                    direction: angle,
                    isBearing: false,
                    intensity: intensity,
                    channelIndex: channelIndex,
                    stopOtherChannels: stopOtherChannels)))
            return true
        }
        return false
    }
    
    /**
     Configures a vibration-channel of the belt.
     
     - Important: A vibration-channel configuration is accepted by the belt if
     the belt is in App-mode, or if 1) the channel index is 0 and 2) the number
     of iteration is limited and 3) the other channels are not cleared.
     
     - Parameters:
        - channelIndex: The channel index to configure. The belt has four
     channels (index 0 to 3).
        - pattern: The vibration pattern to use.
        - intensity: The vibration intensity in range [0-100] or -1 to use the
     default vibration intensity.
        - orientationType: The type of orientation value.
        - orientation: The orientation value.
        - patternIterations: The number of iterations of the vibration pattern
     or -1 to repeat indefinitively the vibration pattern. The maximum value is
     255 iterations.
        - patternPeriod: The duration in milliseconds of one pattern iteration.
     The maximum period is 65535 milliseconds.
        - patternStartTime: The starting time in milliseconds of the first
     pattern iteration.
        - exclusiveChannel: `true` to suspend other channels as long as this
     vibration-channel is used.
        - clearOtherChannels: `true` to stop and clear other channels when this
     vibration-channel configuration is applied.
     - Returns: `false` in case of immediate failure of the command (no
     connection or invalid parameter).
     */
    public func configureVibrationChannel(channelIndex: Int,
                                          pattern: FSVibrationPattern,
                                          intensity: Int = -1,
                                          orientationType: FSOrientationType,
                                          orientation: Int,
                                          patternIterations: Int,
                                          patternPeriod: Int,
                                          patternStartTime: Int = 0,
                                          exclusiveChannel: Bool,
                                          clearOtherChannels: Bool) -> Bool {
        if (connectionManager.state != .connected) {
            print("Cannot send vibration-channel configuration without " +
                "connection.")
            return false
        }
        if (intensity < -1 || channelIndex < 0 || channelIndex >= 6 ||
            patternIterations < -1 || patternPeriod < 0 ||
            patternPeriod > 65535) {
            print("Invalid parameter value for vibration-channel " +
                "configuration.")
            return false
        }
        if let characteristic = vibrationCommandChar, let peripheral = belt {
            // Generate and send packet
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: FSCommandDataPacket
                    .getVibrationChannelConfigurationDataPacket(
                        channelIndex: channelIndex,
                        pattern: pattern,
                        intensity: intensity,
                        orientationType: orientationType,
                        orientation: orientation,
                        patternIterations: patternIterations,
                        patternPeriod: patternPeriod,
                        patternStartTime: patternStartTime,
                        exclusiveChannel: exclusiveChannel,
                        clearOtherChannels: clearOtherChannels)))
            return true
        }
        print("No characteristic or peripheral for vibration-channel " +
            "configuration.")
        return false
    }
    
    /**
     Starts a 'system' vibration signal.
     
     - Parameters:
        - signal: The vibration signal to start.
     - Returns: `true` if the command has been sent.
     */
    public func signal(signalType: FSSystemSignal) -> Bool {
        // Check parameters
        if (connectionManager.state != .connected) {
            return false
        }
        
        if let characteristic = vibrationCommandChar, let peripheral = belt {
            // Send packet
            switch signalType {
                
            case .warning:
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: FSCommandDataPacket.WARNING_SIGNAL_DATA_PACKET))
                
            case .battery:
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: FSCommandDataPacket.BATTERY_SIGNAL_DATA_PACKET))
                
            case .goalReached:
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: FSCommandDataPacket.GOAL_REACHED_SIGNAL_DATA_PACKET))
            }
            return true
        } else {
            return false
        }
    }
    
    /**
     Stops the vibration for one or all channels. This method only stop
     vibration signals for the app mode.
     - Parameters:
        - channelIndex: The channel index to stop or -1 for stopping all 
     channels.
     - Returns: `true` if the command has been sent.
     */
    public func stopVibration(_ channelIndex: Int = -1) -> Bool {
        if (connectionManager.state != .connected || channelIndex < -1) {
            return false
        }
        // Send command
        if let characteristic = vibrationCommandChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: FSCommandDataPacket
                    .getStopChannelDataPacket(channelIndex)))
            return true
        } else {
            return false
        }
    }
    
    /**
     Starts notifications of the belt orientation.
     
     This method must be called only when the connection state is `connected`.
     If the connection state is not `connected`, the request to start
     notifications will fail.
     
     - Parameters:
         - minPeriod: Minimum period, in seconds, between orientation's
     notifications transmitted to the delegate. This parameter filters the
     notifications received from the belt. A notification is transmitted to the
     delegate only if the time since the previous notification is greater than
     or equal to 'minPeriod'. To obtain all notifications, the value of this
     parameter must be 0.
         - minHeadingVariation: Minimum variation, in degrees, of the belt
     heading to notify the delegate of an orientation change. This parameter
     filters the notifications received from the belt. A notification is
     transmitted to the delegate only if the heading variation since the
     previous notification is greater than or equal to 'minHeadingVariation'. To
     obtain all notifications, the value of this parameter must be 0.
     - Returns: `true` if the request for starting notifications has been
     successfully sent.
     */
    public func startOrientationNotifications(
        minPeriod: Double = 0, minHeadingVariation: Int = 0) -> Bool {
        if (connectionManager.state != .connected) {
            return false
        }
        // Set filter parameters
        orientationNotifMinPeriod = minPeriod
        orientationNotifMinHeadingVariation = minHeadingVariation
        // Register to characteristic notifications
        if let characteristic = orientationDataNotificationChar,
            let peripheral = belt {
            operationQueue.add(FSBleOperationSetNotifyValue(
                peripheral: peripheral, characteristic: characteristic,
                notify: true))
        } else {
            return false
        }
        return true
    }
    
    /**
     Stops notifications of the belt orientation.
     
     - Returns: `true` if the request for stoping notifications has been
     successfully sent.
     */
    public func stopOrientationNotifications() -> Bool {
        if (connectionManager.state != .connected) {
            return false
        }
        // Reset notification parameters
        orientationNotifMinPeriod = 0
        orientationNotifMinHeadingVariation = 0
        // Unregister to characteristic notifications
        if let characteristic = orientationDataNotificationChar,
            let peripheral = belt {
            operationQueue.add(FSBleOperationSetNotifyValue(
                peripheral: peripheral, characteristic: characteristic,
                notify: false))
        } else {
            return false
        }
        return true
    }
    
    /**
     Sends debug data to the belt.
     - Important: This is only for firmware debug purpose.
     - Parameters:
        - debugData: The debug data to send.
     - Returns: `true` if the command has been sent.
     */
    public func sendDebugData(_ debugData: Data) -> Bool {
        if (connectionManager.state != .connected) {
            return false
        }
        // Send data
        if let characteristic = beltDebugInputChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: debugData))
            return true
        } else {
            return false
        }
    }
    
    // Clears all reference to GATT services and characteristics (to disconnect)
    internal func clearGattReference() {
        beltControlService = nil
        firmwareInfoChar = nil
        keepAliveChar = nil
        vibrationCommandChar = nil
        buttonPressNotificationChar = nil
        parameterRequestChar = nil
        parameterNotificationChar = nil
        batteryStatusChar = nil
        beltSensorService = nil
        orientationDataNotificationChar = nil
        beltDebugService = nil
        beltDebugInputChar = nil
        beltDebugOutputChar = nil
        // Registration to notification
        keepAliveCharRegistered = false
        parameterNotificationCharRegistered = false
        buttonPressNotificationCharRegistered = false
        beltDebugOutputCharRegistered = false
        // Reset belt mode
        mode = .unknown
        // Reset default intensity
        defaultIntensity = -1
        // Reset firmware version
        firmwareVersion = -1
        // Reset battery status
        beltBatteryStatus.powerStatus = .unknown
        beltBatteryStatus.batteryLevel = -1.0
        beltBatteryStatus.batteryTteTtf = -1.0
        // Reset belt orientation
        beltOrientation = nil
        orientationLastNotif = nil
        lastNotifiedBeltMagHeading = nil
        // Reset offset parameter
        beltHeadingOffset = nil
        // Remove reference to belt
        belt = nil
        // Clear operation queue
        operationQueue.clear()
    }
    
    // Called by the connection manager to start service discovery
    internal func discoverServices(_ device: CBPeripheral) {
        clearGattReference()
        // Reference to belt
        belt = device
        // Register as delegate
        belt!.delegate = self
        // Start service discovery
        belt!.discoverServices([FSCommandManager.BELT_CONTROL_SERVICE_UUID,
                                FSCommandManager.BELT_SENSOR_SERVICE_UUID,
                               FSCommandManager.BELT_DEBUG_SERVICE_UUID])
    }
    
    // Sends a parameter request to get the belt mode, returns true if success
    internal func requestBeltMode() -> Bool {
        if let characteristic = parameterRequestChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x01, FSBeltParameter.mode.rawValue])))
            return true
        } else {
            return false
        }
    }
    
    // Sends a parameter request to get the default intensity
    internal func requestDefaultIntensity() -> Bool {
        if let characteristic = parameterRequestChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x01, FSBeltParameter.defaultIntensity.rawValue])))
            return true
        } else {
            return false
        }
    }
    
    // Reads the firmware version value of the connected belt
    internal func readFirmwareVersion() -> Bool {
        if let characteristic = firmwareInfoChar, let peripheral = belt {
            operationQueue.add(FSBleOperationReadCharacteristic(
                peripheral: peripheral, characteristic: characteristic))
            return true
        } else {
            return false
        }
    }
    
    // Read the battery status characteristic of the connected belt
    internal func readBatteryStatus() -> Bool {
        if let characteristic = batteryStatusChar, let peripheral = belt {
            operationQueue.add(FSBleOperationReadCharacteristic(
                peripheral: peripheral, characteristic: characteristic))
            return true
        } else {
            return false
        }
    }
    
    // Retrieves the parameter value in a parameter notification packet
    internal func retrieveParametersFromPacket(_ parameterPacket: Data) {
        if (parameterPacket.count < 3) {
            // Invalid packet
            return
        }
        if let parameterID = FSBeltParameter(rawValue: parameterPacket[1]) {
            switch parameterID {
            case .mode:
                // Update and notify mode
                updateBeltMode(parameterPacket[2])
            case .defaultIntensity:
                // Update and notify new intensity
                updateDefaultIntensity(parameterPacket[2])
            case .headingOffset:
                // Update and notify heading offset
                if (parameterPacket.count < 4) {
                    // Invalid packet
                    return
                }
                updateHeadingOffset(
                    (UInt16(parameterPacket[3]) << 8) +
                        (UInt16(parameterPacket[2])) )
            default:
                // TODO Support backing and delegate's notification of other
                // parameters
                break
            }
        }
    }
    
    // Retrieves the battery status values from a packet
    internal func retrieveBatteryStatusFromPacket(_ batteryStatusPacket: Data) {
        if (batteryStatusPacket.count < 5) {
            // Invalid packet
            return
        }
        if let status = FSPowerStatus(rawValue: batteryStatusPacket[0]) {
            var batteryLevel: Double = (Double) (
                (UInt16(batteryStatusPacket[2]) << 8) +
                    (UInt16(batteryStatusPacket[1])));
            batteryLevel /= 256.0;
            var batteryTteTtf: Double = (Double) (
                (UInt16(batteryStatusPacket[2]) << 8) +
                    (UInt16(batteryStatusPacket[1])));
            batteryTteTtf *= 5.625;
            if (status != beltBatteryStatus.powerStatus ||
                batteryLevel != beltBatteryStatus.batteryLevel ||
                batteryTteTtf != beltBatteryStatus.batteryTteTtf) {
                beltBatteryStatus.powerStatus = status
                beltBatteryStatus.batteryLevel = batteryLevel
                beltBatteryStatus.batteryTteTtf = batteryTteTtf
                if (connectionManager.state == .connected) {
                    delegate?.onBeltBatteryStatusUpdated(beltBatteryStatus)
                }
            }
        }
    }
    
    // Processes a button press notification
    internal func processButtonPressPacket(_ buttonPressPacket: Data) {
        if (buttonPressPacket.count < 5) {
            // Invalid packet
            return
        }
        // Retrieve button press and inform delegate
        var pressType = FSPressType.shortPress
        if (buttonPressPacket[1] >= 0x03) {
            pressType = FSPressType.longPress
        }
        if let button = FSBeltButton(rawValue: buttonPressPacket[0]),
            let previousBeltMode = FSBeltMode(rawValue: buttonPressPacket[3]),
            let newBeltMode = FSBeltMode(rawValue: buttonPressPacket[4]) {
            // Set local belt mode
            mode = newBeltMode
            // Inform delegate of button press
            if (connectionManager.state == .connected) {
                delegate?.onBeltButtonPressed(button: button,
                                              pressType: pressType,
                                              previousMode: previousBeltMode,
                                              newMode: newBeltMode)
            }
        }
    }
    
    // Processes a keep alive notification
    internal func processKeepAliveNotification(_ keepAlivePacket: Data) {
        // Retrieve and set new mode
        if keepAlivePacket.count >= 2  {
            updateBeltMode(keepAlivePacket[1])
        }
        // Send keep alive response
        if let characteristic = keepAliveChar, let peripheral = belt {
            operationQueue.add(FSBleOperationWriteCharacteristic(
                peripheral: peripheral, characteristic: characteristic,
                value: Data([0x00])))
        }
    }
    
    // Sets the local belt mode and informs the delegate
    internal func updateBeltMode(_ rawBeltMode: UInt8) {
        if let newMode = FSBeltMode(rawValue: rawBeltMode) {
            if (newMode != mode) {
                mode = newMode
                if (connectionManager.state == .connected) {
                    delegate?.onBeltModeChanged(mode)
                }
            }
        }
    }
    
    // Sets the local default intensity and informs the delegate
    internal func updateDefaultIntensity(_ rawBeltIntensity: UInt8) {
        let newIntensity = Int(rawBeltIntensity)
        if (newIntensity != defaultIntensity) {
            defaultIntensity = newIntensity
            if (connectionManager.state == .connected) {
                delegate?.onDefaultIntensityChanged(defaultIntensity)
            }
        }
    }
    
    // Updates the heading offset value and informs the delegate
    internal func updateHeadingOffset(_ rawHeadingOffset: UInt16) {
        let newHeadingOffset = Int(rawHeadingOffset)
        if (newHeadingOffset != beltHeadingOffset) {
            beltHeadingOffset = newHeadingOffset
            if (connectionManager.state == .connected) {
                delegate?.onHeadingOffsetChanged(beltHeadingOffset!)
            }
        }
    }
    
    // Processes an orientation update
    internal func handleOrientationNotificationPacket(_ rawNotification: Data) {
        if (rawNotification.count < 16) {
            // Invalid packet
            return
        }
        // Only fusion notifications
        if (rawNotification[0] != 0x02) {
            return
        }
        // Retrieve and update belt heading value
        let beltMagHeading = (Int) (
            (UInt16(rawNotification[2]) << 8) +
                (UInt16(rawNotification[1]))
        );
        let beltCompassInaccurate = (rawNotification[15] != 0)
        beltOrientation = FSBeltOrientation(
            beltMagHeading: beltMagHeading,
            beltCompassInaccurate: beltCompassInaccurate)
        // Notification filter parameters
        var notifHeadingVariation = 0
        if (lastNotifiedBeltMagHeading != nil) {
            notifHeadingVariation = abs(
                lastNotifiedBeltMagHeading!-beltOrientation!.beltMagHeading)
        }
        let notifElapsedTime = Date().timeIntervalSince1970-orientationLastDelegateNotif
        // Check for delegate notification
        var notify = false
        if (connectionManager.state == .connected) {
            if (orientationLastNotif == nil) {
                notify = true;
            } else {
                notify = (notifHeadingVariation >=
                    orientationNotifMinHeadingVariation &&
                    notifElapsedTime >=
                    orientationNotifMinPeriod)
            }
        }
        if (notify) {
            orientationLastDelegateNotif = Date().timeIntervalSince1970
            lastNotifiedBeltMagHeading = beltMagHeading
            delegate?.onBeltOrientationNotified(
                beltOrientation: beltOrientation!)
        }
    }
    
    // *** CBPeripheralDelegate ***
    
    // Callback for service discovery
    final public func peripheral(_ peripheral: CBPeripheral,
                                 didDiscoverServices error: Error?) {
        // Check error
        if (error != nil) {
            // Failed to discover services
            connectionManager.clearConnection(.serviceDiscoveryFailed)
            return
        }
        
        // Check the list of services
        if (peripheral.services == nil ||
            peripheral.services?.count == 0) {
            // No service (wait for another callback until connection timeout)
            return
        }
        
        // Start characteristics discovery
        for service in peripheral.services! {
            if (service.uuid == FSCommandManager.BELT_CONTROL_SERVICE_UUID) {
                peripheral.discoverCharacteristics(
                    [FSCommandManager.FIRMWARE_INFO_CHAR_UUID,
                     FSCommandManager.KEEP_ALIVE_CHAR_UUID,
                     FSCommandManager.VIBRATION_COMMAND_CHAR_UUID,
                     FSCommandManager.BUTTON_PRESS_NOTIFICATION_CHAR_UUID,
                     FSCommandManager.PARAMETER_REQUEST_CHAR_UUID,
                     FSCommandManager.PARAMETER_NOTIFICATION_CHAR_UUID,
                     FSCommandManager.BATTERY_STATUS_CHAR_UUID],
                    for: service)
            } else if (service.uuid ==
                FSCommandManager.BELT_SENSOR_SERVICE_UUID) {
                peripheral.discoverCharacteristics(
                    [FSCommandManager.ORIENTATION_DATA_NOTIFICATION_CHAR_UUID],
                    for: service)
            } else if (service.uuid ==
                FSCommandManager.BELT_DEBUG_SERVICE_UUID) {
                peripheral.discoverCharacteristics(
                    [FSCommandManager.BELT_DEBUG_INPUT_CHAR_UUID,
                     FSCommandManager.BELT_DEBUG_OUTPUT_CHAR_UUID],
                    for: service)
            }
        }
    }
    
    // Callback for characteristic discovery
    final public func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        
        // Check error
        if (error != nil) {
            // Failed to discover characteristics
            connectionManager.clearConnection(.serviceDiscoveryFailed)
            return
        }
        
        // Keep reference to service and characteristics
        if (service.uuid == FSCommandManager.BELT_CONTROL_SERVICE_UUID) {
            beltControlService = service
            if (service.characteristics == nil ||
                service.characteristics?.count == 0) {
                // No characteristic discovered
                connectionManager.clearConnection(.serviceDiscoveryFailed)
                return
            }
            for characteristic in service.characteristics! {
                if (characteristic.uuid ==
                    FSCommandManager.FIRMWARE_INFO_CHAR_UUID) {
                    firmwareInfoChar = characteristic
                } else if (characteristic.uuid ==
                    FSCommandManager.KEEP_ALIVE_CHAR_UUID) {
                    keepAliveChar = characteristic
                    // Enable notification
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if (characteristic.uuid ==
                    FSCommandManager.VIBRATION_COMMAND_CHAR_UUID) {
                    vibrationCommandChar = characteristic
                } else if (characteristic.uuid ==
                    FSCommandManager.BUTTON_PRESS_NOTIFICATION_CHAR_UUID) {
                    buttonPressNotificationChar = characteristic
                    // Enable notification
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if (characteristic.uuid ==
                    FSCommandManager.PARAMETER_REQUEST_CHAR_UUID) {
                    parameterRequestChar = characteristic
                } else if (characteristic.uuid ==
                    FSCommandManager.PARAMETER_NOTIFICATION_CHAR_UUID) {
                    parameterNotificationChar = characteristic
                    // Enable notification
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if (characteristic.uuid ==
                    FSCommandManager.BATTERY_STATUS_CHAR_UUID) {
                    batteryStatusChar = characteristic
                    // Enable notification
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        } else if (service.uuid == FSCommandManager.BELT_SENSOR_SERVICE_UUID) {
            beltSensorService = service
            if (service.characteristics == nil ||
                service.characteristics?.count == 0) {
                // No characteristic discovered
                connectionManager.clearConnection(.serviceDiscoveryFailed)
                return
            }
            for characteristic in service.characteristics! {
                if (characteristic.uuid ==
                    FSCommandManager.ORIENTATION_DATA_NOTIFICATION_CHAR_UUID) {
                    orientationDataNotificationChar = characteristic
                    // Note: notifications disabled at the beginning
                }
            }
        } else if (service.uuid == FSCommandManager.BELT_DEBUG_SERVICE_UUID) {
            beltDebugService = service
            if (service.characteristics == nil ||
                service.characteristics?.count == 0) {
                // No characteristic discovered
                connectionManager.clearConnection(.serviceDiscoveryFailed)
                return
            }
            for characteristic in service.characteristics! {
                if (characteristic.uuid ==
                    FSCommandManager.BELT_DEBUG_INPUT_CHAR_UUID) {
                    beltDebugInputChar = characteristic
                } else if (characteristic.uuid ==
                    FSCommandManager.BELT_DEBUG_OUTPUT_CHAR_UUID) {
                    beltDebugOutputChar = characteristic
                    // Enable notification
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    // Callback for read descriptor operations
    final public func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor descriptor: CBDescriptor,
                    error: Error?) {
        if (error != nil) {
            print(error.debugDescription)
        }
    }
    
    // Callback for write operations
    final public func peripheral(
                _ peripheral: CBPeripheral,
                didWriteValueFor characteristic: CBCharacteristic,
                error: Error?) {
        if let err = error {
            print("Error GATT write characteristic:",  err.localizedDescription)
        }
        // Callback for operation queue
        operationQueue.peripheralDidWriteValueFor(peripheral: peripheral,
                characteristic: characteristic, error: error)
    }
    
    // Callback for registration to notification
    final public func peripheral(
                _ peripheral: CBPeripheral,
                didUpdateNotificationStateFor characteristic: CBCharacteristic,
                error: Error?) {
        if let err = error {
            print("Error GATT update notification:",  err.localizedDescription)
        }
        if (error != nil && connectionManager.state == .discoveringServices) {
            // Failed to register for notifications
            connectionManager.clearConnection(.handshakeFailed)
        } else {
            if (characteristic.uuid == FSCommandManager.KEEP_ALIVE_CHAR_UUID) {
                keepAliveCharRegistered = true
            } else if (characteristic.uuid ==
                FSCommandManager.BUTTON_PRESS_NOTIFICATION_CHAR_UUID) {
                buttonPressNotificationCharRegistered = true
            } else if (characteristic.uuid ==
                FSCommandManager.PARAMETER_NOTIFICATION_CHAR_UUID) {
                parameterNotificationCharRegistered = true
            } else if (characteristic.uuid ==
                FSCommandManager.BELT_DEBUG_OUTPUT_CHAR_UUID) {
                beltDebugOutputCharRegistered = true
            } else if (characteristic.uuid ==
                FSCommandManager.BATTERY_STATUS_CHAR_UUID) {
                batteryStatusCharRegistered = true
            }
        }
        // Continue with handshake when all services discovered and
        // registrations performed
        if (beltControlService != nil &&
            beltSensorService != nil &&
            beltDebugService != nil &&
            keepAliveCharRegistered &&
            parameterNotificationCharRegistered &&
            buttonPressNotificationCharRegistered &&
            beltDebugOutputCharRegistered &&
            batteryStatusCharRegistered &&
            connectionManager.state == .discoveringServices) {
            // Start handshake
            connectionManager.setState(newState: .handshake,
                                       cause: .servicesDiscovered)
            // Read firmware version
            if let characteristic = firmwareInfoChar, let peripheral = belt {
                operationQueue.add(FSBleOperationReadCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    onOperationDone: {(operation) -> () in
                        if (operation.state == .failed) {
                            FSConnectionManager.instance.clearConnection(
                                .handshakeFailed)
                        }
                }))
            }
            // Read battery status
            if let characteristic = batteryStatusChar, let peripheral = belt {
                operationQueue.add(FSBleOperationReadCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    onOperationDone: {(operation) -> () in
                        if (operation.state == .failed) {
                            FSConnectionManager.instance.clearConnection(
                                .handshakeFailed)
                        }
                }))
            }
            // Request default intensity
            if let characteristic = parameterRequestChar,
                let peripheral = belt {
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: Data([0x01,
                                 FSBeltParameter.defaultIntensity.rawValue]),
                    onOperationDone: {(operation) -> () in
                        if (operation.state == .failed) {
                            FSConnectionManager.instance.clearConnection(
                                .handshakeFailed)
                        }
                }))
            }
            // Request belt mode
            if let characteristic = parameterRequestChar,
                let peripheral = belt {
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: Data([0x01, FSBeltParameter.mode.rawValue]),
                    onOperationDone: {(operation) -> () in
                        if (operation.state == .failed) {
                            FSConnectionManager.instance.clearConnection(
                                .handshakeFailed)
                        }
                }))
            }
            // Request heading offset
            if let characteristic = parameterRequestChar,
                let peripheral = belt {
                operationQueue.add(FSBleOperationWriteCharacteristic(
                    peripheral: peripheral, characteristic: characteristic,
                    value: Data([0x01,
                                 FSBeltParameter.headingOffset.rawValue])))
                // Note: Handshake does not fail when this request fails
            }
            // Note: Handshake finished in callback for read operations
        }
        // Callback for operation queue
        operationQueue.peripheralDidUpdateNotificationStateFor(
            peripheral: peripheral, characteristic: characteristic,
            error: error)
    }
    
    // Callback for notification and read operations
    final public func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let err = error {
            print("Error GATT notification/read characteristic:",
                  err.localizedDescription)
        }
        // Check connection state
        if (connectionManager.state == .notConnected) {
            // Ignore notification when not connected
            return
        }
        if (characteristic.uuid == FSCommandManager.KEEP_ALIVE_CHAR_UUID) {
            // Send keep-alive response
            if (characteristic.value != nil) {
                processKeepAliveNotification(characteristic.value!)
            }
        } else if (characteristic.uuid ==
            FSCommandManager.BUTTON_PRESS_NOTIFICATION_CHAR_UUID) {
            // Update mode and inform delegate of button press
            if (characteristic.value != nil) {
                processButtonPressPacket(characteristic.value!)
            }
        }
        else if (characteristic.uuid ==
            FSCommandManager.PARAMETER_NOTIFICATION_CHAR_UUID) {
            // Update parameters and inform delegate
            if (characteristic.value != nil) {
                retrieveParametersFromPacket(characteristic.value!)
            }
        } else if (characteristic.uuid ==
            FSCommandManager.BATTERY_STATUS_CHAR_UUID) {
            // Update belt's battery status
            if (characteristic.value != nil) {
                retrieveBatteryStatusFromPacket(characteristic.value!)
            }
        } else if (characteristic.uuid ==
            FSCommandManager.BELT_DEBUG_OUTPUT_CHAR_UUID) {
            // TODO Manage received debug data...
        } else if (characteristic.uuid ==
            FSCommandManager.FIRMWARE_INFO_CHAR_UUID) {
            // Retrieve firmware version
            firmwareVersion = Int(characteristic.value![0])
        } else if (characteristic.uuid ==
            FSCommandManager.ORIENTATION_DATA_NOTIFICATION_CHAR_UUID) {
            // Update and notify belt orientation
            handleOrientationNotificationPacket(characteristic.value!)
        }
        // Condition to finish handshake
        if (connectionManager.state == .handshake &&
            mode != .unknown && defaultIntensity != -1) {
            connectionManager.setState(newState: .connected,
                                       cause: .handshakeFinished)
        }
        // Callback for operation queue
        operationQueue.peripheralDidUpdateValueFor(peripheral: peripheral,
                characteristic: characteristic, error: error)
    }
    
}

/**
 Values of the different belt's parameters that can be requested.
 */
internal enum FSBeltParameter: UInt8 {
    /** Mode ofthe belt. */
    case mode = 0x01
    /** Default intensity parameter. */
    case defaultIntensity = 0x02
    /** Bearing offset parameter. */
    case headingOffset = 0x03
    /** Name advertised by the belt. */
    case bleName = 0x04
}

/**
 Values representing vibration patterns
 */
public enum FSVibrationPattern: UInt8 {
    // Note: 0x00 for no vibration
    /** Continuous vibration. */
    case continuous = 0x01
    /** Single short pulse. */
    case singleShort = 0x02
    /** Single long pulse. */
    case singleLong = 0x03
    /** Double short pulse. */
    case doubleShort = 0x04
    /** Double long pulse. */
    case doubleLong = 0x05
    /** Waving signal. */
    case shortShiftWave = 0x06
    /** Pattern for goal reached. */
    case goalReached = 0x09
}

/**
 Enumeration of vibration signals
 */
public enum FSVibrationSignal: UInt8 {
    /** Continuous vibration. */
    case continuous = 0x01
    /** Default vibration for navigation. */
    case navigation = 0x81
    /** Repeated signal for destination reached. */
    case destinationReachedRepeated = 0x82
    /** Single iteration of the destination reached signal */
    case destinationReached = 0x83
    /** Default vibration pattern when approaching the destination. */
    case approachingDestination = 0x84
    /** Notification of a direction (e.g. POI). */
    case directionNotification = 0x85
    /** Repeated signal for ongoing turn */
    case ongoingTurn = 0x86
}

/**
 Values representing the type of orientation for a vibration signal.
 */
public enum FSOrientationType: UInt8 {
    /**
     For a binary mask, each bit of the orientation value represents the
     activation state of a vibromotor. A bit with the value `1` indicates that
     the vibromotor is used for the vibration pattern. The first (right-most)
     bit of the orientation value corresponds to the front vibromotor. Ascending
     bit positions are assigned clockwise to vibromotors. For instance, the
     vibromotor on the right side of the belt is the vibromotor index 4, and the
     binary mask to activate it is `0b0000000000010000'`. Note that multiple
     vibromotors can be activated by a single channel using a binary mask.
     */
    case binaryMask = 0x00
    /**
     The `vibromotorIndex` orientation type indicates that the orientation value
     is the index of the vibromotor to activate for the vibration pattern. The
     front vibromotor has index 0, and index are assigned clockwise on the belt.
     For instance, the vibromotor on the right side of the belt is the
     vibromotor index 4.
     */
    case vibromotorIndex = 0x01
    /**
     Using `angle` orientation type, vibromotors are specified according to
     their orientation, in degrees. Angle `0` corresponds to the front
     vibromotor, and a positive angle variation is considered clockwise on the
     belt. For instance, the vibromotor on the right side of the belt is
     activated with a angle between 79 and 101 degrees.
     */
    case angle = 0x02
    /**
     The `magneticBearing` orientation type use the compass of the belt to
     determine the vibromotor to use for the vibration pattern. A magnetic
     bearing of `0` points to magnetic North and a positive bearing
     variation is considered clockwise on the belt. For instance, to use the
     vibromotor pointing East, the magnetic bearing value is 90 degrees.
     */
    case magneticBearing = 0x03
}

/**
 Enumeration of belt 'system' signals
 */
public enum FSSystemSignal: UInt8 {
    /** Warning signal (belt specific intensity). */
    case warning = 0x00
    /** Signal for a goal reached. */
    case goalReached = 0x01
    /** Battery signal (belt specific intensity). */
    case battery = 0x02
}

/**
 A battery status stores information about the power supply and battery level.
 */
public struct FSBatteryStatus {
    
    /**
     The power status of the battery.
     */
    public var powerStatus: FSPowerStatus = .unknown
    
    /**
     The battery level in percent.
     */
    public var batteryLevel: Double = -1
    
    /**
     Time-to-empty (TTE) or time-to-full (TTF) in seconds.
     
     If the power status is `onBattery` this attribute represents the TTE, if
     the poser status is `charging` this attribute represents the TTF.
     */
    public var batteryTteTtf: Double = -1
    
}

/**
 Structure that represents orientation information of the belt.
 */
public struct FSBeltOrientation {
    
    /**
     The magnetic heading of the belt.
     */
    public var beltMagHeading: Int
    
    /**
     Flag for inaccurate compass.
     */
    public var beltCompassInaccurate: Bool
}

/**
 Values representing power supply status of the belt.
 */
@objc public enum FSPowerStatus: UInt8 {
    /** The power source is unknown. */
    case unknown = 0x00
    /** The battery of the belt is used. */
    case onBattery = 0x01
    /** The battery is charging. */
    case charging = 0x02
    /** An external power supply is used without charging the battery. */
    case external = 0x03
}

