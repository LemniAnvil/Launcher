//
//  AccountInfoViewController.swift
//  Launcher
//
//  View controller for displaying Microsoft account information
//

import AppKit
import CraftKit
import SnapKit
import UniformTypeIdentifiers
import Yatagarasu

class AccountInfoViewController: NSViewController {

  // MARK: - Properties

  var accounts: [MicrosoftAccount] = []
  var selectedAccount: MicrosoftAccount?

  // MARK: - UI Components

  private let titleLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Account.accountInfoWindowTitle,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let subtitleLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Account.accountInfoSubtitle,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private let verticalSeparator: BRSeparator = {
    return BRSeparator.vertical()
  }()

  private let accountScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.scrollerStyle = .overlay
    scrollView.drawsBackground = false
    return scrollView
  }()

  private lazy var accountTableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 60
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

    tableView.dataSource = self
    tableView.delegate = self

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AccountColumn"))
    column.width = 250
    tableView.addTableColumn(column)

    return tableView
  }()

  // Tab View for right side
  lazy var tabView: NSTabView = {
    let tabView = NSTabView()
    tabView.tabViewType = .topTabsBezelBorder
    return tabView
  }()

  // Tab 1: Account Info (existing detail view)
  private let accountInfoScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.scrollerStyle = .overlay
    scrollView.drawsBackground = false
    return scrollView
  }()

  private let detailContainerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    return view
  }()

  // Container for account info tab
  private let accountInfoTabContainer: NSView = {
    let view = NSView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var accountInfoTab: NSTabViewItem = {
    let item = NSTabViewItem(identifier: "accountInfo")
    item.label = Localized.Account.accountInfoTab
    item.view = accountInfoTabContainer
    return item
  }()

  // Tab 2: Skin Management
  lazy var skinLibraryView: AccountSkinLibraryView = {
    let view = AccountSkinLibraryView()
    view.delegate = self
    return view
  }()

  private lazy var skinManagementTab: NSTabViewItem = {
    let item = NSTabViewItem(identifier: "skinManagement")
    item.label = Localized.Account.skinManagementTab
    item.view = skinLibraryView
    return item
  }()

  private let emptyLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Account.noMicrosoftAccounts,
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.isHidden = true
    return label
  }()

  private let selectPromptLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Account.selectAccountPrompt,
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadAccounts()

    // Set window constraints to prevent resizing issues
    if let window = view.window {
      window.minSize = NSSize(width: 900, height: 600)
      window.setContentSize(NSSize(width: 900, height: 600))
    }
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    // Ensure window size constraints are applied
    if let window = view.window {
      window.minSize = NSSize(width: 900, height: 600)
      if window.frame.size.width < 900 || window.frame.size.height < 600 {
        window.setContentSize(NSSize(width: 900, height: 600))
      }
    }
  }

  // MARK: - Setup

  private func setupUI() {
    // Remove title and subtitle - they are redundant
    // view.addSubview(titleLabel)
    // view.addSubview(subtitleLabel)
    // view.addSubview(headerSeparator)

    view.addSubview(accountScrollView)
    view.addSubview(verticalSeparator)
    view.addSubview(tabView)
    view.addSubview(emptyLabel)

    accountScrollView.documentView = accountTableView

    // Setup tab view with two tabs
    tabView.addTabViewItem(accountInfoTab)
    tabView.addTabViewItem(skinManagementTab)

    // Setup account info tab content
    accountInfoTabContainer.addSubview(accountInfoScrollView)
    accountInfoTabContainer.addSubview(selectPromptLabel)
    accountInfoScrollView.documentView = detailContainerView

    // Layout - no header, start from top
    // Account list on the left
    accountScrollView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.bottom.equalToSuperview().offset(-20)
      make.width.equalTo(250)
    }

    verticalSeparator.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalTo(accountScrollView.snp.right).offset(12)
      make.bottom.equalToSuperview().offset(-20)
      make.width.equalTo(1)
    }

    // Detail view on the right (tab view)
    tabView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalTo(verticalSeparator.snp.right).offset(12)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalToSuperview().offset(-20)
    }

    // Account info scroll view fills the container
    accountInfoScrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    // Initial container constraints - will be updated when showing details
    detailContainerView.snp.makeConstraints { make in
      make.top.left.equalToSuperview()
      make.right.greaterThanOrEqualToSuperview()
      make.width.greaterThanOrEqualTo(400).priority(.medium)
      // Note: bottom is NOT set here - it will be set based on content height
    }

    // Add selectPromptLabel centered in the tab container
    selectPromptLabel.snp.makeConstraints { make in
      make.center.equalTo(accountInfoTabContainer)
      make.width.lessThanOrEqualTo(accountInfoTabContainer).offset(-80)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(view)
      make.left.right.equalToSuperview().inset(40)
    }
  }

  // MARK: - Data Management

  func loadAccounts() {
    accounts = MicrosoftAccountManager.shared.loadAccounts()
    accountTableView.reloadData()
    updateEmptyState()
  }

  private func updateEmptyState() {
    let isEmpty = accounts.isEmpty
    emptyLabel.isHidden = !isEmpty
    accountScrollView.isHidden = isEmpty
    verticalSeparator.isHidden = isEmpty
    tabView.isHidden = isEmpty
  }

  func showAccountDetails(_ account: MicrosoftAccount) {
    selectedAccount = account

    // Hide the select prompt label
    selectPromptLabel.isHidden = true

    // Clear previous details and constraints
    detailContainerView.subviews.forEach { $0.removeFromSuperview() }
    detailContainerView.snp.removeConstraints()

    // Re-establish base constraints
    detailContainerView.snp.makeConstraints { make in
      make.top.left.equalToSuperview()
      make.right.greaterThanOrEqualToSuperview()
      make.width.greaterThanOrEqualTo(400).priority(.medium)
      // Note: bottom will be set at the end based on content height
    }

    // Create detail labels
    var yOffset: CGFloat = 0

    // Player info card
    let playerCard = createInfoCard()
    detailContainerView.addSubview(playerCard)
    playerCard.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(yOffset)
      make.left.right.equalToSuperview().inset(20)
    }

    // Player name - large and prominent
    let nameLabel = DisplayLabel(
      text: account.name,
      font: .systemFont(ofSize: 24, weight: .bold),
      textColor: .labelColor,
      alignment: .left
    )
    playerCard.addSubview(nameLabel)

    // UUID info in a compact layout
    let uuidLabel = DisplayLabel(
      text: "UUID",
      font: .systemFont(ofSize: 10, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    playerCard.addSubview(uuidLabel)

    let shortUUIDLabel = DisplayLabel(
      text: account.shortUUID,
      font: NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    playerCard.addSubview(shortUUIDLabel)

    let fullUUIDLabel = DisplayLabel(
      text: account.id,
      font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
      textColor: .tertiaryLabelColor,
      alignment: .left
    )
    fullUUIDLabel.isSelectable = true
    fullUUIDLabel.lineBreakMode = .byTruncatingMiddle
    playerCard.addSubview(fullUUIDLabel)

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.left.right.equalToSuperview().inset(16)
    }

    uuidLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(16)
    }

    shortUUIDLabel.snp.makeConstraints { make in
      make.top.equalTo(uuidLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(16)
    }

    fullUUIDLabel.snp.makeConstraints { make in
      make.top.equalTo(shortUUIDLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(16)
      make.bottom.equalToSuperview().offset(-16)
    }

    yOffset += 150  // Approximate card height

    // Status card
    let statusCard = createInfoCard()
    detailContainerView.addSubview(statusCard)
    statusCard.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(yOffset)
      make.left.right.equalToSuperview().inset(20)
    }

    // Login timestamp
    let loginDate = Date(timeIntervalSince1970: account.timestamp)
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium

    let loginTitleLabel = DisplayLabel(
      text: Localized.Account.loginTimestamp,
      font: .systemFont(ofSize: 11, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    statusCard.addSubview(loginTitleLabel)

    let loginValueLabel = DisplayLabel(
      text: dateFormatter.string(from: loginDate),
      font: .systemFont(ofSize: 13, weight: .regular),
      textColor: .labelColor,
      alignment: .left
    )
    statusCard.addSubview(loginValueLabel)

    // Token expiration
    let expirationDate = account.expirationDate
    let expirationTitleLabel = DisplayLabel(
      text: Localized.Account.tokenExpiration,
      font: .systemFont(ofSize: 11, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    statusCard.addSubview(expirationTitleLabel)

    let expirationValueLabel = DisplayLabel(
      text: dateFormatter.string(from: expirationDate),
      font: .systemFont(ofSize: 13, weight: .regular),
      textColor: .labelColor,
      alignment: .left
    )
    statusCard.addSubview(expirationValueLabel)

    // Access token status with badge
    let tokenStatusLabel = DisplayLabel(
      text: Localized.Account.accessTokenStatus,
      font: .systemFont(ofSize: 11, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    statusCard.addSubview(tokenStatusLabel)

    let tokenStatus = account.isExpired ? Localized.Account.tokenExpired : Localized.Account.tokenValid
    let tokenColor: NSColor = account.isExpired ? .systemOrange : .systemGreen

    let statusBadge = NSView()
    statusBadge.wantsLayer = true
    statusBadge.layer?.backgroundColor = tokenColor.cgColor
    statusBadge.layer?.cornerRadius = 10
    statusCard.addSubview(statusBadge)

    let statusIcon = NSImageView()
    statusIcon.image = NSImage(systemSymbolName: account.isExpired ? "exclamationmark.circle" : "checkmark.circle", accessibilityDescription: nil)
    statusIcon.contentTintColor = .white
    statusIcon.imageScaling = .scaleProportionallyDown
    statusBadge.addSubview(statusIcon)

    let statusTextLabel = DisplayLabel(
      text: tokenStatus,
      font: .systemFont(ofSize: 12, weight: .semibold),
      textColor: .white,
      alignment: .left
    )
    statusBadge.addSubview(statusTextLabel)

    loginTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.left.equalToSuperview().offset(16)
    }

    loginValueLabel.snp.makeConstraints { make in
      make.top.equalTo(loginTitleLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(16)
    }

    expirationTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(loginValueLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(16)
    }

    expirationValueLabel.snp.makeConstraints { make in
      make.top.equalTo(expirationTitleLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(16)
    }

    tokenStatusLabel.snp.makeConstraints { make in
      make.top.equalTo(expirationValueLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(16)
    }

    statusBadge.snp.makeConstraints { make in
      make.top.equalTo(tokenStatusLabel.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(16)
      make.bottom.equalToSuperview().offset(-16)
      make.height.equalTo(32)
    }

    statusIcon.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(10)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(16)
    }

    statusTextLabel.snp.makeConstraints { make in
      make.left.equalTo(statusIcon.snp.right).offset(6)
      make.right.equalToSuperview().offset(-12)
      make.centerY.equalToSuperview()
    }

    yOffset += 200  // Approximate card height

    // Helper function to add a detail row (keep for compatibility)
    func addDetailRow(label: String, value: String, valueFont: NSFont = .systemFont(ofSize: 12), valueColor: NSColor = .labelColor, selectable: Bool = false) -> NSView {
      let labelView = DisplayLabel(
        text: label,
        font: .systemFont(ofSize: 11, weight: .medium),
        textColor: .secondaryLabelColor,
        alignment: .left
      )
      detailContainerView.addSubview(labelView)
      labelView.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(yOffset)
        make.left.equalToSuperview().offset(20)
        make.right.lessThanOrEqualToSuperview().offset(-20)
      }

      let valueView = DisplayLabel(
        text: value,
        font: valueFont,
        textColor: valueColor,
        alignment: .left
      )
      valueView.lineBreakMode = .byTruncatingMiddle
      valueView.maximumNumberOfLines = 2
      if selectable {
        valueView.isSelectable = true
      }
      detailContainerView.addSubview(valueView)
      valueView.snp.makeConstraints { make in
        make.top.equalTo(labelView.snp.bottom).offset(4)
        make.left.equalToSuperview().offset(20)
        make.right.lessThanOrEqualToSuperview().offset(-20)
      }

      yOffset += 42
      return valueView
    }

    // Helper function to create an info card
    func createInfoCard() -> NSView {
      let card = NSView()
      card.wantsLayer = true
      card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
      card.layer?.cornerRadius = 10
      return card
    }

    // Helper function to add a section title
    func addSectionTitle(_ title: String) -> NSView {
      let titleView = DisplayLabel(
        text: title,
        font: .systemFont(ofSize: 16, weight: .semibold),
        textColor: .labelColor,
        alignment: .left
      )
      detailContainerView.addSubview(titleView)
      titleView.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(yOffset)
        make.left.equalToSuperview().offset(20)
        make.right.lessThanOrEqualToSuperview().offset(-20)
      }

      yOffset += 30
      return titleView
    }

    // Helper function to add a separator
    func addSeparator() -> NSView {
      let separator = BRSeparator.horizontal()
      detailContainerView.addSubview(separator)
      separator.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(yOffset)
        make.left.right.equalToSuperview().inset(20)
        make.height.equalTo(1)
      }

      yOffset += 20
      return separator
    }

    yOffset += 20  // Add spacing before skins section

    // Add separator before skins section
    _ = addSeparator()

    // Skins section
    _ = addSectionTitle("\(Localized.Account.allSkinsTitle) (\(account.skins?.count ?? 0))")

    if let skins = account.skins, !skins.isEmpty {
      for skin in skins {
        let skinCard = createSkinCard(skin: skin)
        detailContainerView.addSubview(skinCard)
        skinCard.snp.makeConstraints { make in
          make.top.equalToSuperview().offset(yOffset)
          make.left.right.equalToSuperview().inset(20)
        }

        yOffset += 125 // Height of skin card (110) + spacing (15)
      }
    } else {
      let noSkinsLabel = DisplayLabel(
        text: Localized.Account.noSkins,
        font: .systemFont(ofSize: 12),
        textColor: .secondaryLabelColor,
        alignment: .center
      )
      detailContainerView.addSubview(noSkinsLabel)
      noSkinsLabel.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(yOffset)
        make.left.right.equalToSuperview().inset(20)
        make.height.equalTo(60)
      }
      yOffset += 80
    }

    // Add separator before capes section
    _ = addSeparator()

    // Capes section header with action buttons
    let capesHeaderContainer = NSView()
    detailContainerView.addSubview(capesHeaderContainer)

    let capesTitleLabel = DisplayLabel(
      text: "\(Localized.Account.allCapesTitle) (\(account.capes?.count ?? 0))",
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    capesHeaderContainer.addSubview(capesTitleLabel)

    // Action buttons
    let refreshButton = NSButton(
      image: NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)!,
      target: self,
      action: #selector(refreshCapesButtonClicked)
    )
    refreshButton.bezelStyle = .rounded
    refreshButton.isBordered = false
    refreshButton.toolTip = Localized.Account.refreshCapes
    capesHeaderContainer.addSubview(refreshButton)

    let hideCapeButton = NSButton(
      title: Localized.Account.hideCape,
      target: self,
      action: #selector(hideCapeButtonClicked)
    )
    hideCapeButton.bezelStyle = .rounded
    hideCapeButton.isEnabled = account.capes?.contains(where: { $0.isActive }) ?? false
    capesHeaderContainer.addSubview(hideCapeButton)

    capesHeaderContainer.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(yOffset)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(30)
    }

    capesTitleLabel.snp.makeConstraints { make in
      make.left.centerY.equalToSuperview()
    }

    hideCapeButton.snp.makeConstraints { make in
      make.right.centerY.equalToSuperview()
    }

    refreshButton.snp.makeConstraints { make in
      make.right.equalTo(hideCapeButton.snp.left).offset(-8)
      make.centerY.equalToSuperview()
    }

    yOffset += 30

    if let capes = account.capes, !capes.isEmpty {
      // Grid layout for capes - 4 columns
      let columnsPerRow = 4
      let cardWidth: CGFloat = 100
      let cardHeight: CGFloat = 170
      let horizontalSpacing: CGFloat = 8
      let verticalSpacing: CGFloat = 8

      for (index, cape) in capes.enumerated() {
        let capeCard = createCapeCard(cape: cape)
        detailContainerView.addSubview(capeCard)

        let column = index % columnsPerRow
        let row = index / columnsPerRow
        let xOffset: CGFloat = 20 + CGFloat(column) * (cardWidth + horizontalSpacing)
        let rowYOffset = yOffset + CGFloat(row) * (cardHeight + verticalSpacing)

        capeCard.snp.makeConstraints { make in
          make.top.equalToSuperview().offset(rowYOffset)
          make.left.equalToSuperview().offset(xOffset)
          make.width.equalTo(cardWidth)
          make.height.equalTo(cardHeight)
        }
      }

      // Calculate total height for all rows
      let totalRows = (capes.count + columnsPerRow - 1) / columnsPerRow
      yOffset += CGFloat(totalRows) * (cardHeight + verticalSpacing)
    } else {
      let noCapesLabel = DisplayLabel(
        text: Localized.Account.noCapes,
        font: .systemFont(ofSize: 12),
        textColor: .secondaryLabelColor,
        alignment: .center
      )
      detailContainerView.addSubview(noCapesLabel)
      noCapesLabel.snp.makeConstraints { make in
        make.top.equalToSuperview().offset(yOffset)
        make.left.right.equalToSuperview().inset(20)
        make.height.equalTo(60)
      }
      yOffset += 80
    }

    // Update container height - set bottom constraint to enable scrolling
    // This makes the documentView tall enough to contain all content
    detailContainerView.snp.makeConstraints { make in
      make.bottom.equalTo(detailContainerView.snp.top).offset(yOffset + 20)
    }
  }
}

// MARK: - NSTableViewDataSource

extension AccountInfoViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return accounts.count
  }
}

// MARK: - NSTableViewDelegate

extension AccountInfoViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let account = accounts[row]

    let cellView = NSView()
    cellView.wantsLayer = true

    let nameLabel = DisplayLabel(
      text: account.name,
      font: .systemFont(ofSize: 14, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )

    let uuidLabel = DisplayLabel(
      text: "UUID: \(account.shortUUID)",
      font: .systemFont(ofSize: 10),
      textColor: .secondaryLabelColor,
      alignment: .left
    )

    let statusLabel = DisplayLabel(
      text: account.isExpired ? Localized.Account.statusExpired : Localized.Account.statusLoggedIn,
      font: .systemFont(ofSize: 9),
      textColor: account.isExpired ? .systemOrange : .systemGreen,
      alignment: .left
    )

    cellView.addSubview(nameLabel)
    cellView.addSubview(uuidLabel)
    cellView.addSubview(statusLabel)

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.left.right.equalToSuperview().inset(12)
    }

    uuidLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(12)
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(uuidLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(12)
    }

    return cellView
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let selectedRow = accountTableView.selectedRow
    if selectedRow >= 0 && selectedRow < accounts.count {
      showAccountDetails(accounts[selectedRow])
    }
  }
}

