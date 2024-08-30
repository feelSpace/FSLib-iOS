//
//  FSBleOperationWriteCharacteristic.swift
//  FSLibIOs
//
//  Created by David on 07/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A write characteristic operation.
 */
class FSBleOperationWriteCharacteristic: FSBleOperation {
    
    // Description
    var description: String
    
    //MARK: Private properties
    
    // The GATT peripheral reference
    private var peripheral: CBPeripheral
    
    // The characteristic to write
    private var characteristic: CBCharacteristic
    
    // The value to write
    private var value: Data
    
    // Callback closure
    private var callback: (_ operation: FSBleOperationWriteCharacteristic)->()

    //MARK: Public properties
    
    /**
     State of the operation.
     */
    public private(set) var state: FSBleOperationState = .notStarted;

    // MARK: Methods
    
    /**
     Creates a read characteristic operation.
     */
    init(peripheral: CBPeripheral,
         characteristic: CBCharacteristic,
         value: Data,
         onOperationDone: @escaping ((_ operation:
        FSBleOperationWriteCharacteristic)->()) = {_ in }) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.value = value
        self.callback = onOperationDone
        self.description = "GATT write, \(characteristic.uuid.uuidString), \(value.toHexString())"
    }
    
    /** Starts the BLE operation. */
    func start() -> Bool {
        state = .started
        peripheral.writeValue(value, for: characteristic,
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
        return (self.characteristic == characteristic)
    }
    
    /** Checks if the peripheral callback for reading a value corresponds to the
     operation. */
    func matchDidUpdateValueFor(peripheral: CBPeripheral,
                                characteristic: CBCharacteristic,
                                error: Error?) -> Bool {
        return false
    }
    
    /** Checks if the peripheral callback for changing notification state
     corresponds to the operation. */
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: Error?) -> Bool {
        return false
    }
}
