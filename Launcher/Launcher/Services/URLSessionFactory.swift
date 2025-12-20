//
//  URLSessionFactory.swift
//  Launcher
//
//  Factory for creating configured URLSession instances with proxy support
//

import Foundation

/// Factory for creating URLSession instances with consistent configuration
/// Centralizes proxy and timeout configuration to avoid code duplication
enum URLSessionFactory {

  // MARK: - Session Cache

  /// Cached default session (invalidate when proxy settings change)
  private static var _cachedDefaultSession: URLSession?
  private static var _cachedProxyConfigHash: Int?

  // MARK: - Public Methods

  /// Creates a new URLSession with default configuration and proxy support
  /// - Parameters:
  ///   - requestTimeout: Request timeout interval (default from AppConstants)
  ///   - resourceTimeout: Resource timeout interval (default from AppConstants)
  ///   - maxConnectionsPerHost: Maximum concurrent connections per host (optional)
  ///   - delegate: URLSession delegate (optional)
  ///   - delegateQueue: Operation queue for delegate calls (optional)
  /// - Returns: Configured URLSession instance
  static func createSession(
    requestTimeout: TimeInterval = AppConstants.Network.defaultRequestTimeout,
    resourceTimeout: TimeInterval = AppConstants.Network.defaultResourceTimeout,
    maxConnectionsPerHost: Int? = nil,
    delegate: URLSessionDelegate? = nil,
    delegateQueue: OperationQueue? = nil
  ) -> URLSession {
    let config = createConfiguration(
      requestTimeout: requestTimeout,
      resourceTimeout: resourceTimeout,
      maxConnectionsPerHost: maxConnectionsPerHost
    )

    if let delegate = delegate {
      return URLSession(configuration: config, delegate: delegate, delegateQueue: delegateQueue)
    } else {
      return URLSession(configuration: config)
    }
  }

  /// Creates a URLSession optimized for downloads
  /// - Parameters:
  ///   - maxConcurrentDownloads: Maximum concurrent downloads
  ///   - delegate: URLSession delegate
  ///   - delegateQueue: Operation queue for delegate calls
  /// - Returns: Configured URLSession for downloads
  static func createDownloadSession(
    requestTimeout: TimeInterval,
    resourceTimeout: TimeInterval,
    maxConcurrentDownloads: Int,
    delegate: URLSessionDelegate? = nil,
    delegateQueue: OperationQueue? = nil
  ) -> URLSession {
    let config = createConfiguration(
      requestTimeout: requestTimeout,
      resourceTimeout: resourceTimeout,
      maxConnectionsPerHost: maxConcurrentDownloads
    )

    // Disable cache for downloads to save memory
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil

    if let delegate = delegate {
      return URLSession(configuration: config, delegate: delegate, delegateQueue: delegateQueue)
    } else {
      return URLSession(configuration: config)
    }
  }

  /// Gets or creates a cached default session
  /// The session is invalidated when proxy settings change
  /// - Returns: Cached or new URLSession
  static func getDefaultSession() -> URLSession {
    let currentProxyHash = computeProxyConfigHash()

    // Return cached session if proxy config hasn't changed
    if let cachedSession = _cachedDefaultSession,
       let cachedHash = _cachedProxyConfigHash,
       cachedHash == currentProxyHash {
      return cachedSession
    }

    // Create new session and cache it
    let session = createSession()
    _cachedDefaultSession = session
    _cachedProxyConfigHash = currentProxyHash

    return session
  }

  /// Invalidates the cached session (call when proxy settings change)
  static func invalidateCachedSession() {
    _cachedDefaultSession?.invalidateAndCancel()
    _cachedDefaultSession = nil
    _cachedProxyConfigHash = nil
  }

  // MARK: - Configuration

  /// Creates a URLSessionConfiguration with proxy support
  /// - Parameters:
  ///   - requestTimeout: Request timeout interval
  ///   - resourceTimeout: Resource timeout interval
  ///   - maxConnectionsPerHost: Maximum connections per host (optional)
  /// - Returns: Configured URLSessionConfiguration
  static func createConfiguration(
    requestTimeout: TimeInterval = AppConstants.Network.defaultRequestTimeout,
    resourceTimeout: TimeInterval = AppConstants.Network.defaultResourceTimeout,
    maxConnectionsPerHost: Int? = nil
  ) -> URLSessionConfiguration {
    let config = URLSessionConfiguration.default

    // Timeout configuration
    config.timeoutIntervalForRequest = requestTimeout
    config.timeoutIntervalForResource = resourceTimeout

    // Connection configuration
    if let maxConnections = maxConnectionsPerHost {
      config.httpMaximumConnectionsPerHost = maxConnections
    }

    // Apply proxy configuration if enabled
    applyProxyConfiguration(to: config)

    return config
  }

  // MARK: - Private Methods

  /// Applies proxy configuration to URLSessionConfiguration
  private static func applyProxyConfiguration(to config: URLSessionConfiguration) {
    if let proxyDict = ProxyManager.shared.getProxyConfigurationForBoth() {
      config.connectionProxyDictionary = proxyDict
      Logger.shared.debug(
        "Proxy applied: \(ProxyManager.shared.proxyType.rawValue) \(ProxyManager.shared.proxyHost):\(ProxyManager.shared.proxyPort)",
        category: "URLSessionFactory"
      )
    }
  }

  /// Computes a hash of current proxy configuration for cache invalidation
  private static func computeProxyConfigHash() -> Int {
    var hasher = Hasher()
    hasher.combine(ProxyManager.shared.proxyEnabled)
    hasher.combine(ProxyManager.shared.proxyHost)
    hasher.combine(ProxyManager.shared.proxyPort)
    hasher.combine(ProxyManager.shared.proxyType.rawValue)
    return hasher.finalize()
  }
}
