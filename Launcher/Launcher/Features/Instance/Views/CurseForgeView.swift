//
//  CurseForgeView.swift
//  Launcher
//
//  View for CurseForge modpack browsing and selection.
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

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

final class CurseForgeView: NSView {
  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Size = DesignSystem.Size
  private typealias Width = DesignSystem.Width
  private typealias Fonts = DesignSystem.Fonts

  // MARK: - View-Specific Layout Constants

  private enum LocalLayout {
    static let curseForgeBottomSpace: CGFloat = 50
    static let filterMinWidth: CGFloat = 180
  }

  // MARK: - Properties

  private let curseForgeAPI: CurseForgeAPIClient

  private var curseForgeModpacks: [CurseForgeModpack] = []
  private var selectedModpack: CurseForgeModpack?
  private var modpackFiles: [CurseForgeModpackFile] = []
  private(set) var selectedModpackFile: CurseForgeModpackFile?
  private var currentSearchTerm: String = ""
  private var currentSortMethod: CurseForgeSortMethod = .featured
  private var currentPaginationIndex: Int = 0
  private var isLoadingMore: Bool = false
  private var hasMoreResults: Bool = true
  private var searchDebounceTimer: Timer?

  private var categories: [CurseForgeCategory] = []
  private var selectedCategoryIds: Set<Int> = []
  private var categoryCheckboxes: [Int: NSButton] = [:]

  private var curseForgeContentLoaded = false

