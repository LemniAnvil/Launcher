//
//  AccountViewController+AvatarLoading.swift
//  Launcher
//
//  Avatar loading methods for AccountViewController
//

import AppKit

extension AccountViewController {
  // MARK: - Avatar Loading

  func loadMinecraftAvatar(uuid: String?, username: String? = nil, completion: @escaping (NSImage?) -> Void) {
    // Use Crafatar service for avatar rendering
    // https://crafatar.com provides Minecraft player avatars
    let avatarURLString: String

    if let uuid = uuid {
      // Format UUID properly (remove dashes for Crafatar)
      let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
      // Use size 128 for better quality, overlay for skin layers
      avatarURLString = "https://crafatar.com/avatars/\(cleanUUID)?size=128&overlay"
    } else if let username = username {
      // For offline accounts, use Steve skin via MineAvatar
      avatarURLString = "https://minotar.net/avatar/\(username)/128"
    } else {
      completion(nil)
      return
    }

    guard let url = URL(string: avatarURLString) else {
      completion(nil)
      return
    }

    // Load image asynchronously
    URLSession.shared.dataTask(with: url) { data, response, error in
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
