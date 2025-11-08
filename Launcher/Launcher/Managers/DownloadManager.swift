//
//  DownloadManager.swift
//  Launcher
//
//  Download Manager - responsible for file downloading, validation and progress tracking
//

import Combine
import Foundation

/// Download Manager
@MainActor
class DownloadManager: NSObject, ObservableObject {
  // swiftlint:disable:previous type_body_length
  static let shared = DownloadManager()

  // MARK: - Published Properties

  @Published var currentProgress: DownloadProgress
  @Published var isDownloading = false
  @Published var downloadSpeed: Double = 0  // bytes per second

  // MARK: - Private Properties

  private let logger = Logger.shared
  private let downloadSettingsManager = DownloadSettingsManager.shared
  private var session: URLSession?
  private var downloadTasks: [UUID: DownloadTask] = [:]
  private var taskQueue: [DownloadQueueItem] = []
  private var activeDownloads = 0

  private var maxConcurrentDownloads: Int {
    downloadSettingsManager.maxConcurrentDownloads
  }

  private let downloadQueue = DispatchQueue(
    label: "com.launcher.download",
    attributes: .concurrent
  )
  private let progressUpdateInterval: TimeInterval = 0.5
  private var lastProgressUpdate = Date()
  private var lastDownloadedBytes: Int64 = 0

  // MARK: - Initialization

  override private init() {
    self.currentProgress = DownloadProgress(
      totalTasks: 0,
      completedTasks: 0,
      failedTasks: 0,
      totalBytes: 0,
      downloadedBytes: 0
    )

    super.init()

    configureSession()

    logger.info("Download manager initialized", category: "DownloadManager")
  }

  /// Configure URLSession with proxy settings
  private func configureSession() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300
    config.httpMaximumConnectionsPerHost = maxConcurrentDownloads

    // Apply proxy configuration if enabled
    if let proxyDict = ProxyManager.shared.getProxyConfigurationForBoth() {
      config.connectionProxyDictionary = proxyDict
      logger.info(
        "Proxy enabled for downloads: \(ProxyManager.shared.proxyType.rawValue) \(ProxyManager.shared.proxyHost):\(ProxyManager.shared.proxyPort)",
        category: "DownloadManager"
      )
    } else {
      logger.debug("Proxy not configured for downloads", category: "DownloadManager")
    }

