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
  // swiftlint:disable:previous type_body_length

  // MARK: - Layout Constants

  private enum Layout {
    // Corner radius
    static let cornerRadius: CGFloat = 8

    // Spacing
    static let standardPadding: CGFloat = 20
    static let contentPadding: CGFloat = 15
    static let smallPadding: CGFloat = 10
    static let tinyPadding: CGFloat = 8
    static let minimalPadding: CGFloat = 6
    static let microPadding: CGFloat = 4
    static let sectionSpacing: CGFloat = 12
    static let buttonSpacing: CGFloat = 12
    static let labelSpacing: CGFloat = 16

    // Sizes
    static let categorySidebarWidth: CGFloat = 180
    static let instanceInfoHeight: CGFloat = 140
    static let iconSize: CGFloat = 100
    static let categoryIconSize: CGFloat = 20
    static let buttonSize: CGFloat = 32
    static let smallIndicatorSize: CGFloat = 16
    static let actionButtonWidth: CGFloat = 100
    static let textFieldHeight: CGFloat = 28
    static let popupHeight: CGFloat = 24
    static let separatorHeight: CGFloat = 1
    static let versionTableHeight: CGFloat = 250

    // Filter panel
    static let filterPanelWidth: CGFloat = 220
    static let filterCheckboxWidth: CGFloat = 120
    static let filterMinWidth: CGFloat = 180
    static let sortLabelWidth: CGFloat = 60
    static let sortPopupWidth: CGFloat = 150
    static let versionLabelWidth: CGFloat = 120
    static let groupLabelWidth: CGFloat = 60

    // Mod loader
    static let modLoaderPanelWidth: CGFloat = 200
    static let modLoaderVersionTableLeft: CGFloat = 150
    static let placeholderWidth: CGFloat = 240
    static let largePlaceholderWidth: CGFloat = 280
    static let refreshButtonWidth: CGFloat = 100

    // CurseForge
    static let curseForgeBottomSpace: CGFloat = 50
    static let emptyLabelWidth: CGFloat = 200
  }

  // MARK: - Font Constants

  private enum Fonts {
    static let title = NSFont.systemFont(ofSize: 16, weight: .semibold)
    static let sectionTitle = NSFont.systemFont(ofSize: 14, weight: .semibold)
    static let label = NSFont.systemFont(ofSize: 13, weight: .medium)
    static let body = NSFont.systemFont(ofSize: 13)
    static let small = NSFont.systemFont(ofSize: 12)
    static let smallMedium = NSFont.systemFont(ofSize: 12, weight: .medium)
    static let caption = NSFont.systemFont(ofSize: 11)
    static let tableHeader = NSFont.systemFont(ofSize: 13, weight: .semibold)
  }

  // MARK: - Symbol Constants

  private enum Symbols {
    static let largeIconSize: CGFloat = 60
    static let mediumIconSize: CGFloat = 16
  }

  // MARK: - Properties

  var onInstanceCreated: ((Instance) -> Void)?
  var onCancel: (() -> Void)?

  private let instanceManager = InstanceManager.shared
  private let versionManager = VersionManager.shared
  private let modLoaderManager = ModLoaderManager.shared
  private let curseForgeAPI = CurseForgeAPIClient.shared
  private var selectedVersionId: String?
  private var selectedModLoader: ModLoader = .NONE
  private var selectedModLoaderVersion: String?
  private var availableModLoaderVersions: [String] = []

  // CurseForge properties
  private var curseForgeModpacks: [CurseForgeModpack] = []
  private var selectedModpack: CurseForgeModpack?
  private var modpackFiles: [CurseForgeModpackFile] = []
  private var selectedModpackFile: CurseForgeModpackFile?
  private var currentSearchTerm: String = ""
  private var currentSortMethod: CurseForgeSortMethod = .featured
  private var currentPaginationIndex: Int = 0
  private var isLoadingMore: Bool = false
  private var hasMoreResults: Bool = true
  private var searchDebounceTimer: Timer?
  // Category filter properties
  private var categories: [CurseForgeCategory] = []
  private var selectedCategoryIds: Set<Int> = []
  private var categoryCheckboxes: [Int: NSButton] = [:]

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

  // Version data model
  struct VersionItem: Hashable {
    let version: VersionInfo

    var id: String { version.id }
    var releaseDate: String { Self.formatDate(version.releaseTime) }
    var type: String { version.type.displayName }
    var versionType: VersionType { version.type }

    func hash(into hasher: inout Hasher) {
      hasher.combine(version.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.version.id == rhs.version.id
    }

    private static func formatDate(_ date: Date) -> String {
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

  // Modpack data model for CurseForge table
  struct ModpackItem: Hashable {
    let modpack: CurseForgeModpack

    var id: Int { modpack.id }
    var name: String { modpack.name }
    var author: String { modpack.primaryAuthor }
    var downloads: String { modpack.formattedDownloadCount }

    func hash(into hasher: inout Hasher) {
      hasher.combine(modpack.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.modpack.id == rhs.modpack.id
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

  private lazy var iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = Layout.cornerRadius
    imageView.imageScaling = .scaleProportionallyUpOrDown
    let config = NSImage.SymbolConfiguration(pointSize: Symbols.largeIconSize, weight: .regular)
    let image = NSImage(
      systemSymbolName: "cube.fill",
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let nameLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.nameLabel,
      font: Fonts.label,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var nameTextField: NSTextField = {
    let field = NSTextField()
    field.placeholderString = Localized.AddInstance.namePlaceholder
    field.font = Fonts.body
    field.lineBreakMode = .byTruncatingTail
    return field
  }()

  private let groupLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.groupLabel,
      font: Fonts.label,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var groupPopUpButton: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = Fonts.body
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
    scrollView.layer?.cornerRadius = Layout.cornerRadius
    scrollView.layer?.borderWidth = 1
    scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
    return scrollView
  }()

  private lazy var instanceInfoView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private lazy var customContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private lazy var importContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var atLauncherContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var curseForgeContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var ftbLegacyContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var ftbImportContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var modrinthContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  private lazy var technicContentView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = Layout.cornerRadius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    view.isHidden = true
    return view
  }()

  // MARK: - CurseForge UI Components

  private lazy var curseForgeSearchField: NSSearchField = {
    let field = NSSearchField()
    field.placeholderString = Localized.AddInstance.searchPlaceholder
    field.font = Fonts.body
    return field
  }()

  private lazy var curseForgeSortLabel = DisplayLabel(
    text: Localized.AddInstance.sortByLabel,
    font: Fonts.smallMedium,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var curseForgeSortPopup: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = Fonts.small
    // Add sort options
    for sortMethod in CurseForgeSortMethod.allCases {
      button.addItem(withTitle: sortMethod.displayName)
    }
    button.target = self
    button.action = #selector(curseForgeSortChanged)
    return button
  }()

  private lazy var curseForgeModpackTableView: VersionTableView<ModpackItem> = {
    let columns: [VersionTableView<ModpackItem>.ColumnConfig] = [
      .init(
        identifier: "ModpackColumn",
        title: Localized.AddInstance.columnModpackName,
        width: 250,
        valueProvider: { $0.name },
        fontProvider: { _ in Fonts.label },
        colorProvider: { _ in .labelColor }
      ),
      .init(
        identifier: "AuthorColumn",
        title: Localized.AddInstance.columnModpackAuthor,
        width: 120,
        valueProvider: { $0.author },
        fontProvider: { _ in Fonts.body },
        colorProvider: { _ in .secondaryLabelColor }
      ),
      .init(
        identifier: "DownloadsColumn",
        title: Localized.AddInstance.columnModpackDownloads,
        width: 80,
        valueProvider: { $0.downloads },
        fontProvider: { _ in Fonts.body },
        colorProvider: { _ in .tertiaryLabelColor }
      ),
    ]

    let tableView = VersionTableView<ModpackItem>(
      columns: columns
    ) { [weak self] item in
      // Handle modpack selection
      guard let self = self, let item = item else {
        self?.selectedModpack = nil
        self?.selectedModpackFile = nil
        self?.modpackFiles = []
        self?.curseForgeVersionPopup.removeAllItems()
        self?.curseForgeVersionPopup.isEnabled = false
        return
      }
      self.selectedModpack = item.modpack
      self.loadModpackVersions(for: item.modpack)
    }
    return tableView
  }()

  private lazy var curseForgeLoadingIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.controlSize = .regular
    indicator.isHidden = true
    return indicator
  }()

  private lazy var curseForgeEmptyLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.noModpacksFound,
      font: Fonts.body,
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.isHidden = true
    return label
  }()

  private lazy var curseForgeVersionLabel = DisplayLabel(
    text: Localized.AddInstance.versionSelectedLabel,
    font: Fonts.smallMedium,
    textColor: .labelColor,
    alignment: .right
  )

  private lazy var curseForgeVersionPopup: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = Fonts.small
    button.target = self
    button.action = #selector(curseForgeVersionChanged)
    button.isEnabled = false
    return button
  }()

  private lazy var curseForgeVersionLoadingIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.controlSize = .small
    indicator.isHidden = true
    return indicator
  }()

  // MARK: - CurseForge Filter UI Components

  private lazy var curseForgeFilterScrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = true
    scrollView.backgroundColor = NSColor.controlBackgroundColor
    scrollView.wantsLayer = true
    scrollView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    scrollView.layer?.cornerRadius = Layout.cornerRadius
    scrollView.layer?.borderWidth = 1
    scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
    return scrollView
  }()

  private let curseForgeFilterStackView: NSStackView = {
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading  // Keep leading for checkbox alignment
    stackView.distribution = .fill  // Use fill instead of gravityAreas
    stackView.spacing = 6
    stackView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    stackView.wantsLayer = true
    // Lower hugging priority to allow stackView to be flexible
    // But keep default compression resistance so content isn't clipped
    stackView.setHuggingPriority(.defaultLow, for: .horizontal)
    stackView.setHuggingPriority(.defaultLow, for: .vertical)
    return stackView
  }()

  private lazy var curseForgeFilterTitleLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.categoriesFilterTitle,
      font: Fonts.tableHeader,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var versionTitleLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.customTitle,
      font: Fonts.title,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var filterLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.filterLabel,
      font: Fonts.small,
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
    button.font = Fonts.small
    return button
  }()

  private lazy var snapshotCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterSnapshot,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = Fonts.small
    return button
  }()

  private lazy var betaCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterBeta,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = Fonts.small
    return button
  }()

  private lazy var alphaCheckbox: NSButton = {
    let button = NSButton(
      checkboxWithTitle: Localized.AddInstance.filterAlpha,
      target: self,
      action: #selector(filterChanged)
    )
    button.state = .off
    button.font = Fonts.small
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
        fontProvider: { _ in Fonts.label },
        colorProvider: { _ in .labelColor }
      ),
      .init(
        identifier: "ReleaseColumn",
        title: Localized.AddInstance.columnRelease,
        width: 120,
        valueProvider: { $0.releaseDate },
        fontProvider: { _ in Fonts.body },
        colorProvider: { _ in .secondaryLabelColor }
      ),
      .init(
        identifier: "TypeColumn",
        title: Localized.AddInstance.columnType,
        width: 100,
        valueProvider: { $0.type },
        fontProvider: { _ in Fonts.tableHeader },
        colorProvider: { [weak self] item in
          self?.getTypeColor(for: item.versionType) ?? .labelColor
        }
      ),
    ]

    let tableView = VersionTableView<VersionItem>(
      columns: columns
    ) { [weak self] item in
      self?.selectedVersionId = item?.id
      if let versionId = item?.id {
        self?.updateNameFromVersion(versionId)
        if self?.selectedModLoader != .NONE {
          self?.loadModLoaderVersions()
        }
      }
    }
    return tableView
  }()

  private lazy var modLoaderLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.modLoaderTitle,
      font: Fonts.sectionTitle,
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let versionModLoaderSeparator: BRSeparator = BRSeparator(type: .horizontal)

  private lazy var modLoaderPlaceholder: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.modLoaderPlaceholder,
      font: Fonts.body,
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = false  // Show initially when no mod loader selected (NONE is default)
    return label
  }()

  private lazy var modLoaderVersionPlaceholder: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.modLoaderVersionPlaceholder,
      font: Fonts.body,
      textColor: .tertiaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true  // Hide initially (only show when mod loader is selected but no versions available)
    return label
  }()

  private lazy var modLoaderDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.modLoaderDescription,
      font: Fonts.caption,
      textColor: .tertiaryLabelColor,
      alignment: .left
    )
    label.maximumNumberOfLines = 0
    label.isHidden = true
    return label
  }()

  private lazy var modLoaderVersionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.AddInstance.modLoaderVersionLabel,
      font: Fonts.smallMedium,
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
        fontProvider: { _ in Fonts.body },
        colorProvider: { _ in .labelColor }
      ),
    ]

    let tableView = VersionTableView<LoaderVersionItem>(
      columns: columns
    ) { [weak self] item in
      self?.selectedModLoaderVersion = item?.id
    }
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
      button.font = Fonts.small
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
    let config = NSImage.SymbolConfiguration(pointSize: Symbols.mediumIconSize, weight: .regular)
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
      make.left.equalToSuperview().offset(Layout.tinyPadding)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(Layout.categoryIconSize)
    }

    textField.snp.makeConstraints { make in
      make.left.equalTo(imageView.snp.right).offset(Layout.tinyPadding)
      make.centerY.equalToSuperview()
      make.right.equalToSuperview().offset(-Layout.tinyPadding)
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
          Logger.shared.error("Failed to refresh version list: \(error)", category: "AddInstance")
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
    let versions: [VersionInfo]
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
      make.top.equalToSuperview().offset(Layout.standardPadding)
      make.left.equalToSuperview().offset(Layout.standardPadding)
      make.width.equalTo(Layout.categorySidebarWidth)
      make.bottom.equalTo(helpButton.snp.top).offset(-Layout.standardPadding)
    }

    instanceInfoView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Layout.standardPadding)
      make.left.equalTo(categoryScrollView.snp.right).offset(Layout.standardPadding)
      make.right.equalToSuperview().offset(-Layout.standardPadding)
      make.height.equalTo(Layout.instanceInfoHeight)
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
      technicContentView,
    ]

    for contentView in contentViews {
      contentView.snp.makeConstraints { make in
        make.top.equalTo(instanceInfoView.snp.bottom).offset(Layout.standardPadding)
        make.left.equalTo(categoryScrollView.snp.right).offset(Layout.standardPadding)
        make.right.equalToSuperview().offset(-Layout.standardPadding)
        make.bottom.equalTo(cancelButton.snp.top).offset(-Layout.standardPadding)
      }
    }

    helpButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Layout.standardPadding)
      make.left.equalToSuperview().offset(Layout.standardPadding)
      make.width.height.equalTo(Layout.buttonSize)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Layout.standardPadding)
      make.right.equalTo(confirmButton.snp.left).offset(-Layout.sectionSpacing)
      make.width.equalTo(Layout.actionButtonWidth)
    }

    confirmButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Layout.standardPadding)
      make.right.equalToSuperview().offset(-Layout.standardPadding)
      make.width.equalTo(Layout.actionButtonWidth)
    }
  }

  private func setupInstanceInfoView() {
    instanceInfoView.addSubview(iconImageView)
    instanceInfoView.addSubview(nameLabel)
    instanceInfoView.addSubview(nameTextField)
    instanceInfoView.addSubview(groupLabel)
    instanceInfoView.addSubview(groupPopUpButton)

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Layout.standardPadding)
      make.left.equalToSuperview().offset(Layout.standardPadding)
      make.width.height.equalTo(Layout.iconSize)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(30)
      make.left.equalTo(iconImageView.snp.right).offset(Layout.standardPadding)
      make.right.equalToSuperview().offset(-Layout.standardPadding)
    }

    nameTextField.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(Layout.tinyPadding)
      make.left.equalTo(iconImageView.snp.right).offset(Layout.standardPadding)
      make.right.equalToSuperview().offset(-Layout.standardPadding)
      make.height.equalTo(Layout.textFieldHeight)
    }

    groupLabel.snp.makeConstraints { make in
      make.top.equalTo(nameTextField.snp.bottom).offset(Layout.labelSpacing)
      make.left.equalTo(iconImageView.snp.right).offset(Layout.standardPadding)
      make.width.equalTo(Layout.groupLabelWidth)
    }

    groupPopUpButton.snp.makeConstraints { make in
      make.centerY.equalTo(groupLabel)
      make.left.equalTo(groupLabel.snp.right).offset(Layout.tinyPadding)
      make.right.equalToSuperview().offset(-Layout.standardPadding)
      make.height.equalTo(Layout.popupHeight)
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
      make.top.equalToSuperview().offset(Layout.smallPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalTo(alphaCheckbox.snp.bottom).offset(Layout.sectionSpacing)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.height.equalTo(Layout.buttonSize)
    }

    filterLabel.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(Layout.sectionSpacing)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.filterCheckboxWidth)
    }

    releaseCheckbox.snp.makeConstraints { make in
      make.top.equalTo(filterLabel.snp.bottom).offset(Layout.tinyPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.filterCheckboxWidth)
    }

    snapshotCheckbox.snp.makeConstraints { make in
      make.top.equalTo(releaseCheckbox.snp.bottom).offset(Layout.minimalPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.filterCheckboxWidth)
    }

    betaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(snapshotCheckbox.snp.bottom).offset(Layout.minimalPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.filterCheckboxWidth)
    }

    alphaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(betaCheckbox.snp.bottom).offset(Layout.minimalPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.filterCheckboxWidth)
    }

    versionTableView.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(Layout.sectionSpacing)
      make.left.equalToSuperview().offset(Layout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Layout.smallPadding)
      make.height.equalTo(Layout.versionTableHeight)
    }

    // Horizontal separator between version and mod loader sections
    versionModLoaderSeparator.snp.makeConstraints { make in
      make.top.equalTo(versionTableView.snp.bottom).offset(Layout.smallPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.right.equalToSuperview().offset(-Layout.smallPadding)
      make.height.equalTo(Layout.separatorHeight)
    }

    // Mod Loader section (bottom half) - Options on left, Table on right
    modLoaderLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(Layout.smallPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.modLoaderPanelWidth)
    }

    modLoaderDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(modLoaderLabel.snp.bottom).offset(Layout.microPadding)
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.modLoaderPanelWidth)
    }

    var previousButton: NSButton?
    for button in modLoaderRadioButtons {
      button.snp.makeConstraints { make in
        if let previous = previousButton {
          make.top.equalTo(previous.snp.bottom).offset(Layout.tinyPadding)
        } else {
          make.top.equalTo(modLoaderDescriptionLabel.snp.bottom).offset(Layout.labelSpacing)
        }
        make.left.equalToSuperview().offset(Layout.smallPadding)
        make.width.equalTo(Layout.modLoaderPanelWidth)
      }
      previousButton = button
    }

    modLoaderVersionLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(Layout.smallPadding)
      make.left.equalToSuperview().offset(Layout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Layout.smallPadding)
    }

    modLoaderVersionTableView.snp.makeConstraints { make in
      make.top.equalTo(modLoaderVersionLabel.snp.bottom).offset(Layout.tinyPadding)
      make.left.equalToSuperview().offset(Layout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Layout.smallPadding)
      make.bottom.equalToSuperview().offset(-Layout.smallPadding)
    }

    modLoaderPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(Layout.placeholderWidth)
    }

    modLoaderVersionPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(Layout.largePlaceholderWidth)
    }

    modLoaderVersionLoadingIndicator.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.height.equalTo(Layout.smallIndicatorSize)
    }

    modLoaderRefreshButton.snp.makeConstraints { make in
      if let lastButton = modLoaderRadioButtons.last {
        make.top.equalTo(lastButton.snp.bottom).offset(Layout.sectionSpacing)
      }
      make.left.equalToSuperview().offset(Layout.smallPadding)
      make.width.equalTo(Layout.refreshButtonWidth)
    }
  }

  private func setupOtherContentViews() {
    // Setup placeholder content for other views
    setupPlaceholderContent(for: importContentView, title: Localized.AddInstance.categoryImport)
    setupPlaceholderContent(for: atLauncherContentView, title: "ATLauncher")
    setupCurseForgeContentView()  // Functional CurseForge implementation
    setupPlaceholderContent(for: ftbLegacyContentView, title: "FTB Legacy")
    setupPlaceholderContent(for: ftbImportContentView, title: Localized.AddInstance.categoryFTBImport)
    setupPlaceholderContent(for: modrinthContentView, title: "Modrinth")
    setupPlaceholderContent(for: technicContentView, title: "Technic")
  }

  private func setupCurseForgeContentView() {
    // Add filter panel (left) and main content area (right)
    curseForgeContentView.addSubview(curseForgeFilterScrollView)
    curseForgeFilterStackView.translatesAutoresizingMaskIntoConstraints = false
    curseForgeFilterScrollView.documentView = curseForgeFilterStackView

    // Add search and sort controls
    curseForgeContentView.addSubview(curseForgeSearchField)
    curseForgeContentView.addSubview(curseForgeSortLabel)
    curseForgeContentView.addSubview(curseForgeSortPopup)
    curseForgeContentView.addSubview(curseForgeModpackTableView)
    curseForgeContentView.addSubview(curseForgeLoadingIndicator)
    curseForgeContentView.addSubview(curseForgeEmptyLabel)
    curseForgeContentView.addSubview(curseForgeVersionLabel)
    curseForgeContentView.addSubview(curseForgeVersionPopup)
    curseForgeContentView.addSubview(curseForgeVersionLoadingIndicator)

    // Left filter panel constraints (fixed width ~220pt)
    curseForgeFilterScrollView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Layout.contentPadding)
      make.left.equalToSuperview().offset(Layout.contentPadding)
      make.width.equalTo(Layout.filterPanelWidth).priority(.required)  // Force this width constraint
      make.bottom.equalToSuperview().offset(-Layout.curseForgeBottomSpace) // Leave space for version selector at bottom
    }

    // Right content area - search field
    curseForgeSearchField.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Layout.contentPadding)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Layout.contentPadding)
      make.right.equalToSuperview().offset(-Layout.contentPadding)
      make.height.equalTo(Layout.textFieldHeight)
    }

    // Sort controls (on the right side)
    curseForgeSortLabel.snp.makeConstraints { make in
      make.top.equalTo(curseForgeSearchField.snp.bottom).offset(Layout.sectionSpacing)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Layout.contentPadding)
      make.width.equalTo(Layout.sortLabelWidth)
    }

    curseForgeSortPopup.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeSortLabel)
      make.left.equalTo(curseForgeSortLabel.snp.right).offset(Layout.tinyPadding)
      make.width.equalTo(Layout.sortPopupWidth)
      make.height.equalTo(Layout.popupHeight)
    }

    // Modpack table view
    curseForgeModpackTableView.snp.makeConstraints { make in
      make.top.equalTo(curseForgeSortLabel.snp.bottom).offset(Layout.sectionSpacing)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Layout.contentPadding)
      make.right.equalToSuperview().offset(-Layout.contentPadding)
      make.bottom.equalTo(curseForgeVersionLabel.snp.top).offset(-Layout.sectionSpacing)
    }

    curseForgeLoadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(curseForgeModpackTableView)
      make.width.height.equalTo(Layout.buttonSize)
    }

    curseForgeEmptyLabel.snp.makeConstraints { make in
      make.center.equalTo(curseForgeModpackTableView)
      make.width.equalTo(Layout.emptyLabelWidth)
    }

    // Version selection UI at bottom (spans entire width)
    curseForgeVersionLabel.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Layout.contentPadding)
      make.left.equalTo(curseForgeSortPopup.snp.right).offset(Layout.standardPadding)
      make.width.equalTo(Layout.versionLabelWidth)
    }

    curseForgeVersionPopup.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeVersionLabel)
      make.left.equalTo(curseForgeVersionLabel.snp.right).offset(Layout.tinyPadding)
      make.right.equalToSuperview().offset(-Layout.contentPadding)
      make.height.equalTo(Layout.popupHeight)
    }

    curseForgeVersionLoadingIndicator.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeVersionPopup)
      make.left.equalTo(curseForgeVersionLabel.snp.left).offset(-24)
      make.width.height.equalTo(Layout.smallIndicatorSize)
    }

    // Setup search field delegate
    curseForgeSearchField.target = self
    curseForgeSearchField.action = #selector(curseForgeSearchChanged)

    // Setup infinite scroll
    setupInfiniteScroll()

    // Don't load data here - wait until CurseForge is actually selected
    // Data will be loaded in updateContentView() when category is selected
  }

  /// Setup infinite scroll for modpack list
  private func setupInfiniteScroll() {
    // Monitor scroll events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(modpackScrollViewDidScroll(_:)),
      name: NSScrollView.didLiveScrollNotification,
      object: curseForgeModpackTableView.scrollView
    )
  }

  @objc private func modpackScrollViewDidScroll(_ notification: Notification) {
    guard let scrollView = notification.object as? NSScrollView else { return }

    // Don't load if already loading or no more results
    guard !isLoadingMore, hasMoreResults else { return }

    // Calculate scroll position
    let contentView = scrollView.contentView
    let documentRect = contentView.documentRect
    let visibleRect = contentView.documentVisibleRect

    // Trigger load when scrolled to 80% of content
    let scrollPosition = (visibleRect.origin.y + visibleRect.height) / documentRect.height
    let threshold: CGFloat = 0.8

    if scrollPosition > threshold {
      Logger.shared.info("Loading more modpacks (scroll position: \(Int(scrollPosition * 100))%)", category: "AddInstance")
      loadCurseForgeModpacks(reset: false)
    }
  }

  private func setupPlaceholderContent(for contentView: NSView, title: String) {
    let titleLabel = DisplayLabel(
      text: title,
      font: Fonts.title,
      textColor: .labelColor,
      alignment: .center
    )

    let comingSoonLabel = DisplayLabel(
      text: "Coming Soon",
      font: Fonts.sectionTitle,
      textColor: .secondaryLabelColor,
      alignment: .center
    )

    contentView.addSubview(titleLabel)
    contentView.addSubview(comingSoonLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-Layout.standardPadding)
    }

    comingSoonLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(Layout.sectionSpacing)
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
          Logger.shared.error("Failed to refresh versions: \(error)", category: "AddInstance")
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
          Logger.shared.error("Failed to load mod loader versions: \(error)", category: "AddInstance")
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

  // MARK: - CurseForge Methods

  @objc private func curseForgeSearchChanged() {
    // Debounce search input
    searchDebounceTimer?.invalidate()
    searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
      self?.performCurseForgeSearch()
    }
  }

  private func performCurseForgeSearch() {
    currentSearchTerm = curseForgeSearchField.stringValue
    loadCurseForgeModpacks(reset: true)
  }

  @objc private func curseForgeSortChanged() {
    let selectedIndex = curseForgeSortPopup.indexOfSelectedItem
    guard selectedIndex >= 0, selectedIndex < CurseForgeSortMethod.allCases.count else { return }
    currentSortMethod = CurseForgeSortMethod.allCases[selectedIndex]
    loadCurseForgeModpacks(reset: true)
  }

  private func loadCurseForgeModpacks(reset: Bool) {
    if reset {
      currentPaginationIndex = 0
      curseForgeModpacks.removeAll()
      hasMoreResults = true
    }

    guard !isLoadingMore else { return }
    guard hasMoreResults else { return }

    isLoadingMore = true

    // Show loading indicator
    curseForgeLoadingIndicator.isHidden = false
    curseForgeLoadingIndicator.startAnimation(nil)
    curseForgeEmptyLabel.isHidden = true

    Task {
      do {
        let searchTerm = currentSearchTerm.isEmpty ? nil : currentSearchTerm
        let categoryIds = selectedCategoryIds.isEmpty ? nil : Array(selectedCategoryIds)
        let response = try await curseForgeAPI.searchModpacks(
          searchTerm: searchTerm,
          sortMethod: currentSortMethod,
          offset: currentPaginationIndex,
          categoryIds: categoryIds
        )

        await MainActor.run {
          // Update modpacks list
          if reset {
            self.curseForgeModpacks = response.data
          } else {
            self.curseForgeModpacks.append(contentsOf: response.data)
          }

          // Update pagination state
          self.currentPaginationIndex = response.pagination.nextIndex
          self.hasMoreResults = response.pagination.hasMoreResults

          // Update table view
          let modpackItems = self.curseForgeModpacks.map { ModpackItem(modpack: $0) }
          self.curseForgeModpackTableView.updateItems(modpackItems)

          // Hide loading indicator
          self.curseForgeLoadingIndicator.stopAnimation(nil)
          self.curseForgeLoadingIndicator.isHidden = true
          self.isLoadingMore = false

          // Show empty message if no results
          if self.curseForgeModpacks.isEmpty {
            self.curseForgeEmptyLabel.isHidden = false
          } else {
            self.curseForgeEmptyLabel.isHidden = true
          }
        }
      } catch {
        await MainActor.run {
          Logger.shared.error("Failed to load CurseForge modpacks: \(error)", category: "AddInstance")
          self.curseForgeLoadingIndicator.stopAnimation(nil)
          self.curseForgeLoadingIndicator.isHidden = true
          self.isLoadingMore = false

          // Show error alert
          let alert = NSAlert()
          alert.messageText = Localized.AddInstance.errorLoadModpacksFailed
          alert.informativeText = error.localizedDescription
          alert.alertStyle = .warning
          alert.addButton(withTitle: Localized.AddInstance.okButton)

          if let window = self.view.window {
            alert.beginSheetModal(for: window)
          } else {
            alert.runModal()
          }
        }
      }
    }
  }

  /// Load available versions for selected modpack
  private func loadModpackVersions(for modpack: CurseForgeModpack) {
    // Clear previous selections
    curseForgeVersionPopup.removeAllItems()
    selectedModpackFile = nil
    curseForgeVersionPopup.isEnabled = false

    // Show loading indicator
    curseForgeVersionLoadingIndicator.isHidden = false
    curseForgeVersionLoadingIndicator.startAnimation(nil)

    Task {
      do {
        let files = try await curseForgeAPI.getModpackFiles(modpackId: modpack.id)

        await MainActor.run {
          self.modpackFiles = files

          // Add versions to popup
          for file in files {
            self.curseForgeVersionPopup.addItem(withTitle: file.versionDisplayString)
          }

          // Select first version by default
          if !files.isEmpty {
            self.curseForgeVersionPopup.selectItem(at: 0)
            self.selectedModpackFile = files[0]
            self.curseForgeVersionPopup.isEnabled = true
          }

          // Hide loading indicator
          self.curseForgeVersionLoadingIndicator.stopAnimation(nil)
          self.curseForgeVersionLoadingIndicator.isHidden = true
        }
      } catch {
        await MainActor.run {
          Logger.shared.error("Failed to load modpack versions: \(error)", category: "AddInstance")
          self.curseForgeVersionLoadingIndicator.stopAnimation(nil)
          self.curseForgeVersionLoadingIndicator.isHidden = true

          // Show error in popup
          self.curseForgeVersionPopup.addItem(withTitle: "Failed to load versions")
          self.curseForgeVersionPopup.isEnabled = false
        }
      }
    }
  }

  // Track whether CurseForge content has been loaded
  private var curseForgeContentLoaded = false

  /// Lazy load CurseForge content only when needed
  private func loadCurseForgeContentIfNeeded() {
    guard !curseForgeContentLoaded else { return }
    curseForgeContentLoaded = true

    Logger.shared.info("Loading CurseForge content for the first time", category: "AddInstance")
    loadCategories()
    loadCurseForgeModpacks(reset: true)
  }

  @objc private func curseForgeVersionChanged() {
    let selectedIndex = curseForgeVersionPopup.indexOfSelectedItem
    guard selectedIndex >= 0, selectedIndex < modpackFiles.count else {
      selectedModpackFile = nil
      return
    }
    selectedModpackFile = modpackFiles[selectedIndex]
  }

  // MARK: - Category Loading

  /// Load available categories for modpacks
  private func loadCategories() {
    Task {
      do {
        let loadedCategories = try await curseForgeAPI.getCategories()
        Logger.shared.info("Loaded \(loadedCategories.count) categories from API", category: "AddInstance")

        await MainActor.run {
          // Show all categories (not just root categories)
          // CurseForge API may not always set parentCategoryId correctly
          self.categories = loadedCategories
          Logger.shared.info("Displaying \(self.categories.count) categories in filter panel", category: "AddInstance")
          self.createCategoryCheckboxes()
        }
      } catch {
        await MainActor.run {
          Logger.shared.error("Failed to load categories: \(error)", category: "AddInstance")
          // Show error in UI by adding an error label to filter panel
          self.showCategoryLoadError()
        }
      }
    }
  }

  /// Show error message when categories fail to load
  private func showCategoryLoadError() {
    let errorLabel = DisplayLabel(
      text: Localized.AddInstance.errorLoadCategoriesFailed,
      font: Fonts.caption,
      textColor: .systemRed,
      alignment: .left
    )
    curseForgeFilterStackView.addArrangedSubview(curseForgeFilterTitleLabel)
    curseForgeFilterStackView.addArrangedSubview(errorLabel)
  }

  /// Create checkboxes for each category
  private func createCategoryCheckboxes() {
    Logger.shared.debug("Creating category checkboxes for \(categories.count) categories", category: "AddInstance")

    // Clear existing checkboxes
    curseForgeFilterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    categoryCheckboxes.removeAll()

    // Set stackView constraints - use lessThanOrEqualTo to prevent window expansion
    curseForgeFilterStackView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalToSuperview()
      make.width.lessThanOrEqualTo(curseForgeFilterScrollView.snp.width).offset(-Layout.standardPadding)
      make.width.greaterThanOrEqualTo(Layout.filterMinWidth)
    }

    // Add title label
    curseForgeFilterStackView.addArrangedSubview(curseForgeFilterTitleLabel)

    // Create checkbox for each category
    for category in categories {
      Logger.shared.debug("Adding checkbox for category: \(category.name) (ID: \(category.id))", category: "AddInstance")
      let checkbox = NSButton(
        checkboxWithTitle: category.name,
        target: self,
        action: #selector(categoryCheckboxChanged(_:))
      )
      checkbox.font = Fonts.small
      checkbox.tag = category.id
      checkbox.lineBreakMode = .byTruncatingTail
      // Ensure checkbox doesn't get compressed
      checkbox.setContentCompressionResistancePriority(.required, for: .horizontal)

      categoryCheckboxes[category.id] = checkbox
      curseForgeFilterStackView.addArrangedSubview(checkbox)
    }

    Logger.shared.debug("Created \(categoryCheckboxes.count) category checkboxes", category: "AddInstance")
  }

  @objc private func categoryCheckboxChanged(_ sender: NSButton) {
    let categoryId = sender.tag

    if sender.state == .on {
      selectedCategoryIds.insert(categoryId)
    } else {
      selectedCategoryIds.remove(categoryId)
    }

    // Reload modpacks with new filter
    loadCurseForgeModpacks(reset: true)
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
    let config = NSImage.SymbolConfiguration(pointSize: Symbols.largeIconSize, weight: .regular)
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
      // Lazy load CurseForge content when first selected
      loadCurseForgeContentIfNeeded()
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
