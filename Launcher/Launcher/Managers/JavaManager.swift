//
//  JavaManager.swift
//  Launcher
//
//  Java installation detection and management
//

import Foundation

/// Java installation information
struct JavaInstallation: Identifiable, Hashable {
  let id = UUID()
  let path: String
  let version: String
  let type: JavaType
  let isValid: Bool

  enum JavaType: String, Hashable {
    case oracle = "Oracle JDK"
    case openjdk = "OpenJDK"
    case adoptium = "Eclipse Adoptium"
    case azul = "Azul Zulu"
    case amazon = "Amazon Corretto"
    case system = "System Java"
    case homebrew = "Homebrew"
    case unknown = "Unknown"
  }

  // Hashable conformance
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

/// Manager for detecting and managing Java installations
class JavaManager {
  static let shared = JavaManager()

  private let logger = Logger.shared

  private init() {}

  // MARK: - Common Java Installation Paths

  /// Common Java installation paths on macOS
  private var commonJavaPaths: [String] {
    return [
      // macOS standard locations
      "/Library/Java/JavaVirtualMachines",

      // Homebrew locations
      "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
      "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home",
      "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home",
      "/opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home",
      "/usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home",

      // System Java wrapper
      "/usr/bin/java",

      // User installed Java
      NSHomeDirectory() + "/Library/Java/JavaVirtualMachines",
    ]
  }

  // MARK: - Java Detection

  /// Detect all available Java installations
  func detectJavaInstallations() async -> [JavaInstallation] {
    var installations: [JavaInstallation] = []

    // Check system Java first
    if let systemJava = await checkSystemJava() {
      installations.append(systemJava)
    }

    // Check Java Virtual Machines directory
    if let jvmInstalls = await checkJVMDirectory() {
      installations.append(contentsOf: jvmInstalls)
    }

    // Check Homebrew installations
    if let homebrewJava = await checkHomebrewJava() {
      installations.append(contentsOf: homebrewJava)
    }

    // Check custom paths
    for path in commonJavaPaths where FileManager.default.fileExists(atPath: path) {
      if let installation = await checkJavaAtPath(path) {
        // Avoid duplicates
        if !installations.contains(where: { $0.path == installation.path }) {
          installations.append(installation)
        }
      }
    }

    return installations
  }

  /// Check system Java installation
  private func checkSystemJava() async -> JavaInstallation? {
    return await runJavaVersionCheck(
      executablePath: "/usr/bin/env",
      arguments: ["java", "-version"],
      javaPath: "/usr/bin/java"
    )
  }

  /// Check Java installations in /Library/Java/JavaVirtualMachines
  private func checkJVMDirectory() async -> [JavaInstallation]? {
    let jvmPath = "/Library/Java/JavaVirtualMachines"
    guard let contents = try? FileManager.default.contentsOfDirectory(atPath: jvmPath) else {
      return nil
    }

    var installations: [JavaInstallation] = []

    for item in contents where item.hasSuffix(".jdk") {
      let javaHome = "\(jvmPath)/\(item)/Contents/Home"
      if let installation = await checkJavaAtPath(javaHome) {
        installations.append(installation)
      }
    }

    return installations.isEmpty ? nil : installations
  }

  /// Check Homebrew Java installations
  private func checkHomebrewJava() async -> [JavaInstallation]? {
    var installations: [JavaInstallation] = []

    let homebrewPaths = [
      "/opt/homebrew/opt",
      "/usr/local/opt",
    ]

    for basePath in homebrewPaths {
      guard let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) else {
        continue
      }

      for item in contents where item.hasPrefix("openjdk") {
        let javaHome = "\(basePath)/\(item)/libexec/openjdk.jdk/Contents/Home"
        if FileManager.default.fileExists(atPath: javaHome) {
          if let installation = await checkJavaAtPath(javaHome) {
            installations.append(installation)
          }
        }
      }
    }

    return installations.isEmpty ? nil : installations
  }

  /// Check Java installation at specific path
  private func checkJavaAtPath(_ path: String) async -> JavaInstallation? {
    let javaBinary = path.hasSuffix("java") ? path : "\(path)/bin/java"

    guard FileManager.default.fileExists(atPath: javaBinary) else {
      return nil
    }

    return await runJavaVersionCheck(
      executablePath: javaBinary,
      arguments: ["-version"],
      javaPath: path
    )
  }

