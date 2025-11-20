//
//  MockManagers.swift
//  LauncherTests
//
//  Mock implementations for unit testing
//  Demonstrates the advantages of dependency injection - easy to create test doubles
//

import Foundation
@testable import Launcher

// MARK: - Mock Instance Manager

/// Mock instance manager
/// Used for testing, no real file system operations involved
@MainActor
class MockInstanceManager: InstanceManaging {
  // ✅ Mutable instance list for testing
  var instances: [Instance] = []

  // ✅ Record method calls for test verification
  var createInstanceCalled = false
  var deleteInstanceCalled = false
  var getInstanceCalled = false
  var refreshInstancesCalled = false

  // ✅ Record call parameters
  var createdInstanceName: String?
  var createdInstanceVersionId: String?
  var deletedInstanceId: String?

  // ✅ Can preset return values or throw errors
  var shouldThrowError = false
  var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: nil)

  func createInstance(name: String, versionId: String, modLoader: String?) throws -> Instance {
    createInstanceCalled = true
    createdInstanceName = name
    createdInstanceVersionId = versionId

    if shouldThrowError {
      throw errorToThrow
    }

    let instance = Instance(name: name, versionId: versionId)
    instances.append(instance)
    return instance
  }

  func deleteInstance(_ instance: Instance) throws {
    deleteInstanceCalled = true
    deletedInstanceId = instance.id

    if shouldThrowError {
      throw errorToThrow
    }

    instances.removeAll { $0.id == instance.id }
  }

  func getInstance(byId id: String) -> Instance? {
    getInstanceCalled = true
    return instances.first { $0.id == id }
  }

  func getInstanceDirectory(for instance: Instance) -> URL {
    // Return test directory
    return URL(fileURLWithPath: "/tmp/test/instances/\(instance.name)")
  }

  func refreshInstances() {
    refreshInstancesCalled = true
    // Mock implementation: do nothing
  }

  // ✅ Helper method: reset state
  func reset() {
    instances = []
    createInstanceCalled = false
    deleteInstanceCalled = false
    getInstanceCalled = false
    refreshInstancesCalled = false
    createdInstanceName = nil
    createdInstanceVersionId = nil
    deletedInstanceId = nil
    shouldThrowError = false
  }
}

// MARK: - Mock Version Manager

/// Mock version manager
@MainActor
class MockVersionManager: VersionManaging {
  var versions: [MinecraftVersion] = []
  var latestRelease: String?
  var latestSnapshot: String?
  var isLoading = false

  // Record method calls
  var refreshVersionListCalled = false
  var getVersionCalled = false
  var getVersionDetailsCalled = false
  var isVersionInstalledCalled = false
  var downloadVersionCalled = false

  // Record call parameters
  var downloadedVersionId: String?
  var requestedVersionDetailsId: String?

  // Preset behavior
  var shouldThrowError = false
  var errorToThrow: Error = NSError(domain: "MockError", code: 2, userInfo: nil)

  func refreshVersionList() async throws {
    refreshVersionListCalled = true

    if shouldThrowError {
      throw errorToThrow
    }

    // Mock data: add some test versions
    versions = [
      MinecraftVersion(
        id: "1.20.1",
        type: .release,
        url: "https://test.com/1.20.1.json",
        time: Date(),
        releaseTime: Date()
      ),
      MinecraftVersion(
        id: "1.19.4",
        type: .release,
        url: "https://test.com/1.19.4.json",
        time: Date(),
        releaseTime: Date()
      ),
      MinecraftVersion(
        id: "23w51b",
        type: .snapshot,
        url: "https://test.com/23w51b.json",
        time: Date(),
        releaseTime: Date()
      )
    ]
    latestRelease = "1.20.1"
    latestSnapshot = "23w51b"
  }

  func getVersion(byId id: String) -> MinecraftVersion? {
    getVersionCalled = true
    return versions.first { $0.id == id }
  }

