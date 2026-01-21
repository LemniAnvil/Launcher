//
//  CurseForgeAPIClient.swift
//  Launcher
//
//  CurseForge API client provider (CraftKit-backed)
//

import CraftKit
import Foundation

/// Factory for CraftKit CurseForge API clients with app configuration.
enum CurseForgeClientProvider {

  /// Creates a CraftKit CurseForge API client using the app's API key and proxy settings.
  static func makeClient() -> CurseForgeAPIClient {
    let configuration = CurseForgeAPIConfiguration(apiKey: apiKey)
    let session = URLSessionFactory.createSession()
    return CurseForgeAPIClient(configuration: configuration, session: session)
  }

  // MARK: - Private

  private static let apiKey: String = {
    guard let key = Bundle.main.infoDictionary?["CurseForgeAPIKey"] as? String,
          !key.isEmpty,
          !key.contains("YOUR_") else {
      fatalError("""
        ❌ CurseForge API key not configured!

        Please follow these steps:
        1. Copy Config.xcconfig.template to Config.xcconfig
        2. Replace YOUR_CURSEFORGE_API_KEY_HERE with your actual API key
        3. In Xcode, select your project → Info tab → Configurations
        4. Set Config.xcconfig for both Debug and Release configurations
        5. Clean build folder (⌘⇧K) and rebuild

        Get your API key from: https://console.curseforge.com/
        """)
    }
    return key
  }()
}
