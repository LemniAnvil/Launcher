//
//  Localized.swift
//  Launcher
//

import Foundation

enum Localized {

  // MARK: - Errors

  enum Errors {

    // VersionManager Errors
    static func versionNotFound(_ version: String) -> String {
      String(localized: "Version not found: \(version)", comment: "[Error] Version not found.")
    }

    static func invalidURL(_ url: String) -> String {
      String(localized: "Invalid URL: \(url)", comment: "[Error] Invalid URL.")
    }

    static func downloadFailed(_ reason: String) -> String {
      String(localized: "Download failed: \(reason)", comment: "[Error] Download failed.")
    }

    static func parseFailed(_ reason: String) -> String {
      String(localized: "Parse failed: \(reason)", comment: "[Error] Parse failed.")
    }

    // DownloadManager Errors
    static func httpError(_ code: Int) -> String {
      String(localized: "HTTP error: \(code)", comment: "[Error] HTTP error.")
    }

    static let sha1Mismatch = String(localized: "SHA1 verification failed", comment: "[Error] SHA1 verification failed.")

    static func assetIndexNotFound(_ id: String) -> String {
      String(localized: "Asset index not found: \(id)", comment: "[Error] Asset index not found.")
    }

    static let downloadCancelled = String(localized: "Download cancelled", comment: "[Error] Download cancelled.")

    static func fileNotFound(_ path: String) -> String {
      String(localized: "File not found: \(path)", comment: "[Error] File not found.")
    }
  }
}
