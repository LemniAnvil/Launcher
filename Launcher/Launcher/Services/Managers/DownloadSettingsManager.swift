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
  private(set) var requestTimeout: Int = 15
  private(set) var resourceTimeout: Int = 300
  private(set) var progressUpdateInterval: Double = 0.5
  private(set) var useV2Manifest: Bool = false

  private let logger = Logger.shared

  // MARK: - UserDefaults Keys

  private enum UserDefaultsKeys {
    static let fileVerificationEnabled = "FileVerificationEnabled"
    static let maxConcurrentDownloads = "MaxConcurrentDownloads"
    static let requestTimeout = "RequestTimeout"
    static let resourceTimeout = "ResourceTimeout"
    static let progressUpdateInterval = "ProgressUpdateInterval"
    static let useV2Manifest = "UseV2Manifest"
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

  /// Configure request timeout
  func setRequestTimeout(_ timeout: Int) {
    // Clamp value between 5 and 120 seconds
    let clampedTimeout = max(5, min(120, timeout))
    self.requestTimeout = clampedTimeout
    saveSettings()

    logger.info(
      "Request timeout set to \(clampedTimeout)s",
      category: "DownloadSettingsManager"
    )
  }

  /// Configure resource timeout
  func setResourceTimeout(_ timeout: Int) {
    // Clamp value between 60 and 600 seconds
    let clampedTimeout = max(60, min(600, timeout))
    self.resourceTimeout = clampedTimeout
    saveSettings()

    logger.info(
      "Resource timeout set to \(clampedTimeout)s",
      category: "DownloadSettingsManager"
    )
  }

  /// Configure progress update interval
  func setProgressUpdateInterval(_ interval: Double) {
    // Clamp value between 0.1 and 5.0 seconds
    let clampedInterval = max(0.1, min(5.0, interval))
    self.progressUpdateInterval = clampedInterval
    saveSettings()

    logger.info(
      "Progress update interval set to \(String(format: "%.1f", clampedInterval))s",
      category: "DownloadSettingsManager"
    )
  }

  /// Configure API manifest version
  func setUseV2Manifest(_ enabled: Bool) {
    self.useV2Manifest = enabled
    saveSettings()

    logger.info(
      "API manifest version set to \(enabled ? "V2" : "Official")",
      category: "DownloadSettingsManager"
    )
  }

  // MARK: - Private Methods

  private func saveSettings() {
    UserDefaults.standard.set(fileVerificationEnabled, forKey: UserDefaultsKeys.fileVerificationEnabled)
    UserDefaults.standard.set(maxConcurrentDownloads, forKey: UserDefaultsKeys.maxConcurrentDownloads)
    UserDefaults.standard.set(requestTimeout, forKey: UserDefaultsKeys.requestTimeout)
    UserDefaults.standard.set(resourceTimeout, forKey: UserDefaultsKeys.resourceTimeout)
    UserDefaults.standard.set(progressUpdateInterval, forKey: UserDefaultsKeys.progressUpdateInterval)
    UserDefaults.standard.set(useV2Manifest, forKey: UserDefaultsKeys.useV2Manifest)
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

    // Load request timeout (default 15)
    let savedRequestTimeout = UserDefaults.standard.integer(forKey: UserDefaultsKeys.requestTimeout)
    if savedRequestTimeout > 0 {
      requestTimeout = max(5, min(120, savedRequestTimeout))
    } else {
      requestTimeout = 15
    }

    // Load resource timeout (default 300)
    let savedResourceTimeout = UserDefaults.standard.integer(forKey: UserDefaultsKeys.resourceTimeout)
    if savedResourceTimeout > 0 {
      resourceTimeout = max(60, min(600, savedResourceTimeout))
    } else {
      resourceTimeout = 300
    }

    // Load progress update interval (default 0.5)
    let savedProgressInterval = UserDefaults.standard.double(forKey: UserDefaultsKeys.progressUpdateInterval)
    if savedProgressInterval > 0 {
      progressUpdateInterval = max(0.1, min(5.0, savedProgressInterval))
    } else {
      progressUpdateInterval = 0.5
    }

    // Load V2 manifest setting (default false)
    useV2Manifest = UserDefaults.standard.bool(forKey: UserDefaultsKeys.useV2Manifest)

    logger.debug(
      "Download settings loaded: fileVerification=\(fileVerificationEnabled), maxConcurrent=\(maxConcurrentDownloads), requestTimeout=\(requestTimeout)s, resourceTimeout=\(resourceTimeout)s, progressInterval=\(String(format: "%.1f", progressUpdateInterval))s, useV2Manifest=\(useV2Manifest)",
      category: "DownloadSettingsManager"
    )
  }
}
