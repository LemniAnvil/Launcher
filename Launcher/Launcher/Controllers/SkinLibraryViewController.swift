//
//  SkinLibraryViewController.swift
//  Launcher
//
//  Simple viewer for skins stored in Application Support/Launcher/Skins.
//

import AppKit
import SnapKit

final class SkinLibraryViewController: NSViewController {
  private let library = SkinLibrary()
  private var skins: [LauncherSkinAsset] = []

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingMiddle
    return label
  }()

  private lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.headerView = nil
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.addTableColumn(NSTableColumn(identifier: .name))
    tableView.addTableColumn(NSTableColumn(identifier: .size))
    tableView.addTableColumn(NSTableColumn(identifier: .modified))
    tableView.addTableColumn(NSTableColumn(identifier: .path))
    tableView.delegate = self
    tableView.dataSource = self
    return tableView
  }()

  private let tableContainer: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    return scrollView
  }()

  private lazy var refreshButton: NSButton = {
    let button = NSButton(title: "Refresh", target: self, action: #selector(refresh))
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var openFolderButton: NSButton = {
    let button = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
    button.bezelStyle = .rounded
    return button
  }()

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    refresh()
  }

  private func setupUI() {
    let buttonStack = NSStackView(views: [refreshButton, openFolderButton])
    buttonStack.orientation = .horizontal
    buttonStack.alignment = .centerY
    buttonStack.spacing = 8

    let headerStack = NSStackView(views: [statusLabel, buttonStack])
    headerStack.orientation = .horizontal
    headerStack.alignment = .centerY
    headerStack.distribution = .fill
    headerStack.spacing = 8

    tableContainer.documentView = tableView

    view.addSubview(headerStack)
    view.addSubview(tableContainer)

    headerStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(32)
      make.left.equalToSuperview().offset(12)
      make.right.lessThanOrEqualToSuperview().offset(-12)
    }

    tableContainer.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(8)
      make.left.right.bottom.equalToSuperview().inset(12)
    }
  }

  @objc private func refresh() {
    do {
      skins = try library.listSkins()
      let countText = skins.isEmpty ? "No skins found" : "Loaded \(skins.count) skins"
      statusLabel.stringValue = "\(countText) • \(library.libraryDirectory.path)"
      tableView.reloadData()
    } catch {
      statusLabel.stringValue = "Failed to load skins: \(error.localizedDescription)"
      skins = []
      tableView.reloadData()
    }
  }

  @objc private func openFolder() {
    NSWorkspace.shared.activateFileViewerSelecting([library.libraryDirectory])
  }
}

private extension NSUserInterfaceItemIdentifier {
  static let name = NSUserInterfaceItemIdentifier("name")
  static let size = NSUserInterfaceItemIdentifier("size")
  static let modified = NSUserInterfaceItemIdentifier("modified")
  static let path = NSUserInterfaceItemIdentifier("path")
}

extension SkinLibraryViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    skins.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard row < skins.count, let identifier = tableColumn?.identifier else { return nil }
    let skin = skins[row]
    let text: String

    switch identifier {
    case .name:
      text = skin.name
    case .size:
      text = ByteCountFormatter.string(fromByteCount: skin.fileSize, countStyle: .file)
    case .modified:
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      text = formatter.string(from: skin.lastModified)
    case .path:
      text = skin.fileURL.path
    default:
      text = ""
    }

    let cell = NSTableCellView()
    let textField = NSTextField(labelWithString: text)
    textField.lineBreakMode = identifier == .path ? .byTruncatingMiddle : .byTruncatingTail
    cell.addSubview(textField)
    textField.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(4)
    }
    return cell
  }
}

#Preview {
  SkinLibraryViewController()
}
