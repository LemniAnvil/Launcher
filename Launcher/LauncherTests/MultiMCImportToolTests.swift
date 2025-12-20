//
//  MultiMCImportToolTests.swift
//  LauncherTests
//

import XCTest
@testable import Launcher

final class MultiMCImportToolTests: XCTestCase {

  func testParsesValidInstance() throws {
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("mmc-import-\(UUID().uuidString)")
    let instancesRoot = tempRoot.appendingPathComponent("instances")
    let instanceDir = instancesRoot.appendingPathComponent("TestInstance")

    try FileManager.default.createDirectory(at: instanceDir, withIntermediateDirectories: true)

    // Write instance.cfg
    let instanceCfg = """
    InstanceType=OneSix
    name=Test Instance
    IconKey=grass
    """
    try instanceCfg.write(to: instanceDir.appendingPathComponent("instance.cfg"), atomically: true, encoding: .utf8)

    // Write mmc-pack.json with net.minecraft component
    let mmcPack: [String: Any] = [
      "formatVersion": 1,
      "components": [
        [
          "cachedName": "Minecraft",
          "cachedRequires": [["uid": "org.lwjgl3", "suggests": "3.3.3"]],
          "cachedVersion": "1.20.4",
          "cachedVolatile": false,
          "dependencyOnly": false,
          "important": true,
          "uid": "net.minecraft",
          "version": "1.20.4"
        ],
      ],
    ]
    let packData = try JSONSerialization.data(withJSONObject: mmcPack, options: .prettyPrinted)
    try packData.write(to: instanceDir.appendingPathComponent("mmc-pack.json"))

    let tool = MultiMCImportTool(instancesRoot: instancesRoot)
    let instances = try tool.loadInstances()

    XCTAssertEqual(instances.count, 1)
    let info = try XCTUnwrap(instances.first)
    XCTAssertEqual(info.name, "Test Instance")
    XCTAssertEqual(info.versionId, "1.20.4")
    XCTAssertEqual(info.directoryName, "TestInstance")
    XCTAssertEqual(info.path, instanceDir)
  }

  func testSkipsInvalidInstance() throws {
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("mmc-import-\(UUID().uuidString)")
    let instancesRoot = tempRoot.appendingPathComponent("instances")
    let instanceDir = instancesRoot.appendingPathComponent("InvalidInstance")

    try FileManager.default.createDirectory(at: instanceDir, withIntermediateDirectories: true)
    // Missing required files => should be skipped

    let tool = MultiMCImportTool(instancesRoot: instancesRoot)
    let instances = try tool.loadInstances()
    XCTAssertTrue(instances.isEmpty)
  }
}
