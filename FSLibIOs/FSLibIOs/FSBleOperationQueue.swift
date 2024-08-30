//
//  FSBleOperationQueue.swift
//  FSLibIOs
//
//  Created by David on 06/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth
import OSLog

/**
 A queue for BLE operations (e.g. write and read characteristic).
 
 The queue system takes care of waiting the end of one BLE operation before
 starting another.
 */
class FSBleOperationQueue: NSObject {
    
    //MARK: Private properties
    
    // The list of BLE operations in queue
    private var bleOperationQueue: [FSBleOperation] = []
    
    // The running BLE operation
    private var runningBleOperation: FSBleOperation?
    
    // Timeout timer for the running BLE operation
    private var runningBleOperationTimeoutTimer: Timer?
    private static let BLE_OPERATION_TIMEOUT_SEC = 0.25
    
    //MARK: Methods
    
    /**
     Clears all BLE operations including the running one.
     */
    public func clear() {
        if FSConnectionManager.logBleEvents {
            os_log("Clear BLE operations.",
                   log: FSConnectionManager.log, type: .debug)
        }
        // Stop timeout timer
        if let timer = runningBleOperationTimeoutTimer {
            runningBleOperationTimeoutTimer = nil
            timer.invalidate()
        }
        // Operations to cancel
        // Note: cancelled at the end for synchronization purpose.
        var toCancel: [FSBleOperation] = []
        // Clear running operation
        if let operation = runningBleOperation {
            runningBleOperation = nil
            toCancel.append(operation)
        }
        // Clear queue
        toCancel.append(contentsOf: bleOperationQueue)
        bleOperationQueue.removeAll()
        // Cancel callback
        for operation in toCancel {
            operation.cancel()
        }
    }
    
    /**
     Adds a BLE operation into the queue.
     If the queue is empty, the operation is immediately started.
     */
    public func add(_ operation: FSBleOperation, isHighPriority: Bool = false) {
        if isHighPriority {
            if FSConnectionManager.logBleEvents {
                os_log("Insert BLE operation, %@.",
                       log: FSConnectionManager.log,
                       type: .debug, 
                       operation.description)
            }
            bleOperationQueue.insert(operation, at: 0)
        } else {
            if FSConnectionManager.logBleEvents { os_log("Append BLE operation, %@.", log: FSConnectionManager.log, type: .debug, operation.description) }
            bleOperationQueue.append(operation)
        }
        checkAndStartBleOperation()
    }
    
    /**
     Checks if a BLE operation can be started.
     */
    internal func checkAndStartBleOperation() {
        // Operations cancelled/failed
        // Note: cancel/fail callbacks at the end for synchronization purpose.
        var toCancel: [FSBleOperation] = []
        var failedOperations: [FSBleOperation] = []
        
        // Check running operation (just in case of synchronization problem)
        if (runningBleOperationTimeoutTimer == nil) {
            if let operation = runningBleOperation {
                runningBleOperation = nil
                toCancel.append(operation)
            }
        } else if (runningBleOperation == nil) {
            if let timer = runningBleOperationTimeoutTimer {
                runningBleOperationTimeoutTimer = nil
                timer.invalidate()
            }
        } else {
            if let timer = runningBleOperationTimeoutTimer {
                if (!timer.isValid) {
                    runningBleOperationTimeoutTimer = nil
                    timer.invalidate()
                    if let operation = runningBleOperation {
                        runningBleOperation = nil
                        toCancel.append(operation)
                    }
                }
            }
        }
        
        // Next operation if no running operation
        while (runningBleOperation == nil && !bleOperationQueue.isEmpty) {
            let operationToStart = bleOperationQueue.remove(at: 0)
            if FSConnectionManager.logBleEvents {
                os_log("Start BLE operation, %@.",
                       log: FSConnectionManager.log,
                       type: .debug,
                       operationToStart.description)
            }
            if (operationToStart.start()) {
                runningBleOperation = operationToStart
                runningBleOperationTimeoutTimer =
                    Timer.scheduledTimer(
                        timeInterval: TimeInterval(
                            FSBleOperationQueue.BLE_OPERATION_TIMEOUT_SEC),
                        target: self,
                        selector: #selector(bleOperationTimeout),
                        userInfo: nil,
                        repeats: false)
            } else {
                if FSConnectionManager.logBleEvents {
                    os_log("Start BLE operation failed, %@.",
                           log: FSConnectionManager.log,
                           type: .debug,
                           operationToStart.description)
                }
                failedOperations.append(operationToStart)
            }
        }
        
        // Cancel operations
        for operation in toCancel {
            operation.cancel()
        }
        // Failed operations
        for operation in failedOperations {
            operation.fail()
        }
    }
    
