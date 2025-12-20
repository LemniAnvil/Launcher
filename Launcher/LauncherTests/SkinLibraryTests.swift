//
//  SkinLibraryTests.swift
//  LauncherTests
//

import XCTest
@testable import Launcher

final class SkinLibraryTests: XCTestCase {

  func testListAndSaveSkins() throws {
    let tempRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("skins-\(UUID().uuidString)")
    let library = SkinLibrary(directory: tempRoot)

    // Initially empty
    XCTAssertTrue(try library.listSkins().isEmpty)

    // Save a skin
    let pngData = Data(repeating: 0, count: 10)
    let savedURL = try library.saveSkin(named: "TestSkin", data: pngData)
    XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))

    // List and validate metadata
    let skins = try library.listSkins()
    XCTAssertEqual(skins.count, 1)
    let skin = try XCTUnwrap(skins.first)
    XCTAssertEqual(skin.name, "TestSkin")
    XCTAssertEqual(skin.fileURL, savedURL)
    XCTAssertEqual(skin.fileSize, 10)
  }
}
