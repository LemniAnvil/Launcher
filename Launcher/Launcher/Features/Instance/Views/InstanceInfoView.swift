//
//  InstanceInfoView.swift
//  Launcher
//
//  View for instance name, group, and icon controls.
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

final class InstanceInfoView: NSView {
  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Size = DesignSystem.Size
  private typealias Width = DesignSystem.Width
  private typealias Fonts = DesignSystem.Fonts
  private typealias SymbolSize = DesignSystem.SymbolSize

  // MARK: - UI Components

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = Radius.standard
    imageView.imageScaling = .scaleProportionallyUpOrDown
    let config = NSImage.SymbolConfiguration(pointSize: SymbolSize.large, weight: .regular)
    let image = NSImage(
      systemSymbolName: "cube.fill",
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let nameLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.nameLabel,
      font: Fonts.bodyMedium,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let nameTextField: NSTextField = {
    let field = NSTextField()
    field.placeholderString = Localized.AddInstance.namePlaceholder
    field.font = Fonts.body
    field.lineBreakMode = .byTruncatingTail
    return field
  }()

  private let groupLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.groupLabel,
      font: Fonts.bodyMedium,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let groupPopUpButton: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = Fonts.body
    button.addItem(withTitle: Localized.AddInstance.groupUncategorized)
    return button
  }()

  // MARK: - Properties

  var name: String {
    get { nameTextField.stringValue }
    set { nameTextField.stringValue = newValue }
  }

  // MARK: - Initialization

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Setup

  func setIcon(symbolName: String, tint: NSColor) {
    let config = NSImage.SymbolConfiguration(pointSize: SymbolSize.large, weight: .regular)
    let image = NSImage(
      systemSymbolName: symbolName,
      accessibilityDescription: nil
    )
    iconImageView.image = image?.withSymbolConfiguration(config)
    iconImageView.contentTintColor = tint
  }

  private func setupUI() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    layer?.cornerRadius = Radius.standard
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.separatorColor.cgColor

    addSubview(iconImageView)
    addSubview(nameLabel)
    addSubview(nameTextField)
    addSubview(groupLabel)
    addSubview(groupPopUpButton)

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.standard)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.height.equalTo(Size.instanceIcon)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(30)
      make.left.equalTo(iconImageView.snp.right).offset(Spacing.standard)
      make.right.equalToSuperview().offset(-Spacing.standard)
    }

    nameTextField.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(Spacing.tiny)
      make.left.equalTo(iconImageView.snp.right).offset(Spacing.standard)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.height.equalTo(Size.textFieldHeight)
    }

    groupLabel.snp.makeConstraints { make in
      make.top.equalTo(nameTextField.snp.bottom).offset(Spacing.medium)
      make.left.equalTo(iconImageView.snp.right).offset(Spacing.standard)
      make.width.equalTo(Width.shortLabel)
    }

    groupPopUpButton.snp.makeConstraints { make in
      make.centerY.equalTo(groupLabel)
      make.left.equalTo(groupLabel.snp.right).offset(Spacing.tiny)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.height.equalTo(Size.popupHeight)
    }
  }
}
