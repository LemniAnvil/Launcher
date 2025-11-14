//
//  AccountViewController.swift
//  Launcher
//
//  Account management view controller
//

import AppKit
import SnapKit
import Yatagarasu

class AccountViewController: NSViewController {

  // MARK: - Properties

  private var microsoftAccounts: [MicrosoftAccount] = []
  private let accountManager = MicrosoftAccountManager.shared
  private var isDeveloperMode: Bool = false {
    didSet {
      UserDefaults.standard.set(isDeveloperMode, forKey: "AccountDeveloperMode")
      updateTableRowHeight()
      tableView.reloadData()
    }
  }

  // UI components
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Account.title,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let subtitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Account.subtitle,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var loginMicrosoftButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Account.signInMicrosoftButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(loginMicrosoft)
    return button
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    return scrollView
  }()

  private lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 64
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 4)

    tableView.dataSource = self
    tableView.delegate = self

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AccountColumn"))
    column.width = 300
    tableView.addTableColumn(column)

    tableView.menu = createContextMenu()

    return tableView
  }()

  private let emptyLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Account.emptyMicrosoftMessage,
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true
    return label
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private lazy var developerModeSwitch: NSSwitch = {
    let toggle = NSSwitch()
    toggle.target = self
    toggle.action = #selector(toggleDeveloperMode)
    return toggle
  }()

  private let developerModeLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Account.developerModeLabel,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 500))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadDeveloperMode()
    loadAccounts()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(headerSeparator)
    view.addSubview(developerModeLabel)
    view.addSubview(developerModeSwitch)
    view.addSubview(loginMicrosoftButton)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)

    scrollView.documentView = tableView

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    headerSeparator.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    developerModeSwitch.snp.makeConstraints { make in
      make.top.equalTo(headerSeparator.snp.bottom).offset(12)
      make.right.equalToSuperview().offset(-20)
    }

    developerModeLabel.snp.makeConstraints { make in
      make.centerY.equalTo(developerModeSwitch)
      make.right.equalTo(developerModeSwitch.snp.left).offset(-8)
    }

    loginMicrosoftButton.snp.makeConstraints { make in
      make.top.equalTo(developerModeSwitch.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
      make.width.equalTo(200)
      make.height.equalTo(32)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(loginMicrosoftButton.snp.bottom).offset(16)
      make.left.right.bottom.equalToSuperview().inset(20)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalToSuperview().inset(40)
    }
  }

  // MARK: - Data Management

  private func loadAccounts() {
    microsoftAccounts = accountManager.loadAccounts()
    tableView.reloadData()
    updateEmptyState()
  }

  private func loadDeveloperMode() {
    isDeveloperMode = UserDefaults.standard.bool(forKey: "AccountDeveloperMode")
    developerModeSwitch.state = isDeveloperMode ? .on : .off
  }

  private func updateEmptyState() {
    emptyLabel.isHidden = !microsoftAccounts.isEmpty
    scrollView.isHidden = microsoftAccounts.isEmpty
  }

  private func updateTableRowHeight() {
    tableView.rowHeight = isDeveloperMode ? 120 : 64
  }

  // MARK: - Actions

  @objc private func toggleDeveloperMode() {
    isDeveloperMode = developerModeSwitch.state == .on
    Logger.shared.info("Developer mode: \(isDeveloperMode)", category: "Account")
  }

  @objc private func loginMicrosoft() {
    // Open Microsoft authentication window
    let authWindowController = MicrosoftAuthWindowController()
    authWindowController.window?.makeKeyAndOrderFront(nil)

    // Set up callbacks
    if let viewController = authWindowController.contentViewController as? MicrosoftAuthViewController {
      viewController.onAuthSuccess = { [weak self] response in
        self?.loadAccounts()
        Logger.shared.info("Account added: \(response.name)", category: "Account")
      }

      viewController.onAuthFailure = { error in
        Logger.shared.error("Authentication failed: \(error.localizedDescription)", category: "Account")
      }
    }
  }

  // MARK: - Context Menu

  private func createContextMenu() -> NSMenu {
    let menu = NSMenu()

    let refreshItem = NSMenuItem(
      title: Localized.Account.menuRefresh,
      action: #selector(refreshAccount(_:)),
      keyEquivalent: ""
    )
    refreshItem.target = self
    menu.addItem(refreshItem)

    menu.addItem(NSMenuItem.separator())

    let deleteItem = NSMenuItem(
      title: Localized.Account.menuDelete,
      action: #selector(deleteAccount(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)

    return menu
  }

  @objc private func refreshAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < microsoftAccounts.count else {
      return
    }

    let account = microsoftAccounts[tableView.clickedRow]

    Task { @MainActor in
      do {
        // Refresh the account using refresh token
        let authManager = MicrosoftAuthManager.shared
        let response = try await authManager.completeRefresh(refreshToken: account.refreshToken)

        Logger.shared.info("Account refreshed: \(response.name)", category: "Account")
        loadAccounts()

        showAlert(
          title: Localized.Account.refreshSuccessTitle,
          message: Localized.Account.refreshSuccessMessage(response.name)
        )
      } catch {
        Logger.shared.error("Refresh failed: \(error.localizedDescription)", category: "Account")
        showAlert(
          title: Localized.Account.refreshFailedTitle,
          message: error.localizedDescription
        )
      }
    }
  }

  @objc private func deleteAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < microsoftAccounts.count else {
      return
    }

    let rowToDelete = tableView.clickedRow
    let account = microsoftAccounts[rowToDelete]

    let alert = NSAlert()
    alert.messageText = Localized.Account.deleteConfirmTitle
    alert.informativeText = Localized.Account.deleteAccountConfirmMessage(account.name)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.deleteButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(accountId: account.id)
    }
  }

  private func performDelete(accountId: String) {
    accountManager.deleteAccount(id: accountId)
    loadAccounts()
    Logger.shared.info("Deleted account: \(accountId)", category: "Account")
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}

