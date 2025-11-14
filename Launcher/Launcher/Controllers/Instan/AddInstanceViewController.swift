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
  private var selectedVersionId: String?
  private var selectedModLoader: ModLoader = .NONE

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
  private var versionDataSource: NSTableViewDiffableDataSource<Section, VersionItem>?

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

  private let categoriesLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.categoriesTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
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
    scrollView.drawsBackground = false
    return scrollView
  }()

  private let customContentView: NSView = {
    let view = NSView()
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

  private let versionScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    return scrollView
  }()

  private lazy var versionTableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 36
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.intercellSpacing = NSSize(width: 0, height: 0)
    tableView.delegate = self

    let versionColumn = NSTableColumn(
      identifier: NSUserInterfaceItemIdentifier("VersionColumn")
    )
    versionColumn.title = Localized.AddInstance.columnVersion
    versionColumn.width = 120
    tableView.addTableColumn(versionColumn)

    let releaseColumn = NSTableColumn(
      identifier: NSUserInterfaceItemIdentifier("ReleaseColumn")
    )
    releaseColumn.title = Localized.AddInstance.columnRelease
    releaseColumn.width = 120
    tableView.addTableColumn(releaseColumn)

    let typeColumn = NSTableColumn(
      identifier: NSUserInterfaceItemIdentifier("TypeColumn")
    )
    typeColumn.title = Localized.AddInstance.columnType
    typeColumn.width = 100
    tableView.addTableColumn(typeColumn)

    return tableView
  }()

  private let modLoaderLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderTitle,
      font: .systemFont(ofSize: 14, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let modLoaderPlaceholder: BRLabel = {
    let label = BRLabel(
      text: Localized.AddInstance.modLoaderPlaceholder,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    return label
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

  private lazy var helpButton: NSButton = {
    let button = NSButton(
      title: Localized.AddInstance.helpButton,
      target: self,
      action: #selector(showHelp)
    )
    button.bezelStyle = .rounded
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
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
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

    // Setup version list DataSource
    versionDataSource = NSTableViewDiffableDataSource<Section, VersionItem>(
      tableView: versionTableView
    ) { [weak self] _, tableColumn, _, versionItem in
      guard let self = self else { return NSView() }
      return self.makeVersionCell(for: versionItem, column: tableColumn)
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

  private func makeVersionCell(
    for versionItem: VersionItem,
    column: NSTableColumn?
  ) -> NSView {
    let cellView = NSTableCellView()

    if column?.identifier.rawValue == "VersionColumn" {
      let textField = NSTextField(labelWithString: versionItem.id)
      textField.font = .systemFont(ofSize: 12, weight: .medium)
      cellView.addSubview(textField)
      textField.snp.makeConstraints { make in
        make.left.equalToSuperview().offset(8)
        make.centerY.equalToSuperview()
        make.right.lessThanOrEqualToSuperview().offset(-8).priority(.high)
      }
    } else if column?.identifier.rawValue == "ReleaseColumn" {
      let textField = NSTextField(labelWithString: versionItem.releaseDate)
      textField.font = .systemFont(ofSize: 12)
      textField.textColor = .secondaryLabelColor
      cellView.addSubview(textField)
      textField.snp.makeConstraints { make in
        make.left.equalToSuperview().offset(8)
        make.centerY.equalToSuperview()
        make.right.lessThanOrEqualToSuperview().offset(-8).priority(.high)
      }
    } else if column?.identifier.rawValue == "TypeColumn" {
      let textField = NSTextField(labelWithString: versionItem.type)
      textField.font = .systemFont(ofSize: 12, weight: .semibold)
      textField.textColor = getTypeColor(for: versionItem.versionType)
      cellView.addSubview(textField)
      textField.snp.makeConstraints { make in
        make.left.equalToSuperview().offset(8)
        make.centerY.equalToSuperview()
        make.right.lessThanOrEqualToSuperview().offset(-8).priority(.high)
      }
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

    // Convert to VersionItem and create snapshot
    let versionItems = versions.map { VersionItem(version: $0) }

    var snapshot = NSDiffableDataSourceSnapshot<Section, VersionItem>()
    snapshot.appendSections([.main])
    snapshot.appendItems(versionItems, toSection: .main)

    versionDataSource?.apply(snapshot, animatingDifferences: true)

    // Select first item if available
    if !versionItems.isEmpty && versionTableView.selectedRow < 0 {
      versionTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      selectedVersionId = versionItems[0].id
      if nameTextField.stringValue.isEmpty {
        nameTextField.stringValue = versionItems[0].id
      }
    }
  }

  // MARK: - Setup UI

  private func setupUI() {
    view.addSubview(iconImageView)
    view.addSubview(nameLabel)
    view.addSubview(nameTextField)
    view.addSubview(groupLabel)
    view.addSubview(groupPopUpButton)
    view.addSubview(categoriesLabel)
    view.addSubview(categoryScrollView)
    view.addSubview(customContentView)
    view.addSubview(helpButton)
    view.addSubview(cancelButton)
    view.addSubview(confirmButton)

    categoryScrollView.documentView = categoryTableView
    setupCustomContentView()

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(220)
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

    categoriesLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(20)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(180)
    }

    categoryScrollView.snp.makeConstraints { make in
      make.top.equalTo(categoriesLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(180)
      make.bottom.equalTo(helpButton.snp.top).offset(-20)
    }

    customContentView.snp.makeConstraints { make in
      make.top.equalTo(groupLabel.snp.bottom).offset(20)
      make.left.equalTo(categoryScrollView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
      make.bottom.equalTo(cancelButton.snp.top).offset(-20)
    }

    helpButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(80)
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

  private func setupCustomContentView() {
    customContentView.addSubview(versionTitleLabel)
    customContentView.addSubview(filterLabel)
    customContentView.addSubview(releaseCheckbox)
    customContentView.addSubview(snapshotCheckbox)
    customContentView.addSubview(betaCheckbox)
    customContentView.addSubview(alphaCheckbox)
    customContentView.addSubview(refreshButton)
    customContentView.addSubview(versionScrollView)
    customContentView.addSubview(modLoaderLabel)
    customContentView.addSubview(modLoaderPlaceholder)
    customContentView.addSubview(modLoaderRefreshButton)

    for button in modLoaderRadioButtons {
      customContentView.addSubview(button)
    }

    versionScrollView.documentView = versionTableView

    versionTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.left.equalToSuperview().offset(10)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-290)
      make.width.height.equalTo(32)
    }

    filterLabel.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(10)
    }

    releaseCheckbox.snp.makeConstraints { make in
      make.top.equalTo(filterLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(10)
    }

    snapshotCheckbox.snp.makeConstraints { make in
      make.top.equalTo(releaseCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
    }

    betaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(snapshotCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
    }

    alphaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(betaCheckbox.snp.bottom).offset(6)
      make.left.equalToSuperview().offset(10)
    }

    versionScrollView.snp.makeConstraints { make in
      make.top.equalTo(alphaCheckbox.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-290)
      make.bottom.equalToSuperview().offset(-10)
    }

    modLoaderLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(10)
      make.right.equalToSuperview().offset(-10)
      make.width.equalTo(270)
    }

    modLoaderPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderLabel)
      make.centerY.equalToSuperview()
      make.width.equalTo(220)
    }

    var previousButton: NSButton?
    for button in modLoaderRadioButtons {
      button.snp.makeConstraints { make in
        if let previous = previousButton {
          make.top.equalTo(previous.snp.bottom).offset(8)
        } else {
          make.top.equalTo(modLoaderLabel.snp.bottom).offset(16)
        }
        make.right.equalToSuperview().offset(-30)
      }
      previousButton = button
    }

    modLoaderRefreshButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-10)
      make.right.equalToSuperview().offset(-10)
      make.width.equalTo(100)
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
          alert.messageText = "Failed to Refresh"
          alert.informativeText = error.localizedDescription
          alert.alertStyle = .warning
          alert.addButton(withTitle: "OK")

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
  }

  @objc private func showHelp() {
    guard let url = URL(string: "https://minecraft.wiki") else { return }
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
      let instance = try instanceManager.createInstance(
        name: name,
        versionId: selectedVersion
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
    } else if notification.object as? NSTableView == versionTableView {
      let row = versionTableView.selectedRow
      if row >= 0,
        let versionItem = versionDataSource?.itemIdentifier(forRow: row) {
        selectedVersionId = versionItem.id
        if nameTextField.stringValue.isEmpty {
          nameTextField.stringValue = versionItem.id
        }
      }
    }
  }

  private func updateContentView() {
    // Update content view based on selected category
  }
}

// MARK: - String Extension

extension String {
  fileprivate var nonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

#Preview {
  AddInstanceViewController()
}
