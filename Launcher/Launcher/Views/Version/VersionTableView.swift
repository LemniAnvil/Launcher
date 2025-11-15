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
  private var tableDelegate: TableViewDelegateWrapper?

  enum Section: Hashable {
    case main
  }

  // MARK: - UI Components

  private lazy var scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .bezelBorder
    return scrollView
  }()

  private(set) lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.style = .plain
    tableView.rowHeight = 36
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.intercellSpacing = NSSize(width: 0, height: 0)

    // Add columns
    for column in columns {
      let tableColumn = NSTableColumn(
        identifier: NSUserInterfaceItemIdentifier(column.identifier)
      )
      tableColumn.title = column.title
      tableColumn.width = max(column.width, 20) // Ensure minimum width
      tableColumn.minWidth = 20 // Set minimum width to prevent negative values
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
    tableDelegate = TableViewDelegateWrapper(
      selectionChangedHandler: { [weak self] in
        self?.handleSelectionChanged()
      }
    )
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
    let reuseIdentifier = columnIdentifier
    var cellView = tableView.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier),
      owner: self
    ) as? NSTableCellView

    // Create new cell if needed
    if cellView == nil {
      cellView = NSTableCellView()
      cellView?.identifier = NSUserInterfaceItemIdentifier(reuseIdentifier)

      let textField = NSTextField()
      textField.isBordered = false
      textField.isBezeled = false
      textField.drawsBackground = false
      textField.isEditable = false
      textField.isSelectable = false
      textField.translatesAutoresizingMaskIntoConstraints = false

      cellView?.addSubview(textField)
      cellView?.textField = textField

      if let cellView = cellView {
        NSLayoutConstraint.activate([
          textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
          textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
          textField.trailingAnchor.constraint(lessThanOrEqualTo: cellView.trailingAnchor, constant: -8),
        ])
      }
    }

    // Update cell content
    guard let textField = cellView?.textField else {
      return cellView ?? NSTableCellView()
    }

    textField.stringValue = columnConfig.valueProvider(item)
    textField.font = columnConfig.fontProvider?(item) ?? .systemFont(ofSize: 12)
    textField.textColor = columnConfig.colorProvider?(item) ?? .labelColor

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
}
