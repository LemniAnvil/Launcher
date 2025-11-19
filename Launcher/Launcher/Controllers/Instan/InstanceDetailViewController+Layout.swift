//
//  InstanceDetailViewController+Layout.swift
//  Launcher
//
//  Layout setup for instance detail view
//

import AppKit
import SnapKit

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
      make.top.equalToSuperview().offset(40)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(120)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(20)
      make.left.right.equalToSuperview().inset(40)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(40)
    }

    separator1.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(30)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(1)
    }

    // Configuration section
    configTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(separator1.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(40)
    }

    nameFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(configTitleLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    nameValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    nameTextField.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
      make.height.equalTo(24)
    }

    versionFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(nameFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    versionValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(versionFieldLabel)
      make.left.equalTo(versionFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    idFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(versionFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    idValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(idFieldLabel)
      make.left.equalTo(idFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    createdFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(idFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    createdValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(createdFieldLabel)
      make.left.equalTo(createdFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    modifiedFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(createdFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    modifiedValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(modifiedFieldLabel)
      make.left.equalTo(modifiedFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    separator2.snp.makeConstraints { make in
      make.top.equalTo(modifiedValueLabel.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(1)
    }

    // Buttons
    editButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(80)
    }

    saveButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(80)
    }

    cancelEditButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalTo(saveButton.snp.right).offset(12)
      make.width.equalTo(80)
    }

    openFolderButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalTo(closeButton.snp.left).offset(-12)
      make.width.equalTo(120)
    }

    closeButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalToSuperview().offset(-40)
      make.width.equalTo(80)
    }
  }
}
