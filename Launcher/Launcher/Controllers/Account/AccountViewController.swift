//
//  AccountViewController.swift
//  Launcher
//
//  Account management view controller
//

import AppKit
import SnapKit
import Yatagarasu

// swiftlint:disable type_body_length
class AccountViewController: NSViewController {

  // MARK: - Properties

  private var microsoftAccounts: [MicrosoftAccount] = []
  private var offlineAccounts: [OfflineAccount] = []
  private let accountManager = MicrosoftAccountManager.shared
  private let offlineAccountManager = OfflineAccountManager.shared
  private var isDeveloperMode: Bool = false {
    didSet {
      UserDefaults.standard.set(isDeveloperMode, forKey: "AccountDeveloperMode")
      updateTableRowHeight()
      tableView.reloadData()
    }
  }

  // UI components
  private let titleLabel = BRLabel(
    text: Localized.Account.title,
    font: .systemFont(ofSize: 20, weight: .semibold),
    textColor: .labelColor,
    alignment: .left
  )

  private let subtitleLabel = BRLabel(
    text: Localized.Account.subtitle,
    font: .systemFont(ofSize: 12),
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  private lazy var loginMicrosoftButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Account.signInMicrosoftButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(loginMicrosoft)
    return button
  }()

  private lazy var addOfflineAccountButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Account.addOfflineAccountButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(addOfflineAccount)
    return button
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.scrollerStyle = .overlay
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

  private let headerSeparator = BRSeparator.horizontal()

  private lazy var developerModeSwitch: NSSwitch = {
    let toggle = NSSwitch()
    toggle.target = self
    toggle.action = #selector(toggleDeveloperMode)
    return toggle
  }()

