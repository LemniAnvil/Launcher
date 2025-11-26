//
//  ViewController.swift
//  Launcher
//

import AppKit
import MojangAPI
import SnapKit
import Yatagarasu

class ViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  private var versionListWindowController: VersionListWindowController?
  private var javaDetectionWindowController: JavaDetectionWindowController?
  private var accountWindowController: AccountWindowController?
  private var settingsWindowController: SettingsWindowController?
  private var addInstanceWindowController: AddInstanceWindowController?
  private var instanceDetailWindowController: InstanceDetailWindowController?
  private var microsoftAuthWindowController: MicrosoftAuthWindowController?
  private var installedVersionsWindowController: InstalledVersionsWindowController?
  private var windowObserver: NSObjectProtocol?
  private var instanceDetailWindowObserver: NSObjectProtocol?
  private var microsoftAuthWindowObserver: NSObjectProtocol?
  private var installedVersionsWindowObserver: NSObjectProtocol?

  // MARK: - Dependency Injection
  // ✅ Depend on protocols rather than concrete implementations
  private let instanceManager: InstanceManaging
  private let versionManager: VersionManaging
  private let gameLauncher: GameLaunching
  private var instances: [Instance] = []

  // UI elements
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Instances.title,
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

  private lazy var installedVersionsButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "square.stack.3d.up.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemTeal,
      accessibilityLabel: Localized.InstalledVersions.windowTitle
    )
    button.target = self
    button.action = #selector(openInstalledVersionsWindow)
    return button
  }()

  private lazy var addInstanceButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "plus.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemGreen,
      accessibilityLabel: Localized.AddInstance.openAddInstanceButton
    )
    button.target = self
    button.action = #selector(openAddInstanceWindow)
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
      accessibilityLabel: Localized.Instances.refreshButton
    )
    button.target = self
    button.action = #selector(refreshInstances)
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
      InstanceCollectionViewItem.self,
      forItemWithIdentifier: InstanceCollectionViewItem.identifier
    )

    collectionView.dataSource = self
    collectionView.delegate = self

    collectionView.menu = createContextMenu()

    // Add double-click gesture
    let doubleClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
    doubleClickGesture.numberOfClicksRequired = 2
    collectionView.addGestureRecognizer(doubleClickGesture)

    return collectionView
  }()

  private let emptyLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Instances.emptyMessage,
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

  // MARK: - Initialization

  /// Dependency injection via constructor
  /// Provides default parameters for backward compatibility
  init(
    instanceManager: InstanceManaging = InstanceManager.shared,
    versionManager: VersionManaging = VersionManager.shared,
    gameLauncher: GameLaunching = GameLauncher.shared
  ) {
    self.instanceManager = instanceManager
    self.versionManager = versionManager
    self.gameLauncher = gameLauncher
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view.wantsLayer = true
    self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadInstances()
  }

  private func setupUI() {
    // Add all UI elements
    view.addSubview(titleLabel)
    view.addSubview(countLabel)
    view.addSubview(addInstanceButton)
    view.addSubview(refreshButton)
    view.addSubview(javaDetectionButton)
    view.addSubview(accountButton)
    view.addSubview(settingsButton)
    view.addSubview(installedVersionsButton)
    view.addSubview(headerSeparator)
    view.addSubview(scrollView)
    view.addSubview(emptyLabel)

    scrollView.documentView = collectionView

    // Layout constraints using SnapKit
    // Top-right button group (from left to right: add, refresh, installedVersions, java, account, settings)
    addInstanceButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-236)
      make.width.height.equalTo(36)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-192)
      make.width.height.equalTo(36)
    }

    installedVersionsButton.snp.makeConstraints { make in
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

    countLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(addInstanceButton.snp.left).offset(-10)
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

  private func loadInstances() {
    instanceManager.refreshInstances()
    instances = instanceManager.instances

    collectionView.reloadData()
    updateEmptyState()
    updateCountLabel()
  }

  private func updateEmptyState() {
    emptyLabel.isHidden = !instances.isEmpty
    scrollView.isHidden = instances.isEmpty
  }

  private func updateCountLabel() {
    let count = instances.count
    if count == 0 {
      countLabel.stringValue = Localized.Instances.countNone
    } else if count == 1 {
      countLabel.stringValue = Localized.Instances.countOne
    } else {
      countLabel.stringValue = Localized.Instances.countMultiple(count)
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

    // Setup callbacks for instance creation
    if let viewController = versionListWindowController?.window?.contentViewController as? VersionListViewController {
      viewController.onInstanceCreated = { [weak self] _ in
        self?.loadInstances()
      }
      viewController.onCancel = {
        // Just close the window
      }
    }

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

    if let window = javaDetectionWindowController?.window {
      // Run as modal window
      NSApplication.shared.runModal(for: window)
    }

    // Clean up after modal closes
    javaDetectionWindowController = nil
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

    if let window = accountWindowController?.window {
      // Run as modal window
      NSApplication.shared.runModal(for: window)
    }

    // Clean up after modal closes
    accountWindowController = nil
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

    if let window = settingsWindowController?.window {
      // Run as modal window
      NSApplication.shared.runModal(for: window)
    }

    // Clean up after modal closes
    settingsWindowController = nil
  }

  @objc private func openInstalledVersionsWindow() {
    // If window already exists, show it
    if let existingController = installedVersionsWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new installed versions window
    installedVersionsWindowController = InstalledVersionsWindowController()

    installedVersionsWindowController?.showWindow(nil)
    installedVersionsWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    installedVersionsWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: installedVersionsWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.installedVersionsWindowController = nil
      if let observer = self?.installedVersionsWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.installedVersionsWindowObserver = nil
      }
    }
  }

  @objc private func openMicrosoftAuthWindow() {
    // If window already exists, show it
    if let existingController = microsoftAuthWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new Microsoft auth window
    microsoftAuthWindowController = MicrosoftAuthWindowController()

    // Setup callbacks
    if let viewController = microsoftAuthWindowController?.window?.contentViewController as? MicrosoftAuthViewController {
      viewController.onAuthSuccess = { (loginResponse: CompleteLoginResponse) in
        Logger.shared.info("Microsoft authentication successful: \(loginResponse.name)", category: "MainWindow")
        // You can handle the login response here (e.g., save account, update UI)
      }
      viewController.onAuthFailure = { error in
        Logger.shared.error("Microsoft authentication failed: \(error.localizedDescription)", category: "MainWindow")
      }
    }

    microsoftAuthWindowController?.showWindow(nil)
    microsoftAuthWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    microsoftAuthWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: microsoftAuthWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.microsoftAuthWindowController = nil
      if let observer = self?.microsoftAuthWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.microsoftAuthWindowObserver = nil
      }
    }
  }

  @objc func refreshInstances() {
    loadInstances()
  }

  @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
    let point = sender.location(in: collectionView)
    guard let indexPath = collectionView.indexPathForItem(at: point),
      indexPath.item < instances.count
    else {
      return
    }

    let selectedInstance = instances[indexPath.item]
    openInstanceDetailWindow(for: selectedInstance)
  }

  @objc private func openAddInstanceWindow() {
    // If window already exists, show it
    if let existingController = addInstanceWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new add instance window
    addInstanceWindowController = AddInstanceWindowController()

    // Setup callback for instance creation
    if let viewController = addInstanceWindowController?.window?.contentViewController as? AddInstanceViewController {
      viewController.onInstanceCreated = { [weak self] _ in
        self?.loadInstances()
      }
      viewController.onCancel = {
        // Just close the window
      }
    }

    if let window = addInstanceWindowController?.window {
      // Run as modal window
      NSApplication.shared.runModal(for: window)
    }

    // Clean up after modal closes
    addInstanceWindowController = nil
  }

  private func openInstanceDetailWindow(for instance: Instance) {
    // If window already exists, close it first to create a new one with updated data
    if let existingController = instanceDetailWindowController {
      existingController.close()
      instanceDetailWindowController = nil
      if let observer = instanceDetailWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        instanceDetailWindowObserver = nil
      }
    }

    // Create new instance detail window
    instanceDetailWindowController = InstanceDetailWindowController(instance: instance)

    // Setup callback
    if let viewController = instanceDetailWindowController?.window?.contentViewController as? InstanceDetailViewController {
      viewController.onClose = {
        // Just close the window
      }
    }

    instanceDetailWindowController?.showWindow(nil)
    instanceDetailWindowController?.window?.makeKeyAndOrderFront(nil)

    // Window close callback
    instanceDetailWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: instanceDetailWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.instanceDetailWindowController = nil
      if let observer = self?.instanceDetailWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.instanceDetailWindowObserver = nil
      }
    }
  }
}

