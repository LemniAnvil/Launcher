//
//  Download.swift
//  Launcher
//
//  Download related data models
//

import Combine
import Foundation

/// Download task
class DownloadTask: Identifiable, ObservableObject {
  let id = UUID()
  let url: URL
  let destination: URL
  let expectedSize: Int
  let expectedSHA1: String?

  @Published var state: DownloadState = .pending
  @Published var progress: Double = 0.0
  @Published var downloadedSize: Int = 0
  @Published var error: Error?

  var task: URLSessionDownloadTask?

  init(
    url: URL,
    destination: URL,
    expectedSize: Int,
    expectedSHA1: String? = nil
  ) {
    self.url = url
    self.destination = destination
    self.expectedSize = expectedSize
    self.expectedSHA1 = expectedSHA1
  }
}

/// Download state
enum DownloadState: Equatable {
  case pending      // Pending
  case downloading  // Downloading
  case completed    // Completed
  case failed       // Failed
  case cancelled    // Cancelled
  case verifying    // Verifying
}

/// Download progress information
struct DownloadProgress {
  let totalTasks: Int
  let completedTasks: Int
  let failedTasks: Int
  let totalBytes: Int64
  let downloadedBytes: Int64

  var overallProgress: Double {
    guard totalTasks > 0 else { return 0 }
    return Double(completedTasks) / Double(totalTasks)
  }

  var bytesProgress: Double {
    guard totalBytes > 0 else { return 0 }
    return Double(downloadedBytes) / Double(totalBytes)
  }

  var displayProgress: String {
    let completed = completedTasks
    let total = totalTasks
    let percent = Int(overallProgress * 100)
    return "\(completed)/\(total) (\(percent)%)"
  }

  var bytesDisplay: String {
    let downloaded = ByteCountFormatter.string(
      fromByteCount: downloadedBytes,
      countStyle: .file
    )
    let total = ByteCountFormatter.string(
      fromByteCount: totalBytes,
      countStyle: .file
    )
    return "\(downloaded) / \(total)"
  }
}

/// Download queue item
struct DownloadQueueItem {
  let url: String
  let destination: URL
  let size: Int
  let sha1: String?
  let priority: DownloadPriority
}

/// Download priority
enum DownloadPriority: Int, Comparable {
  case low = 0
  case normal = 1
  case high = 2
  case critical = 3

  static func < (lhs: DownloadPriority, rhs: DownloadPriority) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}
