//
//  VersionCellView.swift
//  Launcher
//
//  自定义版本单元格视图
//

import AppKit
import SnapKit

class VersionCellView: NSView {

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: "cube.box.fill", accessibilityDescription: nil)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let versionLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    return label
  }()

  private let typeLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    return label
  }()

  private let containerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.cornerRadius = 8
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    return view
  }()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    addSubview(containerView)
    containerView.addSubview(iconImageView)
    containerView.addSubview(versionLabel)
    containerView.addSubview(typeLabel)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(4)
    }

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(36)
    }

    versionLabel.snp.makeConstraints { make in
      make.left.equalTo(iconImageView.snp.right).offset(12)
      make.right.equalToSuperview().offset(-12)
      make.top.equalToSuperview().offset(10)
    }

    typeLabel.snp.makeConstraints { make in
      make.left.equalTo(versionLabel)
      make.right.equalToSuperview().offset(-12)
      make.top.equalTo(versionLabel.snp.bottom).offset(4)
    }
  }

  func configure(with versionId: String) {
    versionLabel.stringValue = versionId

    // Determine version type
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      typeLabel.stringValue = Localized.InstalledVersions.typeSnapshot
      iconImageView.contentTintColor = .systemOrange
    } else if versionId.hasPrefix("1.") {
      typeLabel.stringValue = Localized.InstalledVersions.typeRelease
      iconImageView.contentTintColor = .systemGreen
    } else if versionId.contains("a") || versionId.contains("alpha") {
      typeLabel.stringValue = Localized.InstalledVersions.typeAlpha
      iconImageView.contentTintColor = .systemPurple
    } else if versionId.contains("b") || versionId.contains("beta") {
      typeLabel.stringValue = Localized.InstalledVersions.typeBeta
      iconImageView.contentTintColor = .systemBlue
    } else {
      typeLabel.stringValue = Localized.InstalledVersions.typeUnknown
      iconImageView.contentTintColor = .systemGray
    }
  }
}
