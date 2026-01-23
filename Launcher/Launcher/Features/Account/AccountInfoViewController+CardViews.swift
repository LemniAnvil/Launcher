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

    let trimmedCGImage = trimTransparentBorder(from: croppedCGImage)

    // Scale up the image using nearest-neighbor interpolation
    return createScaledBitmap(from: trimmedCGImage, scale: 10)
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

  private func createScaledBitmap(
    from cgImage: CGImage,
    targetPixelSize: CGSize,
    pointSize: CGSize
  ) -> NSImage? {
    let width = max(Int(targetPixelSize.width.rounded()), 1)
    let height = max(Int(targetPixelSize.height.rounded()), 1)

    guard let colorSpace = cgImage.colorSpace,
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
      return nil
    }

    context.interpolationQuality = .none
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    guard let scaledCGImage = context.makeImage() else {
      return nil
    }

    return NSImage(cgImage: scaledCGImage, size: pointSize)
  }

  /// Composite the cape image onto a rounded background to avoid transparent bars.
  private func composeRoundedCapeImage(
    _ image: NSImage,
    backgroundColor: NSColor,
    cornerRadius: CGFloat
  ) -> NSImage {
    let size = image.size
    let output = NSImage(size: size)
    output.lockFocus()

    let rect = NSRect(origin: .zero, size: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    backgroundColor.setFill()
    path.fill()

    path.addClip()
    image.draw(
      in: rect,
      from: .zero,
      operation: .sourceOver,
      fraction: 1,
      respectFlipped: true,
      hints: [.interpolation: NSImageInterpolation.none]
    )

    output.unlockFocus()
    return output
  }

  /// Trim fully transparent pixels around the edges to avoid visible padding bars.
  private func trimTransparentBorder(from cgImage: CGImage) -> CGImage {
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width

    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return cgImage
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let data = context.data else { return cgImage }
    let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    var found = false

    for y in 0..<height {
      for x in 0..<width {
        let alpha = buffer[(y * width + x) * bytesPerPixel + 3]
        if alpha > 0 {
          found = true
          if x < minX { minX = x }
          if y < minY { minY = y }
          if x > maxX { maxX = x }
          if y > maxY { maxY = y }
        }
      }
    }

    guard found else { return cgImage }

    let cropRect = CGRect(
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1
    )

    return cgImage.cropping(to: cropRect) ?? cgImage
  }

  // MARK: - Skin Card

  func createSkinCard(skin: SkinResponse) -> NSView {
    let imageInset = Spacing.small
    let innerRadius = Radius.standard
    let outerRadius = innerRadius + imageInset

    let card = NSView()
    card.wantsLayer = true
    card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    card.layer?.cornerRadius = outerRadius

    // Skin preview image
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.imageScaling = .scaleAxesIndependently
    imageView.layer?.cornerRadius = innerRadius
    imageView.layer?.masksToBounds = true
    imageView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    card.addSubview(imageView)

    // Load skin image asynchronously
    if let url = URL(string: skin.url) {
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: url.s)
          if let image = NSImage(data: data) {
            let targetInfo = await MainActor.run { () -> (CGSize, CGFloat) in
              imageView.superview?.layoutSubtreeIfNeeded()
              let size = imageView.bounds.size
              let scale = imageView.window?.backingScaleFactor
                ?? NSScreen.main?.backingScaleFactor
                ?? 1
              return (size, scale)
            }

            let targetSize = targetInfo.0
            let scaleFactor = targetInfo.1
            let scaledImage: NSImage?
            if targetSize.width > 0,
               targetSize.height > 0,
               let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
              let pixelSize = CGSize(
                width: targetSize.width * scaleFactor,
                height: targetSize.height * scaleFactor
              )
              scaledImage = createScaledBitmap(
                from: cgImage,
                targetPixelSize: pixelSize,
                pointSize: targetSize
              )
            } else {
              scaledImage = nil
            }

            await MainActor.run {
              imageView.image = scaledImage ?? image
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
      make.top.equalToSuperview().offset(imageInset)
      make.left.right.equalToSuperview().inset(imageInset)
      make.height.equalTo(imageView.snp.width)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(imageView.snp.bottom).offset(Spacing.small)
      make.left.right.equalToSuperview().inset(Spacing.section)
    }

    variantStateLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(Spacing.minimal)
      make.left.right.equalToSuperview().inset(Spacing.section)
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
      make.top.greaterThanOrEqualTo(variantStateLabel.snp.bottom).offset(Spacing.small)
      make.left.right.equalToSuperview().inset(Spacing.small)
      make.bottom.equalToSuperview().offset(-Spacing.small)
      make.height.equalTo(Size.textFieldHeight)
    }

    return card
  }

  // MARK: - Cape Card

  func createCapeCard(cape: Cape) -> NSView {
    let imageInset = Spacing.small
    let innerRadius = Radius.standard
    let outerRadius = innerRadius + imageInset

    let card = NSView()
    card.wantsLayer = true
    card.layer?.cornerRadius = outerRadius
    card.layer?.masksToBounds = true
    if cape.isActive {
      card.layer?.borderWidth = 2
      card.layer?.borderColor = NSColor.systemGreen.cgColor
    } else {
      card.layer?.borderWidth = 1
      card.layer?.borderColor = NSColor.separatorColor.cgColor
    }
    card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

    // Set tooltip for the card
    card.toolTip = cape.alias ?? Localized.Account.unnamedCape

    // Store cape ID in card's identifier for click handling
    card.identifier = NSUserInterfaceItemIdentifier(cape.id)

    // Add click gesture for equipping cape
    let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(capeCardClicked(_:)))
    card.addGestureRecognizer(clickGesture)

    // Cape preview image
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.imageScaling = .scaleProportionallyUpOrDown
    card.addSubview(imageView)

    // Load cape image asynchronously
    if let url = URL(string: cape.url) {
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: url.s)
          if let fullImage = NSImage(data: data) {
            // Extract the front part of the cape and scale it up
            if let frontImage = extractCapeFront(from: fullImage) {
              await MainActor.run {
                imageView.image = composeRoundedCapeImage(
                  frontImage,
                  backgroundColor: NSColor.windowBackgroundColor,
                  cornerRadius: innerRadius
                )
              }
            } else {
              // If extraction fails, show the full image
              await MainActor.run {
                imageView.image = composeRoundedCapeImage(
                  fullImage,
                  backgroundColor: NSColor.windowBackgroundColor,
                  cornerRadius: innerRadius
                )
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

    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(imageInset)
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
