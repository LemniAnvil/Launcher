//
//  InstanceCellView.swift
//  Launcher
//
//  Custom instance cell view
//

import AppKit
import SnapKit
import Yatagarasu

class InstanceCellView: NSView {

  // MARK: - Properties

  private var isHighlighted: Bool = false

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: BRIcons.instance, accessibilityDescription: nil)
    imageView.contentTintColor = BRColorPalette.releaseVersion
    return imageView
  }()

  private let nameLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "",
      font: .systemFont(ofSize: 14, weight: .medium),
      textColor: BRColorPalette.text,
      alignment: .left
    )
    return label
  }()

  private let versionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "",
      font: .systemFont(ofSize: 11),
      textColor: BRColorPalette.secondaryText,
      alignment: .left
    )
    return label
  }()

  private let containerView: BRNSView = {
    let view = BRNSView(
      backgroundColor: BRColorPalette.background,
      cornerRadius: BRSpacing.cornerRadiusSmall
    )
    return view
  }()

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
    containerView.addSubview(nameLabel)
    containerView.addSubview(versionLabel)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(BRSpacing.extraSmall)
    }

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(BRSpacing.medium)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(36)
    }

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconImageView.snp.right).offset(BRSpacing.medium)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.smallMedium)
    }

    versionLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.top.equalTo(nameLabel.snp.bottom).offset(BRSpacing.extraSmall)
    }
  }

  func configure(with instance: Instance) {
    nameLabel.stringValue = instance.name
    versionLabel.stringValue = Localized.Instances.versionInfo(instance.versionId)

    // Determine version type color
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
