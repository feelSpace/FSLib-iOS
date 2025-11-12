//
//  BeltErrorLog.swift
//  feelSpace beeline
//
//  Created by David Meignan on 07.08.25.
//  Copyright © 2025 feelSpace GmbH. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Class to retrieve the error log of a connected belt.
 
 This feature is only for development and testing. Only specific belt firmwares for development allows
 retrieving the internal error log.
 */
public class FSBeltErrorLog {
    
    /** Current error session (only incremented when an error is logged) */
    var currentSession: Int = 0
    
    /** Total number of errors in the log */
    var logEntryCount: Int = 0
    
    /** First error code in the current session, 0 if no error */
    var currentSessionFirstError: Int = 0
    
    /** Last error code in the current session, 0 if no error */
    var currentSessionLastError: Int = 0
    
    /** List of error log entries */
    var entries: [BeltErrorLogEntry] = []
    
    /**
     Returns a text description of the error log.
     
     - Returns:A text description of the error log.
     */
    public func toString() -> String {
        var content = ""
        content.append("Current session: \(currentSession)\n")
        content.append("Entry count: \(logEntryCount)\n")
        let firstHex = String(format: "%08X", currentSessionFirstError)
        content.append("First error in session: 0x\(firstHex)\n")
        let lastHex = String(format: "%08X", currentSessionLastError)
        content.append("Last error in session: 0x\(lastHex)\n")
        content.append("Code\tTime\tSession\tMore\n")
        for entry in entries {
            let codeHex = String(format: "%08X", entry.errorCode)
            content.append("0x\(codeHex)\t\(entry.timeMs)\t\(entry.session)\t\(entry.more)\n")
        }
        return content
    }
    
    /**
     Parses the header packet of the error log.
     
     - Parameters:
        - data: Binary header packet of the error log.
     */
    internal func parseHeader(_ data: Data) {
        if data.count < 12 { return }
        currentSession = (Int) ( (UInt16(data[2]) << 8) + (UInt16(data[1])) )
        logEntryCount = (Int) ( UInt16(data[3]) )
        currentSessionFirstError = (Int) ( (UInt32(data[7]) << 24) + (UInt32(data[6]) << 16) + (UInt32(data[5]) << 8) + (UInt32(data[4])) )
        currentSessionLastError = (Int) ( (UInt32(data[11]) << 24) + (UInt32(data[10]) << 16) + (UInt32(data[9]) << 8) + (UInt32(data[8])) )
        entries = []
    }
    
    /**
     Parses and adds an entry to the error log.
     
     - Parameters:
        - data: Binary packet of the error log entry.
     */
    internal func parseEntry(_ data: Data) {
        if data.count < 12 { return }
        let code = (Int) ( (UInt32(data[4]) << 24) + (UInt32(data[3]) << 16) + (UInt32(data[2]) << 8) + (UInt32(data[1])) )
        let time = (Int) ( (UInt32(data[8]) << 24) + (UInt32(data[7]) << 16) + (UInt32(data[6]) << 8) + (UInt32(data[5])) )
        let session = (Int) ( (UInt16(data[10]) << 8) + (UInt16(data[9])) )
        let more = (Bool) (data[11] != 0)
        let entry = BeltErrorLogEntry(errorCode: code, timeMs: time, session: session, more: more)
        entries.append(entry)
    }
    
}

/**
 Entry to the belt error log.
 */
class BeltErrorLogEntry {
    
    /** Error code */
    var errorCode: Int
    
    /** Elapsed time when the error was raised */
    var timeMs: Int
    
    /** Error session */
    var session: Int
    
    /** Flag for more errors */
    var more: Bool
    
    /**
     Constructs an error log entry.
     
     - Parameters:
        - errorCode: The error code.
        - timeMs: The elsapsed time in milliseconds.
        - session: The error session.
        - mode: Flag value for more errors.
     */
    init(errorCode: Int, timeMs: Int, session: Int, more: Bool) {
        self.errorCode = errorCode
        self.timeMs = timeMs
        self.session = session
        self.more = more
    }
    
}

