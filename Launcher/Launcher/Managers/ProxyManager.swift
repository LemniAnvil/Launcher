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
        kCFNetworkProxiesHTTPPort as String: proxyPort
      ]
      
    case .https:
      return [
        kCFNetworkProxiesHTTPSEnable as String: true,
        kCFNetworkProxiesHTTPSProxy as String: proxyHost,
        kCFNetworkProxiesHTTPSPort as String: proxyPort
      ]
      
    case .socks5:
      return [
        kCFNetworkProxiesSOCKSEnable as String: true,
        kCFNetworkProxiesSOCKSProxy as String: proxyHost,
        kCFNetworkProxiesSOCKSPort as String: proxyPort
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
        kCFNetworkProxiesHTTPSPort as String: proxyPort
      ]
      
    case .socks5:
      return [
        kCFNetworkProxiesSOCKSEnable as String: true,
        kCFNetworkProxiesSOCKSProxy as String: proxyHost,
        kCFNetworkProxiesSOCKSPort as String: proxyPort
      ]
    }
  }
  
  /// Test proxy connection
  func testProxyConnection() async throws -> Bool {
    guard proxyEnabled, !proxyHost.isEmpty, proxyPort > 0 else {
      throw ProxyError.invalidConfiguration
    }
    
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 10
    
    if let proxyDict = getProxyConfiguration() {
      config.connectionProxyDictionary = proxyDict
    }
    
    let session = URLSession(configuration: config)
    
    let testURL = URL(string: APIEndpoints.versionManifestOfficial)!
    
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
