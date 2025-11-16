//
//  AccountViewController+CellHelpers.swift
//  Launcher
//
//  Cell view helper methods for AccountViewController
//

import AppKit
import SnapKit
import Yatagarasu

extension AccountViewController {
  // MARK: - Developer Mode Info

  func addDeveloperModeInfo(to container: NSView, for account: MicrosoftAccount, below nameLabel: BRLabel) {
    let fullUUIDLabel = BRLabel(
      text: "UUID: \(account.id)",
      font: .systemFont(ofSize: 10, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    fullUUIDLabel.maximumNumberOfLines = 1
    container.addSubview(fullUUIDLabel)
    fullUUIDLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.right.equalToSuperview().offset(-12)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let timestampLabel = BRLabel(
      text: Localized.Account.loginTime(dateFormatter.string(from: Date(timeIntervalSince1970: account.timestamp))),
      font: .systemFont(ofSize: 10),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(timestampLabel)
    timestampLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(fullUUIDLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let expirationLabel = BRLabel(
      text: "Expires: \(dateFormatter.string(from: account.expirationDate))",
      font: .systemFont(ofSize: 10),
      textColor: account.isExpired ? .systemOrange : .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(expirationLabel)
    expirationLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(timestampLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let tokenLabel = BRLabel(
      text: "Access Token: \(String(account.accessToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    tokenLabel.maximumNumberOfLines = 1
    container.addSubview(tokenLabel)
    tokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(expirationLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let refreshTokenLabel = BRLabel(
      text: "Refresh Token: \(String(account.refreshToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    refreshTokenLabel.maximumNumberOfLines = 1
    container.addSubview(refreshTokenLabel)
    refreshTokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(tokenLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let expiryTime = Date().timeIntervalSince1970 - account.timestamp
    let hoursRemaining = max(0, 24 - Int(expiryTime / 3600))
    let statusText = account.isExpired ? Localized.Account.statusExpired : Localized.Account.statusValid(hoursRemaining)
    let statusLabel = BRLabel(
      text: statusText,
      font: .systemFont(ofSize: 10, weight: .medium),
      textColor: account.isExpired ? .systemOrange : .systemGreen,
      alignment: .left
    )
    container.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(refreshTokenLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }
  }

  func addNormalModeInfo(to container: NSView, for account: MicrosoftAccount, below nameLabel: BRLabel) {
    let uuidLabel = BRLabel(
      text: "UUID: \(account.shortUUID)",
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(uuidLabel)
    uuidLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(nameLabel.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-12)
    }

    let statusLabel = BRLabel(
      text: account.isExpired ? Localized.Account.statusExpired : Localized.Account.statusLoggedIn,
      font: .systemFont(ofSize: 10),
      textColor: account.isExpired ? .systemOrange : .systemGreen,
      alignment: .left
    )
    container.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(uuidLabel.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-12)
    }
  }

  func addOfflineNormalModeInfo(to container: NSView, for account: OfflineAccount, below nameLabel: BRLabel) {
    let uuidLabel = BRLabel(
      text: "UUID: \(account.shortUUID)",
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(uuidLabel)
    uuidLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(nameLabel.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-12)
    }

    let statusLabel = BRLabel(
      text: "\(Localized.Account.offlineAccountType) Mode",
      font: .systemFont(ofSize: 10),
      textColor: .systemBlue,
      alignment: .left
    )
    container.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(uuidLabel.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-12)
    }
  }

  func addOfflineDeveloperModeInfo(to container: NSView, for account: OfflineAccount, below nameLabel: BRLabel) {
    let fullUUIDLabel = BRLabel(
      text: "UUID: \(account.id)",
      font: .systemFont(ofSize: 10, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    fullUUIDLabel.maximumNumberOfLines = 1
    container.addSubview(fullUUIDLabel)
    fullUUIDLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.right.equalToSuperview().offset(-12)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let timestampLabel = BRLabel(
      text: Localized.Account.loginTime(dateFormatter.string(from: Date(timeIntervalSince1970: account.timestamp))),
      font: .systemFont(ofSize: 10),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(timestampLabel)
    timestampLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(fullUUIDLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let typeLabel = BRLabel(
      text: "Type: \(Localized.Account.offlineAccountType)",
      font: .systemFont(ofSize: 10),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    container.addSubview(typeLabel)
    typeLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(timestampLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let tokenLabel = BRLabel(
      text: "Access Token: \(String(account.accessToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    tokenLabel.maximumNumberOfLines = 1
    container.addSubview(tokenLabel)
    tokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(typeLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }

    let statusLabel = BRLabel(
      text: "✓ \(Localized.Account.offlineAccountType) Mode",
      font: .systemFont(ofSize: 10, weight: .medium),
      textColor: .systemBlue,
      alignment: .left
    )
    container.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(tokenLabel.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-12)
    }
  }
}
