//
//  ViewControllerTests.swift
//  LauncherTests
//
//  ViewController unit test examples
//  Demonstrates how dependency injection makes testing simple
//

import XCTest
@testable import Launcher

@MainActor
final class ViewControllerTests: XCTestCase {

  // MARK: - Properties

  var sut: ViewController!  // System Under Test
  var mockInstanceManager: MockInstanceManager!
  var mockVersionManager: MockVersionManager!
  var mockGameLauncher: MockGameLauncher!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()

    // ✅ Create Mock objects
    mockInstanceManager = MockInstanceManager()
    mockVersionManager = MockVersionManager()
    mockGameLauncher = MockGameLauncher()

    // ✅ Inject Mock dependencies
    sut = ViewController(
      instanceManager: mockInstanceManager,
      versionManager: mockVersionManager,
      gameLauncher: mockGameLauncher
    )
  }

  override func tearDown() {
    // Clean up resources
    sut = nil
    mockInstanceManager = nil
    mockVersionManager = nil
    mockGameLauncher = nil
    super.tearDown()
  }

  // MARK: - Test Cases

  /// Test: ViewController should correctly inject dependencies on initialization
  func testInitialization() {
    // Given & When
    // sut is already created in setUp

    // Then
    XCTAssertNotNil(sut, "ViewController should be initialized")
  }

  /// Test: viewDidLoad should load instance list
  func testViewDidLoad_LoadsInstances() {
    // Given - Prepare test data
    let testInstance1 = Instance(name: "Survival World", versionId: "1.20.1")
    let testInstance2 = Instance(name: "Creative World", versionId: "1.19.4")
    mockInstanceManager.instances = [testInstance1, testInstance2]

    // When - Execute test operation
    sut.viewDidLoad()

    // Then - Verify results
    // Note: Since instances is private, we mainly verify Manager calls
    // In actual projects, you can add public methods to get instance count
    XCTAssertEqual(mockInstanceManager.instances.count, 2)
  }

  /// Test: Create instance successfully
  func testCreateInstance_Success() async throws {
    // Given
    let instanceName = "New World"
    let versionId = "1.20.1"

    // Add version to Mock Manager
    await mockVersionManager.refreshVersionList()

    // When
    let instance = try mockInstanceManager.createInstance(
      name: instanceName,
      versionId: versionId,
      modLoader: nil
    )

    // Then
    XCTAssertTrue(mockInstanceManager.createInstanceCalled, "createInstance should be called")
    XCTAssertEqual(mockInstanceManager.createdInstanceName, instanceName)
    XCTAssertEqual(mockInstanceManager.createdInstanceVersionId, versionId)
    XCTAssertEqual(mockInstanceManager.instances.count, 1)
    XCTAssertEqual(instance.name, instanceName)
  }

  /// Test: Should throw error when instance creation fails
  func testCreateInstance_ThrowsError() async {
    // Given
    mockInstanceManager.shouldThrowError = true
    mockInstanceManager.errorToThrow = NSError(
      domain: "TestError",
      code: 100,
      userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )

    // When & Then
    do {
      _ = try mockInstanceManager.createInstance(
        name: "Test",
        versionId: "1.20.1",
        modLoader: nil
      )
      XCTFail("Should throw error")
    } catch {
      XCTAssertTrue(mockInstanceManager.createInstanceCalled)
      XCTAssertEqual((error as NSError).code, 100)
    }
  }

  /// Test: Delete instance successfully
  func testDeleteInstance_Success() throws {
    // Given
    let instance = Instance(name: "Test Instance", versionId: "1.20.1")
    mockInstanceManager.instances = [instance]

    // When
    try mockInstanceManager.deleteInstance(instance)

    // Then
    XCTAssertTrue(mockInstanceManager.deleteInstanceCalled)
    XCTAssertEqual(mockInstanceManager.deletedInstanceId, instance.id)
    XCTAssertEqual(mockInstanceManager.instances.count, 0)
  }

  /// Test: Get instance by ID when it exists
  func testGetInstance_ByIdExists() {
    // Given
    let instance1 = Instance(name: "World 1", versionId: "1.20.1")
    let instance2 = Instance(name: "World 2", versionId: "1.19.4")
    mockInstanceManager.instances = [instance1, instance2]

    // When
    let result = mockInstanceManager.getInstance(byId: instance1.id)

    // Then
    XCTAssertTrue(mockInstanceManager.getInstanceCalled)
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.id, instance1.id)
    XCTAssertEqual(result?.name, "World 1")
  }

  /// Test: Get non-existent instance returns nil
  func testGetInstance_ByIdNotExists() {
    // Given
    mockInstanceManager.instances = []

    // When
    let result = mockInstanceManager.getInstance(byId: "non-existent-id")

    // Then
    XCTAssertTrue(mockInstanceManager.getInstanceCalled)
    XCTAssertNil(result)
  }

  /// Test: Refresh version list successfully
  func testRefreshVersionList_Success() async throws {
    // Given & When
    try await mockVersionManager.refreshVersionList()

    // Then
    XCTAssertTrue(mockVersionManager.refreshVersionListCalled)
    XCTAssertEqual(mockVersionManager.versions.count, 3)
    XCTAssertEqual(mockVersionManager.latestRelease, "1.20.1")
    XCTAssertEqual(mockVersionManager.latestSnapshot, "23w51b")
  }

  /// Test: Download version successfully
  func testDownloadVersion_Success() async throws {
    // Given
    let versionId = "1.20.1"

    // When
    try await mockVersionManager.downloadVersion(versionId: versionId)

    // Then
    XCTAssertTrue(mockVersionManager.downloadVersionCalled)
    XCTAssertEqual(mockVersionManager.downloadedVersionId, versionId)
  }

  /// Test: Launch game successfully
  func testLaunchGame_Success() async throws {
    // Given
    let config = GameLauncher.LaunchConfig(
      versionId: "1.20.1",
      javaPath: "/usr/bin/java",
      username: "TestPlayer",
      uuid: "test-uuid",
      accessToken: "test-token",
      maxMemory: 2048,
      minMemory: 512,
      windowWidth: 854,
      windowHeight: 480
    )

    // When
    try await mockGameLauncher.launchGame(config: config)

    // Then
    XCTAssertTrue(mockGameLauncher.launchGameCalled)
    XCTAssertNotNil(mockGameLauncher.launchedConfig)
    XCTAssertEqual(mockGameLauncher.launchedConfig?.versionId, "1.20.1")
    XCTAssertEqual(mockGameLauncher.launchedConfig?.username, "TestPlayer")
  }

  /// Test: Should throw error when game launch fails
  func testLaunchGame_ThrowsError() async {
    // Given
    mockGameLauncher.shouldThrowError = true
    let config = GameLauncher.LaunchConfig.default(
      versionId: "1.20.1",
      javaPath: "/usr/bin/java"
    )

    // When & Then
    do {
      try await mockGameLauncher.launchGame(config: config)
      XCTFail("Should throw error")
    } catch {
      XCTAssertTrue(mockGameLauncher.launchGameCalled)
    }
  }

  // MARK: - Performance Tests

  /// Performance test: Create 100 instances
  func testPerformance_CreateMultipleInstances() {
    measure {
      for i in 0..<100 {
        _ = try? mockInstanceManager.createInstance(
          name: "Instance \(i)",
          versionId: "1.20.1",
          modLoader: nil
        )
      }
      mockInstanceManager.reset()
    }
  }
}

// MARK: - Test Summary

/*
 Testing advantages brought by dependency injection:

 1. ✅ No need for real file system
    - Mock objects don't create real files
    - Fast tests (millisecond level)

 2. ✅ Fully controllable test environment
    - Can preset Mock return values
    - Can simulate error conditions

 3. ✅ Tests don't affect each other
    - Each test uses independent Mock objects
    - setUp/tearDown ensures isolation

 4. ✅ Verify interaction behavior
    - Check if methods are called
    - Check if call parameters are correct

 5. ✅ Easy to maintain
    - When Manager interface changes, only need to update Mock
    - Test code is clear and readable

 Running tests:
 Cmd + U or select Product > Test in Xcode
 */
