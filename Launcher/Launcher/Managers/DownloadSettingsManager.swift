//
//  DownloadSettingsManager.swift
//  Launcher
//
//  Download Settings Manager - responsible for managing download settings
//

import Foundation

/// Download Settings Manager
class DownloadSettingsManager {
  static let shared = DownloadSettingsManager()

  // MARK: - Properties

  private(set) var fileVerificationEnabled: Bool = true
  private(set) var maxConcurrentDownloads: Int = 8

  private let logger = Logger.shared

  // MARK: - UserDefaults Keys

  private enum UserDefaultsKeys {
    static let fileVerificationEnabled = "FileVerificationEnabled"
    static let maxConcurrentDownloads = "MaxConcurrentDownloads"
  }

  // MARK: - Initialization

  private init() {
    loadSettings()
    logger.info("DownloadSettingsManager initialized", category: "DownloadSettingsManager")
  }

  // MARK: - Public Methods

  /// Configure file verification setting
  func setFileVerification(enabled: Bool) {
    self.fileVerificationEnabled = enabled
    saveSettings()

    logger.info(
      "File verification \(enabled ? "enabled" : "disabled")",
      category: "DownloadSettingsManager"
    )
  }

  /// Configure max concurrent downloads
  func setMaxConcurrentDownloads(_ count: Int) {
    // Clamp value between 1 and 64
    let clampedCount = max(1, min(64, count))
    self.maxConcurrentDownloads = clampedCount
    saveSettings()

    logger.info(
      "Max concurrent downloads set to \(clampedCount)",
      category: "DownloadSettingsManager"
    )
  }

  // MARK: - Private Methods

  private func saveSettings() {
    UserDefaults.standard.set(fileVerificationEnabled, forKey: UserDefaultsKeys.fileVerificationEnabled)
    UserDefaults.standard.set(maxConcurrentDownloads, forKey: UserDefaultsKeys.maxConcurrentDownloads)
    logger.debug("Download settings saved", category: "DownloadSettingsManager")
  }

  private func loadSettings() {
    // Default to true if not set
    if UserDefaults.standard.object(forKey: UserDefaultsKeys.fileVerificationEnabled) == nil {
      fileVerificationEnabled = true
    } else {
      fileVerificationEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.fileVerificationEnabled)
    }

    // Default to 8 if not set
    let savedConcurrent = UserDefaults.standard.integer(forKey: UserDefaultsKeys.maxConcurrentDownloads)
    if savedConcurrent > 0 {
      maxConcurrentDownloads = max(1, min(64, savedConcurrent))
    } else {
      maxConcurrentDownloads = 8
    }

    logger.debug(
      "Download settings loaded: fileVerification=\(fileVerificationEnabled), maxConcurrent=\(maxConcurrentDownloads)",
      category: "DownloadSettingsManager"
    )
  }
}