// MARK: - Context Menu

extension ViewController {

  func createContextMenu() -> NSMenu {
    let menu = NSMenu()

    let launchItem = NSMenuItem(
      title: Localized.Instances.menuLaunchGame,
      action: #selector(launchGame(_:)),
      keyEquivalent: ""
    )
    launchItem.target = self
    menu.addItem(launchItem)

    menu.addItem(NSMenuItem.separator())

    let openFolderItem = NSMenuItem(
      title: Localized.Instances.menuShowInFinder,
      action: #selector(openInstanceFolder(_:)),
      keyEquivalent: ""
    )
    openFolderItem.target = self
    menu.addItem(openFolderItem)

    menu.addItem(NSMenuItem.separator())

    let deleteItem = NSMenuItem(
      title: Localized.Instances.menuDelete,
      action: #selector(deleteInstance(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)

    return menu
  }

  @objc func launchGame(_ sender: Any?) {
    guard let instance = getClickedInstance() else { return }

    // Check if version is installed
    if !versionManager.isVersionInstalled(versionId: instance.versionId) {
      showVersionNotInstalledAlert(for: instance)
      return
    }

    // Check if there's a default account
    if let defaultAccountInfo = DefaultAccountManager.shared.getDefaultAccountInfo() {
      // Use default account to launch directly
      Logger.shared.info("Using default account: \(defaultAccountInfo.username)", category: "MainWindow")
      let accountInfo = OfflineLaunchViewController.AccountInfo(
        username: defaultAccountInfo.username,
        uuid: defaultAccountInfo.uuid,
        accessToken: defaultAccountInfo.accessToken
      )
      performLaunch(instance: instance, accountInfo: accountInfo)
    } else {
      // No default account, show account selection window
      let windowController = OfflineLaunchWindowController()
      if let viewController = windowController.window?.contentViewController as? OfflineLaunchViewController {
        viewController.onLaunch = { [weak self] accountInfo in
          self?.performLaunch(instance: instance, accountInfo: accountInfo)
        }
      }
      windowController.showWindow(nil)
    }
  }

  func performLaunch(instance: Instance, accountInfo: OfflineLaunchViewController.AccountInfo) {
    Task { @MainActor in
      do {
        Logger.shared.info(Localized.GameLauncher.logLaunchingVersion(instance.versionId), category: "MainWindow")

        // Detect Java
        Logger.shared.info(Localized.GameLauncher.statusDetectingJava, category: "MainWindow")

        let versionDetails = try await versionManager.getVersionDetails(versionId: instance.versionId)
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

        // Create launch configuration with account info
        let config = GameLauncher.LaunchConfig(
          versionId: instance.versionId,
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
        Logger.shared.info(Localized.GameLauncher.statusLaunching, category: "MainWindow")
        try await gameLauncher.launchGame(config: config)

        Logger.shared.info(Localized.GameLauncher.statusLaunched, category: "MainWindow")

        // Show success notification
        showNotification(
          title: Localized.GameLauncher.statusLaunched,
          message: "Instance: \(instance.name), Version: \(instance.versionId), User: \(accountInfo.username)"
        )
      } catch let error as GameLauncherError {
        Logger.shared.error(
          "Failed to launch game: \(error.localizedDescription)",
          category: "MainWindow"
        )

        // Handle different error types with specific messages
        switch error {
        case .versionNotInstalled(let version):
          showAlert(
            title: Localized.GameLauncher.alertVersionNotInstalledTitle,
            message: Localized.GameLauncher.alertVersionFileMissingMessage(version)
          )
        case .javaNotFound(let path):
          showAlert(
            title: Localized.GameLauncher.alertNoJavaTitle,
            message: "\(Localized.GameLauncher.alertJavaNotFoundMessage(path))\n\n\(Localized.GameLauncher.alertNoJavaMessage)"
          )
        case .launchFailed(let reason):
          showAlert(
            title: Localized.GameLauncher.alertLaunchFailedTitle,
            message: reason
          )
        }
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

  @objc func openInstanceFolder(_ sender: Any?) {
    guard let instance = getClickedInstance() else { return }

    let instanceDir = instanceManager.getInstanceDirectory(for: instance)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: instanceDir.path)
  }

  @objc func deleteInstance(_ sender: Any?) {
    guard let instance = getClickedInstance() else { return }

    // Show confirmation dialog
    let alert = NSAlert()
    alert.messageText = Localized.Instances.deleteConfirmTitle
    alert.informativeText = Localized.Instances.deleteConfirmMessage(instance.name)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Instances.deleteButton)
    alert.addButton(withTitle: Localized.Instances.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      guard response == .alertFirstButtonReturn else { return }
      self?.performDelete(instance: instance)
    }
  }

  func performDelete(instance: Instance) {
    do {
      try instanceManager.deleteInstance(instance)
      Logger.shared.info("Deleted instance: \(instance.id)", category: "Instances")

      // Refresh list
      loadInstances()

      // Show success notification
      showNotification(
        title: Localized.Instances.deleteSuccessTitle,
        message: Localized.Instances.deleteSuccessMessage(instance.name)
      )
    } catch {
      Logger.shared.error("Failed to delete instance: \(error.localizedDescription)", category: "Instances")

      // Show error dialog
      let alert = NSAlert()
      alert.messageText = Localized.Instances.deleteFailedTitle
      alert.informativeText = Localized.Instances.deleteFailedMessage(instance.name, error.localizedDescription)
      alert.alertStyle = .critical
      alert.addButton(withTitle: Localized.Instances.okButton)

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
    alert.addButton(withTitle: Localized.Instances.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  private func showVersionNotInstalledAlert(for instance: Instance) {
    let alert = NSAlert()
    alert.messageText = Localized.GameLauncher.alertVersionNotInstalledTitle
    alert.informativeText = Localized.GameLauncher.alertVersionNotInstalledMessage(instance.name, instance.versionId)
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.GameLauncher.downloadButton)
    alert.addButton(withTitle: Localized.Instances.cancelButton)

    guard let window = view.window else { return }
    alert.beginSheetModal(for: window) { [weak self] response in
      if response == .alertFirstButtonReturn {
        // User chose to download - directly download the version
        self?.downloadVersionForInstance(instance)
      }
    }
  }

  /// Download version directly for the instance
  private func downloadVersionForInstance(_ instance: Instance) {
    // Show download progress window
    let progressWindowController = DownloadProgressWindowController()
    if let progressViewController = progressWindowController.window?.contentViewController as? DownloadProgressViewController {
      progressViewController.setVersion(instance.versionId)

      // Handle completion
      progressViewController.onComplete = { [weak self, weak progressWindowController] in
        progressWindowController?.close()

        // Ask if user wants to launch now
        let launchAlert = NSAlert()
        launchAlert.messageText = Localized.GameLauncher.downloadCompleteTitle
        launchAlert.informativeText = Localized.GameLauncher.launchNowMessage(instance.name)
        launchAlert.alertStyle = .informational
        launchAlert.addButton(withTitle: Localized.GameLauncher.launchButton)
        launchAlert.addButton(withTitle: Localized.Instances.cancelButton)

        if let window = self?.view.window {
          launchAlert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
              // User wants to launch now
              self?.launchGame(nil)
            }
          }
        }
      }

      // Handle cancel
      progressViewController.onCancel = { [weak progressWindowController] in
        progressWindowController?.close()
      }
    }

    progressWindowController.showWindow(nil)

    // Start download in background
    Task { @MainActor in
      do {
        Logger.shared.info(
          "Starting version download for instance '\(instance.name)': \(instance.versionId)",
          category: "MainWindow"
        )

        // Download the version
        try await versionManager.downloadVersion(versionId: instance.versionId)

        Logger.shared.info(
          "Version download completed: \(instance.versionId)",
          category: "MainWindow"
        )
      } catch {
        Logger.shared.error(
          "Failed to download version: \(error.localizedDescription)",
          category: "MainWindow"
        )

        // Close progress window
        progressWindowController.close()

        // Show error alert
        let errorAlert = NSAlert()
        errorAlert.messageText = Localized.GameLauncher.downloadFailedTitle
        errorAlert.informativeText = Localized.GameLauncher.downloadFailedMessage(
          instance.versionId,
          error.localizedDescription
        )
        errorAlert.alertStyle = .critical
        errorAlert.addButton(withTitle: Localized.Instances.okButton)

        if let window = self.view.window {
          errorAlert.beginSheetModal(for: window, completionHandler: nil)
        } else {
          errorAlert.runModal()
        }
      }
    }
  }

  private func openVersionListWindowForDownload(versionId: String) {
    // If window already exists, show it
    if let existingController = versionListWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new version list window
    versionListWindowController = VersionListWindowController()

    // Setup callbacks for instance creation
    if let viewController = versionListWindowController?.window?.contentViewController as? VersionListViewController {
      // Preselect the version that needs to be downloaded
      viewController.preselectVersion(versionId)
      viewController.onInstanceCreated = { [weak self] _ in
        self?.loadInstances()
      }
      viewController.onCancel = {
        // Just close the window
      }
    }

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

  // Get clicked instance
  func getClickedInstance() -> Instance? {
    let point = collectionView.convert(view.window?.mouseLocationOutsideOfEventStream ?? .zero, from: nil)
    guard let indexPath = collectionView.indexPathForItem(at: point),
      indexPath.item < instances.count
    else {
      // If no item clicked, try to get selected item
      guard let selectedIndexPath = collectionView.selectionIndexPaths.first,
        selectedIndexPath.item < instances.count
      else {
        return nil
      }
      return instances[selectedIndexPath.item]
    }
    return instances[indexPath.item]
  }
}

// MARK: - NSCollectionViewDataSource

extension ViewController: NSCollectionViewDataSource {

  func collectionView(
    _ collectionView: NSCollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return instances.count
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    guard
      let item = collectionView.makeItem(
        withIdentifier: InstanceCollectionViewItem.identifier,
        for: indexPath
      ) as? InstanceCollectionViewItem
    else {
      return NSCollectionViewItem()
    }

    let instance = instances[indexPath.item]
    item.configure(with: instance)

    return item
  }
}

// MARK: - NSCollectionViewDelegate

extension ViewController: NSCollectionViewDelegate {

  func collectionView(
    _ collectionView: NSCollectionView,
    didSelectItemsAt indexPaths: Set<IndexPath>
  ) {
    guard let indexPath = indexPaths.first,
      indexPath.item < instances.count
    else { return }

    let selectedInstance = instances[indexPath.item]
    Logger.shared.info("Selected instance: \(selectedInstance.name)", category: "MainWindow")
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    didDeselectItemsAt indexPaths: Set<IndexPath>
  ) {
    // Handle deselection if needed
  }
}