    /**
     Callback of the timeout timer.
     */
    @objc internal func bleOperationTimeout() {
        if let operation = runningBleOperation {
            if FSConnectionManager.logBleEvents {
                os_log("BLE operation timeout, %@.",
                       log: FSConnectionManager.log,
                       type: .debug,
                       operation.description)
            }
            runningBleOperation = nil
            runningBleOperationTimeoutTimer = nil
            checkAndStartBleOperation()
            operation.fail()
        }
    }
    
    /**
     Clears the running operation and check for starting the next in queue.
     */
    internal func nextOperation() {
        runningBleOperation = nil
        if let timer = runningBleOperationTimeoutTimer {
            runningBleOperationTimeoutTimer = nil
            timer.invalidate()
        }
        checkAndStartBleOperation()
    }
    
    /**
     To be called by the GATT peripheral delegate to check and start operations
     in queue.
     
     - Parameters:
        - peripheral: The GATT peripheral.
        - characteristic: The characteristic parameter of the callback.
        - error: The error parameter of the callback.
     */
    public func peripheralDidWriteValueFor(peripheral: CBPeripheral,
                                           characteristic: CBCharacteristic,
                                           error: Error?) {
        if let operation = runningBleOperation {
            if (operation.matchDidWriteValueFor(
                peripheral: peripheral,
                characteristic: characteristic,
                error: error)) {
                nextOperation()
                if error == nil {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation ACK, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.success()
                } else {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation failed, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.fail()
                }
            }
        }
    }
    
    /**
     To be called by the GATT peripheral delegate to check and start operations
     in queue.
     
     - Parameters:
        - peripheral: The GATT peripheral.
        - characteristic: The characteristic parameter of the callback.
        - error: The error parameter of the callback.
     */
    public func peripheralDidUpdateValueFor(peripheral: CBPeripheral,
                                           characteristic: CBCharacteristic,
                                           error: Error?) {
        if FSConnectionManager.logBleEvents {
            os_log("GATT notif, %@, %@.",
                   log: FSConnectionManager.log,
                   type: .debug,
                   characteristic.uuid.uuidString,
                   characteristic.value?.toHexString() ?? "nil")
        }
        if let operation = runningBleOperation {
            if (operation.matchDidUpdateValueFor(
                peripheral: peripheral,
                characteristic: characteristic,
                error: error)) {
                nextOperation()
                if error == nil {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation ACK, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.success()
                } else {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation failed, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.fail()
                }
            }
        }
    }
    
    /**
     To be called by the GATT peripheral delegate to check and start operations
     in queue.
     
     - Parameters:
         - peripheral: The GATT peripheral.
         - characteristic: The characteristic parameter of the callback.
         - error: The error parameter of the callback.
     */
    public func peripheralDidUpdateNotificationStateFor(
        peripheral: CBPeripheral, characteristic: CBCharacteristic,
        error: Error?) {
        if let operation = runningBleOperation {
            if (operation.matchDidUpdateNotificationStateFor(
                peripheral: peripheral,
                characteristic: characteristic,
                error: error)) {
                nextOperation()
                if error == nil {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation ACK, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.success()
                } else {
                    if FSConnectionManager.logBleEvents {
                        os_log("BLE operation failed, %@.",
                               log: FSConnectionManager.log,
                               type: .debug,
                               operation.description)
                    }
                    operation.fail()
                }
            }
        }
    }

}


