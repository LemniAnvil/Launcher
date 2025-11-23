//
//  CurseForgeAPIClient.swift
//  Launcher
//
//  CurseForge API client for fetching modpacks
//  Handles network requests with pagination and error handling
//

import Foundation

/// CurseForge API client for modpack operations
class CurseForgeAPIClient {

  // MARK: - Properties

  /// Shared singleton instance
  static let shared = CurseForgeAPIClient()

  /// API key for CurseForge API (required for authentication)
  /// Loaded from Info.plist, which gets the value from Config.xcconfig
  private let apiKey: String = {
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

  /// URLSession configuration with proxy support
  private var urlSession: URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300

    // Add proxy configuration if enabled
    if let proxyConfig = ProxyManager.shared.getProxyConfiguration() {
      config.connectionProxyDictionary = proxyConfig
    }

    return URLSession(configuration: config)
  }

  // MARK: - Initialization

  private init() {}

  // MARK: - Public Methods

  /// Search for modpacks with optional filters
  /// - Parameters:
  ///   - searchTerm: Optional search term to filter modpacks
  ///   - sortMethod: Sort method for results
  ///   - offset: Pagination offset (default: 0)
  ///   - categoryIds: Optional array of category IDs to filter by
  /// - Returns: Search response with modpacks and pagination info
  /// - Throws: APIError if request fails
  func searchModpacks(
    searchTerm: String? = nil,
    sortMethod: CurseForgeSortMethod = .featured,
    offset: Int = 0,
    categoryIds: [Int]? = nil
  ) async throws -> CurseForgeSearchResponse {
    // Validate API key
    guard !apiKey.isEmpty else {
      throw APIError.authenticationFailed
    }

    // Build URL
    let urlString = APIService.CurseForge.searchURL(
      searchTerm: searchTerm,
      sortField: sortMethod.apiValue,
      offset: offset,
      categoryIds: categoryIds
    )

    guard let url = URL(string: urlString) else {
      throw APIError.invalidURL(urlString)
    }

    // Create request with API key
    var request = URLRequest(url: url)
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Perform request
    let (data, response) = try await urlSession.data(for: request)

    // Validate response
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 {
        throw APIError.unauthorized
      } else if httpResponse.statusCode >= 500 {
        throw APIError.serverError(httpResponse.statusCode)
      } else {
        throw APIError.httpError(httpResponse.statusCode)
      }
    }

    // Decode response
    do {
      let decoder = JSONDecoder()
      let searchResponse = try decoder.decode(CurseForgeSearchResponse.self, from: data)
      return searchResponse
    } catch {
      throw APIError.decodingError(error)
    }
  }

  /// Get detailed information for a specific modpack
  /// - Parameter modpackId: Modpack ID
  /// - Returns: Modpack details
  /// - Throws: APIError if request fails
  func getModpackDetails(modpackId: Int) async throws -> CurseForgeModpack {
    // Validate API key
    guard !apiKey.isEmpty else {
      throw APIError.authenticationFailed
    }

    // Build URL
    let urlString = APIService.CurseForge.modpackDetailsURL(modpackId: modpackId)

    guard let url = URL(string: urlString) else {
      throw APIError.invalidURL(urlString)
    }

    // Create request with API key
    var request = URLRequest(url: url)
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Perform request
    let (data, response) = try await urlSession.data(for: request)

    // Validate response
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 {
        throw APIError.unauthorized
      } else if httpResponse.statusCode >= 500 {
        throw APIError.serverError(httpResponse.statusCode)
      } else {
        throw APIError.httpError(httpResponse.statusCode)
      }
    }

    // Decode response
    do {
      let decoder = JSONDecoder()
      // CurseForge API returns single item wrapped in { "data": {...} }
      struct Response: Codable {
        let data: CurseForgeModpack
      }
      let detailResponse = try decoder.decode(Response.self, from: data)
      return detailResponse.data
    } catch {
      throw APIError.decodingError(error)
    }
  }

  /// Get available files (versions) for a specific modpack
  /// - Parameter modpackId: Modpack ID
  /// - Returns: Array of modpack files/versions
  /// - Throws: APIError if request fails
  func getModpackFiles(modpackId: Int) async throws -> [CurseForgeModpackFile] {
    // Validate API key
    guard !apiKey.isEmpty else {
      throw APIError.authenticationFailed
    }

    // Build URL
    let urlString = APIService.CurseForge.modpackFilesURL(modpackId: modpackId)

    guard let url = URL(string: urlString) else {
      throw APIError.invalidURL(urlString)
    }

    // Create request with API key
    var request = URLRequest(url: url)
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Perform request
    let (data, response) = try await urlSession.data(for: request)

    // Validate response
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 {
        throw APIError.unauthorized
      } else if httpResponse.statusCode >= 500 {
        throw APIError.serverError(httpResponse.statusCode)
      } else {
        throw APIError.httpError(httpResponse.statusCode)
      }
    }

    // Decode response
    do {
      let decoder = JSONDecoder()
      let filesResponse = try decoder.decode(CurseForgeModpackFilesResponse.self, from: data)
      return filesResponse.data
    } catch {
      throw APIError.decodingError(error)
    }
  }

  /// Get available categories for modpacks
  /// - Parameters:
  ///   - gameId: Game ID (default: 432 for Minecraft)
  ///   - classId: Class ID (default: 4471 for Modpacks)
  /// - Returns: Array of categories
  /// - Throws: APIError if request fails
  func getCategories(gameId: Int = 432, classId: Int? = 4471) async throws -> [CurseForgeCategory] {
    // Validate API key
    guard !apiKey.isEmpty else {
      throw APIError.authenticationFailed
    }

    // Build URL
    let urlString = APIService.CurseForge.categoriesURL(gameId: gameId, classId: classId)

    guard let url = URL(string: urlString) else {
      throw APIError.invalidURL(urlString)
    }

    // Create request with API key
    var request = URLRequest(url: url)
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    // Perform request
    let (data, response) = try await urlSession.data(for: request)

    // Validate response
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 {
        throw APIError.unauthorized
      } else if httpResponse.statusCode >= 500 {
        throw APIError.serverError(httpResponse.statusCode)
      } else {
        throw APIError.httpError(httpResponse.statusCode)
      }
    }

    // Decode response
    do {
      let decoder = JSONDecoder()
      let categoriesResponse = try decoder.decode(CurseForgeCategoriesResponse.self, from: data)
      return categoriesResponse.data
    } catch {
      throw APIError.decodingError(error)
    }
  }
}