  // MARK: - Process Execution

  /// Asynchronously execute Java version check to avoid blocking the main thread
  /// - Parameters:
  ///   - executablePath: Path to Java executable
  ///   - arguments: Command line arguments
  ///   - javaPath: Java path to use in the returned result
  /// - Returns: JavaInstallation or nil
  private func runJavaVersionCheck(
    executablePath: String,
    arguments: [String],
    javaPath: String
  ) async -> JavaInstallation? {
    await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else {
          continuation.resume(returning: nil)
          return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        do {
          try process.run()

          // Use terminationHandler to avoid blocking
          process.terminationHandler = { [weak self] terminatedProcess in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            guard let output = String(data: data, encoding: .utf8) else {
              continuation.resume(returning: nil)
              return
            }

            let version = self?.parseJavaVersion(from: output) ?? "Unknown"
            let type = self?.detectJavaType(from: output) ?? .unknown

            let installation = JavaInstallation(
              path: javaPath,
              version: version,
              type: type,
              isValid: terminatedProcess.terminationStatus == 0
            )

            continuation.resume(returning: installation)
          }
        } catch {
          self.logger.error("Failed to check Java at \(javaPath): \(error.localizedDescription)")
          continuation.resume(returning: nil)
        }
      }
    }
  }

  // MARK: - Version Parsing

  /// Parse Java version from output string
  private func parseJavaVersion(from output: String) -> String? {
    // Match version patterns like "1.8.0_292", "11.0.12", "17.0.1"
    let patterns = [
      "version \"([^\"]+)\"",
      "openjdk version \"([^\"]+)\"",
      "java version \"([^\"]+)\"",
    ]

    for pattern in patterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let nsString = output as NSString
        let results = regex.matches(in: output, options: [], range: NSRange(location: 0, length: nsString.length))

        if let match = results.first, match.numberOfRanges > 1 {
          let versionRange = match.range(at: 1)
          return nsString.substring(with: versionRange)
        }
      }
    }

    return nil
  }

  /// Detect Java type from version output
  private func detectJavaType(from output: String) -> JavaInstallation.JavaType {
    let lowerOutput = output.lowercased()

    if lowerOutput.contains("openjdk") {
      if lowerOutput.contains("temurin") || lowerOutput.contains("adoptium") {
        return .adoptium
      } else if lowerOutput.contains("zulu") {
        return .azul
      } else if lowerOutput.contains("corretto") {
        return .amazon
      } else if lowerOutput.contains("homebrew") {
        return .homebrew
      }
      return .openjdk
    } else if lowerOutput.contains("oracle") {
      return .oracle
    }

    return .unknown
  }

  // MARK: - Java Validation

  /// Validate if Java installation can run Minecraft
  func validateJavaForMinecraft(_ installation: JavaInstallation) -> (isValid: Bool, message: String) {
    guard installation.isValid else {
      return (false, "Java installation is not valid")
    }

    // Extract major version
    let versionComponents = installation.version.split(separator: ".")
    guard let firstComponent = versionComponents.first,
          let majorVersion = Int(firstComponent.replacingOccurrences(of: "\"", with: "")) else {
      return (false, "Cannot parse Java version")
    }

    // Minecraft 1.17+ requires Java 16+, 1.18+ requires Java 17+
    if majorVersion >= 17 {
      return (true, "Compatible with all Minecraft versions")
    } else if majorVersion >= 16 {
      return (true, "Compatible with Minecraft 1.17+")
    } else if majorVersion >= 8 {
      return (true, "Compatible with Minecraft 1.16 and below")
    } else {
      return (false, "Java version too old (minimum: Java 8)")
    }
  }

  /// Get JAVA_HOME environment variable
  func getJavaHome() -> String? {
    return ProcessInfo.processInfo.environment["JAVA_HOME"]
  }

  /// Set JAVA_HOME for current process
  func setJavaHome(_ path: String) {
    setenv("JAVA_HOME", path, 1)
  }
}
