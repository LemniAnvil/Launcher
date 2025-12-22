//
//  JavaDetectionViewController.swift
//  Launcher
//
//  View controller for Java detection and management
//

import AppKit
import SnapKit
import Yatagarasu

class JavaDetectionViewController: NSViewController {
  // swiftlint:disable:previous type_body_length

  // MARK: - Dependency Injection

  private let javaManager: JavaManaging
  private let logger = Logger.shared

  // Using diffable data source for smooth updates
  private var dataSource: NSTableViewDiffableDataSource<Section, JavaInstallation>?
  private var selectedInstallation: JavaInstallation?
  private var isFirstLoad = true

  // Section for diffable data source
  enum Section: CaseIterable {
    case main
  }

  // MARK: - Initialization

  /// Dependency injection via constructor
  /// Provides default parameter for backward compatibility
  init(javaManager: JavaManaging = JavaManager.shared) {
    self.javaManager = javaManager
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UI Elements

  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.JavaDetection.title,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let subtitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.JavaDetection.subtitle,
      font: .systemFont(ofSize: 12, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var detectButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "magnifyingglass",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.JavaDetection.detectButton
    )
    button.target = self
    button.action = #selector(detectJava)
    return button
  }()

  private lazy var refreshButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.clockwise",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.JavaDetection.refreshButton
    )
    button.target = self
    button.action = #selector(refreshDetection)
    return button
  }()

  private lazy var javaTableView: NSTableView = {
    let table = NSTableView()
    table.style = .plain
    table.rowSizeStyle = .default
    table.usesAlternatingRowBackgroundColors = true
    table.allowsEmptySelection = false
    table.allowsMultipleSelection = false
    table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

    // Path column
    let pathColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("path"))
    pathColumn.title = Localized.JavaDetection.columnPath
    pathColumn.width = 300
    pathColumn.minWidth = 200
    table.addTableColumn(pathColumn)

    // Version column
    let versionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("version"))
    versionColumn.title = Localized.JavaDetection.columnVersion
    versionColumn.width = 80
    versionColumn.minWidth = 80
    table.addTableColumn(versionColumn)

    // Type column
    let typeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("type"))
    typeColumn.title = Localized.JavaDetection.columnType
    typeColumn.width = 100
    typeColumn.minWidth = 100
    table.addTableColumn(typeColumn)

    // Status column
    let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("status"))
    statusColumn.title = Localized.JavaDetection.columnStatus
    statusColumn.width = 30
    statusColumn.minWidth = 30
    table.addTableColumn(statusColumn)

    // DataSource will be set after configuration
    table.delegate = self

    return table
  }()

  private lazy var tableScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.documentView = javaTableView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    return scrollView
  }()

  private let statusLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.JavaDetection.statusReady,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let detailsLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 11),
      textColor: .labelColor,
      alignment: .left,
      lineBreakMode: .byWordWrapping,
      maximumNumberOfLines: 3
    )
    return label
  }()

  private let javaHomeLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .monospacedSystemFont(ofSize: 10, weight: .regular),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private let detailsSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureDiffableDataSource()
    updateJavaHomeLabel()

    // Start detection in background after UI is ready
    Task.detached(priority: .userInitiated) { [weak self] in
      await self?.performDetection()
    }
  }

  // MARK: - UI Setup

  private func setupUI() {
    // Add all UI elements
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(detectButton)
    view.addSubview(refreshButton)
    view.addSubview(headerSeparator)
    view.addSubview(tableScrollView)
    view.addSubview(detailsSeparator)
    view.addSubview(detailsLabel)
    view.addSubview(javaHomeLabel)
    view.addSubview(statusLabel)

    // Layout constraints
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
    }

    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    detectButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.width.height.equalTo(32)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.right.equalTo(detectButton.snp.left).offset(-8)
      make.width.height.equalTo(32)
    }

    headerSeparator.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    tableScrollView.snp.makeConstraints { make in
      make.top.equalTo(headerSeparator.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(300)
    }

    detailsSeparator.snp.makeConstraints { make in
      make.top.equalTo(tableScrollView.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    detailsLabel.snp.makeConstraints { make in
      make.top.equalTo(detailsSeparator.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    javaHomeLabel.snp.makeConstraints { make in
      make.top.equalTo(detailsLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    statusLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalToSuperview().offset(-10)
    }
  }

  // MARK: - Diffable Data Source Configuration

  private func configureDiffableDataSource() {
    // Create diffable data source
    dataSource = NSTableViewDiffableDataSource<Section, JavaInstallation>(
      tableView: javaTableView
    ) { [weak self] tableView, tableColumn, row, installation in
      return self?.configureCell(
        for: tableView,
        tableColumn: tableColumn,
        row: row,
        installation: installation
      ) ?? NSView()
    }
  }

  // MARK: - Actions

  @objc private func detectJava() {
    Task.detached(priority: .userInitiated) { [weak self] in
      await self?.performDetection()
    }
  }

  @objc private func refreshDetection() {
    Task.detached(priority: .userInitiated) { [weak self] in
      await self?.performDetection()
    }
  }

  private func performDetection() async {
    // Update UI on main thread immediately
    await MainActor.run {
      statusLabel.stringValue = Localized.JavaDetection.statusDetecting
      detailsLabel.stringValue = ""
    }

    // Clear current data with animation
    await MainActor.run {
      applySnapshot(with: [], animated: false)
    }

    // Perform heavy detection work in background
    let installations = await javaManager.detectJavaInstallations()

    // Update UI with results on main thread
    await MainActor.run {
      handleDetectionResults(installations)
    }
  }

  private func handleDetectionResults(_ installations: [JavaInstallation]) {
    // First load: no animation for instant display
    // Subsequent loads: smooth animation for better UX
    applySnapshot(with: installations, animated: !isFirstLoad)
    isFirstLoad = false

    if installations.isEmpty {
      statusLabel.stringValue = Localized.JavaDetection.statusNoJavaFound
      detailsLabel.stringValue = Localized.JavaDetection.noJavaMessage
    } else {
      statusLabel.stringValue = Localized.JavaDetection.statusFoundJava(installations.count)
      detailsLabel.stringValue = ""

      // Auto-select first valid installation
      if let firstValid = installations.first(where: { $0.isValid }),
        let index = installations.firstIndex(where: { $0.id == firstValid.id })
      {
        javaTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        selectedInstallation = firstValid
        updateDetailsForSelectedJava()
      }
    }
  }

  private func updateDetailsForSelectedJava() {
    guard let installation = selectedInstallation else {
      detailsLabel.stringValue = ""
      return
    }

    let validation = javaManager.validateJavaForMinecraft(installation)
    let validationIcon = validation.isValid ? "✅" : "⚠️"

    detailsLabel.stringValue = """
      \(validationIcon) \(validation.message)
      Path: \(installation.path)
      """
  }

  private func updateJavaHomeLabel() {
    if let javaHome = javaManager.getJavaHome() {
      javaHomeLabel.stringValue = "JAVA_HOME: \(javaHome)"
    } else {
      javaHomeLabel.stringValue = "JAVA_HOME: Not set"
    }
  }
}

// MARK: - Data Management

extension JavaDetectionViewController {
  fileprivate func applySnapshot(with installations: [JavaInstallation], animated: Bool = true) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, JavaInstallation>()
    snapshot.appendSections([.main])
    snapshot.appendItems(installations, toSection: .main)

    dataSource?.apply(snapshot, animatingDifferences: animated)
  }

  fileprivate func configureCell(
    for tableView: NSTableView,
    tableColumn: NSTableColumn,
    row: Int,
    installation: JavaInstallation
  ) -> NSView? {
    let identifier = tableColumn.identifier
    let cellIdentifier = NSUserInterfaceItemIdentifier("JavaCell")

    var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

    if cell == nil {
      cell = NSTableCellView()
      cell?.identifier = cellIdentifier

      let textField = NSTextField()
      textField.isBordered = false
      textField.drawsBackground = false
      textField.isEditable = false
      textField.isSelectable = false
      textField.lineBreakMode = .byTruncatingMiddle
      textField.usesSingleLineMode = true

      cell?.textField = textField
      cell?.addSubview(textField)

      textField.snp.makeConstraints { make in
        make.left.equalToSuperview().offset(4)
        make.right.equalToSuperview().offset(-4)
        make.centerY.equalToSuperview()
      }
    }

    guard let textField = cell?.textField else { return cell }

    // Reset styles
    textField.font = .systemFont(ofSize: 11)
    textField.textColor = .labelColor
    textField.alignment = .left

    // Set content based on column
    switch identifier.rawValue {
    case "path":
      textField.stringValue = installation.path
      textField.toolTip = installation.path

    case "version":
      textField.stringValue = installation.version
      textField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

    case "type":
      textField.stringValue = installation.type.rawValue
      textField.textColor = .secondaryLabelColor

    case "status":
      let statusIcon = installation.isValid ? "✅" : "❌"
      textField.stringValue = statusIcon
      textField.alignment = .center

    default:
      textField.stringValue = ""
    }

    return cell
  }
}

// MARK: - NSTableViewDelegate

extension JavaDetectionViewController: NSTableViewDelegate {
  func tableViewSelectionDidChange(_ notification: Notification) {
    let row = javaTableView.selectedRow
    guard row >= 0, let dataSource = dataSource else { return }

    // Get installation from diffable data source
    let snapshot = dataSource.snapshot()
    let items = snapshot.itemIdentifiers(inSection: .main)

    if row < items.count {
      selectedInstallation = items[row]
      updateDetailsForSelectedJava()
    }
  }
}
