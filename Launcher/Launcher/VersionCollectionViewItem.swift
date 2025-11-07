//
//  VersionCollectionViewItem.swift
//  Launcher
//
//  版本网格项视图
//

import AppKit
import SnapKit

class VersionCollectionViewItem: NSCollectionViewItem {

  static let identifier = NSUserInterfaceItemIdentifier("VersionCollectionViewItem")

  private let containerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.cornerRadius = 12
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.1).cgColor
    return view
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: "cube.box.fill", accessibilityDescription: nil)
    imageView.contentTintColor = .systemGreen
    imageView.imageScaling = .scaleProportionallyDown
    return imageView
  }()

  private let versionLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 15, weight: .semibold)
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    label.alignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }()

  private let typeLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    label.alignment = .center
    return label
  }()

  override func loadView() {
    self.view = NSView()
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    view.addSubview(containerView)
    containerView.addSubview(iconImageView)
    containerView.addSubview(versionLabel)
    containerView.addSubview(typeLabel)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(8)
    }

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(64)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(12)
    }

    typeLabel.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(12)
      make.bottom.lessThanOrEqualToSuperview().offset(-16)
    }
  }

  func configure(with versionId: String) {
    versionLabel.stringValue = versionId

    // Determine version type
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      typeLabel.stringValue = Localized.InstalledVersions.typeSnapshot
      iconImageView.contentTintColor = .systemOrange
      containerView.layer?.borderColor = NSColor.systemOrange.withAlphaComponent(0.2).cgColor
    } else if versionId.hasPrefix("1.") {
      typeLabel.stringValue = Localized.InstalledVersions.typeRelease
      iconImageView.contentTintColor = .systemGreen
      containerView.layer?.borderColor = NSColor.systemGreen.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("a") || versionId.contains("alpha") {
      typeLabel.stringValue = Localized.InstalledVersions.typeAlpha
      iconImageView.contentTintColor = .systemPurple
      containerView.layer?.borderColor = NSColor.systemPurple.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("b") || versionId.contains("beta") {
      typeLabel.stringValue = Localized.InstalledVersions.typeBeta
      iconImageView.contentTintColor = .systemBlue
      containerView.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor
    } else {
      typeLabel.stringValue = Localized.InstalledVersions.typeUnknown
      iconImageView.contentTintColor = .systemGray
      containerView.layer?.borderColor = NSColor.systemGray.withAlphaComponent(0.2).cgColor
    }
  }

  override var isSelected: Bool {
    didSet {
      updateSelectionState()
    }
  }

  private func updateSelectionState() {
    if isSelected {
      containerView.layer?.borderWidth = 2
      containerView.layer?.shadowColor = NSColor.controlAccentColor.cgColor
      containerView.layer?.shadowOpacity = 0.3
      containerView.layer?.shadowRadius = 8
      containerView.layer?.shadowOffset = NSSize(width: 0, height: 2)
    } else {
      containerView.layer?.borderWidth = 1
      containerView.layer?.shadowOpacity = 0
    }
  }
}
