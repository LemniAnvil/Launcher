//
//  AccountSkinLibraryView.swift
//  Launcher
//
//  View for managing local skin library within account details window
//

import AppKit
import SnapKit
import Yatagarasu

protocol AccountSkinLibraryViewDelegate: AnyObject {
  func accountSkinLibraryView(_ view: AccountSkinLibraryView, didRequestUpload skin: LauncherSkinAsset)
  func accountSkinLibraryViewDidRequestImport(_ view: AccountSkinLibraryView)
}

final class AccountSkinLibraryView: NSView {

  weak var delegate: AccountSkinLibraryViewDelegate?

  private let library = SkinLibrary()
  private var skins: [LauncherSkinAsset] = []
  private var dataSource: NSCollectionViewDiffableDataSource<Int, LauncherSkinAsset>!
  private var lastLayoutWidth: CGFloat = 0

  private enum Layout {
    static let minItemWidth: CGFloat = 170
    static let itemHeight: CGFloat = 200
    static let interItemSpacing: CGFloat = 16
  }

  // MARK: - UI Components

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingMiddle
    return label
  }()

  private lazy var importButton: NSButton = {
    let button = NSButton(title: Localized.Account.importFromFile, target: self, action: #selector(importFromFile))
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var refreshButton: NSButton = {
    let button = NSButton(title: Localized.Account.refreshSkins, target: self, action: #selector(refresh))
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var openFolderButton: NSButton = {
    let button = NSButton(title: Localized.Account.openSkinsFolder, target: self, action: #selector(openFolder))
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var collectionView: NSCollectionView = {
    let layout = NSCollectionViewFlowLayout()
    layout.itemSize = NSSize(width: Layout.minItemWidth, height: Layout.itemHeight)
    layout.minimumInteritemSpacing = Layout.interItemSpacing
    layout.minimumLineSpacing = Layout.interItemSpacing

    let view = NSCollectionView()
    view.collectionViewLayout = layout
    view.register(AccountSkinCollectionItem.self, forItemWithIdentifier: .accountSkinItem)
    view.backgroundColors = [.clear]
    view.allowsMultipleSelection = false
    view.allowsEmptySelection = true
    view.isSelectable = true
    return view
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.scrollerStyle = .overlay
    return scrollView
  }()

  private let emptyLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.Account.noLocalSkins)
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    return label
  }()


  // MARK: - Initialization

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
    configureDataSource()
    loadSkins()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupUI() {
    let buttonStack = NSStackView(views: [importButton, refreshButton, openFolderButton])
    buttonStack.orientation = .horizontal
    buttonStack.alignment = .centerY
    buttonStack.spacing = 8

    let headerStack = NSStackView(views: [statusLabel, buttonStack])
    headerStack.orientation = .vertical
    headerStack.alignment = .leading
    headerStack.distribution = .fill
    headerStack.spacing = 8

    scrollView.documentView = collectionView
    collectionView.menu = createContextMenu()

    addSubview(headerStack)
    addSubview(scrollView)
    addSubview(emptyLabel)

    headerStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    statusLabel.snp.makeConstraints { make in
      make.width.lessThanOrEqualToSuperview().priority(.required)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.bottom.equalToSuperview().offset(-20)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalTo(scrollView).inset(40)
    }
  }

  override func layout() {
    super.layout()
    updateCollectionLayoutIfNeeded()
  }

  private func updateCollectionLayoutIfNeeded() {
    guard let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout else { return }
    let availableWidth = scrollView.contentView.bounds.width
    guard availableWidth > 0 else { return }
    if abs(availableWidth - lastLayoutWidth) < 1 {
      return
    }
    lastLayoutWidth = availableWidth

    let columns = max(1, Int((availableWidth + Layout.interItemSpacing)
      / (Layout.minItemWidth + Layout.interItemSpacing)))
    let totalSpacing = Layout.interItemSpacing * CGFloat(max(0, columns - 1))
    let itemWidth = floor((availableWidth - totalSpacing) / CGFloat(columns))

    layout.itemSize = NSSize(width: itemWidth, height: Layout.itemHeight)
    layout.minimumInteritemSpacing = Layout.interItemSpacing
    layout.minimumLineSpacing = Layout.interItemSpacing
    layout.invalidateLayout()
  }

  private func configureDataSource() {
    dataSource = NSCollectionViewDiffableDataSource<Int, LauncherSkinAsset>(
      collectionView: collectionView
    ) { [weak self] collectionView, indexPath, itemIdentifier in
      guard let self = self,
            let item = collectionView.makeItem(
              withIdentifier: .accountSkinItem,
              for: indexPath
            ) as? AccountSkinCollectionItem else {
        return nil
      }
      item.configure(with: itemIdentifier)
      item.onUpload = { [weak self] skin in
        guard let self = self else { return }
        self.delegate?.accountSkinLibraryView(self, didRequestUpload: skin)
      }
      item.onRename = { [weak self] skin in
        guard let self = self else { return }
        self.showRenameDialog(for: skin)
      }
      return item
    }
  }

  // MARK: - Context Menu

  private func createContextMenu() -> NSMenu {
    let menu = NSMenu()
    let showInFinderItem = NSMenuItem(
      title: Localized.Account.menuShowInFinder,
      action: #selector(showSkinInFinder(_:)),
      keyEquivalent: ""
    )
    showInFinderItem.target = self
    menu.addItem(showInFinderItem)

    menu.addItem(NSMenuItem.separator())

    let deleteItem = NSMenuItem(
      title: Localized.Account.deleteButton,
      action: #selector(deleteSkin(_:)),
      keyEquivalent: ""
    )
    deleteItem.target = self
    menu.addItem(deleteItem)
    return menu
  }

  @objc private func showSkinInFinder(_ sender: Any?) {
    guard let skin = getClickedSkin() else { return }
    NSWorkspace.shared.activateFileViewerSelecting([skin.fileURL])
  }

  @objc private func deleteSkin(_ sender: Any?) {
    guard let skin = getClickedSkin() else { return }
    do {
      try FileManager.default.trashItem(at: skin.fileURL, resultingItemURL: nil)
      if let metadataID = skin.metadataID {
        try? library.deleteMetadata(metadataID: metadataID, kind: skin.kind)
      }
      loadSkins()
    } catch {
      showAlert(message: "Failed to delete skin: \(error.localizedDescription)")
    }
  }

  private func getClickedSkin() -> LauncherSkinAsset? {
    let point = collectionView.convert(window?.mouseLocationOutsideOfEventStream ?? .zero, from: nil)
    if let indexPath = collectionView.indexPathForItem(at: point),
       let skin = dataSource.itemIdentifier(for: indexPath) {
      return skin
    }
    if let selectedIndexPath = collectionView.selectionIndexPaths.first,
       let skin = dataSource.itemIdentifier(for: selectedIndexPath) {
      return skin
    }
    return nil
  }

  // MARK: - Public Methods

  func loadSkins() {
    do {
      skins = try library.listSkins().filter { $0.kind == .skin }
      let countText = skins.isEmpty ? Localized.Account.noLocalSkins : String(format: Localized.Account.skinCount, skins.count)
      statusLabel.stringValue = "\(countText) • \(library.libraryDirectory.path)"

      emptyLabel.isHidden = !skins.isEmpty

      var snapshot = NSDiffableDataSourceSnapshot<Int, LauncherSkinAsset>()
      snapshot.appendSections([0])
      snapshot.appendItems(skins, toSection: 0)
      dataSource.apply(snapshot, animatingDifferences: true)
    } catch {
      statusLabel.stringValue = "Error: \(error.localizedDescription)"
      emptyLabel.isHidden = false
    }
  }

  // MARK: - Actions

  @objc private func refresh() {
    loadSkins()
  }

  @objc private func openFolder() {
    NSWorkspace.shared.open(library.libraryDirectory)
  }

  @objc private func importFromFile() {
    delegate?.accountSkinLibraryViewDidRequestImport(self)
  }

  private func showRenameDialog(for skin: LauncherSkinAsset) {
    guard let metadataID = skin.metadataID else {
      showAlert(message: "Cannot rename: metadata not found")
      return
    }

    let alert = NSAlert()
    alert.messageText = "Rename Skin"
    alert.informativeText = "Enter a new display name for this skin:"
    alert.alertStyle = .informational

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
    textField.stringValue = skin.displayName
    textField.placeholderString = "Display name"
    alert.accessoryView = textField

    alert.addButton(withTitle: "Rename")
    alert.addButton(withTitle: "Cancel")

    let response = alert.runModal()

    if response == .alertFirstButtonReturn {
      let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !newName.isEmpty else {
        showAlert(message: "Display name cannot be empty")
        return
      }

      do {
        try library.updateDisplayName(metadataID: metadataID, kind: skin.kind, displayName: newName)
        loadSkins()
      } catch {
        showAlert(message: "Failed to rename: \(error.localizedDescription)")
      }
    }
  }

  private func showAlert(message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.runModal()
  }
}

fileprivate final class AccountSkinCollectionItem: NSCollectionViewItem {

  var onUpload: ((LauncherSkinAsset) -> Void)?
  var onRename: ((LauncherSkinAsset) -> Void)?
  private var currentSkin: LauncherSkinAsset?
  private static let avatarSize: CGFloat = 144

  private let thumbnailImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleAxesIndependently
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.layer?.borderWidth = 1
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    return imageView
  }()

  private let nameLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .labelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    label.lineBreakMode = .byTruncatingTail
    label.alignment = .left
    return label
  }()

  private let sizeLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    label.alignment = .left
    return label
  }()

  private lazy var uploadButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "arrow.up.circle",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.Account.uploadToAccount
    )
    button.target = self
    button.action = #selector(uploadClicked)
    return button
  }()

  private lazy var renameButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "pencil.circle",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemOrange,
      accessibilityLabel: "Rename"
    )
    button.target = self
    button.action = #selector(renameClicked)
    return button
  }()

  override func loadView() {
    view = NSView()
    view.wantsLayer = true

    let padding: CGFloat = 8
    let buttonSize: CGFloat = 32
    let buttonSpacing: CGFloat = 8
    let imageToTextSpacing: CGFloat = 6

    let textStack = NSStackView(views: [nameLabel, sizeLabel])
    textStack.orientation = .vertical
    textStack.alignment = .leading
    textStack.spacing = 2

    let actionStack = NSStackView(views: [uploadButton, renameButton])
    actionStack.orientation = .horizontal
    actionStack.alignment = .centerY
    actionStack.spacing = buttonSpacing

    view.addSubview(thumbnailImageView)
    view.addSubview(textStack)
    view.addSubview(actionStack)

    thumbnailImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(padding)
      make.left.equalToSuperview().offset(padding)
      make.width.height.equalTo(Self.avatarSize)
    }

    textStack.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(padding)
      make.right.lessThanOrEqualTo(actionStack.snp.left).offset(-padding)
      make.bottom.equalToSuperview().offset(-padding)
      make.top.greaterThanOrEqualTo(thumbnailImageView.snp.bottom).offset(imageToTextSpacing)
    }

    actionStack.snp.makeConstraints { make in
      make.right.equalTo(thumbnailImageView.snp.right)
      make.centerY.equalTo(textStack.snp.centerY)
    }

    uploadButton.snp.makeConstraints { make in
      make.width.height.equalTo(buttonSize)
    }

    renameButton.snp.makeConstraints { make in
      make.width.height.equalTo(buttonSize)
    }
  }

  func configure(with skin: LauncherSkinAsset) {
    currentSkin = skin
    nameLabel.stringValue = skin.displayName

    let sizeKB = Double(skin.fileSize) / 1024.0
    sizeLabel.stringValue = String(format: "%.1f KB", sizeKB)

    if skin.kind == .skin {
      let targetSize = NSSize(width: Self.avatarSize, height: Self.avatarSize)
      if let headImage = SkinHeadRenderer.extractHeadScaled(from: skin.fileURL, targetSize: targetSize) {
        thumbnailImageView.image = headImage
      } else {
        thumbnailImageView.image = nil
      }
    } else {
      if let image = NSImage(contentsOf: skin.fileURL) {
        thumbnailImageView.image = image
      } else {
        thumbnailImageView.image = nil
      }
    }
  }

  @objc private func uploadClicked() {
    guard let skin = currentSkin else { return }
    onUpload?(skin)
  }

  @objc private func renameClicked() {
    guard let skin = currentSkin else { return }
    onRename?(skin)
  }
}

// MARK: - Item Identifier Extension

fileprivate extension NSUserInterfaceItemIdentifier {
  static let accountSkinItem = NSUserInterfaceItemIdentifier("AccountSkinItem")
}
