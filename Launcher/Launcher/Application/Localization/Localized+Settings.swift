//
//  Localized+Settings.swift
//  Launcher
//

import Foundation

// MARK: - Settings-related Localizations
extension Localized {
  // MARK: - Proxy Settings
  enum Proxy {
    // Labels
    static let sectionTitle = String(localized: "Proxy Settings", comment: "[Label] Proxy settings section title.")
    static let enableProxy = String(localized: "Enable Proxy", comment: "[Checkbox] Enable proxy checkbox.")
    static let hostLabel = String(localized: "Host:", comment: "[Label] Proxy host label.")
    static let portLabel = String(localized: "Port:", comment: "[Label] Proxy port label.")
    static let typeLabel = String(localized: "Type:", comment: "[Label] Proxy type label.")
    static let hostPlaceholder = String(localized: "e.g., 127.0.0.1", comment: "[Placeholder] Proxy host placeholder.")
    static let portPlaceholder = String(localized: "e.g., 7890", comment: "[Placeholder] Proxy port placeholder.")

    // Buttons
    static let applyButton = String(localized: "Apply Proxy", comment: "[Button] Apply proxy settings.")
    static let testButton = String(localized: "Test Proxy", comment: "[Button] Test proxy connection.")

    // Types
    static let typeHTTP = String(localized: "HTTP", comment: "[Text] HTTP proxy type.")
    static let typeHTTPS = String(localized: "HTTPS", comment: "[Text] HTTPS proxy type.")
    static let typeSOCKS5 = String(localized: "SOCKS5", comment: "[Text] SOCKS5 proxy type.")

    // Status Messages
    static let statusEnabled = String(localized: "Proxy enabled", comment: "[Status] Proxy enabled.")
    static let statusDisabled = String(localized: "Proxy disabled", comment: "[Status] Proxy disabled.")
    static let statusTesting = String(localized: "Testing proxy connection...", comment: "[Status] Testing proxy connection.")
    static let statusTestSuccess = String(localized: "Proxy connection test successful", comment: "[Status] Proxy connection test successful.")
    static let statusTestFailed = String(localized: "Proxy connection test failed", comment: "[Status] Proxy connection test failed.")

    static func statusApplied(_ host: String, _ port: Int) -> String {
      String(localized: "Proxy applied: \(host):\(port)", comment: "[Status] Proxy applied with host and port.")
    }

    // Log Messages
    static func logEnabled(_ type: String, _ host: String, _ port: Int) -> String {
      String(localized: "✅ Proxy enabled: \(type) \(host):\(port)", comment: "[Log] Proxy enabled.")
    }

    static let logDisabled = String(localized: "❌ Proxy disabled", comment: "[Log] Proxy disabled.")
    static let logTesting = String(localized: "🔄 Testing proxy connection...", comment: "[Log] Testing proxy connection.")
    static let logTestSuccess = String(localized: "✅ Proxy test successful", comment: "[Log] Proxy test successful.")

    static func logTestFailed(_ error: String) -> String {
      String(localized: "❌ Proxy test failed: \(error)", comment: "[Log] Proxy test failed.")
    }

    // Alerts
    static let alertTestSuccessTitle = String(localized: "Proxy Test Successful", comment: "[Alert] Proxy test successful title.")
    static let alertTestSuccessMessage = String(localized: "Proxy connection is working correctly.", comment: "[Alert] Proxy test successful message.")
    static let alertTestFailedTitle = String(localized: "Proxy Test Failed", comment: "[Alert] Proxy test failed title.")

    static func alertTestFailedMessage(_ error: String) -> String {
      String(localized: "Failed to connect through proxy:\n\(error)", comment: "[Alert] Proxy test failed message.")
    }

    static let alertInvalidConfigTitle = String(localized: "Invalid Configuration", comment: "[Alert] Invalid proxy configuration title.")
    static let alertInvalidConfigMessage = String(localized: "Please enter valid host and port.", comment: "[Alert] Invalid proxy configuration message.")

    // Errors
    enum Errors {
      static let invalidConfiguration = String(localized: "Invalid proxy configuration", comment: "[Error] Invalid proxy configuration.")

      static func connectionFailed(_ reason: String) -> String {
        String(localized: "Proxy connection failed: \(reason)", comment: "[Error] Proxy connection failed.")
      }
    }
  }

  // MARK: - Java Detection
  enum JavaDetection {
    static let windowTitle = String(localized: "Java Detection", comment: "[Text] Java detection window title.")
    static let title = String(localized: "Java Installation Detection", comment: "[Text] Java detection title.")
    static let subtitle = String(localized: "Detect and manage Java installations for running Minecraft", comment: "[Text] Java detection subtitle.")

    // Buttons
    static let detectButton = String(localized: "Detect Java", comment: "[Button] Detect Java installations.")
    static let refreshButton = String(localized: "Refresh", comment: "[Button] Refresh Java detection.")
    static let openJavaDetectionButton = String(localized: "Java Detection", comment: "[Button] Open Java detection window.")

    // Table Columns
    static let columnPath = String(localized: "Installation Path", comment: "[Table] Java installation path column.")
    static let columnVersion = String(localized: "Version", comment: "[Table] Java version column.")
    static let columnType = String(localized: "Type", comment: "[Table] Java type column.")
    static let columnStatus = String(localized: "Status", comment: "[Table] Java status column.")

    // Status Messages
    static let statusReady = String(localized: "Ready to detect Java installations", comment: "[Status] Ready to detect Java.")
    static let statusDetecting = String(localized: "Detecting Java installations...", comment: "[Status] Detecting Java installations.")
    static let statusNoJavaFound = String(localized: "No Java installations found", comment: "[Status] No Java found.")

