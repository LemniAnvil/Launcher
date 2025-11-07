//
//  InstalledVersionsViewController.swift
//  Launcher
//
//  已安装版本列表视图控制器
//

import AppKit
import SnapKit

class InstalledVersionsViewController: NSViewController {

  // MARK: - Properties

  private let versionManager = VersionManager.shared
  private var installedVersions: [String] = []

  // UI components
  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.InstalledVersions.title)
    label.font = .systemFont(ofSize: 20, weight: .semibold)
    label.alignment = .left
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
    tableView.rowHeight = 60
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

    // 设置数据源和代理
    tableView.dataSource = self
    tableView.delegate = self

    // 添加列
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("VersionColumn"))
    column.width = 300
    tableView.addTableColumn(column)

    // 设置右键菜单
    tableView.menu = createContextMenu()

    return tableView
  }()

  private let emptyLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.InstalledVersions.emptyMessage)
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.isHidden = true
    return label
  }()

  private let refreshButton: NSButton = {
    let button = NSButton()
    button.title = Localized.InstalledVersions.refreshButton
    button.bezelStyle = .rounded
    button.setButtonType(.momentaryPushIn)
    return button
  }()

  private let countLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.alignment = .left
    return label
  }()

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
    // 添加子视图
    view.addSubview(titleLabel)
    view.addSubview(refreshButton)
    view.addSubview(countLabel)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)

    scrollView.documentView = tableView

    // 按钮动作
    refreshButton.target = self
    refreshButton.action = #selector(refreshVersionList)

    // 布局
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
    }

    refreshButton.snp.makeConstraints { make in
      make.centerY.equalTo(titleLabel)
      make.right.equalToSuperview().offset(-20)
    }

    countLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(refreshButton.snp.left).offset(-10)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(countLabel.snp.bottom).offset(12)
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

    // 按版本号排序（降序）
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
    let count = installedVersions.count
    if count == 0 {
      countLabel.stringValue = Localized.InstalledVersions.countNone
    } else if count == 1 {
      countLabel.stringValue = Localized.InstalledVersions.countOne
    } else {
      countLabel.stringValue = Localized.InstalledVersions.countMultiple(count)
    }
  }

  // MARK: - Actions

  @objc private func refreshVersionList() {
    loadInstalledVersions()
  }

  // MARK: - Context Menu

  private func createContextMenu() -> NSMenu {
    let menu = NSMenu()

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

    // 创建自定义单元格视图
    let cellView = VersionCellView()
    cellView.configure(with: versionId)

    return cellView
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard tableView.selectedRow >= 0 else { return }

    let selectedVersion = installedVersions[tableView.selectedRow]
    Logger.shared.info("选中版本: \(selectedVersion)", category: "InstalledVersions")
  }
}
