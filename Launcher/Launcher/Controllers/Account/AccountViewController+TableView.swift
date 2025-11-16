//
//  AccountViewController+TableView.swift
//  Launcher
//
//  TableView DataSource and Delegate for AccountViewController
//

import AppKit
import SnapKit
import Yatagarasu

// MARK: - Cell View Helpers

extension AccountViewController {
  func createContainerView() -> NSView {
    let containerView = NSView()
    containerView.wantsLayer = true
    containerView.layer?.cornerRadius = 8
    containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    return containerView
  }

  func createIconView(for account: MicrosoftAccount) -> NSImageView {
    let iconView = NSImageView()
    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.wantsLayer = true
    iconView.layer?.cornerRadius = 6
    iconView.layer?.masksToBounds = true

    // Set default image first
    iconView.image = NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: nil)
    iconView.contentTintColor = .systemGreen

    // Load avatar asynchronously
    loadMinecraftAvatar(uuid: account.id) { [weak iconView] image in
      DispatchQueue.main.async {
        iconView?.image = image
        iconView?.contentTintColor = nil
      }
    }

    return iconView
  }

  func createNameLabel(for account: MicrosoftAccount) -> BRLabel {
    BRLabel(
      text: account.name,
      font: .systemFont(ofSize: 14, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
  }

  func createOfflineIconView(for account: OfflineAccount) -> NSImageView {
    let iconView = NSImageView()
    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.wantsLayer = true
    iconView.layer?.cornerRadius = 6
    iconView.layer?.masksToBounds = true

    // Set default image first
    iconView.image = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
    iconView.contentTintColor = .systemBlue

    // Load avatar asynchronously (offline accounts use Steve skin by default)
    loadMinecraftAvatar(uuid: nil, username: account.name) { [weak iconView] image in
      DispatchQueue.main.async {
        iconView?.image = image
        iconView?.contentTintColor = nil
      }
    }

    return iconView
  }

  func createOfflineNameLabel(for account: OfflineAccount) -> BRLabel {
    BRLabel(
      text: account.name,
      font: .systemFont(ofSize: 14, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
  }
}

// MARK: - NSTableViewDataSource

extension AccountViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return microsoftAccounts.count + offlineAccounts.count
  }
}

// MARK: - NSTableViewDelegate

extension AccountViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cellView = NSView()
    let containerView = createContainerView()
    cellView.addSubview(containerView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
    }

    // Check if this is a Microsoft or Offline account
    if row < microsoftAccounts.count {
      // Microsoft account
      let account = microsoftAccounts[row]
      setupMicrosoftAccountCell(containerView: containerView, account: account)
    } else {
      // Offline account
      let account = offlineAccounts[row - microsoftAccounts.count]
      setupOfflineAccountCell(containerView: containerView, account: account)
    }

    return cellView
  }

  func setupMicrosoftAccountCell(containerView: NSView, account: MicrosoftAccount) {
    let iconView = createIconView(for: account)
    containerView.addSubview(iconView)

    iconView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.top.equalToSuperview().offset(10)
      make.width.height.equalTo(36)
    }

    let nameLabel = createNameLabel(for: account)
    containerView.addSubview(nameLabel)

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconView.snp.right).offset(12)
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-12)
    }

    if isDeveloperMode {
      addDeveloperModeInfo(to: containerView, for: account, below: nameLabel)
    } else {
      addNormalModeInfo(to: containerView, for: account, below: nameLabel)
    }
  }

  func setupOfflineAccountCell(containerView: NSView, account: OfflineAccount) {
    let iconView = createOfflineIconView(for: account)
    containerView.addSubview(iconView)

    iconView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.top.equalToSuperview().offset(10)
      make.width.height.equalTo(36)
    }

    let nameLabel = createOfflineNameLabel(for: account)
    containerView.addSubview(nameLabel)

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconView.snp.right).offset(12)
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-12)
    }

    if isDeveloperMode {
      addOfflineDeveloperModeInfo(to: containerView, for: account, below: nameLabel)
    } else {
      addOfflineNormalModeInfo(to: containerView, for: account, below: nameLabel)
    }
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }
}
