//
//  VersionListViewController.swift
//  Launcher
//
//  Version list and download management view controller
//

import AppKit
import SnapKit
import Yatagarasu

// swiftlint:disable:next type_body_length
class VersionListViewController: NSViewController {

  private let logger = Logger.shared
  private let versionManager = VersionManager.shared
  private let downloadManager = DownloadManager.shared

  // UI elements
  private let scrollView = NSScrollView()
  private lazy var logTextView: NSTextView = {
    let textView = NSTextView(frame: .zero)
    textView.isEditable = false
    textView.isSelectable = true
    textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    textView.textColor = .labelColor
    textView.backgroundColor = .textBackgroundColor
    textView.minSize = NSSize(width: 0, height: 0)
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.autoresizingMask = [.width]

    if let textContainer = textView.textContainer {
      textContainer.containerSize = NSSize(width: 200, height: CGFloat.greatestFiniteMagnitude)
      textContainer.widthTracksTextView = true
    }

    return textView
  }()

  private lazy var refreshVersionButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.clockwise",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.VersionListWindow.refreshVersionsButton
    )
    button.target = self
    button.action = #selector(testRefreshVersions)
    return button
  }()

  private lazy var getVersionDetailsButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "info.circle",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.VersionListWindow.getVersionDetailsButton
    )
    button.target = self
    button.action = #selector(testGetVersionDetails)
    return button
  }()

  private lazy var downloadTestFileButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.down.doc",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.VersionListWindow.downloadTestFileButton
    )
    button.target = self
    button.action = #selector(testDownloadFile)
    return button
  }()

  private lazy var downloadVersionButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.down.circle.fill",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemGreen,
      accessibilityLabel: Localized.VersionListWindow.downloadVersionButton
    )
    button.target = self
    button.action = #selector(testDownloadVersion)
    return button
  }()

  private lazy var clearLogButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "trash",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemRed,
      accessibilityLabel: Localized.VersionListWindow.clearLogButton
    )
    button.target = self
    button.action = #selector(clearLog)
    return button
  }()

  // Version table view with Finder-style appearance
  private lazy var versionTableView: NSTableView = {
    let table = NSTableView()
    table.style = .fullWidth
    table.rowSizeStyle = .medium
    table.usesAlternatingRowBackgroundColors = true
    table.allowsEmptySelection = false
    table.allowsMultipleSelection = false
    table.target = self
    table.doubleAction = #selector(versionDoubleClicked)
    table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    table.intercellSpacing = NSSize(width: 3, height: 6)
    table.gridStyleMask = [.solidHorizontalGridLineMask]
    table.gridColor = NSColor.separatorColor.withAlphaComponent(0.3)

    // Add columns
    let versionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("version"))
    versionColumn.title = Localized.VersionListWindow.columnVersion
    versionColumn.width = 160
    versionColumn.minWidth = 120
    table.addTableColumn(versionColumn)

    let typeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
    typeColumn.title = Localized.VersionListWindow.columnType
    typeColumn.width = 100
    typeColumn.minWidth = 80
    table.addTableColumn(typeColumn)

    let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("releaseTime"))
    dateColumn.title = Localized.VersionListWindow.columnReleaseTime
    dateColumn.width = 180
    dateColumn.minWidth = 140
    table.addTableColumn(dateColumn)

    let timeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("time"))
    timeColumn.title = Localized.VersionListWindow.columnUpdateTime
    timeColumn.width = 180
    timeColumn.minWidth = 140
    table.addTableColumn(timeColumn)

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
    return scrollView
  }()

  // Filtered versions for display
  private var displayedVersions: [MinecraftVersion] = []
  private var selectedVersion: MinecraftVersion?

  // Version type filter checkboxes
  private lazy var releaseCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.VersionListWindow.checkboxRelease,
      target: self,
      action: #selector(filterVersions)
    )
    checkbox.state = .on
    return checkbox
  }()

  private lazy var snapshotCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.VersionListWindow.checkboxSnapshot,
      target: self,
      action: #selector(filterVersions)
    )
    checkbox.state = .off
    return checkbox
  }()

  private lazy var betaCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.VersionListWindow.checkboxBeta,
      target: self,
      action: #selector(filterVersions)
    )
    checkbox.state = .off
    return checkbox
  }()

  private lazy var alphaCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.VersionListWindow.checkboxAlpha,
      target: self,
      action: #selector(filterVersions)
    )
    checkbox.state = .off
    return checkbox
  }()

  private let progressBar: NSProgressIndicator = {
    let bar = NSProgressIndicator()
    bar.style = .bar
    bar.isIndeterminate = false
    bar.minValue = 0
    bar.maxValue = 1
    bar.doubleValue = 0
    return bar
  }()

  private let statusLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.VersionListWindow.statusReady,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
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

  override func viewDidAppear() {
    super.viewDidAppear()
    // Force layout update for text view after layout is complete
    logTextView.needsLayout = true
    if let textContainer = logTextView.textContainer {
      logTextView.layoutManager?.ensureLayout(for: textContainer)
    }
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
        applyCurrentFilter()
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

    // Reload data
    versionTableView.reloadData()

    logMessage(Localized.LogMessages.versionListUpdated)
    logMessage(Localized.LogMessages.displayedVersionsCount(displayedVersions.count))

    // Select latest release by default if it's in the filtered list
    if let latestRelease = versionManager.latestRelease, let index = displayedVersions.firstIndex(where: { $0.id == latestRelease }) {
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

  private func setupUI() {
    // Setup scroll view for log text view
    scrollView.documentView = logTextView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = false
    scrollView.borderType = .bezelBorder

    // Create main button container with all action buttons
    // Add visual separator between button groups
    let separator1 = BRSeparator.vertical()
    separator1.snp.makeConstraints { make in
      make.width.equalTo(1)
      make.height.equalTo(24)
    }

    let buttonStack = NSStackView(views: [
      refreshVersionButton,
      getVersionDetailsButton,
      downloadTestFileButton,
      separator1,
      downloadVersionButton,
      clearLogButton,
    ])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 12
    buttonStack.distribution = .gravityAreas

    // Create filter control row
    let filterLabel = BRLabel(
      text: Localized.VersionListWindow.filterLabel,
      font: .systemFont(ofSize: 12),
      textColor: .labelColor,
      alignment: .left
    )

    let checkboxStack = NSStackView(views: [
      releaseCheckbox,
      snapshotCheckbox,
      betaCheckbox,
      alphaCheckbox,
    ])
    checkboxStack.orientation = .horizontal
    checkboxStack.spacing = 15

    let filterStack = NSStackView(views: [
      filterLabel,
      checkboxStack,
    ])
    filterStack.orientation = .horizontal
    filterStack.spacing = 10

    // Add to view
    view.addSubview(buttonStack)
    view.addSubview(filterStack)
    view.addSubview(versionScrollView)
    view.addSubview(scrollView)
    view.addSubview(progressBar)
    view.addSubview(statusLabel)

    // Layout using SnapKit
    // Set button sizes - using standard image button size
    let buttonSize: CGFloat = 32
    [
      refreshVersionButton,
      getVersionDetailsButton,
      downloadTestFileButton,
      downloadVersionButton,
      clearLogButton,
    ].forEach { button in
      button.snp.makeConstraints { make in
        make.width.height.equalTo(buttonSize)
      }
    }

    buttonStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.height.equalTo(32)
    }

    filterStack.snp.makeConstraints { make in
      make.top.equalTo(buttonStack.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(32)
    }

    versionScrollView.snp.makeConstraints { make in
      make.top.equalTo(filterStack.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(730)
      make.bottom.equalTo(progressBar.snp.top).offset(-15)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(filterStack.snp.bottom).offset(10)
      make.left.equalTo(versionScrollView.snp.right).offset(10)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalTo(progressBar.snp.top).offset(-15)
    }

    progressBar.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalTo(statusLabel.snp.top).offset(-8)
      make.height.equalTo(20)
    }

    statusLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalToSuperview().offset(-10)
    }
  }

  private func setupLogObserver() {
    // Monitor download progress updates
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      Task { @MainActor in
        if self.downloadManager.isDownloading {
          let progress = self.downloadManager.currentProgress
          self.progressBar.doubleValue = progress.overallProgress

          let speed = FileUtils.formatBytes(
            Int64(self.downloadManager.downloadSpeed)
          )
          self.statusLabel.stringValue = Localized.VersionListWindow.statusDownloading(
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
    statusLabel.stringValue = Localized.VersionListWindow.statusRefreshing

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

          statusLabel.stringValue = Localized.VersionListWindow.statusRefreshCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue =
          Localized.VersionListWindow.statusRefreshFailed(error.localizedDescription)
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
    statusLabel.stringValue = Localized.VersionListWindow.statusGettingDetails

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

          statusLabel.stringValue = Localized.VersionListWindow.statusDetailsCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue = Localized.VersionListWindow.statusDetailsFailed
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
    statusLabel.stringValue = Localized.VersionListWindow.statusDownloadingTestFile
    progressBar.doubleValue = 0

    Task {
      do {
        let tempDir = FileUtils.getTemporaryDirectory()
        let destination = tempDir.appendingPathComponent("test_manifest.json")

        logMessage(Localized.LogMessages.startingDownloadManifest)
        logMessage(Localized.LogMessages.saveLocation(destination.path))

        try await downloadManager.downloadFile(
          from: APIEndpoints.versionManifestOfficial,
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
          statusLabel.stringValue = Localized.VersionListWindow.statusTestFileCompleted
          disableButtons(false)
        }
      } catch {
        await MainActor.run {
          logMessage(Localized.LogMessages.error(error.localizedDescription))
          statusLabel.stringValue = Localized.VersionListWindow.statusDownloadFailed
          disableButtons(false)
        }
      }
    }
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
    statusLabel.stringValue = Localized.VersionListWindow.statusDownloadingVersion
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
          statusLabel.stringValue = Localized.VersionListWindow.statusDownloadCompleted

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
          statusLabel.stringValue = Localized.VersionListWindow.statusDownloadFailed
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
    downloadVersionButton.isEnabled = !disabled
  }
}

// MARK: - Array Extension

extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

// MARK: - NSTableViewDataSource

extension VersionListViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return displayedVersions.count
  }
}

// MARK: - NSTableViewDelegate

extension VersionListViewController: NSTableViewDelegate {
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

      // Set content hugging and compression resistance
      textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
      textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

      cell?.textField = textField
      cell?.addSubview(textField)

      // Pin to edges with better padding for Finder-style appearance
      textField.snp.makeConstraints { make in
        make.left.equalToSuperview().offset(4)
        make.right.equalToSuperview().offset(-4)
        make.centerY.equalToSuperview()
      }
    }

    // Configure the text field for this specific cell
    guard let textField = cell?.textField else { return cell }

    // Reset to defaults with larger font for Finder-style appearance
    textField.font = .systemFont(ofSize: 13)
    textField.textColor = .labelColor
    textField.alignment = .left

    // Set content based on column
    switch identifier.rawValue {
    case "version":
      let emoji = getVersionEmoji(for: version.type)
      textField.stringValue = "\(emoji) \(version.id)"
      textField.font = .systemFont(ofSize: 13, weight: .medium)

    case "type":
      textField.stringValue = version.type.displayName
      textField.textColor = getTypeColor(for: version.type)
      textField.font = .systemFont(ofSize: 13, weight: .semibold)

    case "releaseTime":
      textField.stringValue = formatDateTime(version.releaseTime)
      textField.textColor = .secondaryLabelColor
      textField.font = .systemFont(ofSize: 13)

    case "time":
      textField.stringValue = formatDateTime(version.time)
      textField.textColor = NSColor.secondaryLabelColor.withAlphaComponent(0.8)
      textField.font = .systemFont(ofSize: 13)

    default:
      textField.stringValue = ""
    }

    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let row = versionTableView.selectedRow
    if row >= 0 && row < displayedVersions.count {
      let version = displayedVersions[row]
      selectedVersion = version
      logMessage(Localized.LogMessages.selectedVersion(version.id))
    }
  }

  // Custom row height for Finder-style appearance
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return 24.0
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
  // swiftlint:disable:next file_length
}
