//
//  InstanceCollectionViewItem.swift
//  Launcher
//
//  Instance collection view item
//

import AppKit
import SnapKit
import Yatagarasu

class InstanceCollectionViewItem: NSCollectionViewItem {

  static let identifier = NSUserInterfaceItemIdentifier("InstanceCollectionViewItem")

  private let containerView: BRNSView = {
    let view = BRNSView(
      backgroundColor: BRColorPalette.background,
      cornerRadius: BRSpacing.cornerRadiusMedium,
      borderWidth: BRSpacing.borderWidthStandard,
      borderColor: BRColorPalette.subtleSeparator
    )
    return view
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)
    imageView.contentTintColor = BRColorPalette.releaseVersion
    imageView.imageScaling = .scaleProportionallyDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.layer?.masksToBounds = true
    return imageView
  }()

  private let nameLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "",
      font: .systemFont(ofSize: 15, weight: .semibold),
      textColor: BRColorPalette.text,
      alignment: .center,
      lineBreakMode: .byTruncatingTail
    )
    return label
  }()

  private let versionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "",
      font: .systemFont(ofSize: 11),
      textColor: BRColorPalette.secondaryText,
      alignment: .center
    )
    return label
  }()

  /// Badge view for external instance indicator
  private let externalBadge: DisplayLabel = {
    let label = DisplayLabel(
      text: "Prism",
      font: .systemFont(ofSize: 9, weight: .medium),
      textColor: .white,
      alignment: .center
    )
    label.wantsLayer = true
    label.layer?.backgroundColor = NSColor.systemPurple.withAlphaComponent(0.8).cgColor
    label.layer?.cornerRadius = 4
    label.isHidden = true
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
    containerView.addSubview(nameLabel)
    containerView.addSubview(versionLabel)
    containerView.addSubview(externalBadge)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(BRSpacing.small)
    }

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(BRSpacing.extraLarge)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(64)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(BRSpacing.medium)
      make.left.right.equalToSuperview().inset(BRSpacing.medium)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(BRSpacing.extraSmall)
      make.left.right.equalToSuperview().inset(BRSpacing.medium)
      make.bottom.lessThanOrEqualToSuperview().offset(-BRSpacing.extraLarge)
    }

    externalBadge.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(BRSpacing.small)
      make.right.equalToSuperview().offset(-BRSpacing.small)
      make.width.equalTo(36)
      make.height.equalTo(16)
    }
  }

  func configure(with instance: Instance) {
    nameLabel.stringValue = instance.name
    versionLabel.stringValue = instance.versionId

    // Configure icon
    configureIcon(for: instance)

    // Configure external badge
    configureExternalBadge(for: instance)

    // Determine version type color for border
    let versionId = instance.versionId
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      containerView.layer?.borderColor =
        BRColorPalette.snapshotVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.hasPrefix("1.") {
      containerView.layer?.borderColor =
        BRColorPalette.releaseVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("a") || versionId.contains("alpha") {
      containerView.layer?.borderColor = BRColorPalette.alphaVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("b") || versionId.contains("beta") {
      containerView.layer?.borderColor = BRColorPalette.betaVersion.withAlphaComponent(0.2).cgColor
    } else {
      containerView.layer?.borderColor =
        BRColorPalette.unknownVersion.withAlphaComponent(0.2).cgColor
    }
  }

  /// Configure icon based on instance type
  private func configureIcon(for instance: Instance) {
    // Check for custom icon path first
    if let iconPath = instance.iconPath, let iconImage = NSImage(contentsOf: iconPath) {
      iconImageView.image = iconImage
      iconImageView.contentTintColor = nil  // Don't tint custom icons
      return
    }

    // Use default icon with version-based tint color
    iconImageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)

    let versionId = instance.versionId
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      iconImageView.contentTintColor = BRColorPalette.snapshotVersion
    } else if versionId.hasPrefix("1.") {
      iconImageView.contentTintColor = BRColorPalette.releaseVersion
    } else if versionId.contains("a") || versionId.contains("alpha") {
      iconImageView.contentTintColor = BRColorPalette.alphaVersion
    } else if versionId.contains("b") || versionId.contains("beta") {
      iconImageView.contentTintColor = BRColorPalette.betaVersion
    } else {
      iconImageView.contentTintColor = BRColorPalette.unknownVersion
    }
  }

  /// Configure external instance badge
  private func configureExternalBadge(for instance: Instance) {
    switch instance.source {
    case .prism:
      externalBadge.stringValue = "Prism"
      externalBadge.layer?.backgroundColor = NSColor.systemPurple.withAlphaComponent(0.8).cgColor
      externalBadge.isHidden = false
    case .native:
      externalBadge.isHidden = true
    }
  }

  override var isSelected: Bool {
    didSet {
      updateSelectionState()
    }
  }

  private func updateSelectionState() {
    if isSelected {
      containerView.layer?.borderWidth = BRSpacing.borderWidthEmphasized
      containerView.layer?.shadowColor = BRColorPalette.selectionShadow.cgColor
      containerView.layer?.shadowOpacity = 0.3
      containerView.layer?.shadowRadius = BRSpacing.shadowRadiusStandard
      containerView.layer?.shadowOffset = BRSpacing.shadowOffsetStandard
    } else {
      containerView.layer?.borderWidth = BRSpacing.borderWidthStandard
      containerView.layer?.shadowOpacity = 0
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reset icon to default
    iconImageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)
    iconImageView.contentTintColor = BRColorPalette.releaseVersion
    externalBadge.isHidden = true
  }
}
