//
//  CurseForgeModels.swift
//  Launcher
//
//  CurseForge API data models for modpack browsing
//  Based on CurseForge API v1 specification
//

import Foundation

// MARK: - Modpack Author

/// Represents a CurseForge modpack author
struct CurseForgeAuthor: Codable, Hashable {
  let id: Int
  let name: String
  let url: String

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case url
  }
}

// MARK: - Modpack Logo

/// Represents a CurseForge modpack logo/thumbnail
struct CurseForgeLogo: Codable, Hashable {
  let id: Int
  let title: String
  let thumbnailUrl: String
  let url: String

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case thumbnailUrl
    case url
  }
}

// MARK: - Modpack Links

/// Represents CurseForge modpack related links
struct CurseForgeLinks: Codable, Hashable {
  let websiteUrl: String?
  let wikiUrl: String?
  let issuesUrl: String?
  let sourceUrl: String?

  enum CodingKeys: String, CodingKey {
    case websiteUrl
    case wikiUrl
    case issuesUrl
    case sourceUrl
  }
}

// MARK: - Modpack

/// Represents a CurseForge modpack
struct CurseForgeModpack: Codable, Hashable, Identifiable {
  let id: Int
  let name: String
  let slug: String
  let summary: String
  let downloadCount: Int
  let dateCreated: String
  let dateModified: String
  let dateReleased: String
  let authors: [CurseForgeAuthor]
  let logo: CurseForgeLogo?
  let links: CurseForgeLinks

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case slug
    case summary
    case downloadCount
    case dateCreated
    case dateModified
    case dateReleased
    case authors
    case logo
    case links
  }

  // Hashable conformance
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.id == rhs.id
  }

  /// Get logo URL for display (thumbnail preferred, fallback to full size)
  var logoUrl: String? {
    return logo?.thumbnailUrl.isEmpty == false ? logo?.thumbnailUrl : logo?.url
  }

  /// Get primary author name
  var primaryAuthor: String {
    return authors.first?.name ?? "Unknown"
  }

  /// Format download count for display (e.g., "1.2M", "45K")
  var formattedDownloadCount: String {
    let count = Double(downloadCount)
    if count >= 1_000_000 {
      return String(format: "%.1fM", count / 1_000_000)
    } else if count >= 1_000 {
      return String(format: "%.1fK", count / 1_000)
    } else {
      return "\(downloadCount)"
    }
  }
}

// MARK: - Pagination

/// Represents pagination metadata from CurseForge API
struct CurseForgePagination: Codable {
  let index: Int
  let pageSize: Int
  let resultCount: Int
  let totalCount: Int

  enum CodingKeys: String, CodingKey {
    case index
    case pageSize
    case resultCount
    case totalCount
  }

  /// Check if there are more results available
  var hasMoreResults: Bool {
    return (index + resultCount) < totalCount
  }

  /// Get next page index
  var nextIndex: Int {
    return index + pageSize
  }
}

// MARK: - Search Response

/// Represents CurseForge search API response
struct CurseForgeSearchResponse: Codable {
  let data: [CurseForgeModpack]
  let pagination: CurseForgePagination

  enum CodingKeys: String, CodingKey {
    case data
    case pagination
  }
}

// MARK: - Sort Method

/// CurseForge modpack sorting methods
enum CurseForgeSortMethod: Int, CaseIterable {
  case featured = 1
  case popularity = 2
  case lastUpdated = 3
  case name = 4
  case author = 5
  case totalDownloads = 6
  case category = 7
  case gameVersion = 8

  var displayName: String {
    switch self {
    case .featured:
      return "Featured"
    case .popularity:
      return "Popularity"
    case .lastUpdated:
      return "Last Updated"
    case .name:
      return "Name"
    case .author:
      return "Author"
    case .totalDownloads:
      return "Downloads"
    case .category:
      return "Category"
    case .gameVersion:
      return "Game Version"
    }
  }

  /// API parameter value
  var apiValue: Int {
    return self.rawValue
  }
}