    static func statusFoundJava(_ count: Int) -> String {
      String(localized: "Found \(count) Java installation(s)", comment: "[Status] Found Java installations.")
    }

    // Messages
    static let noJavaMessage = String(localized: "No Java installations were detected on your system. Please install Java to run Minecraft.", comment: "[Message] No Java installations found message.")

    // Java Home
    static let javaHomeLabel = String(localized: "JAVA_HOME:", comment: "[Label] JAVA_HOME environment variable label.")
    static let javaHomeNotSet = String(localized: "Not set", comment: "[Text] JAVA_HOME not set.")
  }

  // MARK: - Settings
  enum Settings {
    // Window & Labels
    static let windowTitle = String(localized: "Settings", comment: "[Text] Settings window title.")
    static let title = String(localized: "Settings", comment: "[Text] Settings title.")
    static let subtitle = String(localized: "Configure application settings", comment: "[Text] Settings subtitle.")
    static let openSettingsButton = String(localized: "Settings", comment: "[Button] Open settings window.")

    // Tab Titles
    static let proxyTabTitle = String(localized: "Network Proxy", comment: "[Tab] Network proxy settings tab title.")
    static let downloadTabTitle = String(localized: "Download", comment: "[Tab] Download settings tab title.")


    // Proxy Section
    static let proxySectionTitle = String(localized: "Network Proxy", comment: "[Text] Proxy section title.")
    static let enableProxy = String(localized: "Enable Proxy", comment: "[Checkbox] Enable proxy checkbox.")
    static let proxyTypeLabel = String(localized: "Type:", comment: "[Label] Proxy type label.")
    static let proxyHostLabel = String(localized: "Host:", comment: "[Label] Proxy host label.")
    static let proxyPortLabel = String(localized: "Port:", comment: "[Label] Proxy port label.")
    static let hostPlaceholder = String(localized: "e.g., 127.0.0.1", comment: "[Placeholder] Proxy host placeholder.")
    static let portPlaceholder = String(localized: "e.g., 7890", comment: "[Placeholder] Proxy port placeholder.")

    // Download Section
    static let downloadSectionTitle = String(localized: "Download Settings", comment: "[Text] Download section title.")
    static let enableFileVerification = String(localized: "Verify File Integrity", comment: "[Checkbox] Enable file verification checkbox.")
    static let fileVerificationDescription = String(localized: "Verify SHA1 checksums when downloading files", comment: "[Text] File verification description.")
    static let maxConcurrentLabel = String(localized: "Max Concurrent Downloads:", comment: "[Label] Max concurrent downloads label.")
    static let concurrentDescription = String(localized: "Number of simultaneous downloads (1-64)", comment: "[Text] Concurrent downloads description.")
    static let requestTimeoutLabel = String(localized: "Request Timeout:", comment: "[Label] Request timeout label.")
    static let requestTimeoutDescription = String(localized: "Timeout for download requests (5-120 seconds)", comment: "[Text] Request timeout description.")
    static let resourceTimeoutLabel = String(localized: "Resource Timeout:", comment: "[Label] Resource timeout label.")
    static let resourceTimeoutDescription = String(localized: "Maximum time for downloads (60-600 seconds)", comment: "[Text] Resource timeout description.")
    static let useV2Manifest = String(localized: "Use V2 Manifest API", comment: "[Checkbox] Use V2 manifest API checkbox.")
    static let v2ManifestDescription = String(localized: "Use Piston Meta API instead of launcher meta", comment: "[Text] V2 manifest description.")

    // Buttons
    static let applyButton = String(localized: "Apply Settings", comment: "[Button] Apply settings button.")
    static let testButton = String(localized: "Test Proxy", comment: "[Button] Test proxy button.")
    static let detectSystemProxyButton = String(localized: "Detect System Proxy", comment: "[Button] Detect system proxy button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Status Messages
    static let statusReady = String(localized: "Ready", comment: "[Status] Ready status.")
    static let statusDisabled = String(localized: "Proxy disabled", comment: "[Status] Proxy disabled.")
    static let statusDetecting = String(localized: "Detecting system proxy...", comment: "[Status] Detecting system proxy.")
    static let statusSystemProxyApplied = String(localized: "System proxy detected and applied", comment: "[Status] System proxy applied.")
    static let statusNoSystemProxy = String(localized: "No system proxy detected", comment: "[Status] No system proxy found.")
    static let statusTesting = String(localized: "Testing proxy connection...", comment: "[Status] Testing proxy.")
    static let statusTestSuccess = String(localized: "Proxy connection test successful", comment: "[Status] Proxy test success.")
    static let statusTestFailed = String(localized: "Proxy connection test failed", comment: "[Status] Proxy test failed.")

    static func statusApplied(_ host: String, _ port: Int) -> String {
      String(localized: "Proxy applied: \(host):\(port)", comment: "[Status] Proxy applied.")
    }

    // Alerts
    static let alertInvalidConfigTitle = String(localized: "Invalid Configuration", comment: "[Alert] Invalid proxy configuration title.")
    static let alertInvalidConfigMessage = String(localized: "Please enter valid host and port.", comment: "[Alert] Invalid proxy configuration message.")
    static let alertTestSuccessTitle = String(localized: "Proxy Test Successful", comment: "[Alert] Proxy test successful title.")
    static let alertTestSuccessMessage = String(localized: "Proxy connection is working correctly.", comment: "[Alert] Proxy test successful message.")
    static let alertTestFailedTitle = String(localized: "Proxy Test Failed", comment: "[Alert] Proxy test failed title.")

    static func alertTestFailedMessage(_ error: String) -> String {
      String(localized: "Failed to connect through proxy:\n\(error)", comment: "[Alert] Proxy test failed message.")
    }
  }
}