    self.session = URLSession(
      configuration: config,
      delegate: self,
      delegateQueue: nil
    )
  }

  /// Reconfigure session with updated proxy settings
  func reconfigureSession() {
    logger.info("Reconfiguring download session with updated proxy settings", category: "DownloadManager")
    configureSession()
  }

  // MARK: - Public Methods

  /// Download single file
  func downloadFile(
    from urlString: String,
    to destination: URL,
    expectedSize: Int,
    expectedSHA1: String? = nil
  ) async throws {
    logger.info(
      "Starting file download: \(urlString)",
      category: "DownloadManager"
    )

    guard let url = URL(string: urlString) else {
      throw DownloadError.invalidURL(urlString)
    }

    // Ensure destination directory exists
    let directory = destination.deletingLastPathComponent()
    try FileUtils.ensureDirectoryExists(at: directory)

    // Check if file already exists and is valid
    if FileManager.default.fileExists(atPath: destination.path) {
      if let sha1 = expectedSHA1, downloadSettingsManager.fileVerificationEnabled {
        if FileUtils.verifySHA1(of: destination, expectedSHA1: sha1) {
          logger.debug(
            "File exists and verified, skipping: \(destination.lastPathComponent)",
            category: "DownloadManager"
          )
          return
        } else {
          logger.warning(
            "File exists but failed verification, re-downloading: \(destination.lastPathComponent)",
            category: "DownloadManager"
          )
          try? FileManager.default.removeItem(at: destination)
        }
      } else if let size = FileUtils.getFileSize(at: destination), size == expectedSize {
        logger.debug(
          "File exists with matching size, skipping: \(destination.lastPathComponent)",
          category: "DownloadManager"
        )
        return
      }
    }

    // Download file
    guard let session = session else {
      throw DownloadError.downloadCancelled
    }
    let (tempURL, response) = try await session.download(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw DownloadError.httpError(
        (response as? HTTPURLResponse)?.statusCode ?? -1
      )
    }

    // Verify SHA1 if enabled
    if let sha1 = expectedSHA1, downloadSettingsManager.fileVerificationEnabled {
      if !FileUtils.verifySHA1(of: tempURL, expectedSHA1: sha1) {
        throw DownloadError.sha1Mismatch
      }
    }

    // Move file to destination
    try FileUtils.moveFileSafely(from: tempURL, to: destination)

    logger.info(
      "File download completed: \(destination.lastPathComponent)",
      category: "DownloadManager"
    )
  }

  /// Batch download files
  func downloadFiles(_ items: [DownloadQueueItem]) async throws {
    logger.info(
      "Starting batch download, \(items.count) files",
      category: "DownloadManager"
    )

    isDownloading = true
    defer { isDownloading = false }

    // Filter out files that already exist and are valid
    let filteredItems = items.filter { item in
      shouldDownloadFile(
        at: item.destination,
        expectedSize: item.size,
        expectedSHA1: item.sha1
      )
    }

    logger.info(
      "After filtering, \(filteredItems.count) files need downloading",
      category: "DownloadManager"
    )

    if filteredItems.isEmpty {
      logger.info(
        "All files exist, no download needed",
        category: "DownloadManager"
      )
      return
    }

    // Initialize progress
    let totalBytes = filteredItems.reduce(0) { $0 + Int64($1.size) }
    updateProgress(
      total: filteredItems.count,
      completed: 0,
      failed: 0,
      totalBytes: totalBytes,
      downloadedBytes: 0
    )

    // Use TaskGroup for concurrent downloads
    try await withThrowingTaskGroup(of: Void.self) { group in
      var completed = 0
      var failed = 0
      var downloadedBytes: Int64 = 0

      for item in filteredItems {
        // Limit concurrency
        if group.isEmpty == false {
          try await group.next()
          completed += 1
        }

        group.addTask {
          do {
            try await self.downloadFile(
              from: item.url,
              to: item.destination,
              expectedSize: item.size,
              expectedSHA1: item.sha1
            )

            await MainActor.run {
              downloadedBytes += Int64(item.size)
              self.updateProgress(
                total: filteredItems.count,
                completed: completed,
                failed: failed,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes
              )
            }
          } catch {
            await MainActor.run {
              failed += 1
              self.logger.error(
                "File download failed: \(item.url) - \(error.localizedDescription)",
                category: "DownloadManager"
              )
            }
            throw error
          }
        }

        // Control concurrency
        if group.isEmpty == false && completed.isMultiple(of: maxConcurrentDownloads) {
          try await group.next()
          completed += 1
        }
      }

      // Wait for all tasks to complete
      try await group.waitForAll()
    }

    logger.info("Batch download completed", category: "DownloadManager")
  }

  /// Download version related files
  func downloadVersion(_ versionDetails: VersionDetails) async throws {
    logger.info(
      "Starting version download: \(versionDetails.id)",
      category: "DownloadManager"
    )

    var downloadItems: [DownloadQueueItem] = []

    // 1. Download game core JAR
    if let clientDownload = versionDetails.downloads.client {
      let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(
        versionDetails.id
      )
      let jarPath = versionDir.appendingPathComponent(
        "\(versionDetails.id).jar"
      )

      downloadItems.append(
        DownloadQueueItem(
          url: clientDownload.url,
          destination: jarPath,
          size: clientDownload.size,
          sha1: clientDownload.sha1,
          priority: .critical
        )
      )
    }

    // 2. Download dependency libraries
    let libraryItems = getLibraryDownloadItems(from: versionDetails.libraries)
    downloadItems.append(contentsOf: libraryItems)

    // 3. Download asset index
    let assetIndexItem = DownloadQueueItem(
      url: versionDetails.assetIndex.url,
      destination: FileUtils.getAssetsDirectory()
        .appendingPathComponent("indexes")
        .appendingPathComponent("\(versionDetails.assetIndex.id).json"),
      size: versionDetails.assetIndex.size,
      sha1: versionDetails.assetIndex.sha1,
      priority: .high
    )
    downloadItems.append(assetIndexItem)

    // 4. Download logging configuration
    if let logging = versionDetails.logging?.client {
      let loggingItem = DownloadQueueItem(
        url: logging.file.url,
        destination: FileUtils.getAssetsDirectory()
          .appendingPathComponent("log_configs")
          .appendingPathComponent(logging.file.id),
        size: logging.file.size,
        sha1: logging.file.sha1,
        priority: .normal
      )
      downloadItems.append(loggingItem)
    }

    // Sort by priority
    downloadItems.sort { $0.priority > $1.priority }

    // Execute download
    try await downloadFiles(downloadItems)

    logger.info(
      "Version download completed: \(versionDetails.id)",
      category: "DownloadManager"
    )
  }

  /// Download game assets
  func downloadAssets(assetIndexId: String) async throws {
    logger.info(
      "Starting game assets download: \(assetIndexId)",
      category: "DownloadManager"
    )

    // Read asset index file
    let indexPath = FileUtils.getAssetsDirectory()
      .appendingPathComponent("indexes")
      .appendingPathComponent("\(assetIndexId).json")

    guard FileManager.default.fileExists(atPath: indexPath.path) else {
      throw DownloadError.assetIndexNotFound(assetIndexId)
    }

    let data = try Data(contentsOf: indexPath)
    let assetIndex = try JSONDecoder().decode(AssetIndexData.self, from: data)

    logger.info(
      "Asset index contains \(assetIndex.objects.count) objects",
      category: "DownloadManager"
    )

    // Create download tasks
    let objectsDir = FileUtils.getAssetsDirectory().appendingPathComponent(
      "objects"
    )
    var downloadItems: [DownloadQueueItem] = []

    for (_, object) in assetIndex.objects {
      let destination = objectsDir.appendingPathComponent(object.getPath())

      downloadItems.append(
        DownloadQueueItem(
          url: object.getURL(),
          destination: destination,
          size: object.size,
          sha1: object.hash,
          priority: .low
        )
      )
    }

    // Execute download
    try await downloadFiles(downloadItems)

    logger.info(
      "Game assets download completed: \(assetIndexId)",
      category: "DownloadManager"
    )
  }

  /// Cancel all downloads
  func cancelAllDownloads() {
    logger.warning("Cancelling all download tasks", category: "DownloadManager")

    for task in downloadTasks.values {
      task.task?.cancel()
      task.state = .cancelled
    }

    downloadTasks.removeAll()
    taskQueue.removeAll()
    isDownloading = false
  }

  // MARK: - Private Methods

  /// Check if file needs to be downloaded
  private func shouldDownloadFile(
    at url: URL,
    expectedSize: Int,
    expectedSHA1: String?
  ) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return true
    }

    // Verify SHA1 if enabled
    if let sha1 = expectedSHA1, downloadSettingsManager.fileVerificationEnabled {
      if !FileUtils.verifySHA1(of: url, expectedSHA1: sha1) {
        logger.debug(
          "File SHA1 verification failed, need re-download: \(url.lastPathComponent)",
          category: "DownloadManager"
        )
        return true
      }
    } else {
      // Verify file size
      if let size = FileUtils.getFileSize(at: url), size != expectedSize {
        logger.debug(
          "File size mismatch, need re-download: \(url.lastPathComponent)",
          category: "DownloadManager"
        )
        return true
      }
    }

    return false
  }

  /// Get library file download items
  private func getLibraryDownloadItems(from libraries: [Library]) -> [DownloadQueueItem] {
    var items: [DownloadQueueItem] = []
    let librariesDir = FileUtils.getLibrariesDirectory()

    for library in libraries {
      // Check if library is applicable to current system
      guard library.isApplicable() else {
        continue
      }

      // Download main library file
      if let artifact = library.downloads?.artifact {
        let destination = librariesDir.appendingPathComponent(artifact.path)
        items.append(
          DownloadQueueItem(
            url: artifact.url,
            destination: destination,
            size: artifact.size,
            sha1: artifact.sha1,
            priority: .high
          )
        )
      }

      // Download native library
      if let nativeName = library.getNativeName(),
        let classifiers = library.downloads?.classifiers,
        let nativeArtifact = classifiers[nativeName] {
        let destination = librariesDir.appendingPathComponent(
          nativeArtifact.path
        )
        items.append(
          DownloadQueueItem(
            url: nativeArtifact.url,
            destination: destination,
            size: nativeArtifact.size,
            sha1: nativeArtifact.sha1,
            priority: .high
          )
        )
      }
    }

    return items
  }

  /// Update download progress
  private func updateProgress(
    total: Int,
    completed: Int,
    failed: Int,
    totalBytes: Int64,
    downloadedBytes: Int64
  ) {
    currentProgress = DownloadProgress(
      totalTasks: total,
      completedTasks: completed,
      failedTasks: failed,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes
    )

    // Calculate download speed
    let now = Date()
    let timeDiff = now.timeIntervalSince(lastProgressUpdate)

    if timeDiff >= progressUpdateInterval {
      let bytesDiff = Double(downloadedBytes - lastDownloadedBytes)
      downloadSpeed = bytesDiff / timeDiff

      lastProgressUpdate = now
      lastDownloadedBytes = downloadedBytes
    }
  }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
  nonisolated func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    // Handle download completion
  }

  nonisolated func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    // Update progress
    Task { @MainActor in
      let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
      logger.debug(
        "Download progress: \(Int(progress * 100))%",
        category: "DownloadManager"
      )
    }
  }
}

// MARK: - Errors

enum DownloadError: LocalizedError {
  case invalidURL(String)
  case httpError(Int)
  case sha1Mismatch
  case assetIndexNotFound(String)
  case downloadCancelled
  case fileNotFound(URL)

  var errorDescription: String? {
    switch self {
    case .invalidURL(let url):
      return Localized.Errors.invalidURL(url)
    case .httpError(let code):
      return Localized.Errors.httpError(code)
    case .sha1Mismatch:
      return Localized.Errors.sha1Mismatch
    case .assetIndexNotFound(let id):
      return Localized.Errors.assetIndexNotFound(id)
    case .downloadCancelled:
      return Localized.Errors.downloadCancelled
    case .fileNotFound(let url):
      return Localized.Errors.fileNotFound(url.path)
    }
  }
}
