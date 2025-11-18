//
//  AddInstanceViewController.swift
//  Launcher
//
//  View controller for adding new instances
//  Inspired by MultiMC and Prism Launcher UI
//

import AppKit
import SnapKit
import Yatagarasu

class AddInstanceViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  var onInstanceCreated: ((Instance) -> Void)?
  var onCancel: (() -> Void)?

  private let instanceManager = InstanceManager.shared
  private let versionManager = VersionManager.shared
  private let modLoaderManager = ModLoaderManager.shared
  private var selectedVersionId: String?
  private var selectedModLoader: ModLoader = .NONE
  private var selectedModLoaderVersion: String?
  private var availableModLoaderVersions: [String] = []

  // MARK: - Enums & Models

  enum Section: Hashable {
    case main
  }

  enum InstanceCategory: String, CaseIterable, Hashable {
    case custom
    case import1
    case atLauncher
    case curseForge
    case ftbLegacy
    case ftbImport
    case modrinth
    case technic

    var displayName: String {
      switch self {
      case .custom: return Localized.AddInstance.categoryCustom
      case .import1: return Localized.AddInstance.categoryImport
      case .atLauncher: return "ATLauncher"
      case .curseForge: return "CurseForge"
      case .ftbLegacy: return "FTB Legacy"
      case .ftbImport: return Localized.AddInstance.categoryFTBImport
      case .modrinth: return "Modrinth"
      case .technic: return "Technic"
      }
    }

    var iconName: String {
      switch self {
      case .custom: return "cube.fill"
      case .import1: return "folder.fill"
      case .atLauncher: return "rocket.fill"
      case .curseForge: return "flame.fill"
      case .ftbLegacy: return "f.square.fill"
      case .ftbImport: return "f.square"
      case .modrinth: return "m.square.fill"
      case .technic: return "t.square.fill"
      }
    }
  }

  // Version data model
  struct VersionItem: Hashable {
    let version: MinecraftVersion

    var id: String { version.id }
    var releaseDate: String { Self.formatDateTime(version.releaseTime) }
    var type: String { version.type.displayName }
    var versionType: VersionType { version.type }

    func hash(into hasher: inout Hasher) {
      hasher.combine(version.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.version.id == rhs.version.id
    }

    private static func formatDateTime(_ dateString: String) -> String {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      guard let date = formatter.date(from: dateString) else {
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else {
          return dateString
        }
        return Self.formatDateDisplay(date)
      }

      return Self.formatDateDisplay(date)
    }

    private static func formatDateDisplay(_ date: Date) -> String {
      let displayFormatter = DateFormatter()
      displayFormatter.dateFormat = "yyyy-MM-dd"
      displayFormatter.locale = Locale.current
      displayFormatter.timeZone = TimeZone.current
      return displayFormatter.string(from: date)
    }
  }

  // Loader version data model
  struct LoaderVersionItem: Hashable {
    let versionId: String

    var id: String { versionId }

    func hash(into hasher: inout Hasher) {
      hasher.combine(versionId)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.versionId == rhs.versionId
    }
  }

  enum ModLoader: String, CaseIterable {
    case NONE
    case neoForge
    case forge
    case fabric
    case quilt
    case liteLoader

    var displayName: String {
      switch self {
      case .NONE: return Localized.AddInstance.modLoaderNone
      case .neoForge: return "NeoForge"
      case .forge: return "Forge"
      case .fabric: return "Fabric"
      case .quilt: return "Quilt"
      case .liteLoader: return "LiteLoader"
      }
    }
  }

  private var selectedCategory: InstanceCategory = .custom

  // MARK: - DiffableDataSource

  private var categoryDataSource: NSTableViewDiffableDataSource<Section, InstanceCategory>?

  // MARK: - UI Components

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.imageScaling = .scaleProportionallyUpOrDown
    let config = NSImage.SymbolConfiguration(pointSize: 60, weight: .regular)
    let image = NSImage(
      systemSymbolName: "cube.fill",
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let nameLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.nameLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var nameTextField: NSTextField = {
    let field = NSTextField()
    field.placeholderString = Localized.AddInstance.namePlaceholder
    field.font = .systemFont(ofSize: 13)
    field.lineBreakMode = .byTruncatingTail
    return field
  }()

  private let groupLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.groupLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var groupPopUpButton: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = .systemFont(ofSize: 13)
    button.addItem(withTitle: Localized.AddInstance.groupUncategorized)
    return button
  }()

  private lazy var categoryTableView: NSTableView = {
    let tableView = NSTableView()
    tableView.rowHeight = 44
    tableView.headerView = nil
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.intercellSpacing = NSSize(width: 0, height: 0)
    tableView.delegate = self

    let column = NSTableColumn(
      identifier: NSUserInterfaceItemIdentifier("CategoryColumn")
    )
    column.width = 180
    tableView.addTableColumn(column)

    return tableView
  }()

  private let categoryScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = NSColor.controlBackgroundColor
    scrollView.wantsLayer = true
    scrollView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    scrollView.layer?.cornerRadius = 8
    scrollView.layer?.borderWidth = 1
    scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
    return scrollView
  }()

  private let instanceInfoView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private let customContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private lazy var importContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var atLauncherContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var curseForgeContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var ftbLegacyContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var ftbImportContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var modrinthContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var technicContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private let versionTitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.customTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let filterLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.filterLabel,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var releaseCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterRelease,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .on
    button.font = .systemFont(ofSize: 12)
    return button
  }()

  private lazy var snapshotCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterSnapshot,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = .systemFont(ofSize: 12)
    return button
  }()

  private lazy var betaCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterBeta,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = .systemFont(ofSize: 12)
    return button
  }()

  private lazy var alphaCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterAlpha,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = .systemFont(ofSize: 12)
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
      accessibilityLabel: Localized.AddInstance.refreshButton
    )
    button.target = self
    button.action = #selector(refreshVersions)
    return button
  }()

  private lazy var versionTableView: VersionTableView<VersionItem> = {
    let columns: [VersionTableView<VersionItem>.ColumnConfig] = [
      .init(
        identifier: "VersionColumn",
        title: Localized.AddInstance.columnVersion,
        width: 120,
        valueProvider: { $0.id },
        fontProvider: { _ in .systemFont(ofSize: 13, weight: .medium) },
        colorProvider: { _ in .labelColor }
      ),
      .init(
        identifier: "ReleaseColumn",
        title: Localized.AddInstance.columnRelease,
        width: 120,
        valueProvider: { $0.releaseDate },
        fontProvider: { _ in .systemFont(ofSize: 13) },
        colorProvider: { _ in .secondaryLabelColor }
      ),
      .init(
        identifier: "TypeColumn",
        title: Localized.AddInstance.columnType,
        width: 100,
        valueProvider: { $0.type },
        fontProvider: { _ in .systemFont(ofSize: 13, weight: .semibold) },
        colorProvider: { [weak self] item in
          self?.getTypeColor(for: item.versionType) ?? .labelColor
        }
      ),
    ]

    let tableView = VersionTableView<VersionItem>(
      columns: columns,
      onSelectionChanged: { [weak self] item in
        self?.selectedVersionId = item?.id
        if let versionId = item?.id {
          self?.updateNameFromVersion(versionId)
          if self?.selectedModLoader != .NONE {
            self?.loadModLoaderVersions()
          }
        }
      }
    )
    return tableView
  }()

  private let modLoaderLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderTitle,
      font: .systemFont(ofSize: 14, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let versionModLoaderSeparator: BRSeparator = BRSeparator(type: .horizontal)

  private let modLoaderPlaceholder: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderPlaceholder,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = false  // Show initially when no mod loader selected (NONE is default)
    return label
  }()

  private let modLoaderVersionPlaceholder: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderVersionPlaceholder,
      font: .systemFont(ofSize: 13),
      textColor: .tertiaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true  // Hide initially (only show when mod loader is selected but no versions available)
    return label
  }()

  private lazy var modLoaderDescriptionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderDescription,
      font: .systemFont(ofSize: 11),
      textColor: .tertiaryLabelColor,
      alignment: .left
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true
    return label
  }()

  private lazy var modLoaderVersionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderVersionLabel,
      font: .systemFont(ofSize: 12, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    // Always show label
    label.isHidden = false
    return label
  }()

  private lazy var modLoaderVersionTableView: VersionTableView<LoaderVersionItem> = {
    let columns: [VersionTableView<LoaderVersionItem>.ColumnConfig] = [
      .init(
        identifier: "LoaderVersionColumn",
        title: Localized.AddInstance.loaderVersionColumn,
        width: 220,
        valueProvider: { $0.id },
        fontProvider: { _ in .systemFont(ofSize: 13) },
        colorProvider: { _ in .labelColor }
      ),
    ]

    let tableView = VersionTableView<LoaderVersionItem>(
      columns: columns,
      onSelectionChanged: { [weak self] item in
        self?.selectedModLoaderVersion = item?.id
      }
    )
    // Always show table (placeholder will overlay when needed)
    tableView.isHidden = false
    return tableView
  }()

  private lazy var modLoaderVersionLoadingIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.controlSize = .small
    indicator.isHidden = true
    return indicator
  }()

  private lazy var modLoaderRadioButtons: [NSButton] = {
    return ModLoader.allCases.map { loader in
      let button = NSButton(
        radioButtonWithTitle: loader.displayName,
        target: self,
        action: #selector(modLoaderChanged)
      )
      button.font = .systemFont(ofSize: 12)
      if loader == .NONE {
        button.state = .on
      }
      return button
    }
  }()

  private let modLoaderRefreshButton: NSButton = {
    let button = NSButton(
      title: Localized.AddInstance.refreshButton,
      target: nil,
      action: nil
    )
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var helpButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "questionmark.circle",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.AddInstance.helpButton
    )
    button.target = self
    button.action = #selector(showHelp)
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton(
      title: Localized.AddInstance.cancelButton,
      target: self,
      action: #selector(cancel)
    )
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    return button
  }()

  private lazy var confirmButton: NSButton = {
    let button = NSButton(
      title: Localized.AddInstance.confirmButton,
      target: self,
      action: #selector(createInstance)
    )
    button.bezelStyle = .rounded
    button.keyEquivalent = "\r"
    return button
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupDataSources()
    setupUI()
    loadInitialData()
  }

  // MARK: - Setup DataSources

  private func setupDataSources() {
    // Setup category list DataSource
    categoryDataSource = NSTableViewDiffableDataSource<
      Section, InstanceCategory
    >(
      tableView: categoryTableView
    ) { [weak self] _, _, _, category in
      guard let self = self else { return NSView() }
      return self.makeCategoryCell(for: category)
    }
  }

  // MARK: - Cell Factories

  private func makeCategoryCell(for category: InstanceCategory) -> NSView {
    let cellView = NSTableCellView()

    let imageView = NSImageView()
    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    let image = NSImage(
      systemSymbolName: category.iconName,
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .labelColor

    let textField = NSTextField(labelWithString: category.displayName)
    textField.font = .systemFont(ofSize: 13)
    textField.lineBreakMode = .byTruncatingTail

    cellView.addSubview(imageView)
    cellView.addSubview(textField)

    imageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(8)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(20)
    }

    textField.snp.makeConstraints { make in
      make.left.equalTo(imageView.snp.right).offset(8)
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-8)
    }

    return cellView
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

  // MARK: - Data Loading

  private func loadInitialData() {
    // Load category data
    updateCategoryData()

    // Load version data
    loadInstalledVersions()

    // Select first category
    categoryTableView.selectRowIndexes(
      IndexSet(integer: 0),
      byExtendingSelection: false
    )
  }

  private func updateCategoryData() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, InstanceCategory>()
    snapshot.appendSections([.main])
    snapshot.appendItems(InstanceCategory.allCases, toSection: .main)
    categoryDataSource?.apply(snapshot, animatingDifferences: false)
  }

  private func loadInstalledVersions() {
    // Load versions from version manager
    Task {
      // If version manager has no versions, try to refresh
      if versionManager.versions.isEmpty {
        do {
          try await versionManager.refreshVersionList()
        } catch {
          // Failed to refresh, just continue
          print("Failed to refresh version list: \(error)")
        }
      }

      await MainActor.run {
        applyVersionFilter()
      }
    }
  }

  private func applyVersionFilter() {
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

    // Filter versions by type
    let versions: [MinecraftVersion]
    if selectedTypes.isEmpty {
      versions = versionManager.versions
    } else {
      versions = versionManager.versions.filter { version in
        selectedTypes.contains(version.type)
      }
    }

    // Convert to VersionItem and update table
    let versionItems = versions.map { VersionItem(version: $0) }
    versionTableView.updateItems(versionItems)

    // Select first item if available
    if !versionItems.isEmpty, versionTableView.selectedItem == nil {
      versionTableView.selectItem(at: 0)
      selectedVersionId = versionItems[0].id
      // Auto-update name from first version
      updateNameFromVersion(versionItems[0].id)
    }
  }

  // MARK: - Setup UI

  private func setupUI() {
    view.addSubview(categoryScrollView)
    view.addSubview(instanceInfoView)
    view.addSubview(customContentView)
    view.addSubview(importContentView)
    view.addSubview(atLauncherContentView)
    view.addSubview(curseForgeContentView)
    view.addSubview(ftbLegacyContentView)
    view.addSubview(ftbImportContentView)
    view.addSubview(modrinthContentView)
    view.addSubview(technicContentView)
    view.addSubview(helpButton)
    view.addSubview(cancelButton)
    view.addSubview(confirmButton)

    categoryScrollView.documentView = categoryTableView
    setupInstanceInfoView()
    setupCustomContentView()
    setupOtherContentViews()

    categoryScrollView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(180)
      make.bottom.equalTo(helpButton.snp.top).offset(-20)
    }

    instanceInfoView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalTo(categoryScrollView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(140)
    }

    // Setup constraints for all content views to occupy the same space
    let contentViews = [
      customContentView,
      importContentView,
      atLauncherContentView,
      curseForgeContentView,
      ftbLegacyContentView,
      ftbImportContentView,
      modrinthContentView,
      technicContentView
    ]

    for contentView in contentViews {
      contentView.snp.makeConstraints { make in
        make.top.equalTo(instanceInfoView.snp.bottom).offset(20)
        make.left.equalTo(categoryScrollView.snp.right).offset(20)
        make.right.equalToSuperview().offset(-20)
        make.bottom.equalTo(cancelButton.snp.top).offset(-20)
      }
    }

    helpButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(20)
      make.width.height.equalTo(32)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalTo(confirmButton.snp.left).offset(-12)
      make.width.equalTo(100)
    }

    confirmButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(100)
    }
  }

  private func setupInstanceInfoView() {
    instanceInfoView.addSubview(iconImageView)
    instanceInfoView.addSubview(nameLabel)
    instanceInfoView.addSubview(nameTextField)
    instanceInfoView.addSubview(groupLabel)
    instanceInfoView.addSubview(groupPopUpButton)

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.width.height.equalTo(100)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(30)
      make.left.equalTo(iconImageView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    nameTextField.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(8)
      make.left.equalTo(iconImageView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(28)
    }

    groupLabel.snp.makeConstraints { make in
      make.top.equalTo(nameTextField.snp.bottom).offset(16)
      make.left.equalTo(iconImageView.snp.right).offset(20)
      make.width.equalTo(60)
    }

    groupPopUpButton.snp.makeConstraints { make in
      make.centerY.equalTo(groupLabel)
      make.left.equalTo(groupLabel.snp.right).offset(8)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(24)
    }
  }

  private func setupCustomContentView() {
    customContentView.addSubview(versionTitleLabel)
    customContentView.addSubview(filterLabel)
    customContentView.addSubview(releaseCheckbox)
    customContentView.addSubview(snapshotCheckbox)
    customContentView.addSubview(betaCheckbox)
    customContentView.addSubview(alphaCheckbox)
    customContentView.addSubview(refreshButton)
    customContentView.addSubview(versionTableView)
    customContentView.addSubview(versionModLoaderSeparator)
    customContentView.addSubview(modLoaderLabel)
    customContentView.addSubview(modLoaderDescriptionLabel)
    customContentView.addSubview(modLoaderVersionLabel)
    customContentView.addSubview(modLoaderVersionTableView)
    // Add placeholders after table so they overlay on top
    customContentView.addSubview(modLoaderPlaceholder)
    customContentView.addSubview(modLoaderVersionPlaceholder)
    customContentView.addSubview(modLoaderVersionLoadingIndicator)
    customContentView.addSubview(modLoaderRefreshButton)

    for button in modLoaderRadioButtons {
      customContentView.addSubview(button)
    }

    // Version section (top half) - Filters on left, Table on right
    versionTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.left.equalToSuperview().offset(10)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalTo(alphaCheckbox.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(10)
      make.width.height.equalTo(32)
    }

    filterLabel.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(120)
    }

    releaseCheckbox.snp.makeConstraints { make in
      make.top.equalTo(filterLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(120)
    }

    snapshotCheckbox.snp.makeConstraints { make in
      make.top.equalTo(releaseCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(120)
    }

    betaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(snapshotCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(120)
    }

    alphaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(betaCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(120)
    }

    versionTableView.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(150)
      make.right.equalToSuperview().offset(-10)
      make.height.equalTo(250)  // Fixed height for version list
    }

    // Horizontal separator between version and mod loader sections
    versionModLoaderSeparator.snp.makeConstraints { make in
      make.top.equalTo(versionTableView.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-10)
      make.height.equalTo(1)
    }

    // Mod Loader section (bottom half) - Options on left, Table on right
    modLoaderLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(200)
    }

    modLoaderDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(modLoaderLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(200)
    }

    var previousButton: NSButton?
    for button in modLoaderRadioButtons {
      button.snp.makeConstraints { make in
        if let previous = previousButton {
          make.top.equalTo(previous.snp.bottom).offset(8)
        } else {
          make.top.equalTo(modLoaderDescriptionLabel.snp.bottom).offset(16)
        }
        make.left.equalToSuperview().offset(10)
        make.width.equalTo(200)
      }
      previousButton = button
    }

    modLoaderVersionLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(150)
      make.right.equalToSuperview().offset(-10)
    }

    modLoaderVersionTableView.snp.makeConstraints { make in
      make.top.equalTo(modLoaderVersionLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(150)
      make.right.equalToSuperview().offset(-10)
      make.bottom.equalToSuperview().offset(-10)
    }

    modLoaderPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(240)
    }

    modLoaderVersionPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(280)
    }

    modLoaderVersionLoadingIndicator.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.height.equalTo(16)
    }

    modLoaderRefreshButton.snp.makeConstraints { make in
      make.top.equalTo(modLoaderRadioButtons.last!.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(10)
      make.width.equalTo(100)
    }
  }

  private func setupOtherContentViews() {
    // Setup placeholder content for other views
    setupPlaceholderContent(for: importContentView, title: Localized.AddInstance.categoryImport)
    setupPlaceholderContent(for: atLauncherContentView, title: "ATLauncher")
    setupPlaceholderContent(for: curseForgeContentView, title: "CurseForge")
    setupPlaceholderContent(for: ftbLegacyContentView, title: "FTB Legacy")
    setupPlaceholderContent(for: ftbImportContentView, title: Localized.AddInstance.categoryFTBImport)
    setupPlaceholderContent(for: modrinthContentView, title: "Modrinth")
    setupPlaceholderContent(for: technicContentView, title: "Technic")
  }

  private func setupPlaceholderContent(for contentView: NSView, title: String) {
    let titleLabel = BRLabel(
      text: title,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )

    let comingSoonLabel = BRLabel(
      text: "Coming Soon",
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )

    contentView.addSubview(titleLabel)
    contentView.addSubview(comingSoonLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-20)
    }

    comingSoonLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
    }
  }

  // MARK: - Actions

  @objc private func filterChanged() {
    applyVersionFilter()
  }

  @objc private func refreshVersions() {
    refreshButton.isEnabled = false

    Task {
      do {
        try await versionManager.refreshVersionList()

        await MainActor.run {
          applyVersionFilter()
          refreshButton.isEnabled = true
        }
      } catch {
        await MainActor.run {
          print("Failed to refresh versions: \(error)")
          refreshButton.isEnabled = true

          // Show error alert
          let alert = NSAlert()
          alert.messageText = Localized.AddInstance.alertFailedToRefresh
          alert.informativeText = error.localizedDescription
          alert.alertStyle = .warning
          alert.addButton(withTitle: Localized.AddInstance.okButton)

          if let window = view.window {
            alert.beginSheetModal(for: window)
          } else {
            alert.runModal()
          }
        }
      }
    }
  }

  @objc private func modLoaderChanged() {
    for (index, button) in modLoaderRadioButtons.enumerated() where button.state == .on {
      selectedModLoader = ModLoader.allCases[index]
      break
    }

    // Show/hide description label
    modLoaderDescriptionLabel.isHidden = (selectedModLoader == .NONE)

    // Load mod loader versions when a mod loader is selected
    if selectedModLoader != .NONE {
      // Hide the "select mod loader" placeholder (overlay)
      modLoaderPlaceholder.isHidden = true
      // Hide version placeholder initially (will show if loading fails)
      modLoaderVersionPlaceholder.isHidden = true
      // Load versions
      loadModLoaderVersions()
    } else {
      // Show the "select mod loader" placeholder (overlay on table)
      modLoaderPlaceholder.isHidden = false
      // Hide the "select version" placeholder (not applicable when NONE is selected)
      modLoaderVersionPlaceholder.isHidden = true
      // Clear data
      modLoaderVersionTableView.updateItems([])
      availableModLoaderVersions = []
      selectedModLoaderVersion = nil
    }
  }

  private func loadModLoaderVersions() {
    guard let minecraftVersion = selectedVersionId,
          selectedModLoader != .NONE else {
      return
    }

    // Show loading indicator and hide placeholder
    modLoaderVersionLoadingIndicator.isHidden = false
    modLoaderVersionLoadingIndicator.startAnimation(nil)
    modLoaderVersionPlaceholder.isHidden = true
    modLoaderVersionTableView.tableView.isEnabled = false

    Task {
      do {
        let loader = try modLoaderManager.getModLoader(id: selectedModLoader.rawValue)
        let versions = try await loader.getLoaderVersions(
          minecraftVersion: minecraftVersion,
          stableOnly: true
        )

        await MainActor.run {
          self.availableModLoaderVersions = versions
          let loaderItems = versions.map { LoaderVersionItem(versionId: $0) }

          if !loaderItems.isEmpty {
            self.modLoaderVersionTableView.updateItems(loaderItems)
            self.modLoaderVersionTableView.selectItem(at: 0)
            self.selectedModLoaderVersion = versions[0]
            self.modLoaderVersionLabel.isHidden = false
            self.modLoaderVersionTableView.isHidden = false
          } else {
            self.modLoaderVersionTableView.updateItems([])
            self.selectedModLoaderVersion = nil
            self.modLoaderVersionLabel.isHidden = false
            self.modLoaderVersionTableView.isHidden = false
          }

          self.modLoaderVersionLoadingIndicator.stopAnimation(nil)
          self.modLoaderVersionLoadingIndicator.isHidden = true
          self.modLoaderVersionTableView.tableView.isEnabled = true
        }
      } catch {
        await MainActor.run {
          print("Failed to load mod loader versions: \(error)")
          self.modLoaderVersionTableView.updateItems([])
          self.modLoaderVersionLoadingIndicator.stopAnimation(nil)
          self.modLoaderVersionLoadingIndicator.isHidden = true
          self.modLoaderVersionPlaceholder.isHidden = false
          self.modLoaderVersionTableView.tableView.isEnabled = false

          // Error alert removed - silently fail and show placeholder instead
        }
      }
    }
  }

  @objc private func showHelp() {
    guard let url = URL(string: "https://github.com/LemniAnvil/Launcher/wiki") else { return }
    NSWorkspace.shared.open(url)
  }

  @objc private func cancel() {
    onCancel?()
    view.window?.close()
  }

  @objc private func createInstance() {
    guard
      let name = nameTextField.stringValue.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).nonEmpty
    else {
      showError(Localized.AddInstance.errorEmptyName)
      return
    }

    guard let selectedVersion = selectedVersionId else {
      showError(Localized.AddInstance.errorNoVersionSelected)
      return
    }

    do {
      // Get selected mod loader
      let modLoaderString = selectedModLoader == .NONE ? nil : selectedModLoader.rawValue

      let instance = try instanceManager.createInstance(
        name: name,
        versionId: selectedVersion,
        modLoader: modLoaderString
      )
      onInstanceCreated?(instance)
      view.window?.close()
    } catch {
      showError(error.localizedDescription)
    }
  }

  private func showError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.AddInstance.errorTitle
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.AddInstance.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}

