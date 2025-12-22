//
//  InstanceDetailViewController+Configuration.swift
//  Launcher
//
//  Configuration methods for instance detail view
//

import AppKit

// MARK: - Configuration
extension InstanceDetailViewController {
  func configureWithInstance() {
    // Set basic info
    titleLabel.stringValue = instance.name
    versionLabel.stringValue = Localized.InstanceDetail.versionInfo(instance.versionId)

    nameValueLabel.stringValue = instance.name
    versionValueLabel.stringValue = instance.versionId
    idValueLabel.stringValue = instance.id

    // Format dates
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short

    createdValueLabel.stringValue = dateFormatter.string(from: instance.createdAt)
    modifiedValueLabel.stringValue = dateFormatter.string(from: instance.lastModified)

    // Set icon color based on version type
    updateIconForVersion(instance.versionId)
  }

  func updateIconForVersion(_ versionId: String) {
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
}
