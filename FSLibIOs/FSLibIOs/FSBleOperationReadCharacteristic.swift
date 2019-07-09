//
//  FSBleOperationReadCharacteristic.swift
//  FSLibIOs
//
//  Created by David on 07/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A read characteristic operation.
 */
class FSBleOperationReadCharacteristic: FSBleOperation {
    
    //MARK: Private properties
    
    // The GATT peripheral reference
    private var peripheral: CBPeripheral
    
    // The characteristic to read
    private var characteristic: CBCharacteristic
    
    // Callback closure
    private var callback: (_ operation: FSBleOperationReadCharacteristic)->()
    
    
    //MARK: Public properties

    /**
     Value read from the characteristic.
     */
    var characteristicValue: Data? {
        return characteristic.value
    }
    
    /**
     State of the operation.
     */
    public private(set) var state: FSBleOperationState = .notStarted;
    
    //MARK: Methods

    /**
     Creates a read characteristic operation.
     */
    init(peripheral: CBPeripheral,
         characteristic: CBCharacteristic,
         onOperationDone: @escaping ((_ operation:
        FSBleOperationReadCharacteristic)->()) = {_ in }) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.callback = onOperationDone
    }
    
    /** Starts the BLE operation. */
    func start() -> Bool {
        state = .started
        peripheral.readValue(for: characteristic)
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
        return false
    }
    
    
    /** Checks if the peripheral callback for reading a value corresponds to the
     operation. */
    func matchDidUpdateValueFor(peripheral: CBPeripheral,
                                characteristic: CBCharacteristic,
                                error: Error?) -> Bool {
        return (self.characteristic == characteristic)
    }
    
    /** Checks if the peripheral callback for changing notification state
     corresponds to the operation. */
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: Error?) -> Bool {
        return false
    }
}
