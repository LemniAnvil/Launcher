//
//  ProxyManager.swift
//  Launcher
//
//  Proxy Manager - responsible for managing proxy settings
//

import Foundation

/// Proxy Manager
class ProxyManager {

  static let shared = ProxyManager()

  // MARK: - Properties

  private(set) var proxyEnabled: Bool = false
  private(set) var proxyHost: String = ""
  private(set) var proxyPort: Int = 0
  private(set) var proxyType: ProxyType = .http

  private let logger = Logger.shared

  // MARK: - UserDefaults Keys

  private enum UserDefaultsKeys {
    static let proxyEnabled = "ProxyEnabled"
    static let proxyHost = "ProxyHost"
    static let proxyPort = "ProxyPort"
    static let proxyType = "ProxyType"
  }

  // MARK: - Proxy Type

  enum ProxyType: String, CaseIterable {
    case http = "HTTP"
    case https = "HTTPS"
    case socks5 = "SOCKS5"

    var displayName: String {
      switch self {
      case .http:
        return Localized.Proxy.typeHTTP
      case .https:
        return Localized.Proxy.typeHTTPS
      case .socks5:
        return Localized.Proxy.typeSOCKS5
      }
    }
  }

  // MARK: - Initialization

  private init() {
    loadProxySettings()
    logger.info("ProxyManager initialized", category: "ProxyManager")
  }

  // MARK: - Public Methods

  /// Configure proxy settings
  func configureProxy(enabled: Bool, host: String, port: Int, type: ProxyType) {
    self.proxyEnabled = enabled
    self.proxyHost = host.trimmingCharacters(in: .whitespaces)
    self.proxyPort = port
    self.proxyType = type

    saveProxySettings()

    if enabled {
      logger.info(
        "Proxy configured: \(type.rawValue) \(host):\(port)",
        category: "ProxyManager"
      )
    } else {
      logger.info("Proxy disabled", category: "ProxyManager")
    }
  }

  /// Get proxy configuration dictionary for URLSessionConfiguration
  func getProxyConfiguration() -> [String: Any]? {
    guard proxyEnabled, !proxyHost.isEmpty, proxyPort > 0 else {
      return nil
    }

    switch proxyType {
    case .http:
      return [
        kCFNetworkProxiesHTTPEnable as String: true,
        kCFNetworkProxiesHTTPProxy as String: proxyHost,
        kCFNetworkProxiesHTTPPort as String: proxyPort,
      ]

    case .https:
      return [
        kCFNetworkProxiesHTTPSEnable as String: true,
        kCFNetworkProxiesHTTPSProxy as String: proxyHost,
        kCFNetworkProxiesHTTPSPort as String: proxyPort,
      ]

    case .socks5:
      return [
        kCFNetworkProxiesSOCKSEnable as String: true,
        kCFNetworkProxiesSOCKSProxy as String: proxyHost,
        kCFNetworkProxiesSOCKSPort as String: proxyPort,
      ]
    }
  }

  /// Get proxy configuration for both HTTP and HTTPS
  func getProxyConfigurationForBoth() -> [String: Any]? {
    guard proxyEnabled, !proxyHost.isEmpty, proxyPort > 0 else {
      return nil
    }

    switch proxyType {
    case .http, .https:
      return [
        kCFNetworkProxiesHTTPEnable as String: true,
        kCFNetworkProxiesHTTPProxy as String: proxyHost,
        kCFNetworkProxiesHTTPPort as String: proxyPort,
        kCFNetworkProxiesHTTPSEnable as String: true,
        kCFNetworkProxiesHTTPSProxy as String: proxyHost,
        kCFNetworkProxiesHTTPSPort as String: proxyPort,
      ]

    case .socks5:
      return [
        kCFNetworkProxiesSOCKSEnable as String: true,
        kCFNetworkProxiesSOCKSProxy as String: proxyHost,
        kCFNetworkProxiesSOCKSPort as String: proxyPort,
      ]
    }
  }

  /// Test proxy connection
  func testProxyConnection() async throws -> Bool {
    guard proxyEnabled, !proxyHost.isEmpty, proxyPort > 0 else {
      throw ProxyError.invalidConfiguration
    }

    // Use factory with custom timeout for proxy testing
    let session = URLSessionFactory.createSession(
      requestTimeout: AppConstants.Network.proxyTestTimeout
    )

    guard let testURL = URL(string: APIService.MinecraftVersion.manifestOfficial) else {
      throw ProxyError.invalidConfiguration
    }

    do {
      let (_, response) = try await session.data(from: testURL)

      if let httpResponse = response as? HTTPURLResponse,
         httpResponse.statusCode == 200 {
        logger.info("Proxy connection test successful", category: "ProxyManager")
        return true
      }

      logger.warning("Proxy connection test failed: Invalid response", category: "ProxyManager")
      return false
    } catch {
      logger.error(
        "Proxy connection test failed: \(error.localizedDescription)",
        category: "ProxyManager"
      )
      throw ProxyError.connectionFailed(error.localizedDescription)
    }
  }

  /// Disable proxy
  func disableProxy() {
    configureProxy(enabled: false, host: "", port: 0, type: .http)
  }

