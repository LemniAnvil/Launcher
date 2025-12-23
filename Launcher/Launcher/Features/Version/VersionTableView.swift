//
//  VersionTableView.swift
//  Launcher
//
//  Reusable table view component for displaying versions with customizable columns
//

import AppKit
import SnapKit

/// A reusable table view for displaying version information
class VersionTableView<Item: Hashable>: NSView {

  // MARK: - Properties

  /// Column configuration
  struct ColumnConfig {
    let identifier: String
    let title: String
    let width: CGFloat
    let valueProvider: (Item) -> String
    let fontProvider: ((Item) -> NSFont)?
    let colorProvider: ((Item) -> NSColor)?

    init(
      identifier: String,
      title: String,
      width: CGFloat,
      valueProvider: @escaping (Item) -> String,
      fontProvider: ((Item) -> NSFont)? = nil,
      colorProvider: ((Item) -> NSColor)? = nil
    ) {
      self.identifier = identifier
      self.title = title
      self.width = width
      self.valueProvider = valueProvider
      self.fontProvider = fontProvider
      self.colorProvider = colorProvider
    }
  }

  private let columns: [ColumnConfig]
  private var dataSource: NSTableViewDiffableDataSource<Section, Item>?
  private var onSelectionChanged: ((Item?) -> Void)?
  // swiftlint:disable:next weak_delegate
  private var tableDelegate: TableViewDelegateWrapper?

  enum Section: Hashable {
    case main
  }

  // MARK: - UI Components

  lazy var scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    scrollView.scrollerStyle = .overlay
    return scrollView
  }()

  private(set) lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    // Finder-style appearance
    tableView.style = .fullWidth
    tableView.rowSizeStyle = .medium
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.allowsEmptySelection = false
    tableView.allowsMultipleSelection = false
    tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    tableView.intercellSpacing = NSSize(width: 3, height: 6)
    tableView.gridStyleMask = [.solidHorizontalGridLineMask]
    tableView.gridColor = NSColor.separatorColor.withAlphaComponent(0.3)

    // Add columns
    for column in columns {
      let tableColumn = NSTableColumn(
        identifier: NSUserInterfaceItemIdentifier(column.identifier)
      )
      tableColumn.title = column.title
      tableColumn.width = max(column.width, 20) // Ensure minimum width
      tableColumn.minWidth = 80 // Set reasonable minimum width
      tableView.addTableColumn(tableColumn)
    }

    return tableView
  }()

  // MARK: - Initialization

  init(
    columns: [ColumnConfig],
    onSelectionChanged: ((Item?) -> Void)? = nil
  ) {
    self.columns = columns
    self.onSelectionChanged = onSelectionChanged
    super.init(frame: .zero)
    setupUI()
    setupDataSource()
    setupDelegate()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupUI() {
    addSubview(scrollView)

    scrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    // Set document view after constraints to ensure proper geometry
    scrollView.documentView = tableView
  }

  private func setupDataSource() {
    dataSource = NSTableViewDiffableDataSource<Section, Item>(
      tableView: tableView
    ) { [weak self] _, tableColumn, _, item in
      guard let self = self else { return NSView() }
      return self.makeCell(for: item, column: tableColumn)
    }
  }

  private func setupDelegate() {
    tableDelegate = TableViewDelegateWrapper { [weak self] in
      self?.handleSelectionChanged()
    }
    tableView.delegate = tableDelegate
  }

  // MARK: - Cell Creation

  private func makeCell(
    for item: Item,
    column: NSTableColumn?
  ) -> NSView {
    guard let columnIdentifier = column?.identifier.rawValue,
          let columnConfig = columns.first(where: { $0.identifier == columnIdentifier }) else {
      return NSTableCellView()
    }

    // Try to reuse an existing cell view
    let reuseIdentifier = "DataCell"
    var cellView = tableView.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier),
      owner: self
    ) as? NSTableCellView

    // Create new cell if needed
    if cellView == nil {
      cellView = NSTableCellView()
      cellView?.identifier = NSUserInterfaceItemIdentifier(reuseIdentifier)

      // Create text field (NOT label) for Finder-style appearance
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

      cellView?.textField = textField
      cellView?.addSubview(textField)

      // Pin to edges with better padding for Finder-style appearance
      textField.snp.makeConstraints { make in
        // make.left.equalToSuperview().offset(4)
        // make.right.equalToSuperview().offset(-4)
        make.centerY.equalToSuperview()
      }
    }

    // Update cell content
    guard let textField = cellView?.textField else {
      return cellView ?? NSTableCellView()
    }

    // Set content with larger font for Finder-style appearance
    textField.stringValue = columnConfig.valueProvider(item)
    textField.font = columnConfig.fontProvider?(item) ?? .systemFont(ofSize: 13)
    textField.textColor = columnConfig.colorProvider?(item) ?? .labelColor
    textField.alignment = .left

    return cellView ?? NSTableCellView()
  }

  // MARK: - Selection Handling

  private func handleSelectionChanged() {
    onSelectionChanged?(selectedItem)
  }

  // MARK: - Public Methods

  /// Update the table with new items
  func updateItems(_ items: [Item], animatingDifferences: Bool = true) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections([.main])
    snapshot.appendItems(items, toSection: .main)
    dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
  }

  /// Get the currently selected item
  var selectedItem: Item? {
    let row = tableView.selectedRow
    guard row >= 0 else { return nil }
    return dataSource?.itemIdentifier(forRow: row)
  }

  /// Select an item by index
  func selectItem(at index: Int) {
    guard index >= 0 else { return }
    tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
  }

  /// Clear selection
  func clearSelection() {
    tableView.deselectAll(nil)
  }
}

// MARK: - Delegate Wrapper

private class TableViewDelegateWrapper: NSObject, NSTableViewDelegate {
  var selectionChangedHandler: (() -> Void)?

  init(selectionChangedHandler: (() -> Void)? = nil) {
    self.selectionChangedHandler = selectionChangedHandler
    super.init()
  }

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    return true
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    selectionChangedHandler?()
  }

  // Custom row height for Finder-style appearance
  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    return 24.0
  }
}
