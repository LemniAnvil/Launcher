//
//  TestViewController.swift
//  Launcher
//
//  Test function view controller
//

import AppKit

// swiftlint:disable:next type_body_length
class TestViewController: NSViewController {

  private let logger = Logger.shared
  private let versionManager = VersionManager.shared
  private let downloadManager = DownloadManager.shared
  private let proxyManager = ProxyManager.shared

  // UI elements
  private let scrollView = NSScrollView()
  private let logTextView = NSTextView()

  private lazy var refreshVersionButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.refreshVersionsButton,
      target: self,
      action: #selector(testRefreshVersions)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var getVersionDetailsButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.getVersionDetailsButton,
      target: self,
      action: #selector(testGetVersionDetails)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var downloadTestFileButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.downloadTestFileButton,
      target: self,
      action: #selector(testDownloadFile)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var checkInstalledButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.checkInstalledButton,
      target: self,
      action: #selector(testCheckInstalled)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var downloadVersionButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.downloadVersionButton,
      target: self,
      action: #selector(testDownloadVersion)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentTintColor = .systemGreen
    return button
  }()

  private lazy var clearLogButton: NSButton = {
    let button = NSButton(
      title: Localized.TestWindow.clearLogButton,
      target: self,
      action: #selector(clearLog)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  // Version table view
  private lazy var versionTableView: NSTableView = {
    let table = NSTableView()
    table.style = .plain
    table.rowSizeStyle = .default
    table.usesAlternatingRowBackgroundColors = true
    table.allowsEmptySelection = false
    table.allowsMultipleSelection = false
    table.target = self
    table.doubleAction = #selector(versionDoubleClicked)
    table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    
    // Add columns
    let versionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("version"))
    versionColumn.title = Localized.TestWindow.columnVersion
    versionColumn.width = 150
    versionColumn.minWidth = 120
    table.addTableColumn(versionColumn)
    
    let typeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
    typeColumn.title = Localized.TestWindow.columnType
    typeColumn.width = 90
    typeColumn.minWidth = 70
    table.addTableColumn(typeColumn)
    
    let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("releaseTime"))
    dateColumn.title = Localized.TestWindow.columnReleaseTime
    dateColumn.width = 180
    dateColumn.minWidth = 140
    table.addTableColumn(dateColumn)
    
    let timeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("time"))
    timeColumn.title = Localized.TestWindow.columnUpdateTime
    timeColumn.width = 180
    timeColumn.minWidth = 140
    table.addTableColumn(timeColumn)
    
    let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("status"))
    statusColumn.title = Localized.TestWindow.columnStatus
    statusColumn.width = 80
    statusColumn.minWidth = 60
    table.addTableColumn(statusColumn)
    
    table.dataSource = self
    table.delegate = self
    
    return table
  }()
  
  private lazy var versionScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.documentView = versionTableView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()
  
  // Filtered versions for display
  private var displayedVersions: [MinecraftVersion] = []
  private var selectedVersion: MinecraftVersion?

  // Version type filter checkboxes
  private lazy var releaseCheckbox: NSButton = {
    let checkbox = NSButton(checkboxWithTitle: Localized.TestWindow.checkboxRelease, target: self, action: #selector(filterVersions))
    checkbox.state = .off
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    return checkbox
  }()
  
  private lazy var snapshotCheckbox: NSButton = {
    let checkbox = NSButton(checkboxWithTitle: Localized.TestWindow.checkboxSnapshot, target: self, action: #selector(filterVersions))
    checkbox.state = .off
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    return checkbox
  }()
  
  private lazy var betaCheckbox: NSButton = {
    let checkbox = NSButton(checkboxWithTitle: Localized.TestWindow.checkboxBeta, target: self, action: #selector(filterVersions))
    checkbox.state = .off
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    return checkbox
  }()
  
  private lazy var alphaCheckbox: NSButton = {
    let checkbox = NSButton(checkboxWithTitle: Localized.TestWindow.checkboxAlpha, target: self, action: #selector(filterVersions))
    checkbox.state = .off
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    return checkbox
  }()
  
  // Proxy Settings UI
  private lazy var proxyEnableCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.Proxy.enableProxy,
      target: self,
      action: #selector(proxyEnableChanged)
    )
    checkbox.state = proxyManager.proxyEnabled ? .on : .off
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    return checkbox
  }()
  
  private lazy var proxyHostField: NSTextField = {
    let field = NSTextField(string: proxyManager.proxyHost)
    field.placeholderString = Localized.Proxy.hostPlaceholder
    field.translatesAutoresizingMaskIntoConstraints = false
    field.isEnabled = proxyManager.proxyEnabled
    field.setContentCompressionResistancePriority(.required, for: .horizontal)
    field.setContentHuggingPriority(.defaultLow, for: .horizontal)
    return field
  }()
  
  private lazy var proxyPortField: NSTextField = {
    let field = NSTextField(string: proxyManager.proxyPort > 0 ? "\(proxyManager.proxyPort)" : "")
    field.placeholderString = Localized.Proxy.portPlaceholder
    field.translatesAutoresizingMaskIntoConstraints = false
    field.isEnabled = proxyManager.proxyEnabled
    field.setContentCompressionResistancePriority(.required, for: .horizontal)
    field.setContentHuggingPriority(.defaultLow, for: .horizontal)
    return field
  }()
  
  private lazy var proxyTypePopup: NSPopUpButton = {
    let popup = NSPopUpButton()
    popup.addItems(withTitles: ProxyManager.ProxyType.allCases.map { $0.displayName })
    popup.selectItem(at: ProxyManager.ProxyType.allCases.firstIndex(of: proxyManager.proxyType) ?? 0)
    popup.translatesAutoresizingMaskIntoConstraints = false
    popup.isEnabled = proxyManager.proxyEnabled
    popup.setContentCompressionResistancePriority(.required, for: .horizontal)
    return popup
  }()
  
  private lazy var applyProxyButton: NSButton = {
    let button = NSButton(
      title: Localized.Proxy.applyButton,
      target: self,
      action: #selector(applyProxy)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentTintColor = .systemBlue
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    return button
  }()
  
  private lazy var testProxyButton: NSButton = {
    let button = NSButton(
      title: Localized.Proxy.testButton,
      target: self,
      action: #selector(testProxy)
    )
    button.bezelStyle = .rounded
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    return button
  }()

  private let progressBar: NSProgressIndicator = {
    let bar = NSProgressIndicator()
    bar.style = .bar
    bar.isIndeterminate = false
    bar.minValue = 0
    bar.maxValue = 1
    bar.doubleValue = 0
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.TestWindow.statusReady)
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 750))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupLogObserver()
    loadVersionsToTable()
    logMessage(Localized.LogMessages.initialized)
    logMessage(Localized.LogMessages.pleaseClickButtons)
  }

  private func loadVersionsToTable() {
    Task {
      // Load cached versions if available
      logMessage(Localized.LogMessages.checkingVersionManager)
      logMessage(Localized.LogMessages.currentLoadedVersions(versionManager.versions.count))
      
      if versionManager.versions.isEmpty {
        logMessage(Localized.LogMessages.loadingCachedVersions)
      } else {
        logMessage(Localized.LogMessages.versionDataLoaded)
        logVersionStatistics()
        updateVersionTable()
      }
    }
  }
  
  /// Log version statistics by type
  private func logVersionStatistics() {
    let releases = versionManager.getFilteredVersions(type: .release)
    let snapshots = versionManager.getFilteredVersions(type: .snapshot)
    let betas = versionManager.getFilteredVersions(type: .oldBeta)
    let alphas = versionManager.getFilteredVersions(type: .oldAlpha)
    
    logMessage(Localized.LogMessages.versionStatisticsTitle())
    logMessage(Localized.LogMessages.releaseCount(releases.count))
    logMessage(Localized.LogMessages.snapshotCount(snapshots.count))
    logMessage(Localized.LogMessages.betaCount(betas.count))
    logMessage(Localized.LogMessages.alphaCount(alphas.count))
    logMessage(Localized.LogMessages.totalCount(versionManager.versions.count))
  }

  private func updateVersionTable(filterTypes: [VersionType]? = nil) {
    let versions: [MinecraftVersion]
    
    if let filterTypes = filterTypes, !filterTypes.isEmpty {
      // Filter versions by selected types
      versions = versionManager.versions.filter { version in
        filterTypes.contains(version.type)
      }
      let typeNames = filterTypes.map { $0.displayName }.joined(separator: ", ")
      logMessage(Localized.LogMessages.filteringAfterCount(typeNames, versions.count))
    } else {
      versions = versionManager.versions
      logMessage(Localized.LogMessages.showingAllVersions(versions.count))
    }

    if versions.isEmpty {
      displayedVersions = []
      versionTableView.reloadData()
      logMessage(Localized.LogMessages.versionListEmpty)
      return
    }

    displayedVersions = versions
    
    // Reload data and force refresh all visible cells to update installation status
    versionTableView.reloadData()
    
    // Force refresh all visible rows to ensure status column is updated
    let visibleRange = versionTableView.rows(in: versionTableView.visibleRect)
    if visibleRange.length > 0 {
      let indexSet = IndexSet(integersIn: visibleRange.location..<(visibleRange.location + visibleRange.length))
      versionTableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 4)) // Column 4 is status
    }
    
    logMessage(Localized.LogMessages.versionListUpdated)
    logMessage(Localized.LogMessages.displayedVersionsCount(displayedVersions.count))
    
    // Select latest release by default if it's in the filtered list
    if let latestRelease = versionManager.latestRelease,
      let index = displayedVersions.firstIndex(where: { $0.id == latestRelease })
    {
      versionTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
      versionTableView.scrollRowToVisible(index)
      selectedVersion = displayedVersions[index]
      logMessage(Localized.LogMessages.defaultSelectedIndex(latestRelease, index))
    } else if !displayedVersions.isEmpty {
      versionTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      selectedVersion = displayedVersions[0]
      logMessage(Localized.LogMessages.latestReleaseNotFound)
    }
  }

  private func getVersionEmoji(for type: VersionType) -> String {
    switch type {
    case .release: return "🟢"
    case .snapshot: return "🟡"
    case .oldBeta: return "🔵"
    case .oldAlpha: return "🟣"
    }
  }

  @objc private func versionDoubleClicked() {
    let row = versionTableView.clickedRow
    guard row >= 0, row < displayedVersions.count else { return }
    
    let version = displayedVersions[row]
    logMessage("\(Localized.LogMessages.mouseDoubleClickVersion) \(version.id)")
    
    // Trigger version download
    testDownloadVersion()
  }

  @objc private func filterVersions() {
    applyCurrentFilter()
  }
  
  /// Apply current filter based on checkbox states
  private func applyCurrentFilter() {
    // Collect selected version types
    var selectedTypes: [VersionType] = []
    
    if releaseCheckbox.state == .on {
      selectedTypes.append(.release)
    }
    if snapshotCheckbox.state == .on {
      selectedTypes.append(.snapshot)
    }
    if betaCheckbox.state == .on {
      selectedTypes.append(.oldBeta)
    }
    if alphaCheckbox.state == .on {
      selectedTypes.append(.oldAlpha)
    }
    
    // If no types selected, show all versions
    if selectedTypes.isEmpty {
      updateVersionTable(filterTypes: nil)
      logMessage(Localized.LogMessages.filterCleared)
    } else {
      updateVersionTable(filterTypes: selectedTypes)
      let typeNames = selectedTypes.map { $0.displayName }.joined(separator: ", ")
      logMessage(Localized.LogMessages.filterApplied(typeNames))
    }
  }

  // swiftlint:disable:next function_body_length
  private func setupUI() {
    // Setup log text view
    logTextView.isEditable = false
    logTextView.isSelectable = true
    logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logTextView.textColor = .labelColor
    logTextView.backgroundColor = .textBackgroundColor

    scrollView.documentView = logTextView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = false
    scrollView.borderType = .bezelBorder
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    // Create button container
    let buttonStack = NSStackView(views: [
      refreshVersionButton,
      getVersionDetailsButton,
      downloadTestFileButton,
      checkInstalledButton,
    ])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 10
    buttonStack.distribution = .fillEqually
    buttonStack.translatesAutoresizingMaskIntoConstraints = false

    // Create filter control row
    let filterLabel = NSTextField(labelWithString: Localized.TestWindow.filterLabel)
    filterLabel.translatesAutoresizingMaskIntoConstraints = false

    let checkboxStack = NSStackView(views: [
      releaseCheckbox,
      snapshotCheckbox,
      betaCheckbox,
      alphaCheckbox,
    ])
    checkboxStack.orientation = .horizontal
    checkboxStack.spacing = 15
    checkboxStack.translatesAutoresizingMaskIntoConstraints = false

    let filterStack = NSStackView(views: [
      filterLabel,
      checkboxStack,
      downloadVersionButton,
      clearLogButton,
    ])
    filterStack.orientation = .horizontal
    filterStack.spacing = 10
    filterStack.translatesAutoresizingMaskIntoConstraints = false
    
    // Create proxy settings row
    let proxyHostLabel = NSTextField(labelWithString: Localized.Proxy.hostLabel)
    proxyHostLabel.translatesAutoresizingMaskIntoConstraints = false
    proxyHostLabel.alignment = .right
    
    let proxyPortLabel = NSTextField(labelWithString: Localized.Proxy.portLabel)
    proxyPortLabel.translatesAutoresizingMaskIntoConstraints = false
    proxyPortLabel.alignment = .right
    
    let proxyTypeLabel = NSTextField(labelWithString: Localized.Proxy.typeLabel)
    proxyTypeLabel.translatesAutoresizingMaskIntoConstraints = false
    proxyTypeLabel.alignment = .right
    
    // Set fixed widths for input controls
    NSLayoutConstraint.activate([
      proxyTypePopup.widthAnchor.constraint(equalToConstant: 90),
      proxyHostField.widthAnchor.constraint(equalToConstant: 140),
      proxyPortField.widthAnchor.constraint(equalToConstant: 60),
      applyProxyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
      testProxyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
    ])
    
    let proxyStack = NSStackView(views: [
      proxyEnableCheckbox,
      proxyTypeLabel,
      proxyTypePopup,
      proxyHostLabel,
      proxyHostField,
      proxyPortLabel,
      proxyPortField,
      applyProxyButton,
      testProxyButton,
    ])
    proxyStack.orientation = .horizontal
    proxyStack.spacing = 6
    proxyStack.alignment = .centerY
    proxyStack.distribution = .gravityAreas
    proxyStack.translatesAutoresizingMaskIntoConstraints = false

    // Add to view
    view.addSubview(buttonStack)
    view.addSubview(filterStack)
    view.addSubview(proxyStack)
    view.addSubview(versionScrollView)
    view.addSubview(scrollView)
    view.addSubview(progressBar)
    view.addSubview(statusLabel)

    // Layout
    NSLayoutConstraint.activate([
      // First row buttons
      buttonStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      buttonStack.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      buttonStack.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      buttonStack.heightAnchor.constraint(equalToConstant: 32),

      // Filter row
      filterStack.topAnchor.constraint(
        equalTo: buttonStack.bottomAnchor,
        constant: 10
      ),
      filterStack.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      filterStack.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      filterStack.heightAnchor.constraint(equalToConstant: 32),
      
      // Proxy settings row
      proxyStack.topAnchor.constraint(
        equalTo: filterStack.bottomAnchor,
        constant: 10
      ),
      proxyStack.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      proxyStack.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      proxyStack.heightAnchor.constraint(equalToConstant: 32),

      // Version table view
      versionScrollView.topAnchor.constraint(
        equalTo: proxyStack.bottomAnchor,
        constant: 10
      ),
      versionScrollView.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      versionScrollView.widthAnchor.constraint(equalToConstant: 730),
      versionScrollView.bottomAnchor.constraint(
        equalTo: progressBar.topAnchor,
        constant: -15
      ),

      // Log view
      scrollView.topAnchor.constraint(
        equalTo: filterStack.bottomAnchor,
        constant: 10
      ),
      scrollView.leadingAnchor.constraint(
        equalTo: versionScrollView.trailingAnchor,
        constant: 10
      ),
      scrollView.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      scrollView.bottomAnchor.constraint(
        equalTo: progressBar.topAnchor,
        constant: -15
      ),

      // Progress bar
      progressBar.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      progressBar.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      progressBar.bottomAnchor.constraint(
        equalTo: statusLabel.topAnchor,
        constant: -8
      ),
      progressBar.heightAnchor.constraint(equalToConstant: 20),

      // Status label
      statusLabel.leadingAnchor.constraint(
        equalTo: view.leadingAnchor,
        constant: 20
      ),
      statusLabel.trailingAnchor.constraint(
        equalTo: view.trailingAnchor,
        constant: -20
      ),
      statusLabel.bottomAnchor.constraint(
        equalTo: view.bottomAnchor,
        constant: -10
      ),
    ])
  }

  private func setupLogObserver() {
    // Monitor download progress updates
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
      [weak self] _ in
      guard let self = self else { return }

      Task { @MainActor in
        if self.downloadManager.isDownloading {
          let progress = self.downloadManager.currentProgress
          self.progressBar.doubleValue = progress.overallProgress

          let speed = FileUtils.formatBytes(
            Int64(self.downloadManager.downloadSpeed)
          )
          self.statusLabel.stringValue = Localized.TestWindow.statusDownloading(
            progress: progress.displayProgress,
            speed: speed,
            bytes: progress.bytesDisplay
          )
        }
      }
    }
  }

  // MARK: - Test Methods

  @objc private func testRefreshVersions() {
    logMessage("\n" + String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.test1Title)
    logMessage(String(repeating: "=", count: 60))

    disableButtons(true)
    statusLabel.stringValue = Localized.TestWindow.statusRefreshing

    Task {
      do {
        try await versionManager.refreshVersionList()

        await MainActor.run {
          logMessage(Localized.LogMessages.versionListRefreshed)
          logMessage(
            Localized.LogMessages.latestRelease(versionManager.latestRelease ?? "Unknown")
          )
          logMessage(
            Localized.LogMessages.latestSnapshot(versionManager.latestSnapshot ?? "Unknown")
          )
          logMessage(Localized.LogMessages.totalVersions(versionManager.versions.count))

          // Show version statistics
          logVersionStatistics()
          
          // Show first 10 releases
          let releases = versionManager.getFilteredVersions(type: .release)
            .prefix(10)
          logMessage("\n" + Localized.LogMessages.firstReleasesTitle)
          for (index, version) in releases.enumerated() {
            logMessage("  \(index + 1). \(version.id)")
          }

          // Update version table with current filter
          logMessage(Localized.LogMessages.updatingVersionList)
          applyCurrentFilter()
          logMessage(
            Localized.LogMessages.versionDropdownUpdated(versionManager.versions.count)
          )

          statusLabel.stringValue = Localized.TestWindow.statusRefreshCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue =
            Localized.TestWindow.statusRefreshFailed(error.localizedDescription)
          disableButtons(false)
        }
      }
    }
  }

  @objc private func testGetVersionDetails() {
    let row = versionTableView.selectedRow
    guard row >= 0, row < displayedVersions.count else {
      logMessage(Localized.LogMessages.pleaseSelectVersion)
      return
    }
    
    let versionId = displayedVersions[row].id

    logMessage("\n" + String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.test2Title(versionId))
    logMessage(String(repeating: "=", count: 60))

    disableButtons(true)
    statusLabel.stringValue = Localized.TestWindow.statusGettingDetails

    Task {
      do {
        // Ensure version list is loaded
        if versionManager.versions.isEmpty {
          logMessage(Localized.LogMessages.versionListEmptyRefreshing)
          try await versionManager.refreshVersionList()
        }

        let details = try await versionManager.getVersionDetails(
          versionId: versionId
        )

        await MainActor.run {
          logMessage(Localized.LogMessages.versionDetailsRetrieved)
          logMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
          logMessage(Localized.LogMessages.versionId(details.id))
          logMessage(Localized.LogMessages.versionType(details.type))
          logMessage(Localized.LogMessages.mainClass(details.mainClass))
          logMessage(Localized.LogMessages.assetIndex(details.assetIndex.id))

          if let javaVersion = details.javaVersion {
            logMessage(Localized.LogMessages.javaVersion(javaVersion.majorVersion))
          }

          logMessage(Localized.LogMessages.libraryInfo)
          logMessage(Localized.LogMessages.libraryTotal(details.libraries.count))
          let applicable = details.libraries.filter { $0.isApplicable() }
          logMessage(Localized.LogMessages.libraryApplicable(applicable.count))

          if let clientDownload = details.downloads.client {
            logMessage(Localized.LogMessages.clientFile)
            logMessage(
              Localized.LogMessages.clientSize(FileUtils.formatBytes(Int64(clientDownload.size)))
            )
            logMessage(Localized.LogMessages.clientSHA1(clientDownload.sha1))
          }

          statusLabel.stringValue = Localized.TestWindow.statusDetailsCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue = Localized.TestWindow.statusDetailsFailed
          disableButtons(false)
        }
      }
    }
  }

  @objc private func testDownloadFile() {
    logMessage("\n" + String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.test3Title)
    logMessage(String(repeating: "=", count: 60))

    disableButtons(true)
    statusLabel.stringValue = Localized.TestWindow.statusDownloadingTestFile
    progressBar.doubleValue = 0

    Task {
      do {
        let tempDir = FileUtils.getTemporaryDirectory()
        let destination = tempDir.appendingPathComponent("test_manifest.json")

        logMessage(Localized.LogMessages.startingDownloadManifest)
        logMessage(Localized.LogMessages.saveLocation(destination.path))

        try await downloadManager.downloadFile(
          from: "https://launchermeta.mojang.com/mc/game/version_manifest.json",
          to: destination,
          expectedSize: 500000
        )

        await MainActor.run {
          if let size = FileUtils.getFileSize(at: destination) {
            logMessage(Localized.LogMessages.fileDownloadedSuccessfully)
            logMessage(Localized.LogMessages.fileSize(FileUtils.formatBytes(size)))
            logMessage(Localized.LogMessages.filePath(destination.path))
          }

          progressBar.doubleValue = 1.0
          statusLabel.stringValue = Localized.TestWindow.statusTestFileCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue = Localized.TestWindow.statusDownloadFailed
          disableButtons(false)
        }
      }
    }
  }

  @objc private func testCheckInstalled() {
    logMessage("\n" + String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.test4Title)
    logMessage(String(repeating: "=", count: 60))

    let installed = versionManager.getInstalledVersions()

    if installed.isEmpty {
      logMessage(Localized.LogMessages.noInstalledVersions)
    } else {
      logMessage(Localized.LogMessages.installedVersions(installed.count))
      for (index, version) in installed.enumerated() {
        let versionDir = FileUtils.getVersionsDirectory()
          .appendingPathComponent(version)
        let jarFile = versionDir.appendingPathComponent("\(version).jar")

        if let size = FileUtils.getFileSize(at: jarFile) {
          logMessage(
            "  \(index + 1). \(version) - \(FileUtils.formatBytes(size))"
          )
        } else {
          logMessage("  \(index + 1). \(version)")
        }
      }
    }

    logMessage(
      Localized.LogMessages.minecraftDirectory(FileUtils.getMinecraftDirectory().path)
    )
    statusLabel.stringValue =
      Localized.TestWindow.statusCheckCompleted(installed.count)
    
    // Refresh version table to update installation status display
    logMessage(Localized.LogMessages.refreshVersionListToUpdate)
    applyCurrentFilter()
  }

  @objc private func testDownloadVersion() {
    let row = versionTableView.selectedRow
    guard row >= 0, row < displayedVersions.count else {
      logMessage(Localized.LogMessages.pleaseSelectVersion)
      return
    }
    
    let versionId = displayedVersions[row].id

    logMessage("\n" + String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.test5Title(versionId))
    logMessage(String(repeating: "=", count: 60))
    logMessage(Localized.LogMessages.downloadWarning)

    // Confirmation dialog
    let alert = NSAlert()
    alert.messageText = Localized.Alerts.confirmDownloadTitle
    alert.informativeText = Localized.Alerts.confirmDownloadMessage(versionId)
    alert.addButton(withTitle: Localized.Alerts.confirmButton)
    alert.addButton(withTitle: Localized.Alerts.cancelButton)
    alert.alertStyle = .informational

    let response = alert.runModal()
    guard response == .alertFirstButtonReturn else {
      logMessage(Localized.LogMessages.userCancelledDownload)
      return
    }

    disableButtons(true)
    statusLabel.stringValue = Localized.TestWindow.statusDownloadingVersion
    progressBar.doubleValue = 0

    Task {
      do {
        // 1. Ensure version list is loaded
        if versionManager.versions.isEmpty {
          logMessage(Localized.LogMessages.refreshingVersionList)
          try await versionManager.refreshVersionList()
        }

        // 2. Get version details
        logMessage(Localized.LogMessages.gettingVersionDetails)
        let details = try await versionManager.getVersionDetails(
          versionId: versionId
        )

        await MainActor.run {
          logMessage(Localized.LogMessages.versionDetailsRetrievedSuccessfully)
          logMessage(Localized.LogMessages.needToDownloadLibraries(details.libraries.count))
        }

        // 3. Download version files
        logMessage(Localized.LogMessages.downloadingCoreAndLibraries)
        try await downloadManager.downloadVersion(details)

        await MainActor.run {
          logMessage(Localized.LogMessages.coreAndLibrariesCompleted)
        }

        // 4. Download game assets
        logMessage(Localized.LogMessages.downloadingAssets)
        try await downloadManager.downloadAssets(
          assetIndexId: details.assetIndex.id
        )

        await MainActor.run {
          logMessage(Localized.LogMessages.assetsCompleted)
          logMessage("\n" + String(repeating: "=", count: 60))
          logMessage(Localized.LogMessages.downloadCompleted(versionId))
          logMessage(String(repeating: "=", count: 60))

          progressBar.doubleValue = 1.0
          statusLabel.stringValue = Localized.TestWindow.statusDownloadCompleted
          
          // Refresh version table to show updated installation status
          logMessage(Localized.LogMessages.refreshVersionListToShow)
          applyCurrentFilter()
          
          disableButtons(false)

          // Show success dialog
          let successAlert = NSAlert()
          successAlert.messageText = Localized.Alerts.downloadCompletedTitle
          successAlert.informativeText = Localized.Alerts.downloadCompletedMessage(versionId)
          successAlert.alertStyle = .informational
          successAlert.runModal()
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.downloadFailed(error.localizedDescription))
          statusLabel.stringValue = Localized.TestWindow.statusDownloadFailed
          disableButtons(false)

          let errorAlert = NSAlert()
          errorAlert.messageText = Localized.Alerts.downloadFailedTitle
          errorAlert.informativeText = error.localizedDescription
          errorAlert.alertStyle = .critical
          errorAlert.runModal()
        }
      }
    }
  }

  @objc private func clearLog() {
    logTextView.string = ""
    logMessage(Localized.LogMessages.logCleared)
  }

  // MARK: - Helper Methods

  private func logMessage(_ message: String) {
    let timestamp = DateFormatter.localizedString(
      from: Date(),
      dateStyle: .none,
      timeStyle: .medium
    )
    let logLine = "[\(timestamp)] \(message)\n"

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      let textStorage = self.logTextView.textStorage
      let newText = NSAttributedString(
        string: logLine,
        attributes: [
          .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
          .foregroundColor: NSColor.labelColor,
        ]
      )

      textStorage?.append(newText)

      // Scroll to bottom
      let range = NSRange(location: textStorage?.length ?? 0, length: 0)
      self.logTextView.scrollRangeToVisible(range)
    }
  }

  private func disableButtons(_ disabled: Bool) {
    refreshVersionButton.isEnabled = !disabled
    getVersionDetailsButton.isEnabled = !disabled
    downloadTestFileButton.isEnabled = !disabled
    checkInstalledButton.isEnabled = !disabled
    downloadVersionButton.isEnabled = !disabled
  }
  
  // MARK: - Proxy Methods
  
  @objc private func proxyEnableChanged() {
    let enabled = proxyEnableCheckbox.state == .on
    proxyHostField.isEnabled = enabled
    proxyPortField.isEnabled = enabled
    proxyTypePopup.isEnabled = enabled
    
    if !enabled {
      proxyManager.disableProxy()
      downloadManager.reconfigureSession()
      logMessage(Localized.Proxy.logDisabled)
      statusLabel.stringValue = Localized.Proxy.statusDisabled
    }
  }
  
  @objc private func applyProxy() {
    let enabled = proxyEnableCheckbox.state == .on
    let host = proxyHostField.stringValue.trimmingCharacters(in: .whitespaces)
    let port = Int(proxyPortField.stringValue) ?? 0
    
    // Validate input
    if enabled && (host.isEmpty || port <= 0 || port > 65535) {
      let alert = NSAlert()
      alert.messageText = Localized.Proxy.alertInvalidConfigTitle
      alert.informativeText = Localized.Proxy.alertInvalidConfigMessage
      alert.alertStyle = .warning
      alert.runModal()
      return
    }
    
    // Get proxy type
    let selectedIndex = proxyTypePopup.indexOfSelectedItem
    let proxyType = ProxyManager.ProxyType.allCases[safe: selectedIndex] ?? .http
    
    // Configure proxy
    proxyManager.configureProxy(enabled: enabled, host: host, port: port, type: proxyType)
    
    // Reconfigure download manager
    downloadManager.reconfigureSession()
    
    if enabled {
      logMessage(Localized.Proxy.logEnabled(proxyType.displayName, host, port))
      statusLabel.stringValue = Localized.Proxy.statusApplied(host, port)
    } else {
      logMessage(Localized.Proxy.logDisabled)
      statusLabel.stringValue = Localized.Proxy.statusDisabled
    }
  }
  
  @objc private func testProxy() {
    logMessage(Localized.Proxy.logTesting)
    statusLabel.stringValue = Localized.Proxy.statusTesting
    
    Task {
      do {
        let success = try await proxyManager.testProxyConnection()
        
        await MainActor.run {
          if success {
            logMessage(Localized.Proxy.logTestSuccess)
            statusLabel.stringValue = Localized.Proxy.statusTestSuccess
            
            let alert = NSAlert()
            alert.messageText = Localized.Proxy.alertTestSuccessTitle
            alert.informativeText = Localized.Proxy.alertTestSuccessMessage
            alert.alertStyle = .informational
            alert.runModal()
          }
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.Proxy.logTestFailed(error.localizedDescription))
          statusLabel.stringValue = Localized.Proxy.statusTestFailed
          
          let alert = NSAlert()
          alert.messageText = Localized.Proxy.alertTestFailedTitle
          alert.informativeText = Localized.Proxy.alertTestFailedMessage(error.localizedDescription)
          alert.alertStyle = .critical
          alert.runModal()
        }
      }
    }
  }
}

