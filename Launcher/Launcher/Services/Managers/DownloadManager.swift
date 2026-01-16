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
  private let pathManager = PathManager.shared
  private var session: URLSession?
  private var downloadTasks: [UUID: DownloadTask] = [:]
  private var taskQueue: [DownloadQueueItem] = []
  private var activeDownloads = 0

  private var maxConcurrentDownloads: Int {
    downloadSettingsManager.maxConcurrentDownloads
  }

  private let downloadQueue = DispatchQueue(label: "com.launcher.download", attributes: .concurrent)
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

  /// Configure URLSession with proxy settings (uses factory for consistent configuration)
  private func configureSession() {
    self.session = URLSessionFactory.createDownloadSession(
      requestTimeout: TimeInterval(downloadSettingsManager.requestTimeout),
      resourceTimeout: TimeInterval(downloadSettingsManager.resourceTimeout),
      maxConcurrentDownloads: maxConcurrentDownloads,
      delegate: self,
      delegateQueue: nil
    )

    if ProxyManager.shared.proxyEnabled {
      logger.info(
        "Proxy enabled for downloads: \(ProxyManager.shared.proxyType.rawValue) \(ProxyManager.shared.proxyHost):\(ProxyManager.shared.proxyPort)",
        category: "DownloadManager"
      )
    } else {
      logger.debug("Proxy not configured for downloads", category: "DownloadManager")
    }
  }

  /// Reconfigure session with updated proxy settings
  func reconfigureSession() {
    logger.info("Reconfiguring download session with updated proxy settings", category: "DownloadManager")
    configureSession()
  }

  // MARK: - Public Methods

  /// Download single file with automatic retry on failure
  /// - Parameters:
  ///   - urlString: URL to download from
  ///   - destination: Local destination path
  ///   - expectedSize: Expected file size for validation
  ///   - expectedSHA1: Optional SHA1 hash for verification
  ///   - maxRetries: Maximum retry attempts (default from AppConstants)
  func downloadFile(
    from urlString: String,
    to destination: URL,
    expectedSize: Int,
    expectedSHA1: String? = nil,
    maxRetries: Int = AppConstants.Download.defaultRetryAttempts
  ) async throws {
    logger.info("Starting file download: \(urlString)", category: "DownloadManager")

    guard let url = URL(string: urlString) else {
      throw DownloadError.invalidURL(urlString)
    }

    // Check if file already exists and is valid
    if FileManager.default.fileExists(atPath: destination.path) {
      // For existing files, only check file size to avoid expensive SHA1 computation
      if let size = FileUtils.getFileSize(at: destination), size == expectedSize {
        logger.debug("File exists with matching size, skipping: \(destination.lastPathComponent)", category: "DownloadManager")
        return
      } else {
        // File size mismatch, remove and re-download
        logger.debug("File exists but size mismatch, re-downloading: \(destination.lastPathComponent)", category: "DownloadManager")
        try? FileManager.default.removeItem(at: destination)
      }
    }

    // Download with retry
    var lastError: Error?

    for attempt in 0..<maxRetries {
      do {
        try await performDownload(
          url: url,
          to: destination,
          expectedSize: expectedSize,
          expectedSHA1: expectedSHA1
        )
        // Success - return immediately
        logger.info("File download completed: \(destination.lastPathComponent)", category: "DownloadManager")
        return
      } catch {
        lastError = error

        // Don't retry for certain errors
        if case DownloadError.invalidURL = error { throw error }
        if case DownloadError.downloadCancelled = error { throw error }

        // Log retry attempt
        if attempt < maxRetries - 1 {
          let delay = calculateRetryDelay(attempt: attempt)
          logger.warning(
            "Download failed (attempt \(attempt + 1)/\(maxRetries)), retrying in \(String(format: "%.1f", delay))s: \(error.localizedDescription)",
            category: "DownloadManager"
          )
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
      }
    }

    // All retries exhausted
    logger.error(
      "Download failed after \(maxRetries) attempts: \(urlString)",
      category: "DownloadManager"
    )
    throw lastError ?? DownloadError.httpError(-1)
  }

  /// Performs the actual download operation (no retry logic)
  private func performDownload(
    url: URL,
    to destination: URL,
    expectedSize: Int,
    expectedSHA1: String?
  ) async throws {
    // Download file
    guard let session = session else {
      throw DownloadError.downloadCancelled
    }
    let (tempURL, response) = try await session.download(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
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

    // Ensure destination directory exists before moving
    let directory = destination.deletingLastPathComponent()
    try pathManager.ensureDirectoryExists(at: directory)

    // Move file to destination
    try FileUtils.moveFileSafely(from: tempURL, to: destination)
  }

  /// Calculates retry delay using exponential backoff
  /// - Parameter attempt: Current attempt number (0-indexed)
  /// - Returns: Delay in seconds
  private func calculateRetryDelay(attempt: Int) -> TimeInterval {
    let baseDelay = AppConstants.Network.retryBaseDelay
    let maxDelay = AppConstants.Network.retryMaxDelay
    let delay = baseDelay * pow(2.0, Double(attempt))
    return min(delay, maxDelay)
  }

  /// Download single file (legacy method without retry for internal use)
  private func downloadFileDirect(
    from urlString: String,
    to destination: URL,
    expectedSize: Int,
    expectedSHA1: String? = nil
  ) async throws {
    guard let url = URL(string: urlString) else {
      throw DownloadError.invalidURL(urlString)
    }

    try await performDownload(
      url: url,
      to: destination,
      expectedSize: expectedSize,
      expectedSHA1: expectedSHA1
    )

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

    // Pre-create all directories in batch to avoid repeated directory creation
    try prepareDirectories(for: items)

    // Filter out files that already exist and are valid (in background)
    let filteredItems = await batchCheckFiles(items)

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
    let totalCount = filteredItems.count

    updateProgress(
      total: totalCount,
      completed: 0,
      failed: 0,
      totalBytes: totalBytes,
      downloadedBytes: 0
    )

    // Use Actor to ensure thread-safe progress tracking
    let progressTracker = DownloadProgressTracker(total: totalCount, totalBytes: totalBytes)

    // Use TaskGroup for concurrent downloads
    try await withThrowingTaskGroup(of: Void.self) { group in
      var activeCount = 0

      for item in filteredItems {
        // Control concurrency: wait if we've reached the limit
        while activeCount >= maxConcurrentDownloads {
          try await group.next()
          activeCount -= 1
        }

        group.addTask {
          do {
            try await self.downloadFile(
              from: item.url,
              to: item.destination,
              expectedSize: item.size,
              expectedSHA1: item.sha1
            )

            // Thread-safe progress update
            let progress = await progressTracker.markCompleted(bytes: Int64(item.size))

            await MainActor.run {
              self.updateProgress(
                total: totalCount,
                completed: progress.completed,
                failed: progress.failed,
                totalBytes: totalBytes,
                downloadedBytes: progress.downloadedBytes
              )
            }
          } catch {
            // Thread-safe failure marking
            let progress = await progressTracker.markFailed()

            await MainActor.run {
              self.logger.error(
                "File download failed: \(item.url) - \(error.localizedDescription)",
                category: "DownloadManager"
              )
              self.updateProgress(
                total: totalCount,
                completed: progress.completed,
                failed: progress.failed,
                totalBytes: totalBytes,
                downloadedBytes: progress.downloadedBytes
              )
            }
            throw error
          }
        }
        activeCount += 1
      }

      // Wait for all remaining tasks to complete
      while try await group.next() != nil {
        // Task completion is handled inside addTask
      }
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
      let versionDir = pathManager.getVersionPath(versionDetails.id)
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
      destination: pathManager.getPath(for: .assetIndexes)
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
        destination: pathManager.getPath(for: .logConfigs)
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
    let indexPath = pathManager.getPath(for: .assetIndexes)
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
    let objectsDir = pathManager.getPath(for: .assetObjects)
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

  /// Pre-create all required directories in batch
  private func prepareDirectories(for items: [DownloadQueueItem]) throws {
    let directories = Set(items.map { $0.destination.deletingLastPathComponent() })
    logger.debug(
      "Pre-creating \(directories.count) directories",
      category: "DownloadManager"
    )

    for directory in directories {
      try pathManager.ensureDirectoryExists(at: directory)
    }
  }

  /// Batch check files in background to avoid blocking main thread
  private func batchCheckFiles(_ items: [DownloadQueueItem]) async -> [DownloadQueueItem] {
    await Task.detached(priority: .utility) {
      items.filter { item in
        // Check file existence and size in background thread
        guard FileManager.default.fileExists(atPath: item.destination.path) else {
          return true
        }

        // Only check file size (faster than SHA1)
        if let size = FileUtils.getFileSize(at: item.destination), size != item.size {
          return true
        }

        return false
      }
    }.value
  }

  /// Check if file needs to be downloaded
  private func shouldDownloadFile(
    at url: URL,
    expectedSize: Int,
    expectedSHA1: String?
  ) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return true
    }

    // For existing files, only check file size (faster than SHA1)
    if let size = FileUtils.getFileSize(at: url), size != expectedSize {
      logger.debug(
        "File size mismatch, need re-download: \(url.lastPathComponent)",
        category: "DownloadManager"
      )
      return true
    }

    return false
  }

  /// Get library file download items
  private func getLibraryDownloadItems(from libraries: [Library]) -> [DownloadQueueItem] {
    var items: [DownloadQueueItem] = []
    let librariesDir = pathManager.getPath(for: .libraries)

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

// MARK: - Download Progress Tracker

/// Thread-safe download progress tracker
/// Uses Actor to ensure thread safety during concurrent download progress updates
private actor DownloadProgressTracker {
  private(set) var completed: Int = 0
  private(set) var failed: Int = 0
  private(set) var downloadedBytes: Int64 = 0

  let total: Int
  let totalBytes: Int64

  init(total: Int, totalBytes: Int64) {
    self.total = total
    self.totalBytes = totalBytes
  }

  /// Mark a task as completed
  /// - Parameter bytes: Number of bytes downloaded
  /// - Returns: Current progress snapshot
  func markCompleted(bytes: Int64) -> (completed: Int, failed: Int, downloadedBytes: Int64) {
    completed += 1
    downloadedBytes += bytes
    return (completed, failed, downloadedBytes)
  }

  /// Mark a task as failed
  /// - Returns: Current progress snapshot
  func markFailed() -> (completed: Int, failed: Int, downloadedBytes: Int64) {
    failed += 1
    return (completed, failed, downloadedBytes)
  }

  /// Get current progress snapshot
  func getProgress() -> (completed: Int, failed: Int, downloadedBytes: Int64) {
    return (completed, failed, downloadedBytes)
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
