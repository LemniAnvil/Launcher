//
//  SkinValidator.swift
//  Launcher
//
//  Skin file validation utility
//

import Foundation
import AppKit

/// Validates Minecraft skin files
final class SkinValidator {

  // MARK: - Constants

  private static let maxFileSize: Int = 24 * 1024  // 24 KB
  private static let validDimensions: [(width: Int, height: Int)] = [
    (64, 32),   // Classic skin format
    (64, 64)    // New skin format with layers
  ]

  // MARK: - Validation Methods

  /// Validates a skin image data
  /// - Parameter imageData: The PNG image data to validate
  /// - Returns: Tuple containing width and height of the validated image
  /// - Throws: SkinValidationError if validation fails
  static func validate(_ imageData: Data) throws -> (width: Int, height: Int) {
    // 1. Validate file size
    try validateFileSize(imageData)

    // 2. Extract PNG dimensions
    guard let dimensions = extractPNGInfo(imageData) else {
      throw SkinValidationError.invalidFormat
    }

    // 3. Validate dimensions
    try validateDimensions(width: dimensions.width, height: dimensions.height)

    return dimensions
  }

  /// Validates file size
  /// - Parameter data: The file data
  /// - Throws: SkinValidationError.fileTooLarge if file exceeds maximum size
  static func validateFileSize(_ data: Data) throws {
    if data.count > maxFileSize {
      throw SkinValidationError.fileTooLarge(actual: data.count, max: maxFileSize)
    }
  }

  /// Validates skin dimensions
  /// - Parameters:
  ///   - width: Image width
  ///   - height: Image height
  /// - Throws: SkinValidationError.invalidDimensions if dimensions are not valid
  static func validateDimensions(width: Int, height: Int) throws {
    let isValid = validDimensions.contains { $0.width == width && $0.height == height }
    if !isValid {
      throw SkinValidationError.invalidDimensions(width: width, height: height)
    }
  }

  /// Extracts PNG image dimensions from raw data
  /// - Parameter data: PNG file data
  /// - Returns: Tuple containing width and height, or nil if not a valid PNG
  static func extractPNGInfo(_ data: Data) -> (width: Int, height: Int)? {
    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    guard data.count >= 24 else { return nil }

    let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    let signature = [UInt8](data.prefix(8))

    guard signature == pngSignature else { return nil }

    // IHDR chunk starts at byte 8
    // Width is at bytes 16-19 (big-endian)
    // Height is at bytes 20-23 (big-endian)
    let widthBytes = data.subdata(in: 16..<20)
    let heightBytes = data.subdata(in: 20..<24)

    let width = Int(widthBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
    let height = Int(heightBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })

    return (width: width, height: height)
  }

  /// Alternative validation using NSImage (slower but more reliable)
  /// - Parameter data: Image data
  /// - Returns: Tuple containing width and height, or nil if invalid
  static func validateWithNSImage(_ data: Data) -> (width: Int, height: Int)? {
    guard let image = NSImage(data: data),
          let representation = image.representations.first else {
      return nil
    }

    return (width: representation.pixelsWide, height: representation.pixelsHigh)
  }
}

// MARK: - Validation Error

/// Errors that can occur during skin validation
enum SkinValidationError: LocalizedError {
  case fileTooLarge(actual: Int, max: Int)
  case invalidFormat
  case invalidDimensions(width: Int, height: Int)
  case corruptedFile

  var errorDescription: String? {
    switch self {
    case .fileTooLarge(let actual, let max):
      return String(format: Localized.Account.errorFileTooLarge, actual / 1024)

    case .invalidFormat:
      return Localized.Account.errorInvalidFormat

    case .invalidDimensions(let width, let height):
      return String(format: Localized.Account.errorInvalidDimensions, width, height)

    case .corruptedFile:
      return "The skin file appears to be corrupted or incomplete."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .fileTooLarge:
      return Localized.Account.suggestionCompressSkin

    case .invalidDimensions:
      return Localized.Account.suggestionResizeSkin

    case .invalidFormat, .corruptedFile:
      return "Please ensure the file is a valid PNG image."
    }
  }
}