  /// Detect system proxy settings
  func detectSystemProxy() -> (enabled: Bool, host: String, port: Int, type: ProxyType)? {
    // swiftlint:disable:previous large_tuple
    // Try to get the primary network interface (usually Wi-Fi or Ethernet)
    let interfaces = ["Wi-Fi", "Ethernet", "USB Ethernet"]

    for interface in interfaces {
      // Check HTTP proxy first
      if let httpProxy = getProxySettings(for: interface, proxyType: "-getwebproxy") {
        return httpProxy
      }

      // Check HTTPS proxy
      if let httpsProxy = getProxySettings(for: interface, proxyType: "-getsecurewebproxy") {
        return httpsProxy
      }

      // Check SOCKS proxy
      if let socksProxy = getProxySettings(for: interface, proxyType: "-getsocksfirewallproxy") {
        return socksProxy
      }
    }

    return nil
  }

  /// Apply detected system proxy settings
  func applySystemProxy() -> Bool {
    guard let systemProxy = detectSystemProxy() else {
      logger.warning("No system proxy detected", category: "ProxyManager")
      return false
    }

    if systemProxy.enabled {
      configureProxy(
        enabled: true,
        host: systemProxy.host,
        port: systemProxy.port,
        type: systemProxy.type
      )
      logger.info(
        "System proxy applied: \(systemProxy.type.rawValue) \(systemProxy.host):\(systemProxy.port)",
        category: "ProxyManager"
      )
      return true
    } else {
      logger.info("System proxy is disabled", category: "ProxyManager")
      return false
    }
  }

  // MARK: - Helper Methods

  private func getProxySettings(
    for interface: String,
    proxyType: String
  ) -> (enabled: Bool, host: String, port: Int, type: ProxyType)? {
    // swiftlint:disable:previous large_tuple
    let task = Process()
    task.launchPath = "/usr/sbin/networksetup"
    task.arguments = [proxyType, interface]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()

    do {
      try task.run()
      task.waitUntilExit()

      guard task.terminationStatus == 0 else {
        return nil
      }

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      guard let output = String(data: data, encoding: .utf8) else {
        return nil
      }

      return parseProxyOutput(output, proxyType: proxyType)
    } catch {
      logger.error(
        "Failed to execute networksetup: \(error.localizedDescription)",
        category: "ProxyManager"
      )
      return nil
    }
  }

  private func parseProxyOutput(
    _ output: String,
    proxyType: String
  ) -> (enabled: Bool, host: String, port: Int, type: ProxyType)? {
    // swiftlint:disable:previous large_tuple
    var enabled = false
    var host = ""
    var port = 0

    let lines = output.components(separatedBy: .newlines)

    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)

      if trimmedLine.hasPrefix("Enabled:") {
        enabled = trimmedLine.contains("Yes")
      } else if trimmedLine.hasPrefix("Server:") {
        let components = trimmedLine.components(separatedBy: ":")
        if components.count > 1 {
          host = components[1].trimmingCharacters(in: .whitespaces)
        }
      } else if trimmedLine.hasPrefix("Port:") {
        let components = trimmedLine.components(separatedBy: ":")
        if components.count > 1 {
          let portString = components[1].trimmingCharacters(in: .whitespaces)
          port = Int(portString) ?? 0
        }
      }
    }

    // Only return valid proxy settings
    guard enabled, !host.isEmpty, port > 0 else {
      return nil
    }

    // Determine proxy type based on the command used
    let type: ProxyType
    switch proxyType {
    case "-getwebproxy":
      type = .http
    case "-getsecurewebproxy":
      type = .https
    case "-getsocksfirewallproxy":
      type = .socks5
    default:
      type = .http
    }

    return (enabled: enabled, host: host, port: port, type: type)
  }

  // MARK: - Private Methods

  private func saveProxySettings() {
    UserDefaults.standard.set(proxyEnabled, forKey: UserDefaultsKeys.proxyEnabled)
    UserDefaults.standard.set(proxyHost, forKey: UserDefaultsKeys.proxyHost)
    UserDefaults.standard.set(proxyPort, forKey: UserDefaultsKeys.proxyPort)
    UserDefaults.standard.set(proxyType.rawValue, forKey: UserDefaultsKeys.proxyType)

    logger.debug("Proxy settings saved", category: "ProxyManager")
  }

  private func loadProxySettings() {
    proxyEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.proxyEnabled)
    proxyHost = UserDefaults.standard.string(forKey: UserDefaultsKeys.proxyHost) ?? ""
    proxyPort = UserDefaults.standard.integer(forKey: UserDefaultsKeys.proxyPort)

    if let typeString = UserDefaults.standard.string(forKey: UserDefaultsKeys.proxyType),
       let type = ProxyType(rawValue: typeString) {
      proxyType = type
    }

    logger.debug(
      "Proxy settings loaded: enabled=\(proxyEnabled), host=\(proxyHost), port=\(proxyPort), type=\(proxyType.rawValue)",
      category: "ProxyManager"
    )
  }
}

// MARK: - Errors

enum ProxyError: LocalizedError {
  case invalidConfiguration
  case connectionFailed(String)

  var errorDescription: String? {
    switch self {
    case .invalidConfiguration:
      return Localized.Proxy.Errors.invalidConfiguration
    case .connectionFailed(let reason):
      return Localized.Proxy.Errors.connectionFailed(reason)
    }
  }
}