// MARK: - AccountSkinLibraryViewDelegate

extension AccountInfoViewController: AccountSkinLibraryViewDelegate {

  func accountSkinLibraryView(_ view: AccountSkinLibraryView, didRequestUpload skin: LauncherSkinAsset) {
    // Check if account is selected
    guard selectedAccount != nil else {
      showErrorAlert(SkinManagementError.noAccountSelected)
      return
    }

    // Read skin image for preview
    guard let imageData = try? Data(contentsOf: skin.fileURL),
          let image = NSImage(data: imageData) else {
      showErrorAlert(SkinManagementError.invalidFormat)
      return
    }

    // Validate skin before showing picker
    do {
      try SkinValidator.validate(imageData)
    } catch {
      showErrorAlert(error)
      return
    }

    // Show variant picker
    let picker = SkinVariantPickerViewController()
    picker.configure(with: image)
    picker.onConfirm = { [weak self] variant in
      guard let self = self else { return }

      // Upload skin in background
      Task {
        do {
          // Show progress (we'll add a proper progress indicator in Phase 7)
          await MainActor.run {
            print("Uploading skin with variant: \(variant.rawValue)")
          }

          try await self.uploadSkinToAccount(skin, variant: variant)
        } catch {
          await MainActor.run {
            self.showErrorAlert(error)
          }
        }
      }
    }

    presentAsSheet(picker)
  }

  func accountSkinLibraryViewDidRequestImport(_ view: AccountSkinLibraryView) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.png]
    panel.message = Localized.Account.selectSkinFile

    panel.begin { [weak self] response in
      guard response == .OK, let url = panel.url else { return }

      // Import the skin file
      do {
        let data = try Data(contentsOf: url)
        let fileName = url.deletingPathExtension().lastPathComponent
        let library = SkinLibrary()
        try library.saveSkin(named: fileName, data: data)

        // Refresh the skin library view
        self?.skinLibraryView.loadSkins()
      } catch {
        let alert = NSAlert()
        alert.messageText = Localized.Account.error
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
      }
    }
  }
}
