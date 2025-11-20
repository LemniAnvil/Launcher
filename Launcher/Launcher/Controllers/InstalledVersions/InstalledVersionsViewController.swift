//
//  InstalledVersionsViewController.swift
//  Launcher
//
//  Installed versions list view controller
//

import AppKit
import SnapKit
import Yatagarasu

class InstalledVersionsViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  private let versionManager = VersionManager.shared
  private let gameLauncher = GameLauncher.shared
  private var installedVersions: [String] = []

  // UI components
  private let titleLabel = BRLabel(
    text: Localized.InstalledVersions.title,
    font: .systemFont(ofSize: 20, weight: .semibold),
    textColor: .labelColor,
    alignment: .left
  )

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
    tableView.rowHeight = 60
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .none  // Disable default highlight, use custom
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

    // Set data source and delegate
    tableView.dataSource = self
    tableView.delegate = self

    // Add column
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("VersionColumn"))
    column.width = 300
    tableView.addTableColumn(column)

    // Set context menu
    let menu = createContextMenu()
    // Set menu delegate for right-click handling
    menu.delegate = self
    tableView.menu = menu

    return tableView
  }()

  private let emptyLabel = BRLabel(
    text: Localized.InstalledVersions.emptyMessage,
    font: .systemFont(ofSize: 14),
    textColor: .secondaryLabelColor,
    alignment: .center
  )

  private lazy var refreshButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.clockwise",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.InstalledVersions.refreshButton
    )
    button.target = self
    button.action = #selector(refreshVersionList)
    return button
  }()

  private let countLabel = BRLabel(
    text: "",
    font: .systemFont(ofSize: 12),
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  private let headerSeparator: BRSeparator = BRSeparator.horizontal()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadInstalledVersions()
  }

  // MARK: - Setup

  private func setupUI() {
    // Add subviews
    view.addSubview(titleLabel)
    view.addSubview(refreshButton)
    view.addSubview(countLabel)
    view.addSubview(headerSeparator)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)

    scrollView.documentView = tableView

    // Layout
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
    }

    refreshButton.snp.makeConstraints { make in
      make.centerY.equalTo(titleLabel)
      make.right.equalToSuperview().offset(-20)
      make.width.height.equalTo(36)
    }

    countLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(refreshButton.snp.left).offset(-10)
    }

    headerSeparator.snp.makeConstraints { make in
      make.top.equalTo(countLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(headerSeparator.snp.bottom).offset(12)
      make.left.right.bottom.equalToSuperview().inset(20)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalToSuperview().inset(40)
    }
  }

  // MARK: - Data Loading

  private func loadInstalledVersions() {
    installedVersions = versionManager.getInstalledVersions()

    // Sort by version number (descending)
    installedVersions.sort { version1, version2 in
      return version1.compare(version2, options: .numeric) == .orderedDescending
    }

    tableView.reloadData()
    updateEmptyState()
    updateCountLabel()
  }

  private func updateEmptyState() {
    emptyLabel.isHidden = !installedVersions.isEmpty
    scrollView.isHidden = installedVersions.isEmpty
  }

  private func updateCountLabel() {
    countLabel.stringValue = switch installedVersions.count {
    case 0: Localized.InstalledVersions.countNone
    case 1: Localized.InstalledVersions.countOne
    default: Localized.InstalledVersions.countMultiple(installedVersions.count)
    }
  }

  // MARK: - Actions

  @objc private func refreshVersionList() {
    loadInstalledVersions()
  }

  // MARK: - Context Menu

  private func createContextMenu() -> NSMenu {
    let menu = NSMenu()

    let launchItem = NSMenuItem(
      title: Localized.InstalledVersions.menuLaunchGame,
      action: #selector(launchGame(_:)),
      keyEquivalent: ""
    )
    launchItem.target = self
    menu.addItem(launchItem)

    menu.addItem(NSMenuItem.separator())

    let openFolderItem = NSMenuItem(
      title: Localized.InstalledVersions.menuShowInFinder,
      action: #selector(openVersionFolder(_:)),
      keyEquivalent: ""
    )
    openFolderItem.target = self
    menu.addItem(openFolderItem)

    menu.addItem(NSMenuItem.separator())

    let deleteItem = NSMenuItem(
      title: Localized.InstalledVersions.menuDelete,
      action: #selector(deleteVersion(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)

    return menu
  }

  @objc private func launchGame(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < installedVersions.count else {
      return
    }

    let versionId = installedVersions[tableView.clickedRow]

    // Show offline launch window
    let windowController = OfflineLaunchWindowController()
    if let viewController = windowController.window?.contentViewController as? OfflineLaunchViewController {
      viewController.onLaunch = { [weak self] accountInfo in
        self?.performLaunch(versionId: versionId, accountInfo: accountInfo)
      }
    }
    windowController.showWindow(nil)
  }

  private func performLaunch(versionId: String, accountInfo: OfflineLaunchViewController.AccountInfo) {
    Task { @MainActor in
      do {
        Logger.shared.info(Localized.GameLauncher.logLaunchingVersion(versionId), category: "InstalledVersions")

        // Detect Java
        Logger.shared.info(Localized.GameLauncher.statusDetectingJava, category: "InstalledVersions")

        let versionDetails = try await versionManager.getVersionDetails(versionId: versionId)
        guard let javaInstallation = await gameLauncher.getBestJavaForVersion(versionDetails) else {
          showAlert(
            title: Localized.GameLauncher.alertNoJavaTitle,
            message: Localized.GameLauncher.alertNoJavaMessage
          )
          return
        }

        Logger.shared.info(
          Localized.GameLauncher.logJavaDetected(javaInstallation.path, javaInstallation.version),
          category: "InstalledVersions"
        )

        // Create launch configuration with account info
        let config = GameLauncher.LaunchConfig(
          versionId: versionId,
          javaPath: javaInstallation.path,
          username: accountInfo.username,
          uuid: accountInfo.uuid,
          accessToken: accountInfo.accessToken,
          maxMemory: 2048,
          minMemory: 512,
          windowWidth: 854,
          windowHeight: 480
        )

        // Launch game
        Logger.shared.info(Localized.GameLauncher.statusLaunching, category: "InstalledVersions")
        try await gameLauncher.launchGame(config: config)

        Logger.shared.info(Localized.GameLauncher.statusLaunched, category: "InstalledVersions")

        // Show success notification
        showNotification(
          title: Localized.GameLauncher.statusLaunched,
          message: "Version: \(versionId), User: \(accountInfo.username)"
        )
      } catch {
        Logger.shared.error(
          "Failed to launch game: \(error.localizedDescription)",
          category: "InstalledVersions"
        )

        showAlert(
          title: Localized.GameLauncher.alertLaunchFailedTitle,
          message: Localized.GameLauncher.alertLaunchFailedMessage(error.localizedDescription)
        )
      }
    }
  }

  @objc private func openVersionFolder(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < installedVersions.count else {
      return
    }

    let versionId = installedVersions[tableView.clickedRow]
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(versionId)

    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: versionDir.path)
  }

  @objc private func deleteVersion(_ sender: Any?) {
    guard tableView.clickedRow >= 0,
          tableView.clickedRow < installedVersions.count else {
      return
    }

    let versionId = installedVersions[tableView.clickedRow]

    // Show confirmation dialog
    let alert = NSAlert()
    alert.messageText = Localized.InstalledVersions.deleteConfirmTitle
    alert.informativeText = Localized.InstalledVersions.deleteConfirmMessage(versionId)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.InstalledVersions.deleteButton)
    alert.addButton(withTitle: Localized.InstalledVersions.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(versionId: versionId)
    }
  }

  private func performDelete(versionId: String) {
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(versionId)

    do {
      try FileManager.default.removeItem(at: versionDir)
      Logger.shared.info("Deleted version: \(versionId)", category: "InstalledVersions")

      // Refresh list
      loadInstalledVersions()

      // Show success notification
      showNotification(
        title: Localized.InstalledVersions.deleteSuccessTitle,
        message: Localized.InstalledVersions.deleteSuccessMessage(versionId)
      )
    } catch {
      Logger.shared.error("Failed to delete version: \(error.localizedDescription)", category: "InstalledVersions")

      // Show error dialog
      let alert = NSAlert()
      alert.messageText = Localized.InstalledVersions.deleteFailedTitle
      alert.informativeText = Localized.InstalledVersions.deleteFailedMessage(versionId, error.localizedDescription)
      alert.alertStyle = .critical
      alert.addButton(withTitle: Localized.InstalledVersions.okButton)

      if let window = view.window {
        alert.beginSheetModal(for: window)
      }
    }
  }

  private func showNotification(title: String, message: String) {
    // Simplified notification, removed deprecated API
    Logger.shared.info("\(title): \(message)", category: "InstalledVersions")
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.InstalledVersions.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}

// MARK: - NSTableViewDataSource

extension InstalledVersionsViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return installedVersions.count
  }
}

// MARK: - NSTableViewDelegate

extension InstalledVersionsViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let versionId = installedVersions[row]

    // Create custom cell view
    let cellView = VersionCellView()
    cellView.configure(with: versionId)

    // Set initial highlight state
    cellView.setHighlighted(tableView.selectedRow == row)

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    // Update all visible cells to reflect selection state
    for row in 0..<installedVersions.count {
      if let cellView = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? VersionCellView {
        cellView.setHighlighted(row == tableView.selectedRow)
      }
    }

    // Log selection
    if tableView.selectedRow >= 0 {
      let selectedVersion = installedVersions[tableView.selectedRow]
      Logger.shared.info("Selected version: \(selectedVersion)", category: "InstalledVersions")
    }
  }

  func tableView(_ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool {
    return true
  }
}

// MARK: - NSMenuDelegate

extension InstalledVersionsViewController: NSMenuDelegate {

  func menuNeedsUpdate(_ menu: NSMenu) {
    // Automatically select the row that was right-clicked
    let row = tableView.clickedRow

    if row >= 0 {
      tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
  }
}