  func getVersionDetails(versionId: String) async throws -> VersionDetails {
    getVersionDetailsCalled = true
    requestedVersionDetailsId = versionId

    if shouldThrowError {
      throw errorToThrow
    }

    // Mock implementation: return mock version details
    // Note: This is a simplified Mock object, can be customized as needed in actual tests
    return VersionDetails(
      id: versionId,
      type: "release",
      mainClass: "net.minecraft.client.main.Main",
      minecraftArguments: nil,
      arguments: nil,
      libraries: [],
      downloads: VersionDetails.Downloads(
        client: VersionDetails.Download(
          url: "https://mock.test/client.jar",
          sha1: "mock-sha1",
          size: 1024
        )
      ),
      assetIndex: VersionDetails.AssetIndex(
        id: "1.20",
        url: "https://mock.test/assets.json",
        sha1: "mock-sha1",
        size: 512,
        totalSize: 1024
      ),
      assets: "1.20",
      javaVersion: VersionDetails.JavaVersion(majorVersion: 17),
      logging: nil,
      inheritsFrom: nil
    )
  }

  func isVersionInstalled(versionId: String) -> Bool {
    isVersionInstalledCalled = true
    // Mock implementation: assume all versions are installed
    return true
  }

  func downloadVersion(versionId: String) async throws {
    downloadVersionCalled = true
    downloadedVersionId = versionId

    if shouldThrowError {
      throw errorToThrow
    }

    // Mock implementation: simulate download delay
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
  }

  func reset() {
    versions = []
    latestRelease = nil
    latestSnapshot = nil
    isLoading = false
    refreshVersionListCalled = false
    getVersionCalled = false
    getVersionDetailsCalled = false
    isVersionInstalledCalled = false
    downloadVersionCalled = false
    downloadedVersionId = nil
    requestedVersionDetailsId = nil
    shouldThrowError = false
  }
}

// MARK: - Mock Game Launcher

/// Mock game launcher
class MockGameLauncher: GameLaunching {
  // Record method calls
  var launchGameCalled = false
  var getBestJavaForVersionCalled = false

  // Record call parameters
  var launchedConfig: GameLauncher.LaunchConfig?
  var requestedVersionDetails: VersionDetails?

  // Preset behavior
  var shouldThrowError = false
  var errorToThrow: Error = NSError(domain: "MockError", code: 3, userInfo: nil)
  var mockJavaInstallation: JavaInstallation?

  @MainActor
  func launchGame(config: GameLauncher.LaunchConfig) async throws {
    launchGameCalled = true
    launchedConfig = config

    if shouldThrowError {
      throw errorToThrow
    }

    // Mock implementation: simulate launch delay
    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
  }

  func getBestJavaForVersion(_ versionDetails: VersionDetails) async -> JavaInstallation? {
    getBestJavaForVersionCalled = true
    requestedVersionDetails = versionDetails

    // Return preset Java installation or default value
    if let mockJava = mockJavaInstallation {
      return mockJava
    }

    // Return mock Java installation by default
    return JavaInstallation(
      path: "/usr/bin/java",
      version: "17.0.1",
      majorVersion: 17,
      architecture: "x86_64"
    )
  }

  func reset() {
    launchGameCalled = false
    getBestJavaForVersionCalled = false
    launchedConfig = nil
    requestedVersionDetails = nil
    shouldThrowError = false
    mockJavaInstallation = nil
  }
}

// MARK: - Usage Examples

/*
 // Using in unit tests:

 @MainActor
 final class ViewControllerTests: XCTestCase {
   var sut: ViewController!  // System Under Test
   var mockInstanceManager: MockInstanceManager!
   var mockVersionManager: MockVersionManager!
   var mockGameLauncher: MockGameLauncher!

   override func setUp() {
     super.setUp()

     // ✅ Create Mock objects
     mockInstanceManager = MockInstanceManager()
     mockVersionManager = MockVersionManager()
     mockGameLauncher = MockGameLauncher()

     // ✅ Inject Mock objects
     sut = ViewController(
       instanceManager: mockInstanceManager,
       versionManager: mockVersionManager,
       gameLauncher: mockGameLauncher
     )
   }

   func testLoadInstances() {
     // Given
     let testInstance = Instance(name: "Test", versionId: "1.20.1")
     mockInstanceManager.instances = [testInstance]

     // When
     sut.viewDidLoad()

     // Then
     XCTAssertEqual(mockInstanceManager.instances.count, 1)
     XCTAssertTrue(mockInstanceManager.refreshInstancesCalled)
   }
 }
 */