// MARK: - NSTableViewDataSource

extension AccountViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return microsoftAccounts.count
  }
}

// MARK: - NSTableViewDelegate

extension AccountViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let account = microsoftAccounts[row]

    let cellView = NSView()

    // Container for better layout
    let containerView = NSView()
    containerView.wantsLayer = true
    containerView.layer?.cornerRadius = 8
    containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    cellView.addSubview(containerView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
    }

    // Icon
    let iconView = NSImageView()
    iconView.image = NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: nil)
    iconView.contentTintColor = .systemGreen
    containerView.addSubview(iconView)

    iconView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(12)
      make.top.equalToSuperview().offset(10)
      make.width.height.equalTo(36)
    }

    // Name label
    let nameLabel = BRLabel(
      text: account.name,
      font: .systemFont(ofSize: 14, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    containerView.addSubview(nameLabel)

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconView.snp.right).offset(12)
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-12)
    }

    if isDeveloperMode {
      // Developer Mode: Show detailed information

      // Full UUID label
      let fullUUIDLabel = BRLabel(
        text: "UUID: \(account.id)",
        font: .systemFont(ofSize: 10, weight: .regular),
        textColor: .secondaryLabelColor,
        alignment: .left
      )
      fullUUIDLabel.maximumNumberOfLines = 1
      containerView.addSubview(fullUUIDLabel)

      fullUUIDLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(nameLabel.snp.bottom).offset(4)
        make.right.equalToSuperview().offset(-12)
      }

      // Timestamp label
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      dateFormatter.timeStyle = .short
      let date = Date(timeIntervalSince1970: account.timestamp)
      let timestampLabel = BRLabel(
        text: Localized.Account.loginTime(dateFormatter.string(from: date)),
        font: .systemFont(ofSize: 10),
        textColor: .secondaryLabelColor,
        alignment: .left
      )
      containerView.addSubview(timestampLabel)

      timestampLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(fullUUIDLabel.snp.bottom).offset(3)
        make.right.equalToSuperview().offset(-12)
      }

      // Access Token label (truncated)
      let truncatedToken = String(account.accessToken.prefix(40)) + "..."
      let tokenLabel = BRLabel(
        text: "Access Token: \(truncatedToken)",
        font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
        textColor: .secondaryLabelColor,
        alignment: .left
      )
      tokenLabel.maximumNumberOfLines = 1
      containerView.addSubview(tokenLabel)

      tokenLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(timestampLabel.snp.bottom).offset(3)
        make.right.equalToSuperview().offset(-12)
      }

      // Status indicator
      let expiryTime = Date().timeIntervalSince1970 - account.timestamp
      let hoursRemaining = max(0, 24 - Int(expiryTime / 3600))
      let statusText = account.isExpired
        ? Localized.Account.statusExpired
        : Localized.Account.statusValid(hoursRemaining)

      let statusLabel = BRLabel(
        text: statusText,
        font: .systemFont(ofSize: 10, weight: .medium),
        textColor: account.isExpired ? .systemOrange : .systemGreen,
        alignment: .left
      )
      containerView.addSubview(statusLabel)

      statusLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(tokenLabel.snp.bottom).offset(3)
        make.right.equalToSuperview().offset(-12)
      }
    } else {
      // Normal Mode: Show basic information

      // UUID label (short)
      let uuidLabel = BRLabel(
        text: "UUID: \(account.shortUUID)",
        font: .systemFont(ofSize: 11),
        textColor: .secondaryLabelColor,
        alignment: .left
      )
      containerView.addSubview(uuidLabel)

      uuidLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(nameLabel.snp.bottom).offset(2)
        make.right.equalToSuperview().offset(-12)
      }

      // Status indicator
      let statusLabel = BRLabel(
        text: account.isExpired ? Localized.Account.statusExpired : Localized.Account.statusLoggedIn,
        font: .systemFont(ofSize: 10),
        textColor: account.isExpired ? .systemOrange : .systemGreen,
        alignment: .left
      )
      containerView.addSubview(statusLabel)

      statusLabel.snp.makeConstraints { make in
        make.left.equalTo(nameLabel)
        make.top.equalTo(uuidLabel.snp.bottom).offset(2)
        make.right.equalToSuperview().offset(-12)
      }
    }

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }
}
