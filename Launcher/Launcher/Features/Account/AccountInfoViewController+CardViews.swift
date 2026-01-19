//
//  AccountInfoViewController+CardViews.swift
//  Launcher
//
//  Helper methods for creating skin and cape card views
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

extension AccountInfoViewController {

  // MARK: - Helper Methods

  /// Extract the front part of a cape texture and scale it up using nearest-neighbor
  /// Cape texture size: 64x32
  /// Front area: x=1, y=1, width=10, height=16
  private func extractCapeFront(from image: NSImage) -> NSImage? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height

    // Cape texture standard size is 64x32
    // Front part is at (1, 1) with size 10x16
    let scaleX = CGFloat(width) / 64.0
    let scaleY = CGFloat(height) / 32.0

    let frontRect = CGRect(
      x: 1 * scaleX,
      y: 1 * scaleY,
      width: 10 * scaleX,
      height: 16 * scaleY
    )

    guard let croppedCGImage = cgImage.cropping(to: frontRect) else {
      return nil
    }

    // Scale up the image using nearest-neighbor interpolation
    return createScaledBitmap(from: croppedCGImage, scale: 10)
  }

  /// Create a scaled bitmap using nearest-neighbor interpolation (pixel-perfect)
  /// - Parameters:
  ///   - cgImage: Source image
  ///   - scale: Scale factor (e.g., 10 means 10x larger)
  /// - Returns: Scaled NSImage with sharp pixels
  private func createScaledBitmap(from cgImage: CGImage, scale: Int) -> NSImage? {
    let sourceWidth = cgImage.width
    let sourceHeight = cgImage.height
    let scaledWidth = sourceWidth * scale
    let scaledHeight = sourceHeight * scale

    // Create bitmap context with no color space conversion
    guard let colorSpace = cgImage.colorSpace,
          let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: scaledWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
      return nil
    }

    // Disable interpolation for pixel-perfect scaling
    context.interpolationQuality = .none

    // Draw the image scaled up
    context.draw(
      cgImage,
      in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
    )

    // Create CGImage from context
    guard let scaledCGImage = context.makeImage() else {
      return nil
    }

    // Create NSImage with the scaled bitmap
    let scaledImage = NSImage(
      cgImage: scaledCGImage,
      size: NSSize(width: scaledWidth, height: scaledHeight)
    )

    return scaledImage
  }

  // MARK: - Skin Card

  func createSkinCard(skin: SkinResponse) -> NSView {
    let card = NSView()
    card.wantsLayer = true
    card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    card.layer?.cornerRadius = 8

    // Skin preview image
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.layer?.cornerRadius = 4
    imageView.layer?.masksToBounds = true
    imageView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    card.addSubview(imageView)

    // Load skin image asynchronously
    if let url = URL(string: skin.url) {
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: url.s)
          if let image = NSImage(data: data) {
            await MainActor.run {
              imageView.image = image
            }
          }
        } catch {
          // If loading fails, show placeholder
          await MainActor.run {
            let placeholderImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            imageView.image = placeholderImage
            imageView.contentTintColor = .secondaryLabelColor
          }
        }
      }
    }

    // Skin alias/name
    let nameLabel = DisplayLabel(
      text: skin.alias ?? Localized.Account.unnamedSkin,
      font: .systemFont(ofSize: 13, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    card.addSubview(nameLabel)

    // Active badge
    if skin.isActive {
      let activeBadge = NSView()
      activeBadge.wantsLayer = true
      activeBadge.layer?.backgroundColor = NSColor.systemGreen.cgColor
      activeBadge.layer?.cornerRadius = 9

      let activeLabel = DisplayLabel(
        text: Localized.Account.stateActive,
        font: .systemFont(ofSize: 9, weight: .semibold),
        textColor: .white,
        alignment: .center
      )
      activeBadge.addSubview(activeLabel)

      card.addSubview(activeBadge)

      activeBadge.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(10)
        make.right.equalToSuperview().offset(-10)
        make.height.equalTo(18)
        make.width.greaterThanOrEqualTo(50)
      }

      activeLabel.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
      }
    }

    // Variant and State in one line
    let variantStateLabel = DisplayLabel(
      text: "\(Localized.Account.skinVariant): \(skin.variant)  •  \(Localized.Account.skinState): \(skin.state)",
      font: .systemFont(ofSize: 10),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    card.addSubview(variantStateLabel)

    // Layout - image on the left
    imageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.top.equalToSuperview().offset(10)
      make.width.height.equalTo(80)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.left.equalTo(imageView.snp.right).offset(12)
      make.right.equalToSuperview().offset(-80)
    }

    variantStateLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(6)
      make.left.equalTo(imageView.snp.right).offset(12)
      make.right.equalToSuperview().offset(-12)
    }

    // Action buttons
    let buttonStack = NSStackView()
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 8
    buttonStack.distribution = .fillEqually
    card.addSubview(buttonStack)

    // Add buttons based on skin state
    if !skin.isActive {
      // "Activate" button for inactive skins
      let activateButton = NSButton(
        title: Localized.Account.activateSkin,
        target: self,
        action: #selector(activateSkinButtonClicked(_:))
      )
      activateButton.bezelStyle = .rounded
      activateButton.identifier = NSUserInterfaceItemIdentifier(skin.id)
      buttonStack.addArrangedSubview(activateButton)
    }

    // "Download" button for all skins
    let downloadButton = NSButton(
      title: Localized.Account.downloadSkin,
      target: self,
      action: #selector(downloadSkinButtonClicked(_:))
    )
    downloadButton.bezelStyle = .rounded
    downloadButton.identifier = NSUserInterfaceItemIdentifier(skin.id)
    buttonStack.addArrangedSubview(downloadButton)

    // "Reset to Default" button for active skin
    if skin.isActive {
      let resetButton = NSButton(
        title: Localized.Account.resetSkin,
        target: self,
        action: #selector(resetSkinButtonClicked(_:))
      )
      resetButton.bezelStyle = .rounded
      resetButton.hasDestructiveAction = true
      buttonStack.addArrangedSubview(resetButton)
    }

    buttonStack.snp.makeConstraints { make in
      make.top.equalTo(imageView.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(12)
      make.bottom.equalToSuperview().offset(-10)
      make.height.equalTo(28)
    }

    card.snp.makeConstraints { make in
      make.height.equalTo(140)
    }

    return card
  }

  // MARK: - Cape Card

  func createCapeCard(cape: Cape) -> NSView {
    let card = NSView()
    card.wantsLayer = true
    card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    card.layer?.cornerRadius = 8

    // Set tooltip for the card
    card.toolTip = cape.alias ?? Localized.Account.unnamedCape

    // Store cape ID in card's identifier for click handling
    card.identifier = NSUserInterfaceItemIdentifier(cape.id)

    // Add click gesture for equipping cape
    let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(capeCardClicked(_:)))
    card.addGestureRecognizer(clickGesture)

    // Image container - takes the full card space
    let imageContainer = NSView()
    imageContainer.wantsLayer = true
    imageContainer.layer?.cornerRadius = 6
    imageContainer.layer?.masksToBounds = true
    imageContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    card.addSubview(imageContainer)

    // Cape preview image
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageContainer.addSubview(imageView)

    // Load cape image asynchronously
    if let url = URL(string: cape.url) {
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: url.s)
          if let fullImage = NSImage(data: data) {
            // Extract the front part of the cape and scale it up
            if let frontImage = extractCapeFront(from: fullImage) {
              await MainActor.run {
                imageView.image = frontImage
              }
            } else {
              // If extraction fails, show the full image
              await MainActor.run {
                imageView.image = fullImage
              }
            }
          }
        } catch {
          // If loading fails, show placeholder
          await MainActor.run {
            let placeholderImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            imageView.image = placeholderImage
            imageView.contentTintColor = .secondaryLabelColor
          }
        }
      }
    }

    // Active indicator - small badge at top-right of image
    if cape.isActive {
      let activeBadge = NSView()
      activeBadge.wantsLayer = true
      activeBadge.layer?.backgroundColor = NSColor.systemGreen.cgColor
      activeBadge.layer?.cornerRadius = 8

      let checkIcon = NSImageView()
      checkIcon.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
      checkIcon.contentTintColor = .white
      checkIcon.imageScaling = .scaleProportionallyDown
      activeBadge.addSubview(checkIcon)

      imageContainer.addSubview(activeBadge)

      activeBadge.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(4)
        make.right.equalToSuperview().offset(-4)
        make.width.height.equalTo(16)
      }

      checkIcon.snp.makeConstraints { make in
        make.center.equalToSuperview()
        make.width.height.equalTo(10)
      }
    }

    // Layout - image container takes full card space with padding
    imageContainer.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(12)
      make.bottom.equalToSuperview().offset(-12)
      make.left.greaterThanOrEqualToSuperview().offset(6)
      make.right.lessThanOrEqualToSuperview().offset(-6)
      // Set aspect ratio 10:16 for cape front with lower priority
      make.width.equalTo(imageContainer.snp.height).multipliedBy(10.0 / 16.0).priority(.high)
    }

    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    return card
  }

  // MARK: - Button Actions

  @objc private func activateSkinButtonClicked(_ sender: NSButton) {
    guard let account = selectedAccount,
          let skinID = sender.identifier?.rawValue,
          let skin = account.skins?.first(where: { $0.id == skinID }) else {
      return
    }

    Task {
      do {
        await MainActor.run {
          print("Activating skin: \(skin.alias ?? skin.id)")
        }
        try await activateSkin(skin)
        await MainActor.run {
          showSuccessAlert(message: Localized.Account.skinActivated)
        }
      } catch {
        await MainActor.run {
          showErrorAlert(error)
        }
      }
    }
  }

  @objc private func downloadSkinButtonClicked(_ sender: NSButton) {
    guard let account = selectedAccount,
          let skinID = sender.identifier?.rawValue,
          let skin = account.skins?.first(where: { $0.id == skinID }) else {
      return
    }

    Task {
      do {
        await MainActor.run {
          print("Downloading skin: \(skin.alias ?? skin.id)")
        }
        try await downloadSkinToLibrary(skin)
      } catch {
        await MainActor.run {
          showErrorAlert(error)
        }
      }
    }
  }

  @objc private func resetSkinButtonClicked(_ sender: NSButton) {
    showConfirmationAlert(
      title: Localized.Account.confirmResetSkin,
      message: Localized.Account.confirmResetSkinMessage
    ) { [weak self] confirmed in
      guard confirmed, let self = self else { return }

      Task {
        do {
          await MainActor.run {
            print("Resetting skin to default")
          }
          try await self.resetToDefaultSkin()
          await MainActor.run {
            self.showSuccessAlert(message: Localized.Account.skinReset)
          }
        } catch {
          await MainActor.run {
            self.showErrorAlert(error)
          }
        }
      }
    }
  }

  @objc private func capeCardClicked(_ gesture: NSClickGestureRecognizer) {
    guard let card = gesture.view,
          let capeId = card.identifier?.rawValue,
          let account = selectedAccount,
          let cape = account.capes?.first(where: { $0.id == capeId }) else {
      return
    }

    // If already active, do nothing
    if cape.isActive { return }

    Task {
      do {
        await MainActor.run {
          print("Equipping cape: \(cape.alias ?? cape.id)")
        }
        try await equipCape(cape)
      } catch {
        await MainActor.run {
          showErrorAlert(error)
        }
      }
    }
  }
}
