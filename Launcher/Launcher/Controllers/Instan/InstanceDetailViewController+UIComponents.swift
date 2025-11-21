//
//  InstanceDetailViewController+UIComponents.swift
//  Launcher
//
//  UI components for instance detail view
//

import AppKit
import Yatagarasu

// MARK: - UI Components
extension InstanceDetailViewController {
  func createIconImageView() -> NSImageView {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 16
    imageView.imageScaling = .scaleProportionallyUpOrDown
    let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .regular)
    let image = NSImage(
      systemSymbolName: BRIcons.instance,
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .systemGreen
    return imageView
  }

  func createTitleLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 24, weight: .bold),
      textColor: .labelColor,
      alignment: .center
    )
  }

  func createVersionLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
  }

  func createSeparator1() -> BRSeparator {
    return BRSeparator.horizontal()
  }

  func createConfigTitleLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.configurationTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createNameFieldLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.nameLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
  }

  func createNameValueLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createNameTextField() -> NSTextField {
    let field = NSTextField()
    field.font = .systemFont(ofSize: 13)
    field.isHidden = true
    return field
  }

  func createVersionFieldLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.versionLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
  }

  func createVersionValueLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createIdFieldLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.idLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
  }

  func createIdValueLabel() -> BRLabel {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 11, weight: .regular),
      textColor: .tertiaryLabelColor,
      alignment: .left
    )
    label.maximumNumberOfLines = 1
    return label
  }

  func createCreatedFieldLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.createdLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
  }

  func createCreatedValueLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createModifiedFieldLabel() -> BRLabel {
    return BRLabel(
      text: Localized.InstanceDetail.modifiedLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
  }

  func createModifiedValueLabel() -> BRLabel {
    return BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createSeparator2() -> BRSeparator {
    return BRSeparator.horizontal()
  }

  func createEditButton() -> NSButton {
    let button = NSButton(
      title: Localized.InstanceDetail.editButton,
      target: self,
      action: #selector(toggleEditMode)
    )
    button.bezelStyle = .rounded
    return button
  }

  func createSaveButton() -> NSButton {
    let button = NSButton(
      title: Localized.InstanceDetail.saveButton,
      target: self,
      action: #selector(saveChanges)
    )
    button.bezelStyle = .rounded
    button.isHidden = true
    return button
  }

  func createCancelEditButton() -> NSButton {
    let button = NSButton(
      title: Localized.InstanceDetail.cancelButton,
      target: self,
      action: #selector(cancelEdit)
    )
    button.bezelStyle = .rounded
    button.isHidden = true
    button.keyEquivalent = "\u{1b}"
    return button
  }

  func createOpenFolderButton() -> NSButton {
    let button = NSButton(
      title: Localized.InstanceDetail.openFolderButton,
      target: self,
      action: #selector(openInstanceFolder)
    )
    button.bezelStyle = .rounded
    return button
  }

  func createCloseButton() -> NSButton {
    let button = NSButton(
      title: Localized.InstanceDetail.closeButton,
      target: self,
      action: #selector(close)
    )
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    return button
  }
}
