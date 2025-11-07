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

  private var accounts: [String] = []
  private let accountsKey = "SavedAccounts"

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
    tableView.rowHeight = 44
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

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
      text: Localized.Account.emptyMessage,
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.isHidden = true
    return label
  }()

  private let usernameField: NSTextField = {
    let textField = NSTextField()
    textField.placeholderString = Localized.Account.usernamePlaceholder
    textField.font = .systemFont(ofSize: 13)
    textField.focusRingType = .none
    return textField
  }()

  private lazy var addButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "plus.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemGreen,
      accessibilityLabel: Localized.Account.addButton
    )
    button.target = self
    button.action = #selector(addAccount)
    return button
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private let inputSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 500))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadAccounts()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(headerSeparator)
    view.addSubview(usernameField)
    view.addSubview(addButton)
    view.addSubview(inputSeparator)
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

    usernameField.snp.makeConstraints { make in
      make.top.equalTo(headerSeparator.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(addButton.snp.left).offset(-8)
      make.height.equalTo(28)
    }

    addButton.snp.makeConstraints { make in
      make.centerY.equalTo(usernameField)
      make.right.equalToSuperview().offset(-20)
      make.width.height.equalTo(28)
    }

    inputSeparator.snp.makeConstraints { make in
      make.top.equalTo(usernameField.snp.bottom).offset(16)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(inputSeparator.snp.bottom).offset(12)
      make.left.right.bottom.equalToSuperview().inset(20)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalToSuperview().inset(40)
    }
  }

  // MARK: - Data Management

  private func loadAccounts() {
    if let savedAccounts = UserDefaults.standard.array(forKey: accountsKey) as? [String] {
      accounts = savedAccounts
    }

    tableView.reloadData()
    updateEmptyState()
  }

  private func saveAccounts() {
    UserDefaults.standard.set(accounts, forKey: accountsKey)
  }

  private func updateEmptyState() {
    emptyLabel.isHidden = !accounts.isEmpty
    scrollView.isHidden = accounts.isEmpty
  }

  // MARK: - Actions

  @objc private func addAccount() {
    let username = usernameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    // Validate username
    guard !username.isEmpty else {
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.emptyUsernameMessage
      )
      return
    }

    guard username.count >= 3 && username.count <= 16 else {
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.invalidUsernameLengthMessage
      )
      return
    }

    let usernameRegex = "^[a-zA-Z0-9_]+$"
    let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
    guard usernamePredicate.evaluate(with: username) else {
      showAlert(
        title: Localized.Account.invalidUsernameTitle,
        message: Localized.Account.invalidUsernameFormatMessage
      )
      return
    }

    // Check for duplicate
    guard !accounts.contains(username) else {
      showAlert(
        title: Localized.Account.duplicateUsernameTitle,
        message: Localized.Account.duplicateUsernameMessage
      )
      return
    }

    // Add account
    accounts.append(username)
    saveAccounts()
    tableView.reloadData()
    updateEmptyState()

    // Clear input field
    usernameField.stringValue = ""

    Logger.shared.info("Added account: \(username)", category: "Account")
  }

  // MARK: - Context Menu

  private func createContextMenu() -> NSMenu {
    let menu = NSMenu()

    let deleteItem = NSMenuItem(
      title: Localized.Account.menuDelete,
      action: #selector(deleteAccount(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)

    return menu
  }

  @objc private func deleteAccount(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < accounts.count else {
      return
    }

    let rowToDelete = tableView.clickedRow
    let username = accounts[rowToDelete]

    let alert = NSAlert()
    alert.messageText = Localized.Account.deleteConfirmTitle
    alert.informativeText = Localized.Account.deleteConfirmMessage(username)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Account.deleteButton)
    alert.addButton(withTitle: Localized.Account.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(at: rowToDelete)
    }
  }

  private func performDelete(at index: Int) {
    guard index >= 0 && index < accounts.count else { return }

    let username = accounts[index]
    accounts.remove(at: index)
    saveAccounts()
    tableView.reloadData()
    updateEmptyState()

    Logger.shared.info("Deleted account: \(username)", category: "Account")
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
    return accounts.count
  }
}

// MARK: - NSTableViewDelegate

extension AccountViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let username = accounts[row]

    let cellView = NSTableCellView()

    // Icon
    let iconView = NSImageView()
    iconView.image = NSImage(systemSymbolName: "person.circle.fill", accessibilityDescription: nil)
    iconView.contentTintColor = .systemBlue
    cellView.addSubview(iconView)

    iconView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(8)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(24)
    }

    // Username label
    let textLabel = BRLabel(
      text: username,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    cellView.addSubview(textLabel)

    textLabel.snp.makeConstraints { make in
      make.left.equalTo(iconView.snp.right).offset(8)
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-8)
    }

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }
}
