//
//  FSBleOperationSetNotifyValue.swift
//  FSLibIOs
//
//  Created by David Meignan on 13.03.18.
//  Copyright © 2018 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A set notify value operation.
 */
class FSBleOperationSetNotifyValue: FSBleOperation {
    
    // Description
    var description: String
    
    //MARK: Private properties
    
    // The GATT peripheral reference
    private var peripheral: CBPeripheral
    
    // The characteristic to (un)register
    private var characteristic: CBCharacteristic
    
    // The notify state to set
    private var notify: Bool
    
    // Callback closure
    private var callback: (_ operation: FSBleOperationSetNotifyValue)->()
    
    
    //MARK: Public properties
    
    /**
     State of the operation.
     */
    public private(set) var state: FSBleOperationState = .notStarted;
    
    //MARK: Methods
    
    /**
     Creates a set notify operation.
     */
    init(peripheral: CBPeripheral,
         characteristic: CBCharacteristic,
         notify: Bool,
         onOperationDone: @escaping ((_ operation:
        FSBleOperationSetNotifyValue)->()) = {_ in }) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.notify = notify
        self.callback = onOperationDone
        self.description = "GATT set notif, \(characteristic.uuid.uuidString), \(notify)"
    }
    
    /** Starts the BLE operation. */
    func start() -> Bool {
        state = .started
        peripheral.setNotifyValue(notify, for: characteristic)
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
        return false
    }
    
    /** Checks if the peripheral callback for changing notification state
     corresponds to the operation. */
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: Error?) -> Bool {
        return (self.characteristic == characteristic)
    }
}

