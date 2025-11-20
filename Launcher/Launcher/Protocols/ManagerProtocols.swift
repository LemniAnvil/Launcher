//
//  ManagerProtocols.swift
//  Launcher
//
//  Dependency injection protocol definitions - Define abstract interfaces for Managers
//  Purpose:
//  1. Reduce coupling: Depend on interfaces rather than concrete implementations
//  2. Improve testability: Can create Mock objects
//  3. Improve flexibility: Can switch different implementations at runtime
//

import Combine
import Foundation

// MARK: - Instance Management Protocol

/// Instance management protocol
/// Defines core capabilities for managing Minecraft instances
@MainActor
protocol InstanceManaging: AnyObject {
  /// Current list of all instances
  var instances: [Instance] { get }

  /// Create new instance
  /// - Parameters:
  ///   - name: Instance name
  ///   - versionId: Minecraft version ID
  ///   - modLoader: Mod loader (optional)
  /// - Returns: Created instance
  /// - Throws: Throws error when creation fails
  func createInstance(name: String, versionId: String, modLoader: String?) throws -> Instance

  /// Delete instance
  /// - Parameter instance: Instance to delete
  /// - Throws: Throws error when deletion fails
  func deleteInstance(_ instance: Instance) throws

  /// Get instance by ID
  /// - Parameter id: Instance ID
  /// - Returns: Found instance, returns nil if not found
  func getInstance(byId id: String) -> Instance?

  /// Get instance directory path
  /// - Parameter instance: Instance object
  /// - Returns: URL of instance directory
  func getInstanceDirectory(for instance: Instance) -> URL

  /// Refresh instance list (reload from disk)
  func refreshInstances()
}

// MARK: - Version Management Protocol

/// Version management protocol
/// Defines core capabilities for managing Minecraft version manifest and downloads
@MainActor
protocol VersionManaging: AnyObject {
  /// List of all available versions
  var versions: [MinecraftVersion] { get }

  /// Latest release version ID
  var latestRelease: String? { get }

  /// Latest snapshot version ID
  var latestSnapshot: String? { get }

  /// Whether currently loading
  var isLoading: Bool { get }

  /// Refresh version list (fetch from Mojang servers)
  /// - Throws: Network error or parsing error
  func refreshVersionList() async throws

  /// Get version info by ID
  /// - Parameter id: Version ID
  /// - Returns: Version info, returns nil if not found
  func getVersion(byId id: String) -> MinecraftVersion?

  /// Get version details (including libraries, assets, etc.)
  /// - Parameter versionId: Version ID
  /// - Returns: Version details
  /// - Throws: Throws error when version not found or download fails
  func getVersionDetails(versionId: String) async throws -> VersionDetails

  /// Check if version is installed
  /// - Parameter versionId: Version ID
  /// - Returns: Whether installed
  func isVersionInstalled(versionId: String) -> Bool

  /// Download and install version
  /// - Parameter versionId: Version ID
  /// - Throws: Throws error when download or installation fails
  func downloadVersion(versionId: String) async throws
}

// MARK: - Game Launch Protocol

/// Game launch protocol
/// Defines core capabilities for launching Minecraft game
protocol GameLaunching: AnyObject {
  /// Launch configuration
  typealias LaunchConfig = GameLauncher.LaunchConfig

  /// Launch game
  /// - Parameter config: Launch configuration
  /// - Throws: Throws error when launch fails
  @MainActor
  func launchGame(config: LaunchConfig) async throws

  /// Get best Java installation for specified version
  /// - Parameter versionDetails: Version details
  /// - Returns: Java installation info, returns nil if no suitable installation found
  func getBestJavaForVersion(_ versionDetails: VersionDetails) async -> JavaInstallation?
}

// MARK: - Usage Examples

/*
 // 1. Use protocols instead of concrete types in ViewController
 class ViewController: NSViewController {
   private let instanceManager: InstanceManaging  // ✅ Depend on protocol
   private let versionManager: VersionManaging

   // Constructor injection - Provide default values to maintain backward compatibility
   init(
     instanceManager: InstanceManaging = InstanceManager.shared,
     versionManager: VersionManaging = VersionManager.shared
   ) {
     self.instanceManager = instanceManager
     self.versionManager = versionManager
     super.init(nibName: nil, bundle: nil)
   }

   func loadInstances() {
     // Use injected dependencies
     let instances = instanceManager.instances
     // ...
   }
 }

 // 2. Production environment: Use real implementation
 let controller = ViewController()

 // 3. Test environment: Inject Mock objects
 let mockManager = MockInstanceManager()
 let testController = ViewController(instanceManager: mockManager)

 // 4. Mock object example
 class MockInstanceManager: InstanceManaging {
   var instances: [Instance] = []
   var createInstanceCalled = false

   func createInstance(name: String, versionId: String, modLoader: String?) throws -> Instance {
     createInstanceCalled = true
     let instance = Instance(name: name, versionId: versionId)
     instances.append(instance)
     return instance
   }

   // ... Implement other methods
 }
 */
