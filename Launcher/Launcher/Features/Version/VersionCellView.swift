//
//  VersionCellView.swift
//  Launcher
//
//  Custom version cell view
//

import AppKit
import SnapKit
import Yatagarasu

class VersionCellView: NSView {

  // MARK: - Properties

  private var isHighlighted: Bool = false

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)
    imageView.contentTintColor = BRColorPalette.releaseVersion
    return imageView
  }()

  private let versionLabel = DisplayLabel(
    text: "",
    font: .systemFont(ofSize: 14, weight: .medium),
    textColor: BRColorPalette.text,
    alignment: .left
  )

  private let typeLabel = DisplayLabel(
    text: "",
    font: .systemFont(ofSize: 11),
    textColor: BRColorPalette.secondaryText,
    alignment: .left
  )

  private let containerView = BRNSView(
    backgroundColor: BRColorPalette.background,
    cornerRadius: BRSpacing.cornerRadiusSmall
  )

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(containerView)
    containerView.addSubview(iconImageView)
    containerView.addSubview(versionLabel)
    containerView.addSubview(typeLabel)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(BRSpacing.extraSmall)
    }

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(BRSpacing.medium)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(36)
    }

    versionLabel.snp.makeConstraints { make in
      make.left.equalTo(iconImageView.snp.right).offset(BRSpacing.medium)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.smallMedium)
    }

    typeLabel.snp.makeConstraints { make in
      make.left.equalTo(versionLabel)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.top.equalTo(versionLabel.snp.bottom).offset(BRSpacing.extraSmall)
    }
  }

  func configure(with versionId: String) {
    versionLabel.stringValue = versionId

    // Determine version type
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      typeLabel.stringValue = Localized.InstalledVersions.typeSnapshot
      iconImageView.contentTintColor = BRColorPalette.snapshotVersion
    } else if versionId.hasPrefix("1.") {
      typeLabel.stringValue = Localized.InstalledVersions.typeRelease
      iconImageView.contentTintColor = BRColorPalette.releaseVersion
    } else if versionId.contains("a") || versionId.contains("alpha") {
      typeLabel.stringValue = Localized.InstalledVersions.typeAlpha
      iconImageView.contentTintColor = BRColorPalette.alphaVersion
    } else if versionId.contains("b") || versionId.contains("beta") {
      typeLabel.stringValue = Localized.InstalledVersions.typeBeta
      iconImageView.contentTintColor = BRColorPalette.betaVersion
    } else {
      typeLabel.stringValue = Localized.InstalledVersions.typeUnknown
      iconImageView.contentTintColor = BRColorPalette.unknownVersion
    }
  }

  // MARK: - Selection Highlighting

  /// Updates the visual appearance based on selection state
  func setHighlighted(_ highlighted: Bool) {
    isHighlighted = highlighted
    updateAppearance()
  }

  private func updateAppearance() {
    if isHighlighted {
      // Enhanced highlight color for better visibility
      let highlightColor: NSColor
      if NSApp.effectiveAppearance.name == .darkAqua {
        highlightColor = BRColorPalette.highlight
      } else {
        highlightColor = BRColorPalette.subtleHighlight
      }
      containerView.layer?.backgroundColor = highlightColor.cgColor
    } else {
      containerView.layer?.backgroundColor = BRColorPalette.background.cgColor
    }
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    updateAppearance()
  }
}
