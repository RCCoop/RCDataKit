//
//  DataStackLogger.swift
//

import CoreData
import Foundation

// MARK: - Logging

public enum DataStackLogLevel: String {
    case debug, info, error, warning
}

public protocol DataStackLogger: Sendable {
    func log(type: DataStackLogLevel, message: String)
}

public struct DefaultLogger: DataStackLogger {
    public func log(type: DataStackLogLevel, message: String) {
        print("CORE DATA \(type.rawValue.uppercased()): \(message)")
    }
    
    public init() {}
}
