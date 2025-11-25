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

  var microsoftAccounts: [MicrosoftAccount] = []
  var offlineAccounts: [OfflineAccount] = []
  let accountManager = MicrosoftAccountManager.shared
  let offlineAccountManager = OfflineAccountManager.shared
  var isDeveloperMode: Bool = false {
    didSet {
      UserDefaults.standard.set(isDeveloperMode, forKey: "AccountDeveloperMode")
      updateTableRowHeight()
      tableView.reloadData()
    }
  }

  // Microsoft authentication properties
  var loginData: SecureLoginData?
  let authManager: MicrosoftAuthProtocol

  // Refresh status view
  let refreshStatusView = AccountRefreshStatusView()

  // MARK: - Initialization

  init(authManager: MicrosoftAuthProtocol = MicrosoftAuthManager.shared) {
    self.authManager = authManager
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    self.authManager = MicrosoftAuthManager.shared
    super.init(coder: coder)
  }

  // UI components
  private let titleLabel = BRLabel(
    text: Localized.Account.title,
    font: BRFonts.largeTitle,
    textColor: .labelColor,
    alignment: .left
  )

  private let subtitleLabel = BRLabel(
    text: Localized.Account.subtitle,
    font: BRFonts.caption,
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  lazy var loginMicrosoftButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Account.signInMicrosoftButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(loginMicrosoft)
    return button
  }()

  lazy var addOfflineAccountButton: NSButton = {
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

  lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 64
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .none  // Disable default highlight, use custom
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

    // Set data source and delegate
    tableView.dataSource = self
    tableView.delegate = self

    // Add column
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AccountColumn"))
    column.width = 300
    tableView.addTableColumn(column)

    // Set context menu
    tableView.menu = createContextMenu()

    return tableView
  }()

  private let emptyLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Account.emptyMicrosoftMessage,
      font: BRFonts.body,
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true
    return label
  }()

  private let headerSeparator = BRSeparator.horizontal()

  lazy var developerModeSwitch: NSSwitch = {
    let toggle = NSSwitch()
    toggle.target = self
    toggle.action = #selector(toggleDeveloperMode)
    return toggle
  }()

  private let developerModeLabel = BRLabel(
    text: Localized.Account.developerModeLabel,
    font: BRFonts.caption,
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
    view.addSubview(refreshStatusView)

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

    // Position refresh status view to overlay on top of scroll view
    refreshStatusView.snp.makeConstraints { make in
      make.top.equalTo(loginMicrosoftButton.snp.bottom).offset(16)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(0)  // Initially collapsed
    }
  }

  // MARK: - Data Management

  func loadAccounts() {
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
}
