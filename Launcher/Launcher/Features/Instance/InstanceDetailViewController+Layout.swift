//
//  InstanceDetailViewController+Layout.swift
//  Launcher
//
//  Layout setup for instance detail view
//

import AppKit
import SnapKit

// MARK: - Layout Constants
private typealias Spacing = DesignSystem.Spacing

private enum LocalLayout {
  static let largeInset: CGFloat = 40
  static let iconSize: CGFloat = 120
  static let fieldLabelWidth: CGFloat = 100
  static let buttonWidth: CGFloat = 80
  static let wideButtonWidth: CGFloat = 120
  static let inputHeight: CGFloat = 24
  static let sectionSpacing: CGFloat = 24
  static let headerSpacing: CGFloat = 30
}

// MARK: - Layout
extension InstanceDetailViewController {
  func setupUI() {
    view.addSubview(iconImageView)
    view.addSubview(titleLabel)
    view.addSubview(versionLabel)
    view.addSubview(separator1)

    view.addSubview(configTitleLabel)
    view.addSubview(nameFieldLabel)
    view.addSubview(nameValueLabel)
    view.addSubview(nameTextField)
    view.addSubview(versionFieldLabel)
    view.addSubview(versionValueLabel)
    view.addSubview(idFieldLabel)
    view.addSubview(idValueLabel)
    view.addSubview(createdFieldLabel)
    view.addSubview(createdValueLabel)
    view.addSubview(modifiedFieldLabel)
    view.addSubview(modifiedValueLabel)

    view.addSubview(separator2)
    view.addSubview(editButton)
    view.addSubview(saveButton)
    view.addSubview(cancelEditButton)
    view.addSubview(openFolderButton)
    view.addSubview(closeButton)

    setupConstraints()
  }

  private func setupConstraints() {
    // Icon and title
    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(LocalLayout.largeInset)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(LocalLayout.iconSize)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(Spacing.standard)
      make.left.right.equalToSuperview().inset(LocalLayout.largeInset)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.tiny)
      make.left.right.equalToSuperview().inset(LocalLayout.largeInset)
    }

    separator1.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(LocalLayout.headerSpacing)
      make.left.right.equalToSuperview().inset(LocalLayout.largeInset)
      make.height.equalTo(DesignSystem.Size.separatorHeight)
    }

    // Configuration section
    configTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(separator1.snp.bottom).offset(LocalLayout.sectionSpacing)
      make.left.right.equalToSuperview().inset(LocalLayout.largeInset)
    }

    nameFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(configTitleLabel.snp.bottom).offset(Spacing.medium)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.fieldLabelWidth)
    }

    nameValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
    }

    nameTextField.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
      make.height.equalTo(LocalLayout.inputHeight)
    }

    versionFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(nameFieldLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.fieldLabelWidth)
    }

    versionValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(versionFieldLabel)
      make.left.equalTo(versionFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
    }

    idFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(versionFieldLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.fieldLabelWidth)
    }

    idValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(idFieldLabel)
      make.left.equalTo(idFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
    }

    createdFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(idFieldLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.fieldLabelWidth)
    }

    createdValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(createdFieldLabel)
      make.left.equalTo(createdFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
    }

    modifiedFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(createdFieldLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.fieldLabelWidth)
    }

    modifiedValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(modifiedFieldLabel)
      make.left.equalTo(modifiedFieldLabel.snp.right).offset(Spacing.medium)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
    }

    separator2.snp.makeConstraints { make in
      make.top.equalTo(modifiedValueLabel.snp.bottom).offset(LocalLayout.sectionSpacing)
      make.left.right.equalToSuperview().inset(LocalLayout.largeInset)
      make.height.equalTo(DesignSystem.Size.separatorHeight)
    }

    // Buttons
    editButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.buttonWidth)
    }

    saveButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.left.equalToSuperview().offset(LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.buttonWidth)
    }

    cancelEditButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.left.equalTo(saveButton.snp.right).offset(Spacing.section)
      make.width.equalTo(LocalLayout.buttonWidth)
    }

    openFolderButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.right.equalTo(closeButton.snp.left).offset(-Spacing.section)
      make.width.equalTo(LocalLayout.iconSize)
    }

    closeButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.right.equalToSuperview().offset(-LocalLayout.largeInset)
      make.width.equalTo(LocalLayout.buttonWidth)
    }
  }
}
