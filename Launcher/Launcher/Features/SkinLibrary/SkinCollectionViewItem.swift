//
//  SkinCollectionViewItem.swift
//  Launcher
//

import AppKit
import SnapKit

final class SkinCollectionViewItem: NSCollectionViewItem {
  private let nameLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.lineBreakMode = .byTruncatingTail
    return label
  }()

  private let detailLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingMiddle
    return label
  }()

  private let thumbnailView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleAxesIndependently
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 6
    imageView.layer?.masksToBounds = true
    imageView.image = NSImage(size: NSSize(width: 64, height: 64))
    return imageView
  }()

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    view.wantsLayer = true
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor

    view.addSubview(thumbnailView)
    view.addSubview(nameLabel)
    view.addSubview(detailLabel)

    thumbnailView.snp.makeConstraints { make in
      make.left.top.equalToSuperview().offset(8)
      make.width.height.equalTo(72)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.left.equalTo(thumbnailView.snp.right).offset(8)
      make.right.equalToSuperview().inset(8)
    }

    detailLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.left.equalTo(nameLabel)
      make.right.equalToSuperview().inset(8)
      make.bottom.lessThanOrEqualToSuperview().inset(8)
    }
  }

  func configure(with skin: LauncherSkinAsset) {
    nameLabel.stringValue = skin.displayName
    let sizeText = ByteCountFormatter.string(fromByteCount: skin.fileSize, countStyle: .file)
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    let dateText = formatter.string(from: skin.lastModified)
    detailLabel.stringValue = "\(skin.kind.displayName) • \(sizeText) • \(dateText)"

    // Extract and display head portion for skins, full image for capes
    if skin.kind == .skin {
      if let headImage = SkinHeadRenderer.extractHeadScaled(from: skin.fileURL, targetSize: NSSize(width: 72, height: 72)) {
        thumbnailView.image = headImage
      } else {
        thumbnailView.image = NSImage(size: NSSize(width: 64, height: 64))
      }
    } else {
      // For capes, show the full image
      if let image = NSImage(contentsOf: skin.fileURL) {
        thumbnailView.image = image
      } else {
        thumbnailView.image = NSImage(size: NSSize(width: 64, height: 64))
      }
    }
  }
}