// MARK: - NSTableViewDelegate

extension AddInstanceViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    if notification.object as? NSTableView == categoryTableView {
      let row = categoryTableView.selectedRow
      if row >= 0, let category = categoryDataSource?.itemIdentifier(forRow: row) {
        selectedCategory = category
        updateContentView()
      }
    }
  }

  /// Update name field from selected version if appropriate
  private func updateNameFromVersion(_ versionId: String) {
    let currentName = nameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    // Update name if:
    // 1. Name field is empty, OR
    // 2. Current name matches a version ID pattern (likely auto-filled before)
    //    Check if current name matches any version in the version manager
    let isCurrentNameAVersionId = versionManager.versions.contains { $0.id == currentName }

    let shouldUpdate = currentName.isEmpty || isCurrentNameAVersionId

    if shouldUpdate {
      nameTextField.stringValue = versionId
    }
  }

  private func updateContentView() {
    // Hide all content views first
    customContentView.isHidden = true
    importContentView.isHidden = true
    atLauncherContentView.isHidden = true
    curseForgeContentView.isHidden = true
    ftbLegacyContentView.isHidden = true
    ftbImportContentView.isHidden = true
    modrinthContentView.isHidden = true
    technicContentView.isHidden = true

    // Update icon based on selected category
    let config = NSImage.SymbolConfiguration(pointSize: 60, weight: .regular)
    let image = NSImage(
      systemSymbolName: selectedCategory.iconName,
      accessibilityDescription: nil
    )
    iconImageView.image = image?.withSymbolConfiguration(config)

    // Update icon color and show appropriate content view
    switch selectedCategory {
    case .custom:
      iconImageView.contentTintColor = .systemGreen
      customContentView.isHidden = false
    case .import1:
      iconImageView.contentTintColor = .systemBlue
      importContentView.isHidden = false
    case .atLauncher:
      iconImageView.contentTintColor = .systemOrange
      atLauncherContentView.isHidden = false
    case .curseForge:
      iconImageView.contentTintColor = .systemRed
      curseForgeContentView.isHidden = false
    case .ftbLegacy:
      iconImageView.contentTintColor = .systemPurple
      ftbLegacyContentView.isHidden = false
    case .ftbImport:
      iconImageView.contentTintColor = .systemPurple
      ftbImportContentView.isHidden = false
    case .modrinth:
      iconImageView.contentTintColor = .systemGreen
      modrinthContentView.isHidden = false
    case .technic:
      iconImageView.contentTintColor = .systemIndigo
      technicContentView.isHidden = false
    }
  }
}

// MARK: - String Extension

extension String {
  fileprivate var nonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
  // swiftlint:disable:next file_length
}
