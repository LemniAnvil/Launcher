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

private typealias Spacing = DesignSystem.Spacing
private typealias Radius = DesignSystem.CornerRadius
private typealias Size = DesignSystem.Size
private typealias Height = DesignSystem.Height
private typealias Fonts = DesignSystem.Fonts

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
    card.layer?.cornerRadius = Radius.standard

    // Skin preview image
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.layer?.cornerRadius = Radius.small
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
      font: Fonts.tableHeader,
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
        make.top.equalToSuperview().offset(Spacing.small)
        make.right.equalToSuperview().offset(-Spacing.small)
        make.height.equalTo(18)
        make.width.greaterThanOrEqualTo(50)
      }

      activeLabel.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: Spacing.tiny, bottom: 2, right: Spacing.tiny))
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
      make.left.equalToSuperview().offset(Spacing.section)
      make.top.equalToSuperview().offset(Spacing.small)
      make.width.height.equalTo(80)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.small)
      make.left.equalTo(imageView.snp.right).offset(Spacing.section)
      make.right.equalToSuperview().offset(-80)
    }

    variantStateLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(Spacing.minimal)
      make.left.equalTo(imageView.snp.right).offset(Spacing.section)
      make.right.equalToSuperview().offset(-Spacing.section)
    }

    // Action buttons
    let buttonStack = NSStackView()
    buttonStack.orientation = .horizontal
    buttonStack.spacing = Spacing.tiny
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
      make.top.equalTo(imageView.snp.bottom).offset(Spacing.section)
      make.left.right.equalToSuperview().inset(Spacing.section)
      make.bottom.equalToSuperview().offset(-Spacing.small)
      make.height.equalTo(Size.textFieldHeight)
    }

    card.snp.makeConstraints { make in
      make.height.equalTo(Height.instanceInfo)
    }

    return card
  }

  // MARK: - Cape Card

  func createCapeCard(cape: Cape) -> NSView {
    let card = NSView()
    card.wantsLayer = true
    card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    card.layer?.cornerRadius = Radius.standard

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
    imageContainer.layer?.cornerRadius = Radius.medium
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
      activeBadge.layer?.cornerRadius = Radius.standard

      let checkIcon = NSImageView()
      checkIcon.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
      checkIcon.contentTintColor = .white
      checkIcon.imageScaling = .scaleProportionallyDown
      activeBadge.addSubview(checkIcon)

      imageContainer.addSubview(activeBadge)

      activeBadge.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(Spacing.micro)
        make.right.equalToSuperview().offset(-Spacing.micro)
        make.width.height.equalTo(Size.smallIndicator)
      }

      checkIcon.snp.makeConstraints { make in
        make.center.equalToSuperview()
        make.width.height.equalTo(10)
      }
    }

    // Layout - image container takes full card space with padding
    imageContainer.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(Spacing.section)
      make.bottom.equalToSuperview().offset(-Spacing.section)
      make.left.greaterThanOrEqualToSuperview().offset(Spacing.minimal)
      make.right.lessThanOrEqualToSuperview().offset(-Spacing.minimal)
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
