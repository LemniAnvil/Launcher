//
//  ViewController.swift
//  Launcher
//

import AppKit
import SnapKit
import Yatagarasu

class ViewController: NSViewController {

  private var versionListWindowController: VersionListWindowController?
  private var javaDetectionWindowController: JavaDetectionWindowController?
  private var accountWindowController: AccountWindowController?
  private var settingsWindowController: SettingsWindowController?
  private var windowObserver: NSObjectProtocol?
  private var javaWindowObserver: NSObjectProtocol?
  private var accountWindowObserver: NSObjectProtocol?
  private var settingsWindowObserver: NSObjectProtocol?

  // Version management
  private let versionManager = VersionManager.shared
  private let gameLauncher = GameLauncher.shared
  private var installedVersions: [String] = []

  // UI elements
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstalledVersions.title,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let countLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var testButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "play.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.MainWindow.openVersionListWindowButton
    )
    button.target = self
    button.action = #selector(openVersionListWindow)
    return button
  }()

  private lazy var javaDetectionButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "cup.and.saucer.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemOrange,
      accessibilityLabel: Localized.JavaDetection.openJavaDetectionButton
    )
    button.target = self
    button.action = #selector(openJavaDetectionWindow)
    return button
  }()

  private lazy var accountButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "person.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemPurple,
      accessibilityLabel: Localized.Account.openAccountButton
    )
    button.target = self
    button.action = #selector(openAccountWindow)
    return button
  }()

  private lazy var settingsButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "gearshape.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemGray,
      accessibilityLabel: Localized.Settings.openSettingsButton
    )
    button.target = self
    button.action = #selector(openSettingsWindow)
    return button
  }()

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

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false
    return scrollView
  }()

  private lazy var collectionView: NSCollectionView = {
    let collectionView = NSCollectionView()
    collectionView.backgroundColors = [.clear]
    collectionView.isSelectable = true
    collectionView.allowsMultipleSelection = false

    // Create flow layout
    let flowLayout = NSCollectionViewFlowLayout()
    flowLayout.itemSize = NSSize(width: 160, height: 180)
    flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    flowLayout.minimumInteritemSpacing = 16
    flowLayout.minimumLineSpacing = 16
    collectionView.collectionViewLayout = flowLayout

    // Register item
    collectionView.register(
      VersionCollectionViewItem.self,
      forItemWithIdentifier: VersionCollectionViewItem.identifier
    )

    collectionView.dataSource = self
    collectionView.delegate = self

    collectionView.menu = createContextMenu()

    return collectionView
  }()

  private let emptyLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstalledVersions.emptyMessage,
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.isHidden = true
    return label
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view.wantsLayer = true
    self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadInstalledVersions()
  }

  private func setupUI() {
    // Add all UI elements
    view.addSubview(titleLabel)
    view.addSubview(countLabel)
    view.addSubview(refreshButton)
    view.addSubview(testButton)
    view.addSubview(javaDetectionButton)
    view.addSubview(accountButton)
    view.addSubview(settingsButton)
    view.addSubview(headerSeparator)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)

    scrollView.documentView = collectionView

    // Layout constraints using SnapKit
    // Top-right button group
    testButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-148)
      make.width.height.equalTo(36)
    }

    javaDetectionButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-104)
      make.width.height.equalTo(36)
    }

    accountButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-60)
      make.width.height.equalTo(36)
    }

    settingsButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.width.height.equalTo(36)
    }

    // Title and count
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
    }

    refreshButton.snp.makeConstraints { make in
      make.centerY.equalTo(titleLabel)
      make.left.equalTo(titleLabel.snp.right).offset(16)
      make.width.height.equalTo(36)
    }

    countLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(testButton.snp.left).offset(-10)
    }

    headerSeparator.snp.makeConstraints { make in
      make.top.equalTo(countLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    // Version list
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

    collectionView.reloadData()
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

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
}

// MARK: - Actions

extension ViewController {

  @objc func openVersionListWindow() {
    // If window already exists, show it
    if let existingController = versionListWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new version list window
    versionListWindowController = VersionListWindowController()
    versionListWindowController?.showWindow(nil)
    versionListWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    windowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: versionListWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.versionListWindowController = nil
      if let observer = self?.windowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.windowObserver = nil
      }
    }
  }

  @objc private func openJavaDetectionWindow() {
    // If window already exists, show it
    if let existingController = javaDetectionWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new Java detection window
    javaDetectionWindowController = JavaDetectionWindowController()
    javaDetectionWindowController?.showWindow(nil)
    javaDetectionWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    javaWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: javaDetectionWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.javaDetectionWindowController = nil
      if let observer = self?.javaWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.javaWindowObserver = nil
      }
    }
  }

  @objc private func openAccountWindow() {
    // If window already exists, show it
    if let existingController = accountWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new account window
    accountWindowController = AccountWindowController()
    accountWindowController?.showWindow(nil)
    accountWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    accountWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: accountWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.accountWindowController = nil
      if let observer = self?.accountWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.accountWindowObserver = nil
      }
    }
  }

  @objc private func openSettingsWindow() {
    // If window already exists, show it
    if let existingController = settingsWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new settings window
    settingsWindowController = SettingsWindowController()
    settingsWindowController?.showWindow(nil)
    settingsWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    settingsWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: settingsWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.settingsWindowController = nil
      if let observer = self?.settingsWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.settingsWindowObserver = nil
      }
    }
  }

  @objc func refreshVersionList() {
    loadInstalledVersions()
  }
}

