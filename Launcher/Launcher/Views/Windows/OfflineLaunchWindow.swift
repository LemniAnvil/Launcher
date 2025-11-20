//
//  OfflineLaunchWindow.swift
//  Launcher
//
//  Offline launch configuration window
//

import AppKit
import SnapKit
import Yatagarasu

/// Offline launch window controller
class OfflineLaunchWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = Localized.OfflineLaunch.windowTitle
    window.center()

    self.init(window: window)

    let viewController = OfflineLaunchViewController()
    window.contentViewController = viewController
  }
}

/// Offline launch view controller
class OfflineLaunchViewController: NSViewController {

  // MARK: - Properties

  struct AccountInfo {
    let username: String
    let uuid: String
    let accessToken: String
  }

  var onLaunch: ((AccountInfo) -> Void)?
  private var microsoftAccounts: [MicrosoftAccount] = []
  private var offlineAccounts: [OfflineAccount] = []
  private let accountManager = MicrosoftAccountManager.shared
  private let offlineAccountManager = OfflineAccountManager.shared
  private var selectedAccountInfo: AccountInfo?

  // UI components
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.title,
      font: .systemFont(ofSize: 18, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let descriptionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.description,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    return label
  }()

  private let accountLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.selectAccountLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    scrollView.scrollerStyle = .overlay
    return scrollView
  }()

  private lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 44
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.dataSource = self
    tableView.delegate = self

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AccountColumn"))
    column.width = 300
    tableView.addTableColumn(column)

    return tableView
  }()

  private let emptyLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.noAccountsMessage,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true
    return label
  }()

  private lazy var launchButton: NSButton = {
    let button = NSButton()
    button.title = Localized.OfflineLaunch.launchButton
    button.bezelStyle = .rounded
    button.keyEquivalent = "\r"
    button.target = self
    button.action = #selector(launchGame)
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton()
    button.title = Localized.OfflineLaunch.cancelButton
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    button.target = self
    button.action = #selector(cancel)
    return button
  }()

  private let separator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadAccounts()
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    // Select first account if available
    if tableView.numberOfRows > 0 {
      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      updateSelectedAccount()
    }
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(titleLabel)
    view.addSubview(descriptionLabel)
    view.addSubview(accountLabel)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)
    view.addSubview(separator)
    view.addSubview(launchButton)
    view.addSubview(cancelButton)

    scrollView.documentView = tableView

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.right.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(10)
      make.left.right.equalToSuperview().inset(20)
    }

    accountLabel.snp.makeConstraints { make in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
      make.left.equalToSuperview().offset(20)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(accountLabel.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(180)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalToSuperview().inset(40)
    }

    separator.snp.makeConstraints { make in
      make.bottom.equalTo(launchButton.snp.top).offset(-16)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-16)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(80)
    }

    launchButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-16)
      make.right.equalTo(cancelButton.snp.left).offset(-12)
      make.width.equalTo(80)
    }
  }

  // MARK: - Data

  private func loadAccounts() {
    microsoftAccounts = accountManager.loadAccounts()
    offlineAccounts = offlineAccountManager.loadAccounts()
    tableView.reloadData()
    updateEmptyState()
  }

  private func updateEmptyState() {
    let isEmpty = microsoftAccounts.isEmpty && offlineAccounts.isEmpty
    emptyLabel.isHidden = !isEmpty
    scrollView.isHidden = isEmpty
    launchButton.isEnabled = !isEmpty
  }

  private func updateSelectedAccount() {
    let selectedRow = tableView.selectedRow
    guard selectedRow >= 0 else {
      selectedAccountInfo = nil
      launchButton.isEnabled = false
      return
    }

    if selectedRow < microsoftAccounts.count {
      // Microsoft account - use real credentials
      let account = microsoftAccounts[selectedRow]
      selectedAccountInfo = AccountInfo(
        username: account.name,
        uuid: account.id,
        accessToken: account.accessToken
      )
    } else {
      // Offline account - use generated UUID and fake token
      let account = offlineAccounts[selectedRow - microsoftAccounts.count]
      selectedAccountInfo = AccountInfo(
        username: account.name,
        uuid: account.id,
        accessToken: account.accessToken
      )
    }
    launchButton.isEnabled = true
  }

  // MARK: - Actions

  @objc private func launchGame() {
    guard let accountInfo = selectedAccountInfo else {
      showAlert(
        title: Localized.OfflineLaunch.errorTitle,
        message: Localized.OfflineLaunch.errorNoAccountSelected
      )
      return
    }

    // Notify launch with account info
    onLaunch?(accountInfo)

    // Close window
    view.window?.close()
  }

  @objc private func cancel() {
    view.window?.close()
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.OfflineLaunch.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  // MARK: - Avatar Loading

  private func loadMinecraftAvatar(uuid: String?, username: String? = nil, completion: @escaping (NSImage?) -> Void) {
    // Use Crafatar service for avatar rendering
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
    URLSession.shared.dataTask(with: url) { data, _, error in
      guard let data = data, error == nil, let image = NSImage(data: data) else {
        completion(nil)
        return
      }
      completion(image)
    }
    .resume()
  }
}

// MARK: - NSTableViewDataSource

extension OfflineLaunchViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return microsoftAccounts.count + offlineAccounts.count
  }
}

// MARK: - NSTableViewDelegate

extension OfflineLaunchViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cellView = NSView()
    let containerView = NSView()
    containerView.wantsLayer = true
    containerView.layer?.cornerRadius = 6
    containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    cellView.addSubview(containerView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
    }

    // Create icon view
    let iconView = NSImageView()
    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.wantsLayer = true
    iconView.layer?.cornerRadius = 4
    iconView.layer?.masksToBounds = true
    containerView.addSubview(iconView)

    iconView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(8)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(28)
    }

    // Create name label
    let nameLabel = BRLabel(
      text: "",
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    containerView.addSubview(nameLabel)

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconView.snp.right).offset(8)
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-8)
    }

    // Configure based on account type
    if row < microsoftAccounts.count {
      let account = microsoftAccounts[row]
      nameLabel.stringValue = account.name
      iconView.image = NSImage(systemSymbolName: "person.crop.circle.fill", accessibilityDescription: nil)
      iconView.contentTintColor = .systemGreen

      // Load avatar asynchronously
      loadMinecraftAvatar(uuid: account.id) { [weak iconView] image in
        DispatchQueue.main.async {
          if let image = image {
            iconView?.image = image
            iconView?.contentTintColor = nil
          }
        }
      }
    } else {
      let account = offlineAccounts[row - microsoftAccounts.count]
      nameLabel.stringValue = "\(account.name) \(Localized.OfflineLaunch.offlineAccountSuffix)"
      iconView.image = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
      iconView.contentTintColor = .systemBlue

      // Load avatar asynchronously (offline accounts use Steve skin by default)
      loadMinecraftAvatar(uuid: nil, username: account.name) { [weak iconView] image in
        DispatchQueue.main.async {
          if let image = image {
            iconView?.image = image
            iconView?.contentTintColor = nil
          }
        }
      }
    }

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    updateSelectedAccount()
  }
}
