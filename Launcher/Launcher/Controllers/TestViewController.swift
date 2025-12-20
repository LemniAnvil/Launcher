//
//  TestViewController.swift
//  Launcher
//
//  Debug view controller to exercise MultiMCImportTool and show results with AppKit components.
//

import AppKit
import SnapKit

final class TestViewController: NSViewController {
  private let importTool = MultiMCImportTool()
  private var instances: [MultiMCInstanceInfo] = []

  private let rootLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.lineBreakMode = .byTruncatingMiddle
    return label
  }()

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingTail
    return label
  }()

  private lazy var tableView: NSTableView = {
    let tableView = NSTableView()
    tableView.headerView = nil
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.addTableColumn(NSTableColumn(identifier: .name))
    tableView.addTableColumn(NSTableColumn(identifier: .version))
    tableView.addTableColumn(NSTableColumn(identifier: .directory))
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

  override func loadView() {
    view = NSView()
    view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    runImport()
  }

  private func setupUI() {
    let headerStack = NSStackView(views: [rootLabel, statusLabel])
    headerStack.orientation = .vertical
    headerStack.alignment = .leading
    headerStack.spacing = 4

    tableContainer.documentView = tableView

    view.addSubview(headerStack)
    view.addSubview(tableContainer)

    headerStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(12)
      make.left.right.equalToSuperview().inset(12)
    }

    tableContainer.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(8)
      make.left.right.bottom.equalToSuperview().inset(12)
    }
  }

  private func runImport() {
    let fm = FileManager.default
    let rootPath = importTool.instancesRoot.path
    let exists = fm.fileExists(atPath: rootPath)
    let entries = (try? fm.contentsOfDirectory(atPath: rootPath)) ?? []

    rootLabel.stringValue = "Instances root: \(rootPath)"
    statusLabel.stringValue = "Root exists: \(exists) | Entries: \(entries.count)"

    do {
      instances = try importTool.loadInstances()
      statusLabel.stringValue += instances.isEmpty ? " | No instances found." : " | Loaded: \(instances.count)"
      tableView.reloadData()
    } catch {
      statusLabel.stringValue += " | Import failed: \(error.localizedDescription)"
      instances = []
      tableView.reloadData()
    }
  }
}

private extension NSUserInterfaceItemIdentifier {
  static let name = NSUserInterfaceItemIdentifier("name")
  static let version = NSUserInterfaceItemIdentifier("version")
  static let directory = NSUserInterfaceItemIdentifier("directory")
  static let path = NSUserInterfaceItemIdentifier("path")
}

extension TestViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    instances.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard row < instances.count, let identifier = tableColumn?.identifier else { return nil }
    let info = instances[row]

    let text: String
    switch identifier {
    case .name: text = info.name
    case .version: text = info.versionId
    case .directory: text = info.directoryName
    case .path: text = info.path.path
    default: text = ""
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
  TestViewController()
}
