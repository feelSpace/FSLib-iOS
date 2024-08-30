//
//  FSBleOperation.swift
//  FSLibIOs
//
//  Created by David on 06/09/17.
//  Copyright © 2017 feelSpace. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 A BLE operation interface for e.g. write and read characteristic operations.
 */
protocol FSBleOperation {
    
    /**
     Description of the operation.
     */
    var description: String { get }
    
    /**
     Starts the BLE operation.
     
     -Important:
     In case of immediate failure, the `fail` method will be called.
     
     - Returns:
     `true` if the operation is successfully initialized, `false` on immediate
     failure.
     */
    func start() -> Bool
    
    /**
     To be called when the operation is cancelled.
     */
    func cancel()
    
    /**
     To be called when the operation succeed.
     */
    func success()
    
    /**
     To be called when the operation failed or the timeout is reached.
     */
    func fail()
    
    /**
     Checks if the peripheral callback for writing a value corresponds to the
     operation.
     
     - Parameters:
        - peripheral: The peripheral parameter of the callback.
        - characteristic: The characteristic parameter of the peripheral 
     callback.
        - error: The error parameter of the peripheral callback.
     
     - Returns:
     `true` if the callbcak corresponds to the operation.
     */
    func matchDidWriteValueFor(peripheral: CBPeripheral,
                             characteristic: CBCharacteristic,
                             error: Error?) -> Bool
    
    
    /**
     Checks if the peripheral callback for reading a value corresponds to the
     operation.
     
     - Parameters:
        - peripheral: The peripheral parameter of the callback.
        - characteristic: The characteristic parameter of the peripheral
     callback.
        - error: The error parameter of the peripheral callback.
     
     - Returns:
     `true` if the callbcak corresponds to the operation.
     */
    func matchDidUpdateValueFor(peripheral: CBPeripheral,
                               characteristic: CBCharacteristic,
                               error: Error?) -> Bool
    
    /**
     Checks if the peripheral callback for changing notification state
     corresponds to the operation.
     
     - Parameters:
        - peripheral: The peripheral parameter of the callback.
        - characteristic: The characteristic parameter of the peripheral
     callback.
        - error: The error parameter of the peripheral callback.
     
     - Returns:
     `true` if the callbcak corresponds to the operation.
     */
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: Error?) -> Bool
    
}

/**
 States of a BLE operation.
 */
enum FSBleOperationState {
    /** The operation is not yet started. */
    case notStarted
    /** The operation is waiting for termination. */
    case started
    /** The operation was successful. */
    case successful
    /** The operation has been cancelled. */
    case cancelled
    /** The operation has failed (timeout or other failure) */
    case failed
}

extension Data {
    func toHexString() -> String {
        return self.map {
            String(format: " %02hhX", $0)
        }.joined()
    }
}
