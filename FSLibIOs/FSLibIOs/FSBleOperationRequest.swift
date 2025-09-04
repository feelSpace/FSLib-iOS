//
//  FSBleOperationRequest.swift
//  FSLibIOs
//
//  Created by David on 04/09/25.
//  Copyright © 2025 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A request operation.
 */
class FSBleOperationRequest: FSBleOperation {
    
    // Description
    var description: String
    
    // Timeout
    var timeout: Double
    
    //MARK: Private properties
    
    // The GATT peripheral reference
    private var peripheral: CBPeripheral
    
    // The characteristic to write
    private var writeCharacteristic: CBCharacteristic
    
    // The value to write
    private var writeValue: Data
    
    // Flag for write operationacknowledged
    private var writeAcknowledged: Bool = false
    
    // The characteristic notified
    private var notifiedCharacteristic: CBCharacteristic
    
    // The notified pattern
    private var notifiedPattern: [UInt8?]
    
    // Callback closure
    private var callback: (_ operation: FSBleOperationRequest)->()

    //MARK: Public properties
    
    /**
     Value notified.
     */
    public private(set) var notifiedValue: Data? = nil
    
    /**
     State of the operation.
     */
    public private(set) var state: FSBleOperationState = .notStarted;

    // MARK: Methods
    
    /**
     Creates a read characteristic operation.
     */
    init(peripheral: CBPeripheral,
         writeCharacteristic: CBCharacteristic,
         writeValue: Data,
         notifiedCharacteristic: CBCharacteristic,
         notifiedPattern: [UInt8?],
         onOperationDone: @escaping ((_ operation:
        FSBleOperationRequest)->()) = {_ in },
         timeout: Double = FSBleOperationQueue.BLE_OPERATION_DEFAULT_TIMEOUT_SEC
    ) {
        self.peripheral = peripheral
        self.writeCharacteristic = writeCharacteristic
        self.writeValue = writeValue
        self.notifiedCharacteristic = notifiedCharacteristic
        self.notifiedPattern = notifiedPattern
        self.callback = onOperationDone
        self.description = "GATT request, \(writeCharacteristic.uuid.uuidString), \(writeValue.toHexString())"
        self.timeout = timeout
    }
    
    /** Starts the BLE operation. */
    func start() -> Bool {
        state = .started
        peripheral.writeValue(writeValue, for: writeCharacteristic,
                              type: .withResponse)
        return true
    }
    
    /** To be called when the operation is cancelled. */
    func cancel() {
        state = .cancelled
        callback(self)
    }
    
    /** To be called when the operation succeed. */
    func success() {
        state = .successful
        callback(self)
    }
    
    /** To be called when the operation failed or the timeout is reached. */
    func fail() {
        state = .failed
        callback(self)
    }
    
    /** Checks if the peripheral callback for writing a value corresponds to the
     operation. */
    func matchDidWriteValueFor(peripheral: CBPeripheral,
                               characteristic: CBCharacteristic,
                               error: Error?) -> Bool {
        if state == .started && writeCharacteristic == characteristic {
            writeAcknowledged = true
        }
        return false
    }
    
    /** Checks if the peripheral callback for reading a value corresponds to the
     operation. */
    func matchDidUpdateValueFor(peripheral: CBPeripheral,
                                characteristic: CBCharacteristic,
                                error: Error?) -> Bool {
        if state == .started && writeAcknowledged &&
            notifiedCharacteristic == characteristic {
            if FSBleOperationRequest.matchPattern(
                notifiedCharacteristic.value, pattern: notifiedPattern) {
                notifiedValue = notifiedCharacteristic.value
                return true
            }
        }
        return false
    }
    
    /** Checks if the peripheral callback for changing notification state
     corresponds to the operation. */
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: Error?) -> Bool {
        return false
    }
    
    /**
     Checks if the data matches a pattern.
     */
    public static func matchPattern(_ data: Data?, pattern: [UInt8?]) -> Bool {
        if let data = data {
            if data.count < pattern.count {
                // Larger pattern than data
                return false
            } else {
                // Check each value in pattern
                for (i, expectedByte) in pattern.enumerated() {
                    if let expectedByte = expectedByte, data[i] != expectedByte {
                        return false
                    }
                }
                return true
            }
        } else {
            // Empty data only match empty pattern
            return pattern.isEmpty
        }
    }
}
