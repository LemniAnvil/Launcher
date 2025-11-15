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
    imageView.image = NSImage(systemSymbolName: "cube.box.fill", accessibilityDescription: nil)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let nameLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 14, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let versionLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let containerView: BRNSView = {
    let view = BRNSView(
      backgroundColor: .controlBackgroundColor,
      cornerRadius: 8
    )
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
    containerView.addSubview(nameLabel)
    containerView.addSubview(versionLabel)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(4)
    }

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(36)
    }

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconImageView.snp.right).offset(12)
      make.right.equalToSuperview().offset(-12)
      make.top.equalToSuperview().offset(10)
    }

    versionLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.right.equalToSuperview().offset(-12)
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
    }
  }

  func configure(with instance: Instance) {
    nameLabel.stringValue = instance.name
    versionLabel.stringValue = Localized.Instances.versionInfo(instance.versionId)

    // Determine version type color
    let versionId = instance.versionId
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      iconImageView.contentTintColor = .systemOrange
    } else if versionId.hasPrefix("1.") {
      iconImageView.contentTintColor = .systemGreen
    } else if versionId.contains("a") || versionId.contains("alpha") {
      iconImageView.contentTintColor = .systemPurple
    } else if versionId.contains("b") || versionId.contains("beta") {
      iconImageView.contentTintColor = .systemBlue
    } else {
      iconImageView.contentTintColor = .systemGray
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
        highlightColor = NSColor.systemBlue.withAlphaComponent(0.35)
      } else {
        highlightColor = NSColor.systemBlue.withAlphaComponent(0.2)
      }
      containerView.layer?.backgroundColor = highlightColor.cgColor
    } else {
      containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    updateAppearance()
  }
}