// MARK: - Array Extension

extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

// MARK: - NSTableViewDataSource

extension TestViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return displayedVersions.count
  }
}

// MARK: - NSTableViewDelegate

extension TestViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard row >= 0 && row < displayedVersions.count else { return nil }
    
    let version = displayedVersions[row]
    let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
    
    // Use standard table cell view with identifier
    let cellIdentifier = NSUserInterfaceItemIdentifier("DataCell")
    var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
    
    if cell == nil {
      // Create new cell
      cell = NSTableCellView()
      cell?.identifier = cellIdentifier
      
      // Create writable text field (NOT label)
      let textField = NSTextField()
      textField.isBordered = false
      textField.drawsBackground = false
      textField.isEditable = false
      textField.isSelectable = false
      textField.lineBreakMode = .byTruncatingTail
      textField.usesSingleLineMode = true
      textField.cell?.wraps = false
      textField.cell?.isScrollable = false
      textField.translatesAutoresizingMaskIntoConstraints = false
      
      // Set content hugging and compression resistance
      textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
      textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
      
      cell?.textField = textField
      cell?.addSubview(textField)
      
      // Pin to edges with proper priorities
      NSLayoutConstraint.activate([
        textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 2),
        textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -2),
        textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
      ])
    }
    
    // Configure the text field for this specific cell
    guard let textField = cell?.textField else { return cell }
    
    // Reset to defaults
    textField.font = .systemFont(ofSize: 11)
    textField.textColor = .labelColor
    textField.alignment = .left
    
    // Set content based on column
    switch identifier.rawValue {
    case "version":
      let emoji = getVersionEmoji(for: version.type)
      textField.stringValue = "\(emoji) \(version.id)"
      textField.font = .systemFont(ofSize: 11, weight: .medium)
      
    case "type":
      textField.stringValue = version.type.displayName
      textField.textColor = getTypeColor(for: version.type)
      textField.font = .systemFont(ofSize: 11, weight: .semibold)
      
    case "releaseTime":
      textField.stringValue = formatDateTime(version.releaseTime)
      textField.textColor = .secondaryLabelColor
      
    case "time":
      textField.stringValue = formatDateTime(version.time)
      textField.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.8)
      
    case "status":
      let isInstalled = versionManager.isVersionInstalled(versionId: version.id)
      textField.stringValue = isInstalled ? Localized.TestWindow.statusInstalled : ""
      textField.textColor = .systemGreen
      textField.font = .systemFont(ofSize: 10, weight: .medium)
      
    default:
      textField.stringValue = ""
    }
    
    return cell
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    let row = versionTableView.selectedRow
    if row >= 0 && row < displayedVersions.count {
      selectedVersion = displayedVersions[row]
      logMessage(Localized.LogMessages.selectedVersion(selectedVersion!.id))
    }
  }
  
  private func formatDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = formatter.date(from: dateString) else {
      return dateString
    }
    
    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .medium
    displayFormatter.timeStyle = .none
    displayFormatter.locale = Locale(identifier: "zh_CN")
    
    return displayFormatter.string(from: date)
  }
  
  private func formatDateTime(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = formatter.date(from: dateString) else {
      // Try format without milliseconds
      formatter.formatOptions = [.withInternetDateTime]
      guard let date = formatter.date(from: dateString) else {
        return dateString
      }
      return formatDateDisplay(date)
    }
    
    return formatDateDisplay(date)
  }
  
  private func formatDateDisplay(_ date: Date) -> String {
    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    displayFormatter.locale = Locale(identifier: "zh_CN")
    displayFormatter.timeZone = TimeZone.current
    return displayFormatter.string(from: date)
  }
  
  private func getTypeColor(for type: VersionType) -> NSColor {
    switch type {
    case .release:
      return .systemGreen
    case .snapshot:
      return .systemOrange
    case .oldBeta:
      return .systemBlue
    case .oldAlpha:
      return .systemPurple
    }
  }
}