// MARK: - Context Menu

extension ViewController {

  func createContextMenu() -> NSMenu {
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

  @objc func launchGame(_ sender: Any?) {
    guard let versionId = getClickedItem() else { return }

    // Show offline launch window
    let windowController = OfflineLaunchWindowController()
    if let viewController = windowController.window?.contentViewController as? OfflineLaunchViewController {
      viewController.onLaunch = { [weak self] username in
        self?.performLaunch(versionId: versionId, username: username)
      }
    }
    windowController.showWindow(nil)
  }

  func performLaunch(versionId: String, username: String) {
    Task { @MainActor in
      do {
        Logger.shared.info(Localized.GameLauncher.logLaunchingVersion(versionId), category: "MainWindow")

        // Detect Java
        Logger.shared.info(Localized.GameLauncher.statusDetectingJava, category: "MainWindow")

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
          category: "MainWindow"
        )

        // Create launch configuration with username
        let config = GameLauncher.LaunchConfig.default(
          versionId: versionId,
          javaPath: javaInstallation.path,
          username: username
        )

        // Launch game
        Logger.shared.info(Localized.GameLauncher.statusLaunching, category: "MainWindow")
        try await gameLauncher.launchGame(config: config)

        Logger.shared.info(Localized.GameLauncher.statusLaunched, category: "MainWindow")

        // Show success notification
        showNotification(
          title: Localized.GameLauncher.statusLaunched,
          message: "Version: \(versionId), User: \(username)"
        )
      } catch {
        Logger.shared.error(
          "Failed to launch game: \(error.localizedDescription)",
          category: "MainWindow"
        )

        showAlert(
          title: Localized.GameLauncher.alertLaunchFailedTitle,
          message: Localized.GameLauncher.alertLaunchFailedMessage(error.localizedDescription)
        )
      }
    }
  }

  @objc func openVersionFolder(_ sender: Any?) {
    guard let clickedItem = getClickedItem() else { return }

    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(clickedItem)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: versionDir.path)
  }

  @objc func deleteVersion(_ sender: Any?) {
    guard let versionId = getClickedItem() else { return }

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

  func performDelete(versionId: String) {
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

  func showNotification(title: String, message: String) {
    // Simplified notification, removed deprecated API
    Logger.shared.info("\(title): \(message)", category: "MainWindow")
  }

  func showAlert(title: String, message: String) {
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

  // Get clicked item
  func getClickedItem() -> String? {
    let point = collectionView.convert(view.window?.mouseLocationOutsideOfEventStream ?? .zero, from: nil)
    guard let indexPath = collectionView.indexPathForItem(at: point),
          indexPath.item < installedVersions.count else {
      // If no item clicked, try to get selected item
      guard let selectedIndexPath = collectionView.selectionIndexPaths.first,
            selectedIndexPath.item < installedVersions.count else {
        return nil
      }
      return installedVersions[selectedIndexPath.item]
    }
    return installedVersions[indexPath.item]
  }
}

// MARK: - NSCollectionViewDataSource

extension ViewController: NSCollectionViewDataSource {

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return installedVersions.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    guard let item = collectionView.makeItem(
      withIdentifier: VersionCollectionViewItem.identifier,
      for: indexPath
    ) as? VersionCollectionViewItem else {
      return NSCollectionViewItem()
    }

    let versionId = installedVersions[indexPath.item]
    item.configure(with: versionId)

    return item
  }
}

// MARK: - NSCollectionViewDelegate

extension ViewController: NSCollectionViewDelegate {

  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    guard let indexPath = indexPaths.first else { return }
    let selectedVersion = installedVersions[indexPath.item]
    Logger.shared.info("Selected version: \(selectedVersion)", category: "MainWindow")
  }

  func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    // Handle deselection if needed
  }
}
