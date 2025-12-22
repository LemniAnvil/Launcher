//
//  AccountCellView+AvatarLoading.swift
//  Launcher
//
//  Avatar loading extension for AccountCellView
//

import AppKit
import MojangAPI

extension AccountCellView {
  // MARK: - Avatar Loading

  func loadMinecraftAvatar(
    uuid: String?,
    username: String? = nil,
    completion: @escaping (NSImage?) -> Void
  ) {
    if let uuid = uuid {
      loadAvatarFromMojangAPI(uuid: uuid, completion: completion)
    } else if let username = username {
      loadAvatarFromFallbackService(username: username, completion: completion)
    } else {
      completion(nil)
    }
  }

  func loadAvatarFromMojangAPI(uuid: String, completion: @escaping (NSImage?) -> Void) {
    Task {
      do {
        let formattedUUID: String
        if uuid.contains("-") {
          formattedUUID = uuid
        } else {
          let chars = Array(uuid)
          formattedUUID =
            "\(String(chars[0..<8]))-\(String(chars[8..<12]))-\(String(chars[12..<16]))-\(String(chars[16..<20]))-\(String(chars[20..<32]))"
        }

        guard let playerUUID = UUID(uuidString: formattedUUID) else {
          await MainActor.run {
            self.loadAvatarFromFallbackService(uuid: uuid, completion: completion)
          }
          return
        }

        let mojangAPI = MojangAPI()
        let profile = try await mojangAPI.playerService.getPlayerProfile(uuid: playerUUID)

        guard let skinURL = profile.skins.first?.url else {
          await MainActor.run {
            self.loadAvatarFromFallbackService(uuid: uuid, completion: completion)
          }
          return
        }

        await downloadSkinAndExtractAvatar(from: skinURL.absoluteString, completion: completion)
      } catch {
        await MainActor.run {
          self.loadAvatarFromFallbackService(uuid: uuid, completion: completion)
        }
      }
    }
  }

  func downloadSkinAndExtractAvatar(
    from urlString: String, completion: @escaping (NSImage?) -> Void
  ) {
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }

    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let data = data,
        error == nil,
        let skinImage = NSImage(data: data)
      else {
        completion(nil)
        return
      }

      let avatar = self?.extractAvatarFromSkin(skinImage)
      completion(avatar)
    }
    .resume()
  }

  func extractAvatarFromSkin(_ skinImage: NSImage) -> NSImage? {
    guard let cgImage = skinImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height

    guard width == 64 && (height == 64 || height == 32) else {
      return skinImage
    }

    let faceSize: CGFloat = 8
    let scale: CGFloat = 16
    let outputSize = faceSize * scale

    guard let colorSpace = cgImage.colorSpace else {
      return nil
    }

    guard
      let context = CGContext(
        data: nil,
        width: Int(outputSize),
        height: Int(outputSize),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      return nil
    }

    context.interpolationQuality = .none

    if let faceLayer = cgImage.cropping(to: CGRect(x: 8, y: 8, width: 8, height: 8)) {
      context.draw(faceLayer, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
    }

    if let overlayLayer = cgImage.cropping(to: CGRect(x: 40, y: 8, width: 8, height: 8)) {
      context.draw(overlayLayer, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
    }

    guard let resultCGImage = context.makeImage() else {
      return nil
    }

    return NSImage(cgImage: resultCGImage, size: NSSize(width: outputSize, height: outputSize))
  }

  func loadAvatarFromFallbackService(
    uuid: String? = nil,
    username: String? = nil,
    completion: @escaping (NSImage?) -> Void
  ) {
    let avatarURLString: String

    if let uuid = uuid {
      let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
      avatarURLString = "https://crafatar.com/avatars/\(cleanUUID)?size=128&overlay"
    } else if let username = username {
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
        let image = NSImage(data: data)
      else {
        completion(nil)
        return
      }
      completion(image)
    }
    .resume()
  }
}
