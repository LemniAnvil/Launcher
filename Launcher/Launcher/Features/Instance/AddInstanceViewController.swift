//
//  AddInstanceViewController.swift
//  Launcher
//
//  View controller for adding new instances
//  Inspired by MultiMC and Prism Launcher UI
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

class AddInstanceViewController: NSViewController {

  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Size = DesignSystem.Size
  private typealias Width = DesignSystem.Width
  private typealias Height = DesignSystem.Height
  private typealias Fonts = DesignSystem.Fonts
  private typealias SymbolSize = DesignSystem.SymbolSize

  // MARK: - Properties

  var onInstanceCreated: ((Instance) -> Void)?
  var onCancel: (() -> Void)?

  private let instanceManager = InstanceManager.shared
  private let versionManager = VersionManager.shared

  private var selectedCategory: InstanceCategory = .custom

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
      case .custom: return BRIcons.version
      case .import1: return BRIcons.folder
      case .atLauncher: return "rocket.fill"
      case .curseForge: return "flame.fill"
      case .ftbLegacy: return "f.square.fill"
      case .ftbImport: return "f.square"
      case .modrinth: return "m.square.fill"
      case .technic: return "t.square.fill"
      }
    }
  }

  // MARK: - DiffableDataSource

  private var categoryDataSource: NSTableViewDiffableDataSource<Section, InstanceCategory>?

  // MARK: - UI Components

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
    scrollView.layer?.cornerRadius = Radius.standard
    scrollView.layer?.borderWidth = 1
    scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
    return scrollView
  }()

  private lazy var instanceInfoView = InstanceInfoView()

  private lazy var customInstanceView: CustomInstanceView = {
    let view = CustomInstanceView(
      versionManager: versionManager,
      modLoaderManager: ModLoaderManager.shared
    )
    return view
  }()

  private lazy var importContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: Localized.AddInstance.categoryImport)
    view.isHidden = true
    return view
  }()

  private lazy var atLauncherContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: "ATLauncher")
    view.isHidden = true
    return view
  }()

  private lazy var curseForgeView: CurseForgeView = {
    let view = CurseForgeView(curseForgeAPI: CurseForgeClientProvider.makeClient())
    view.isHidden = true
    return view
  }()

  private lazy var ftbLegacyContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: "FTB Legacy")
    view.isHidden = true
    return view
  }()

  private lazy var ftbImportContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: Localized.AddInstance.categoryFTBImport)
    view.isHidden = true
    return view
  }()

  private lazy var modrinthContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: "Modrinth")
    view.isHidden = true
    return view
  }()

  private lazy var technicContentView: PlaceholderContentView = {
    let view = PlaceholderContentView(title: "Technic")
    view.isHidden = true
    return view
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
    customInstanceView.onVersionSelected = { [weak self] versionId in
      self?.updateNameFromVersion(versionId)
    }
    loadInitialData()
  }

  // MARK: - Setup DataSources

  private func setupDataSources() {
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
    let config = NSImage.SymbolConfiguration(pointSize: SymbolSize.medium, weight: .regular)
    let image = NSImage(
      systemSymbolName: category.iconName,
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .labelColor

    let textField = NSTextField(labelWithString: category.displayName)
    textField.font = Fonts.body
    textField.lineBreakMode = .byTruncatingTail

    cellView.addSubview(imageView)
    cellView.addSubview(textField)

    imageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(Spacing.tiny)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(Size.categoryIcon)
    }

    textField.snp.makeConstraints { make in
      make.left.equalTo(imageView.snp.right).offset(Spacing.tiny)
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-Spacing.tiny)
    }

    return cellView
  }

  // MARK: - Data Loading

  private func loadInitialData() {
    updateCategoryData()
    customInstanceView.loadInitialData()

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

  // MARK: - Setup UI

  private func setupUI() {
    view.addSubview(categoryScrollView)
    view.addSubview(instanceInfoView)
    view.addSubview(customInstanceView)
    view.addSubview(importContentView)
    view.addSubview(atLauncherContentView)
    view.addSubview(curseForgeView)
    view.addSubview(ftbLegacyContentView)
    view.addSubview(ftbImportContentView)
    view.addSubview(modrinthContentView)
    view.addSubview(technicContentView)
    view.addSubview(helpButton)
    view.addSubview(cancelButton)
    view.addSubview(confirmButton)

    categoryScrollView.documentView = categoryTableView

    categoryScrollView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.standard)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.equalTo(Width.sidebar)
      make.bottom.equalTo(helpButton.snp.top).offset(-Spacing.standard)
    }

    instanceInfoView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.standard)
      make.left.equalTo(categoryScrollView.snp.right).offset(Spacing.standard)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.height.equalTo(Height.instanceInfo)
    }

    let contentViews: [NSView] = [
      customInstanceView,
      importContentView,
      atLauncherContentView,
      curseForgeView,
      ftbLegacyContentView,
      ftbImportContentView,
      modrinthContentView,
      technicContentView,
    ]

    for contentView in contentViews {
      contentView.snp.makeConstraints { make in
        make.top.equalTo(instanceInfoView.snp.bottom).offset(Spacing.standard)
        make.left.equalTo(categoryScrollView.snp.right).offset(Spacing.standard)
        make.right.equalToSuperview().offset(-Spacing.standard)
        make.bottom.equalTo(cancelButton.snp.top).offset(-Spacing.standard)
      }
    }

    helpButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.height.equalTo(Size.button)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.right.equalTo(confirmButton.snp.left).offset(-Spacing.section)
      make.width.equalTo(Width.actionButton)
    }

    confirmButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.width.equalTo(Width.actionButton)
    }
  }

  // MARK: - Actions

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
      let name = instanceInfoView.name.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).nonEmpty
    else {
      showError(Localized.AddInstance.errorEmptyName)
      return
    }

    guard let selectedVersion = customInstanceView.selectedVersionId else {
      showError(Localized.AddInstance.errorNoVersionSelected)
      return
    }

    do {
      let selectedLoader = customInstanceView.selectedModLoader
      let modLoaderString = selectedLoader == .NONE ? nil : selectedLoader.rawValue

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

  private func updateNameFromVersion(_ versionId: String) {
    let currentName = instanceInfoView.name.trimmingCharacters(in: .whitespacesAndNewlines)

    let isCurrentNameAVersionId = versionManager.versions.contains { $0.id == currentName }
    let shouldUpdate = currentName.isEmpty || isCurrentNameAVersionId

    if shouldUpdate {
      instanceInfoView.name = versionId
    }
  }

  private func updateContentView() {
    customInstanceView.isHidden = true
    importContentView.isHidden = true
    atLauncherContentView.isHidden = true
    curseForgeView.isHidden = true
    ftbLegacyContentView.isHidden = true
    ftbImportContentView.isHidden = true
    modrinthContentView.isHidden = true
    technicContentView.isHidden = true

    switch selectedCategory {
    case .custom:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemGreen)
      customInstanceView.isHidden = false
    case .import1:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemBlue)
      importContentView.isHidden = false
    case .atLauncher:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemOrange)
      atLauncherContentView.isHidden = false
    case .curseForge:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemRed)
      curseForgeView.isHidden = false
      curseForgeView.loadIfNeeded()
    case .ftbLegacy:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemPurple)
      ftbLegacyContentView.isHidden = false
    case .ftbImport:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemPurple)
      ftbImportContentView.isHidden = false
    case .modrinth:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemGreen)
      modrinthContentView.isHidden = false
    case .technic:
      instanceInfoView.setIcon(symbolName: selectedCategory.iconName, tint: .systemIndigo)
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
}
