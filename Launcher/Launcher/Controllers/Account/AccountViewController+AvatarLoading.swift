//
//  AccountViewController+AvatarLoading.swift
//  Launcher
//
//  Avatar loading methods for AccountViewController
//

import AppKit

// MARK: - Mojang Profile Response Models

private struct MojangProfileResponse: Codable {
  let id: String
  let name: String
  let properties: [ProfileProperty]
}

private struct ProfileProperty: Codable {
  let name: String
  let value: String
}

private struct TexturesProperty: Codable {
  let timestamp: Int64
  let profileId: String
  let profileName: String
  let textures: Textures
}

private struct Textures: Codable {
  let SKIN: TextureInfo?
  let CAPE: TextureInfo?
}

private struct TextureInfo: Codable {
  let url: String
}

extension AccountViewController {
  // MARK: - Avatar Loading

  func loadMinecraftAvatar(uuid: String?, username: String? = nil, completion: @escaping (NSImage?) -> Void) {
    if let uuid = uuid {
      // For Microsoft accounts, fetch skin from Mojang API
      loadAvatarFromMojangAPI(uuid: uuid, completion: completion)
    } else if let username = username {
      // For offline accounts, use Steve skin via MineAvatar as fallback
      loadAvatarFromFallbackService(username: username, completion: completion)
    } else {
      completion(nil)
    }
  }

  // MARK: - Mojang API Avatar Loading

  private func loadAvatarFromMojangAPI(uuid: String, completion: @escaping (NSImage?) -> Void) {
    // Step 1: Fetch player profile from Mojang session server
    let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
    let profileURLString = "https://sessionserver.mojang.com/session/minecraft/profile/\(cleanUUID)"

    guard let profileURL = URL(string: profileURLString) else {
      completion(nil)
      return
    }

    URLSession.shared.dataTask(with: profileURL) { [weak self] data, _, error in
      guard let data = data,
            error == nil,
            let profileResponse = try? JSONDecoder().decode(MojangProfileResponse.self, from: data) else {
        // Fallback to Crafatar if API fails
        self?.loadAvatarFromFallbackService(uuid: uuid, completion: completion)
        return
      }

      // Step 2: Decode base64 textures property
      guard let texturesProperty = profileResponse.properties.first(where: { $0.name == "textures" }),
            let texturesData = Data(base64Encoded: texturesProperty.value),
            let textures = try? JSONDecoder().decode(TexturesProperty.self, from: texturesData),
            let skinURL = textures.textures.SKIN?.url else {
        // Fallback if no skin texture found
        self?.loadAvatarFromFallbackService(uuid: uuid, completion: completion)
        return
      }

      // Step 3: Download skin texture and extract avatar
      self?.downloadSkinAndExtractAvatar(from: skinURL, completion: completion)
    }
    .resume()
  }

  private func downloadSkinAndExtractAvatar(from urlString: String, completion: @escaping (NSImage?) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }

    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let data = data,
            error == nil,
            let skinImage = NSImage(data: data) else {
        completion(nil)
        return
      }

      // Step 4: Extract avatar from skin texture
      let avatar = self?.extractAvatarFromSkin(skinImage)
      completion(avatar)
    }
    .resume()
  }

  private func extractAvatarFromSkin(_ skinImage: NSImage) -> NSImage? {
    // Minecraft skin format: 64x64 or 64x32 texture
    // Face (front layer) is at coordinates (8, 8) with size 8x8
    // Head overlay (second layer) is at coordinates (40, 8) with size 8x8

    guard let cgImage = skinImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height

    // Validate skin dimensions (should be 64x64 or 64x32)
    guard width == 64 && (height == 64 || height == 32) else {
      return skinImage // Return original if unexpected format
    }

    // Create a new image with face + overlay combined
    let faceSize: CGFloat = 8
    let scale: CGFloat = 16 // Scale up to 128x128 for better quality
    let outputSize = faceSize * scale

    guard let colorSpace = cgImage.colorSpace else {
      return nil
    }

    // Create bitmap context for rendering
    guard let context = CGContext(
      data: nil,
      width: Int(outputSize),
      height: Int(outputSize),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }

    // Disable interpolation for pixel-perfect rendering
    context.interpolationQuality = .none

    // Draw base face layer (8x8 pixels from position 8,8)
    if let faceLayer = cgImage.cropping(to: CGRect(x: 8, y: 8, width: 8, height: 8)) {
      context.draw(faceLayer, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
    }

    // Draw overlay layer (8x8 pixels from position 40,8) if it exists
    if let overlayLayer = cgImage.cropping(to: CGRect(x: 40, y: 8, width: 8, height: 8)) {
      context.draw(overlayLayer, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
    }

    // Create final image
    guard let resultCGImage = context.makeImage() else {
      return nil
    }

    return NSImage(cgImage: resultCGImage, size: NSSize(width: outputSize, height: outputSize))
  }

  // MARK: - Fallback Service

  private func loadAvatarFromFallbackService(uuid: String? = nil, username: String? = nil, completion: @escaping (NSImage?) -> Void) {
    let avatarURLString: String

    if let uuid = uuid {
      // Fallback to Crafatar for UUID-based avatars
      let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
      avatarURLString = "https://crafatar.com/avatars/\(cleanUUID)?size=128&overlay"
    } else if let username = username {
      // For offline accounts, use Minotar
      avatarURLString = "https://minotar.net/avatar/\(username)/128"
    } else {
      completion(nil)
      return
    }

    guard let url = URL(string: avatarURLString) else {
      completion(nil)
      return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
      guard let data = data,
            error == nil,
            let image = NSImage(data: data) else {
        completion(nil)
        return
      }
      completion(image)
    }
    .resume()
  }
}
