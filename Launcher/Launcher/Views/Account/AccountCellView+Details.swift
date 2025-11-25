//
//  AccountCellView+Details.swift
//  Launcher
//
//  Detail labels extension for AccountCellView
//

import AppKit
import SnapKit
import Yatagarasu

extension AccountCellView {
  // MARK: - Microsoft Account Details

  func addMicrosoftNormalModeDetails(_ account: MicrosoftAccount) {
    var lastView: NSView = nameLabel

    // UUID label
    let uuidLabel = createDetailLabel(
      text: "UUID: \(account.shortUUID)",
      font: .systemFont(ofSize: 11),
      color: BRColorPalette.secondaryText
    )
    containerView.addSubview(uuidLabel)
    uuidLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(uuidLabel)
    lastView = uuidLabel

    // Status label
    let statusLabel = createDetailLabel(
      text: account.isExpired ? Localized.Account.statusExpired : Localized.Account.statusLoggedIn,
      font: .systemFont(ofSize: 10),
      color: account.isExpired ? .systemOrange : .systemGreen
    )
    containerView.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(statusLabel)
  }

  func addMicrosoftDeveloperModeDetails(_ account: MicrosoftAccount) {
    var lastView: NSView = nameLabel

    // Full UUID
    let fullUUIDLabel = createDetailLabel(
      text: "UUID: \(account.id)",
      font: .systemFont(ofSize: 10, weight: .regular),
      color: BRColorPalette.secondaryText
    )
    fullUUIDLabel.maximumNumberOfLines = 1
    containerView.addSubview(fullUUIDLabel)
    fullUUIDLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(4)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(fullUUIDLabel)
    lastView = fullUUIDLabel

    // Timestamp
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let timestampLabel = createDetailLabel(
      text: Localized.Account.loginTime(
        dateFormatter.string(from: Date(timeIntervalSince1970: account.timestamp))
      ),
      font: .systemFont(ofSize: 10),
      color: BRColorPalette.secondaryText
    )
    containerView.addSubview(timestampLabel)
    timestampLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(timestampLabel)
    lastView = timestampLabel

    // Expiration
    let expirationLabel = createDetailLabel(
      text: "Expires: \(dateFormatter.string(from: account.expirationDate))",
      font: .systemFont(ofSize: 10),
      color: account.isExpired ? .systemOrange : BRColorPalette.secondaryText
    )
    containerView.addSubview(expirationLabel)
    expirationLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(expirationLabel)
    lastView = expirationLabel

    // Access Token
    let tokenLabel = createDetailLabel(
      text: "Access Token: \(String(account.accessToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      color: BRColorPalette.secondaryText
    )
    tokenLabel.maximumNumberOfLines = 1
    containerView.addSubview(tokenLabel)
    tokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(tokenLabel)
    lastView = tokenLabel

    // Refresh Token
    let refreshTokenLabel = createDetailLabel(
      text: "Refresh Token: \(String(account.refreshToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      color: BRColorPalette.secondaryText
    )
    refreshTokenLabel.maximumNumberOfLines = 1
    containerView.addSubview(refreshTokenLabel)
    refreshTokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(refreshTokenLabel)
    lastView = refreshTokenLabel

    // Status
    let expiryTime = Date().timeIntervalSince1970 - account.timestamp
    let hoursRemaining = max(0, 24 - Int(expiryTime / 3600))
    let statusText =
      account.isExpired
      ? Localized.Account.statusExpired
      : Localized.Account.statusValid(hoursRemaining)
    let statusLabel = createDetailLabel(
      text: statusText,
      font: .systemFont(ofSize: 10, weight: .medium),
      color: account.isExpired ? .systemOrange : .systemGreen
    )
    containerView.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(statusLabel)
  }

  // MARK: - Offline Account Details

  func addOfflineNormalModeDetails(_ account: OfflineAccount) {
    var lastView: NSView = nameLabel

    // UUID label
    let uuidLabel = createDetailLabel(
      text: "UUID: \(account.shortUUID)",
      font: .systemFont(ofSize: 11),
      color: BRColorPalette.secondaryText
    )
    containerView.addSubview(uuidLabel)
    uuidLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(uuidLabel)
    lastView = uuidLabel

    // Status label
    let statusLabel = createDetailLabel(
      text: "\(Localized.Account.offlineAccountType) Mode",
      font: .systemFont(ofSize: 10),
      color: .systemBlue
    )
    containerView.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(2)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(statusLabel)
  }

  func addOfflineDeveloperModeDetails(_ account: OfflineAccount) {
    var lastView: NSView = nameLabel

    // Full UUID
    let fullUUIDLabel = createDetailLabel(
      text: "UUID: \(account.id)",
      font: .systemFont(ofSize: 10, weight: .regular),
      color: BRColorPalette.secondaryText
    )
    fullUUIDLabel.maximumNumberOfLines = 1
    containerView.addSubview(fullUUIDLabel)
    fullUUIDLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(4)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(fullUUIDLabel)
    lastView = fullUUIDLabel

    // Timestamp
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let timestampLabel = createDetailLabel(
      text: Localized.Account.loginTime(
        dateFormatter.string(from: Date(timeIntervalSince1970: account.timestamp))
      ),
      font: .systemFont(ofSize: 10),
      color: BRColorPalette.secondaryText
    )
    containerView.addSubview(timestampLabel)
    timestampLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(timestampLabel)
    lastView = timestampLabel

    // Type label
    let typeLabel = createDetailLabel(
      text: "Type: \(Localized.Account.offlineAccountType)",
      font: .systemFont(ofSize: 10),
      color: BRColorPalette.secondaryText
    )
    containerView.addSubview(typeLabel)
    typeLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(typeLabel)
    lastView = typeLabel

    // Access Token
    let tokenLabel = createDetailLabel(
      text: "Access Token: \(String(account.accessToken.prefix(40)))...",
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      color: BRColorPalette.secondaryText
    )
    tokenLabel.maximumNumberOfLines = 1
    containerView.addSubview(tokenLabel)
    tokenLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(tokenLabel)
    lastView = tokenLabel

    // Status
    let statusLabel = createDetailLabel(
      text: "✓ \(Localized.Account.offlineAccountType) Mode",
      font: .systemFont(ofSize: 10, weight: .medium),
      color: .systemBlue
    )
    containerView.addSubview(statusLabel)
    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(nameLabel)
      make.top.equalTo(lastView.snp.bottom).offset(3)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }
    detailLabels.append(statusLabel)
  }
}
