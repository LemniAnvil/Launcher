//
//  CustomInstanceView.swift
//  Launcher
//
//  View for custom instance creation (version + mod loader).
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

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

final class CustomInstanceView: NSView {
  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Size = DesignSystem.Size
  private typealias Width = DesignSystem.Width
  private typealias Height = DesignSystem.Height
  private typealias Fonts = DesignSystem.Fonts

  // MARK: - View-Specific Layout Constants

  private enum LocalLayout {
    static let modLoaderVersionTableLeft: CGFloat = 150
  }

  // MARK: - Properties

  private let versionManager: VersionManager
  private let modLoaderManager: ModLoaderManager

  private(set) var selectedVersionId: String?
  private(set) var selectedModLoader: ModLoader = .NONE
  private(set) var selectedModLoaderVersion: String?
  private var availableModLoaderVersions: [String] = []

  var onVersionSelected: ((String) -> Void)?

  // MARK: - UI Components

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
        self?.effectiveAppearance.name == .darkAqua
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
        fontProvider: { _ in Fonts.bodyMedium },
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
        self?.onVersionSelected?(versionId)
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
      font: Fonts.subtitle,
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
    label.isHidden = false
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
    label.isHidden = true
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

  // MARK: - Initialization

  init(versionManager: VersionManager, modLoaderManager: ModLoaderManager) {
    self.versionManager = versionManager
    self.modLoaderManager = modLoaderManager
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    self.versionManager = VersionManager.shared
    self.modLoaderManager = ModLoaderManager.shared
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Data Loading

  func loadInitialData() {
    loadInstalledVersions()
  }

  // MARK: - Setup

  private func setupUI() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    layer?.cornerRadius = Radius.standard
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.separatorColor.cgColor

    addSubview(versionTitleLabel)
    addSubview(filterLabel)
    addSubview(releaseCheckbox)
    addSubview(snapshotCheckbox)
    addSubview(betaCheckbox)
    addSubview(alphaCheckbox)
    addSubview(refreshButton)
    addSubview(versionTableView)
    addSubview(versionModLoaderSeparator)
    addSubview(modLoaderLabel)
    addSubview(modLoaderDescriptionLabel)
    addSubview(modLoaderVersionLabel)
    addSubview(modLoaderVersionTableView)
    addSubview(modLoaderPlaceholder)
    addSubview(modLoaderVersionPlaceholder)
    addSubview(modLoaderVersionLoadingIndicator)
    addSubview(modLoaderRefreshButton)

    for button in modLoaderRadioButtons {
      addSubview(button)
    }

    versionTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.small)
      make.left.equalToSuperview().offset(Spacing.small)
    }

    refreshButton.snp.makeConstraints { make in
      make.top.equalTo(alphaCheckbox.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.height.equalTo(Size.button)
    }

    filterLabel.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.filterCheckbox)
    }

    releaseCheckbox.snp.makeConstraints { make in
      make.top.equalTo(filterLabel.snp.bottom).offset(Spacing.tiny)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.filterCheckbox)
    }

    snapshotCheckbox.snp.makeConstraints { make in
      make.top.equalTo(releaseCheckbox.snp.bottom).offset(Spacing.minimal)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.filterCheckbox)
    }

    betaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(snapshotCheckbox.snp.bottom).offset(Spacing.minimal)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.filterCheckbox)
    }

    alphaCheckbox.snp.makeConstraints { make in
      make.top.equalTo(betaCheckbox.snp.bottom).offset(Spacing.minimal)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.filterCheckbox)
    }

    versionTableView.snp.makeConstraints { make in
      make.top.equalTo(versionTitleLabel.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(LocalLayout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Spacing.small)
      make.height.equalTo(Height.table)
    }

    versionModLoaderSeparator.snp.makeConstraints { make in
      make.top.equalTo(versionTableView.snp.bottom).offset(Spacing.small)
      make.left.equalToSuperview().offset(Spacing.small)
      make.right.equalToSuperview().offset(-Spacing.small)
      make.height.equalTo(Size.separatorHeight)
    }

    modLoaderLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(Spacing.small)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.panel)
    }

    modLoaderDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(modLoaderLabel.snp.bottom).offset(Spacing.micro)
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.panel)
    }

    var previousButton: NSButton?
    for button in modLoaderRadioButtons {
      button.snp.makeConstraints { make in
        if let previous = previousButton {
          make.top.equalTo(previous.snp.bottom).offset(Spacing.tiny)
        } else {
          make.top.equalTo(modLoaderDescriptionLabel.snp.bottom).offset(Spacing.medium)
        }
        make.left.equalToSuperview().offset(Spacing.small)
        make.width.equalTo(Width.panel)
      }
      previousButton = button
    }

    modLoaderVersionLabel.snp.makeConstraints { make in
      make.top.equalTo(versionModLoaderSeparator.snp.bottom).offset(Spacing.small)
      make.left.equalToSuperview().offset(LocalLayout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Spacing.small)
    }

    modLoaderVersionTableView.snp.makeConstraints { make in
      make.top.equalTo(modLoaderVersionLabel.snp.bottom).offset(Spacing.tiny)
      make.left.equalToSuperview().offset(LocalLayout.modLoaderVersionTableLeft)
      make.right.equalToSuperview().offset(-Spacing.small)
      make.bottom.equalToSuperview().offset(-Spacing.small)
    }

    modLoaderPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(Width.placeholder)
    }

    modLoaderVersionPlaceholder.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.equalTo(Width.largePlaceholder)
    }

    modLoaderVersionLoadingIndicator.snp.makeConstraints { make in
      make.centerX.equalTo(modLoaderVersionTableView)
      make.centerY.equalTo(modLoaderVersionTableView)
      make.width.height.equalTo(Size.smallIndicator)
    }

    modLoaderRefreshButton.snp.makeConstraints { make in
      if let lastButton = modLoaderRadioButtons.last {
        make.top.equalTo(lastButton.snp.bottom).offset(Spacing.section)
      }
      make.left.equalToSuperview().offset(Spacing.small)
      make.width.equalTo(Width.actionButton)
    }
  }

  // MARK: - Data Loading

  private func loadInstalledVersions() {
    Task {
      if versionManager.versions.isEmpty {
        do {
          try await versionManager.refreshVersionList()
        } catch {
          Logger.shared.error("Failed to refresh version list: \(error)", category: "AddInstance")
        }
      }

      await MainActor.run {
        applyVersionFilter()
      }
    }
  }

  private func applyVersionFilter() {
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

    let versions: [VersionInfo]
    if selectedTypes.isEmpty {
      versions = versionManager.versions
    } else {
      versions = versionManager.versions.filter { version in
        selectedTypes.contains(version.type)
      }
    }

    let versionItems = versions.map { VersionItem(version: $0) }
    versionTableView.updateItems(versionItems)

    if !versionItems.isEmpty, versionTableView.selectedItem == nil {
      versionTableView.selectItem(at: 0)
      selectedVersionId = versionItems[0].id
      onVersionSelected?(versionItems[0].id)
    }
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

          let alert = NSAlert()
          alert.messageText = Localized.AddInstance.alertFailedToRefresh
          alert.informativeText = error.localizedDescription
          alert.alertStyle = .warning
          alert.addButton(withTitle: Localized.AddInstance.okButton)

          if let window = self.window {
            alert.beginSheetModal(for: window)
          } else {
            alert.runModal()
          }
        }
      }
    }
  }

  @objc private func modLoaderChanged() {
    if let index = modLoaderRadioButtons.firstIndex(where: { $0.state == .on }) {
      selectedModLoader = ModLoader.allCases[index]
    }

    modLoaderDescriptionLabel.isHidden = (selectedModLoader == .NONE)

    if selectedModLoader != .NONE {
      modLoaderPlaceholder.isHidden = true
      modLoaderVersionPlaceholder.isHidden = true
      loadModLoaderVersions()
    } else {
      modLoaderPlaceholder.isHidden = false
      modLoaderVersionPlaceholder.isHidden = true
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
        }
      }
    }
  }
}