  private let developerModeLabel = BRLabel(
    text: Localized.Account.developerModeLabel,
    font: .systemFont(ofSize: 12),
    textColor: .secondaryLabelColor,
    alignment: .left
  )

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
    view.addSubview(addOfflineAccountButton)
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
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(view.snp.centerX).offset(-4)
      make.height.equalTo(32)
    }

    addOfflineAccountButton.snp.makeConstraints { make in
      make.top.equalTo(loginMicrosoftButton)
      make.left.equalTo(view.snp.centerX).offset(4)
      make.right.equalToSuperview().offset(-20)
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
    offlineAccounts = offlineAccountManager.loadAccounts()
    tableView.reloadData()
    updateEmptyState()
  }

  private func loadDeveloperMode() {
    isDeveloperMode = UserDefaults.standard.bool(forKey: "AccountDeveloperMode")
    developerModeSwitch.state = isDeveloperMode ? .on : .off
  }

  private func updateEmptyState() {
    let isEmpty = microsoftAccounts.isEmpty && offlineAccounts.isEmpty
    emptyLabel.isHidden = !isEmpty
    scrollView.isHidden = isEmpty
  }

  private func updateTableRowHeight() {
    tableView.rowHeight = isDeveloperMode ? 165 : 64
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
        guard let self = self else { return }

        // Convert skin and cape data from response
        let skins = response.skins?.compactMap { responseSkin -> Skin in
          Skin(
            id: responseSkin.id,
            state: responseSkin.state,
            url: responseSkin.url,
            variant: responseSkin.variant,
            alias: responseSkin.alias
          )
        }

        let capes = response.capes?.compactMap { responseCape -> Cape in
          Cape(
            id: responseCape.id,
            state: responseCape.state,
            url: responseCape.url,
            alias: responseCape.alias
          )
        }

        // Create account with all data including skins and capes
        let account = MicrosoftAccount(
          id: response.id,
          name: response.name,
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          timestamp: Date().timeIntervalSince1970,
          skins: skins,
          capes: capes
        )

        // Save account
        self.accountManager.saveAccount(account)
        self.loadAccounts()
        Logger.shared.info("Account added: \(response.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes", category: "Account")
      }

      viewController.onAuthFailure = { error in
        Logger.shared.error("Authentication failed: \(error.localizedDescription)", category: "Account")
      }
    }
  }

  @objc private func addOfflineAccount() {
    let alert = NSAlert()
    alert.messageText = Localized.Account.offlineAccountTitle
    alert.informativeText = Localized.Account.offlineAccountMessage
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.Account.addButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
    textField.placeholderString = Localized.Account.offlineAccountPlaceholder
    alert.accessoryView = textField

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.processOfflineAccountAddition(username: textField.stringValue)
    }

    // Focus on text field
    alert.window.makeFirstResponder(textField)
  }

  private func processOfflineAccountAddition(username: String) {
    // Validate username
    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmedUsername.isEmpty {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.emptyUsernameMessage)
      return
    }

    if trimmedUsername.count < 3 || trimmedUsername.count > 16 {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.invalidUsernameLengthMessage)
      return
    }

    // Check if username contains only valid characters (letters, numbers, underscores)
    let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    if trimmedUsername.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
      showAlert(title: Localized.Account.invalidUsernameTitle, message: Localized.Account.invalidUsernameFormatMessage)
      return
    }

    // Check for duplicates
    if offlineAccounts.contains(where: { $0.name.lowercased() == trimmedUsername.lowercased() }) {
      showAlert(title: Localized.Account.duplicateUsernameTitle, message: Localized.Account.duplicateUsernameMessage)
      return
    }

    // Generate UUID for the account
    let uuid = offlineAccountManager.generateUUID(for: trimmedUsername)

    // Create and save the offline account
    let account = OfflineAccount(
      id: uuid,
      name: trimmedUsername,
      timestamp: Date().timeIntervalSince1970
    )

    offlineAccountManager.saveAccount(account)
    loadAccounts()
    Logger.shared.info("Offline account added: \(trimmedUsername)", category: "Account")
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
          tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count else {
      return
    }

    // Only Microsoft accounts can be refreshed
    if tableView.clickedRow >= microsoftAccounts.count {
      showAlert(
        title: Localized.Account.refreshFailedTitle,
        message: "Offline accounts cannot be refreshed"
      )
      return
    }

    let account = microsoftAccounts[tableView.clickedRow]

    Task { @MainActor in
      do {
        // Refresh the account using refresh token
        let authManager = MicrosoftAuthManager.shared
        let response = try await authManager.completeRefresh(refreshToken: account.refreshToken)

        // Convert skin and cape data from response
        let skins = response.skins?.compactMap { responseSkin -> Skin in
          Skin(
            id: responseSkin.id,
            state: responseSkin.state,
            url: responseSkin.url,
            variant: responseSkin.variant,
            alias: responseSkin.alias
          )
        }

        let capes = response.capes?.compactMap { responseCape -> Cape in
          Cape(
            id: responseCape.id,
            state: responseCape.state,
            url: responseCape.url,
            alias: responseCape.alias
          )
        }

        // Save the refreshed account data with skins and capes
        accountManager.updateAccountFromRefresh(
          id: response.id,
          name: response.name,
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          skins: skins,
          capes: capes
        )

        Logger.shared.info("Account refreshed: \(response.name) with \(skins?.count ?? 0) skins and \(capes?.count ?? 0) capes", category: "Account")
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
          tableView.clickedRow < microsoftAccounts.count + offlineAccounts.count else {
      return
    }

    let rowToDelete = tableView.clickedRow
    let isMicrosoftAccount = rowToDelete < microsoftAccounts.count

    let accountName: String
    let accountId: String
    let isOffline: Bool

    if isMicrosoftAccount {
      let account = microsoftAccounts[rowToDelete]
      accountName = account.name
      accountId = account.id
      isOffline = false
    } else {
      let account = offlineAccounts[rowToDelete - microsoftAccounts.count]
      accountName = account.name
      accountId = account.id
      isOffline = true
    }

    let alert = NSAlert()
    alert.messageText = Localized.Account.deleteConfirmTitle
    alert.informativeText = Localized.Account.deleteAccountConfirmMessage(accountName)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.deleteButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(accountId: accountId, isOffline: isOffline)
    }
  }

  private func performDelete(accountId: String, isOffline: Bool) {
    if isOffline {
      offlineAccountManager.deleteAccount(id: accountId)
    } else {
      accountManager.deleteAccount(id: accountId)
    }
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

  // MARK: - Avatar Loading

  private func loadMinecraftAvatar(uuid: String?, username: String? = nil, completion: @escaping (NSImage?) -> Void) {
    // Use Crafatar service for avatar rendering
    // https://crafatar.com provides Minecraft player avatars
    let avatarURLString: String

    if let uuid = uuid {
      // Format UUID properly (remove dashes for Crafatar)
      let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
      // Use size 128 for better quality, overlay for skin layers
      avatarURLString = "https://crafatar.com/avatars/\(cleanUUID)?size=128&overlay"
    } else if let username = username {
      // For offline accounts, use Steve skin via MineAvatar
      avatarURLString = "https://minotar.net/avatar/\(username)/128"
    } else {
      completion(nil)
      return
    }

    guard let url = URL(string: avatarURLString) else {
      completion(nil)
      return
    }

    // Load image asynchronously
    URLSession.shared.dataTask(with: url) { data, response, error in
      guard let data = data,
            error == nil,
            let image = NSImage(data: data) else {
        completion(nil)
        return
      }
      completion(image)
    }.resume()
  }
}

// MARK: - Cell View Helpers

private extension AccountViewController {
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

  private func setupMicrosoftAccountCell(containerView: NSView, account: MicrosoftAccount) {
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

  private func setupOfflineAccountCell(containerView: NSView, account: OfflineAccount) {
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
