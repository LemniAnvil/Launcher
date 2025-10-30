//
//  Logger.swift
//  Launcher
//
//  Logging utility class
//

import Foundation
import os.log

/// Log manager
class Logger {
  static let shared = Logger()

  private let osLog = OSLog(
    subsystem: "com.launcher.minecraft",
    category: "general"
  )
  private var logHistory: [LogEntry] = []
  private let maxHistoryCount = 1000
  private let logQueue = DispatchQueue(
    label: "com.launcher.logger",
    qos: .utility
  )

  private init() {}

  /// Log a message
  func log(
    _ message: String,
    level: LogLevel = .info,
    category: String = "general"
  ) {
    let entry = LogEntry(
      timestamp: Date(),
      level: level,
      category: category,
      message: message
    )

    logQueue.async { [weak self] in
      guard let self = self else { return }

      // Add to history
      self.logHistory.append(entry)
      if self.logHistory.count > self.maxHistoryCount {
        self.logHistory.removeFirst()
      }

      // Output to console
      self.printToConsole(entry)

      // Output to system log
      self.logToSystem(entry)
    }
  }

  /// Convenience methods
  func debug(_ message: String, category: String = "general") {
    log(message, level: .debug, category: category)
  }

  func info(_ message: String, category: String = "general") {
    log(message, level: .info, category: category)
  }

  func warning(_ message: String, category: String = "general") {
    log(message, level: .warning, category: category)
  }

  func error(_ message: String, category: String = "general") {
    log(message, level: .error, category: category)
  }

  /// Get log history
  func getHistory(level: LogLevel? = nil, category: String? = nil) -> [LogEntry] {
    return logHistory.filter { entry in
      if let level = level, entry.level != level {
        return false
      }
      if let category = category, entry.category != category {
        return false
      }
      return true
    }
  }

  /// Clear history
  func clearHistory() {
    logQueue.async { [weak self] in
      self?.logHistory.removeAll()
    }
  }

  /// Print to console
  private func printToConsole(_ entry: LogEntry) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let timestamp = formatter.string(from: entry.timestamp)

    let levelIcon = entry.level.icon
    let levelText = entry.level.rawValue.uppercased()

    print(
      "[\(timestamp)] \(levelIcon) [\(levelText)] [\(entry.category)] \(entry.message)"
    )
  }

  /// Output to system log
  private func logToSystem(_ entry: LogEntry) {
    let type: OSLogType
    switch entry.level {
    case .debug:
      type = .debug
    case .info:
      type = .info
    case .warning:
      type = .default
    case .error:
      type = .error
    }

    os_log("%{public}@", log: osLog, type: type, entry.message)
  }

  /// Save log to file
  func saveToFile() throws {
    let fileManager = FileManager.default
    let logsDirectory = try fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ).appendingPathComponent("Launcher/logs", isDirectory: true)

    try fileManager.createDirectory(
      at: logsDirectory,
      withIntermediateDirectories: true
    )

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let filename = "launcher-\(formatter.string(from: Date())).log"
    let fileURL = logsDirectory.appendingPathComponent(filename)

    let logContent = logHistory.map { entry in
      let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
      return
        "[\(timestamp)] [\(entry.level.rawValue)] [\(entry.category)] \(entry.message)"
    }.joined(separator: "\n")

    try logContent.write(to: fileURL, atomically: true, encoding: .utf8)

    info("Log saved to: \(fileURL.path)", category: "Logger")
  }
}

/// Log level
enum LogLevel: String {
  case debug = "debug"
  case info = "info"
  case warning = "warning"
  case error = "error"

  var icon: String {
    switch self {
    case .debug: return "🔍"
    case .info: return "ℹ️"
    case .warning: return "⚠️"
    case .error: return "❌"
    }
  }
}

/// Log entry
struct LogEntry: Identifiable {
  let id = UUID()
  let timestamp: Date
  let level: LogLevel
  let category: String
  let message: String
}