  // MARK: - UI Components

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
        fontProvider: { _ in Fonts.bodyMedium },
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
    scrollView.layer?.cornerRadius = Radius.standard
    scrollView.layer?.borderWidth = 1
    scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
    return scrollView
  }()

  private let curseForgeFilterStackView: NSStackView = {
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.distribution = .fill
    stackView.spacing = 6
    stackView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    stackView.wantsLayer = true
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

  // MARK: - Initialization

  init(curseForgeAPI: CurseForgeAPIClient) {
    self.curseForgeAPI = curseForgeAPI
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    self.curseForgeAPI = CurseForgeAPIClient.shared
    super.init(coder: coder)
    setupUI()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Setup

  private func setupUI() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    layer?.cornerRadius = Radius.standard
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.separatorColor.cgColor

    addSubview(curseForgeFilterScrollView)
    curseForgeFilterStackView.translatesAutoresizingMaskIntoConstraints = false
    curseForgeFilterScrollView.documentView = curseForgeFilterStackView

    addSubview(curseForgeSearchField)
    addSubview(curseForgeSortLabel)
    addSubview(curseForgeSortPopup)
    addSubview(curseForgeModpackTableView)
    addSubview(curseForgeLoadingIndicator)
    addSubview(curseForgeEmptyLabel)
    addSubview(curseForgeVersionLabel)
    addSubview(curseForgeVersionPopup)
    addSubview(curseForgeVersionLoadingIndicator)

    curseForgeFilterScrollView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.content)
      make.left.equalToSuperview().offset(Spacing.content)
      make.width.equalTo(Width.filterPanel).priority(.required)
      make.bottom.equalToSuperview().offset(-LocalLayout.curseForgeBottomSpace)
    }

    curseForgeSearchField.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.content)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Spacing.content)
      make.right.equalToSuperview().offset(-Spacing.content)
      make.height.equalTo(Size.textFieldHeight)
    }

    curseForgeSortLabel.snp.makeConstraints { make in
      make.top.equalTo(curseForgeSearchField.snp.bottom).offset(Spacing.section)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Spacing.content)
      make.width.equalTo(Width.shortLabel)
    }

    curseForgeSortPopup.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeSortLabel)
      make.left.equalTo(curseForgeSortLabel.snp.right).offset(Spacing.tiny)
      make.width.equalTo(Width.popup)
      make.height.equalTo(Size.popupHeight)
    }

    curseForgeModpackTableView.snp.makeConstraints { make in
      make.top.equalTo(curseForgeSortLabel.snp.bottom).offset(Spacing.section)
      make.left.equalTo(curseForgeFilterScrollView.snp.right).offset(Spacing.content)
      make.right.equalToSuperview().offset(-Spacing.content)
      make.bottom.equalTo(curseForgeVersionLabel.snp.top).offset(-Spacing.section)
    }

    curseForgeLoadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(curseForgeModpackTableView)
      make.width.height.equalTo(Size.button)
    }

    curseForgeEmptyLabel.snp.makeConstraints { make in
      make.center.equalTo(curseForgeModpackTableView)
      make.width.equalTo(Width.panel)
    }

    curseForgeVersionLabel.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.content)
      make.left.equalTo(curseForgeSortPopup.snp.right).offset(Spacing.standard)
      make.width.equalTo(Width.filterCheckbox)
    }

    curseForgeVersionPopup.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeVersionLabel)
      make.left.equalTo(curseForgeVersionLabel.snp.right).offset(Spacing.tiny)
      make.right.equalToSuperview().offset(-Spacing.content)
      make.height.equalTo(Size.popupHeight)
    }

    curseForgeVersionLoadingIndicator.snp.makeConstraints { make in
      make.centerY.equalTo(curseForgeVersionPopup)
      make.left.equalTo(curseForgeVersionLabel.snp.left).offset(-24)
      make.width.height.equalTo(Size.smallIndicator)
    }

    curseForgeSearchField.target = self
    curseForgeSearchField.action = #selector(curseForgeSearchChanged)

    setupInfiniteScroll()
  }

  // MARK: - Public

  func loadIfNeeded() {
    guard !curseForgeContentLoaded else { return }
    curseForgeContentLoaded = true

    Logger.shared.info("Loading CurseForge content for the first time", category: "AddInstance")
    loadCategories()
    loadCurseForgeModpacks(reset: true)
  }

  // MARK: - Scroll Handling

  private func setupInfiniteScroll() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(modpackScrollViewDidScroll(_:)),
      name: NSScrollView.didLiveScrollNotification,
      object: curseForgeModpackTableView.scrollView
    )
  }

  @objc private func modpackScrollViewDidScroll(_ notification: Notification) {
    guard let scrollView = notification.object as? NSScrollView else { return }

    guard !isLoadingMore, hasMoreResults else { return }

    let contentView = scrollView.contentView
    let documentRect = contentView.documentRect
    let visibleRect = contentView.documentVisibleRect

    let scrollPosition = (visibleRect.origin.y + visibleRect.height) / documentRect.height
    let threshold: CGFloat = 0.8

    if scrollPosition > threshold {
      Logger.shared.info("Loading more modpacks (scroll position: \(Int(scrollPosition * 100))%)", category: "AddInstance")
      loadCurseForgeModpacks(reset: false)
    }
  }

  // MARK: - Actions

  @objc private func curseForgeSearchChanged() {
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

  @objc private func curseForgeVersionChanged() {
    let selectedIndex = curseForgeVersionPopup.indexOfSelectedItem
    guard selectedIndex >= 0, selectedIndex < modpackFiles.count else {
      selectedModpackFile = nil
      return
    }
    selectedModpackFile = modpackFiles[selectedIndex]
  }

  @objc private func categoryCheckboxChanged(_ sender: NSButton) {
    let categoryId = sender.tag

    if sender.state == .on {
      selectedCategoryIds.insert(categoryId)
    } else {
      selectedCategoryIds.remove(categoryId)
    }

    loadCurseForgeModpacks(reset: true)
  }

  // MARK: - CurseForge Methods

  private func loadCurseForgeModpacks(reset: Bool) {
    if reset {
      currentPaginationIndex = 0
      curseForgeModpacks.removeAll()
      hasMoreResults = true
    }

    guard !isLoadingMore else { return }
    guard hasMoreResults else { return }

    isLoadingMore = true

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
          if reset {
            self.curseForgeModpacks = response.data
          } else {
            self.curseForgeModpacks.append(contentsOf: response.data)
          }

          self.currentPaginationIndex = response.pagination.nextIndex
          self.hasMoreResults = response.pagination.hasMoreResults

          let modpackItems = self.curseForgeModpacks.map { ModpackItem(modpack: $0) }
          self.curseForgeModpackTableView.updateItems(modpackItems)

          self.curseForgeLoadingIndicator.stopAnimation(nil)
          self.curseForgeLoadingIndicator.isHidden = true
          self.isLoadingMore = false

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

          let alert = NSAlert()
          alert.messageText = Localized.AddInstance.errorLoadModpacksFailed
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

  private func loadModpackVersions(for modpack: CurseForgeModpack) {
    curseForgeVersionPopup.removeAllItems()
    selectedModpackFile = nil
    curseForgeVersionPopup.isEnabled = false

    curseForgeVersionLoadingIndicator.isHidden = false
    curseForgeVersionLoadingIndicator.startAnimation(nil)

    Task {
      do {
        let files = try await curseForgeAPI.getModpackFiles(modpackId: modpack.id)

        await MainActor.run {
          self.modpackFiles = files

          for file in files {
            self.curseForgeVersionPopup.addItem(withTitle: file.versionDisplayString)
          }

          if !files.isEmpty {
            self.curseForgeVersionPopup.selectItem(at: 0)
            self.selectedModpackFile = files[0]
            self.curseForgeVersionPopup.isEnabled = true
          }

          self.curseForgeVersionLoadingIndicator.stopAnimation(nil)
          self.curseForgeVersionLoadingIndicator.isHidden = true
        }
      } catch {
        await MainActor.run {
          Logger.shared.error("Failed to load modpack versions: \(error)", category: "AddInstance")
          self.curseForgeVersionLoadingIndicator.stopAnimation(nil)
          self.curseForgeVersionLoadingIndicator.isHidden = true

          self.curseForgeVersionPopup.addItem(withTitle: "Failed to load versions")
          self.curseForgeVersionPopup.isEnabled = false
        }
      }
    }
  }

  // MARK: - Category Loading

  private func loadCategories() {
    Task {
      do {
        let loadedCategories = try await curseForgeAPI.getCategories()
        Logger.shared.info("Loaded \(loadedCategories.count) categories from API", category: "AddInstance")

        await MainActor.run {
          self.categories = loadedCategories
          Logger.shared.info("Displaying \(self.categories.count) categories in filter panel", category: "AddInstance")
          self.createCategoryCheckboxes()
        }
      } catch {
        await MainActor.run {
          Logger.shared.error("Failed to load categories: \(error)", category: "AddInstance")
          self.showCategoryLoadError()
        }
      }
    }
  }

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

  private func createCategoryCheckboxes() {
    Logger.shared.debug("Creating category checkboxes for \(categories.count) categories", category: "AddInstance")

    curseForgeFilterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    categoryCheckboxes.removeAll()

    curseForgeFilterStackView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalToSuperview()
      make.width.lessThanOrEqualTo(curseForgeFilterScrollView.snp.width).offset(-Spacing.standard)
      make.width.greaterThanOrEqualTo(LocalLayout.filterMinWidth)
    }

    curseForgeFilterStackView.addArrangedSubview(curseForgeFilterTitleLabel)

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
      checkbox.setContentCompressionResistancePriority(.required, for: .horizontal)

      categoryCheckboxes[category.id] = checkbox
      curseForgeFilterStackView.addArrangedSubview(checkbox)
    }

    Logger.shared.debug("Created \(categoryCheckboxes.count) category checkboxes", category: "AddInstance")
  }
}
