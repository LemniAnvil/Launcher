//
//  VersionCollectionViewItem.swift
//  Launcher
//
//  Version collection view item
//

import AppKit
import SnapKit
import Yatagarasu

class VersionCollectionViewItem: NSCollectionViewItem {

  static let identifier = NSUserInterfaceItemIdentifier("VersionCollectionViewItem")

  private let containerView = BRNSView(
    backgroundColor: BRColorPalette.background,
    cornerRadius: BRSpacing.cornerRadiusMedium,
    borderWidth: BRSpacing.borderWidthStandard,
    borderColor: BRColorPalette.subtleSeparator
  )

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)
    imageView.contentTintColor = BRColorPalette.releaseVersion
    imageView.imageScaling = .scaleProportionallyDown
    return imageView
  }()

  private let versionLabel = DisplayLabel(
    text: "",
    font: .systemFont(ofSize: 15, weight: .semibold),
    textColor: BRColorPalette.text,
    alignment: .center,
    lineBreakMode: .byTruncatingTail
  )

  private let typeLabel = DisplayLabel(
    text: "",
    font: .systemFont(ofSize: 11),
    textColor: BRColorPalette.secondaryText,
    alignment: .center
  )

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
      make.edges.equalToSuperview().inset(BRSpacing.small)
    }

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(BRSpacing.extraLarge)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(64)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(BRSpacing.medium)
      make.left.right.equalToSuperview().inset(BRSpacing.medium)
    }

    typeLabel.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(BRSpacing.extraSmall)
      make.left.right.equalToSuperview().inset(BRSpacing.medium)
      make.bottom.lessThanOrEqualToSuperview().offset(-BRSpacing.extraLarge)
    }
  }

  func configure(with versionId: String) {
    versionLabel.stringValue = versionId

    // Determine version type
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      typeLabel.stringValue = Localized.InstalledVersions.typeSnapshot
      iconImageView.contentTintColor = BRColorPalette.snapshotVersion
      containerView.layer?.borderColor = BRColorPalette.snapshotVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.hasPrefix("1.") {
      typeLabel.stringValue = Localized.InstalledVersions.typeRelease
      iconImageView.contentTintColor = BRColorPalette.releaseVersion
      containerView.layer?.borderColor = BRColorPalette.releaseVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("a") || versionId.contains("alpha") {
      typeLabel.stringValue = Localized.InstalledVersions.typeAlpha
      iconImageView.contentTintColor = BRColorPalette.alphaVersion
      containerView.layer?.borderColor = BRColorPalette.alphaVersion.withAlphaComponent(0.2).cgColor
    } else if versionId.contains("b") || versionId.contains("beta") {
      typeLabel.stringValue = Localized.InstalledVersions.typeBeta
      iconImageView.contentTintColor = BRColorPalette.betaVersion
      containerView.layer?.borderColor = BRColorPalette.betaVersion.withAlphaComponent(0.2).cgColor
    } else {
      typeLabel.stringValue = Localized.InstalledVersions.typeUnknown
      iconImageView.contentTintColor = BRColorPalette.unknownVersion
      containerView.layer?.borderColor = BRColorPalette.unknownVersion.withAlphaComponent(0.2).cgColor
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
}
