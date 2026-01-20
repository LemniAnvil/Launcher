//
//  SkinHeadRenderer.swift
//  Launcher
//
//  Extracts and renders the head portion from Minecraft skin textures
//

import AppKit
import Foundation

final class SkinHeadRenderer {

  /// Extract the head face portion from a Minecraft skin texture (no overlay)
  /// - Parameter skinImage: The full skin texture image
  /// - Returns: An image containing only the head face
  static func extractHead(from skinImage: NSImage) -> NSImage? {
    guard let faceCrop = extractFaceCGImage(from: skinImage) else {
      return nil
    }

    let faceSize = CGSize(width: faceCrop.width, height: faceCrop.height)
    return NSImage(cgImage: faceCrop, size: faceSize)
  }

  /// Extract head and render it at a specific size without interpolation
  /// - Parameters:
  ///   - skinImage: The full skin texture image
  ///   - targetSize: The desired output size
  /// - Returns: A scaled head image
  static func extractHeadScaled(from skinImage: NSImage, targetSize: CGSize) -> NSImage? {
    guard let faceCrop = extractFaceCGImage(from: skinImage) else {
      return nil
    }
    return createScaledBitmap(from: faceCrop, targetSize: targetSize)
  }

  /// Extract head from a file URL
  /// - Parameter fileURL: URL to the skin PNG file
  /// - Returns: The extracted head image
  static func extractHead(from fileURL: URL) -> NSImage? {
    guard let skinImage = NSImage(contentsOf: fileURL) else {
      return nil
    }
    return extractHead(from: skinImage)
  }

  /// Extract head from a file URL with scaling
  /// - Parameters:
  ///   - fileURL: URL to the skin PNG file
  ///   - targetSize: The desired output size
  /// - Returns: A scaled head image
  static func extractHeadScaled(from fileURL: URL, targetSize: CGSize) -> NSImage? {
    guard let skinImage = NSImage(contentsOf: fileURL) else {
      return nil
    }
    return extractHeadScaled(from: skinImage, targetSize: targetSize)
  }

  // MARK: - Helpers

  private static func extractFaceCGImage(from skinImage: NSImage) -> CGImage? {
    guard let cgImage = skinImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height

    // Calculate scale factor based on 64px-wide base texture.
    let scale = width / 64
    // Head face coordinates (8x8 pixels at 1x scale) from top-left.
    // Use the same texture coordinate convention as cape extraction (no Y flip).
    let faceRect = CGRect(
      x: CGFloat(8 * scale),
      y: CGFloat(8 * scale),
      width: CGFloat(8 * scale),
      height: CGFloat(8 * scale)
    )

    return cgImage.cropping(to: faceRect)
  }

  private static func createScaledBitmap(from cgImage: CGImage, targetSize: CGSize) -> NSImage? {
    let targetWidth = Int(targetSize.width.rounded())
    let targetHeight = Int(targetSize.height.rounded())
    guard targetWidth > 0, targetHeight > 0 else {
      return nil
    }

    let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
      data: nil,
      width: targetWidth,
      height: targetHeight,
      bitsPerComponent: 8,
      bytesPerRow: targetWidth * 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }

    context.interpolationQuality = .none
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

    guard let scaledCGImage = context.makeImage() else {
      return nil
    }

    return NSImage(
      cgImage: scaledCGImage,
      size: NSSize(width: targetWidth, height: targetHeight)
    )
  }
}
