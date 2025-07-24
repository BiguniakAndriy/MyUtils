//
//  Logger.swift
//  Utils
//
//  Created by Andriy Biguniak on 04.07.2025.
//

import Foundation


enum Logger: String
{
    case error
    case warning
    case success
    case debug
    case info
    case UI
    
    var icon: String {
        switch self {
            case .error:
                return "❌"
            case .warning:
                return "⚠️"
            case .success:
                return "✅"
            case .debug:
                return "📋"
            case .info:
                return "ℹ️"
            case .UI:
                return "📲"
        }
    }
    
    static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    static func error(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .error, file, function, line)
    }
    
    static func warning(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .warning, file, function, line)
    }
    
    static func success(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .success, file, function, line)
    }
    
    static func debug(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .debug, file, function, line)
    }
    
    static func info(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .info, file, function, line)
    }
    static func UI(
        _ message: String,
        _ file: String = #fileID,
        _ function: String = #function,
        _ line: Int = #line
    ) {
        log(message: message, type: .UI, file, function, line)
    }
    
    
    private static func log(
        message: String,
        type: Logger,
        _ file: String,
        _ function: String,
        _ line: Int
    ) {
        let file = file.split(separator: "/").last ?? "can't get name"
        print(
            "\(type.icon) \(Logger.logDateFormatter.string(from: Date())) [\(type.rawValue.uppercased())]: " + "\(message)" +
            (type == .info ? "\n" : "\nFile: \(file), func: \(function), line: \(line)\n")
        )
   }
}
