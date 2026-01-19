//
//  SkinManagementError.swift
//  Launcher
//
//  Errors for skin management operations
//

import Foundation

/// Errors that can occur during skin management operations
enum SkinManagementError: LocalizedError {
  case noAccountSelected
  case invalidURL
  case fileTooLarge(size: Int)
  case invalidFormat
  case invalidDimensions(width: Int, height: Int)
  case tokenExpired
  case networkError(Error)
  case serverError(String)
  case uploadFailed(String)
  case downloadFailed(String)

  var errorDescription: String? {
    switch self {
    case .noAccountSelected:
      return Localized.Account.errorNoAccountSelected

    case .invalidURL:
      return Localized.Account.errorInvalidURL

    case .fileTooLarge(let size):
      return String(format: Localized.Account.errorFileTooLarge, size / 1024)

    case .invalidFormat:
      return Localized.Account.errorInvalidFormat

    case .invalidDimensions(let width, let height):
      return String(format: Localized.Account.errorInvalidDimensions, width, height)

    case .tokenExpired:
      return Localized.Account.errorTokenExpired

    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"

    case .serverError(let message):
      return "Server error: \(message)"

    case .uploadFailed(let reason):
      return "Upload failed: \(reason)"

    case .downloadFailed(let reason):
      return "Download failed: \(reason)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .fileTooLarge:
      return Localized.Account.suggestionCompressSkin

    case .invalidDimensions:
      return Localized.Account.suggestionResizeSkin

    case .tokenExpired:
      return Localized.Account.suggestionRefreshAccount

    case .networkError:
      return "Please check your internet connection and try again."

    case .serverError:
      return "Please try again later. If the problem persists, contact support."

    case .noAccountSelected:
      return "Please select a Microsoft account from the list."

    case .invalidURL:
      return "The skin URL appears to be invalid. Please try a different skin."

    default:
      return nil
    }
  }
}