/**
 Extension of the command manager to request the belt error log.
 
 This feature is only for development and testing. Only specific belt firmwares for development allows
 retrieving the internal error log.
 */
extension FSCommandManager {
    
    /**
     Requests the belt error log asynchronously.
     
     - Parameters:
        - completion: Completion handler for the request.
     */
    public func requestBeltErrorLog(
        _ completion: @escaping (Result<FSBeltErrorLog, Error>) -> Void) {
        if (connectionManager.state != .connected) {
            completion(.failure(BeltErrorLogError.noConnection))
        } else {
            if let cmdChar = beltDebugInputChar,
               let rspChar = beltDebugOutputChar,
               let peripheral = belt {
                operationQueue.add(RequestBeltErrorLogOperation(
                    peripheral: peripheral,
                    debugCommandChar: cmdChar,
                    debugResponseChar: rspChar,
                    completion: completion
                ))
            } else {
                completion(.failure(BeltErrorLogError.noCharOrPeripheral))
            }
        }
    }
    
}

/**
 Enumeration of errors for the error log request.
 */
enum BeltErrorLogError: Error {
    
    /** No connection to make the request */
    case noConnection
    
    /** Connection not finalized to make the request */
    case noCharOrPeripheral
    
    /** Request has been cancelled */
    case operationCancelled
    
    /** Operation failed */
    case operationFailed
    
}

/**
 Implementation of a BLE operation to request the error log.
 */
class RequestBeltErrorLogOperation: FSBleOperation {

    var description: String
    var timeout: Double = 1.5
    
    var peripheral: CBPeripheral
    let debugCommandChar: CBCharacteristic
    let debugResponseChar: CBCharacteristic
    let completion: (Result<FSBeltErrorLog, Error>) -> Void
    let errorLog: FSBeltErrorLog = FSBeltErrorLog()
    var logCompleted: Bool = false
    
    init(peripheral: CBPeripheral,
         debugCommandChar: CBCharacteristic,
         debugResponseChar: CBCharacteristic,
         completion: @escaping (Result<FSBeltErrorLog, Error>) -> Void
    ) {
        self.description = "Belt error log request."
        self.debugCommandChar = debugCommandChar
        self.debugResponseChar = debugResponseChar
        self.peripheral = peripheral
        self.completion = completion
    }
    
    func start() -> Bool {
        let value = Data([0x0B])
        peripheral.writeValue(value, for: debugCommandChar, type: .withResponse)
        return true
    }
    
    func cancel() {
        completion(.failure(BeltErrorLogError.operationCancelled))
    }
    
    func success() {
        completion(.success(errorLog))
    }
    
    func fail() {
        completion(.failure(BeltErrorLogError.operationFailed))
    }
    
    func matchDidWriteValueFor(peripheral: CBPeripheral,
                               characteristic: CBCharacteristic,
                               error: (any Error)?) -> Bool {
        return false
    }
    
    func matchDidUpdateValueFor(peripheral: CBPeripheral,
                                characteristic: CBCharacteristic,
                                error: (any Error)?) -> Bool {
        if debugResponseChar == characteristic, let data = characteristic.value {
            /* Retrieve data and check for completion */
            if data[0] == 0x0B && data.count >= 12 {
                /* Completed if header reports no errors */
                errorLog.parseHeader(data)
                logCompleted = (errorLog.logEntryCount == 0)
            } else if data[0] == 0x0C  && data.count >= 12 {
                /* Completed if all error entries received */
                errorLog.parseEntry(data)
                logCompleted = (errorLog.logEntryCount == errorLog.entries.count)
            }
        }
        return logCompleted
    }
    
    func matchDidUpdateNotificationStateFor(peripheral: CBPeripheral,
                                            characteristic: CBCharacteristic,
                                            error: (any Error)?) -> Bool {
        return false
    }
    
}
