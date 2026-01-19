//
//  AccountSkinLibraryView.swift
//  Launcher
//
//  View for managing local skin library within account details window
//

import AppKit
import SnapKit

protocol AccountSkinLibraryViewDelegate: AnyObject {
  func accountSkinLibraryView(_ view: AccountSkinLibraryView, didRequestUpload skin: LauncherSkinAsset)
  func accountSkinLibraryViewDidRequestImport(_ view: AccountSkinLibraryView)
}

final class AccountSkinLibraryView: NSView {

  weak var delegate: AccountSkinLibraryViewDelegate?

  private let library = SkinLibrary()
  private var skins: [LauncherSkinAsset] = []
  private var dataSource: NSCollectionViewDiffableDataSource<Int, LauncherSkinAsset>!

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
    layout.itemSize = NSSize(width: 200, height: 90)
    layout.minimumInteritemSpacing = 12
    layout.minimumLineSpacing = 12

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
    headerStack.orientation = .horizontal
    headerStack.alignment = .centerY
    headerStack.distribution = .fill
    headerStack.spacing = 12

    scrollView.documentView = collectionView

    addSubview(headerStack)
    addSubview(scrollView)
    addSubview(emptyLabel)

    headerStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.lessThanOrEqualToSuperview().offset(-20)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.bottom.equalToSuperview().offset(-20)
    }

    emptyLabel.snp.makeConstraints { make in
      make.center.equalTo(scrollView)
      make.left.right.equalToSuperview().inset(40)
    }
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
      return item
    }
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
}

// MARK: - Collection View Item

fileprivate final class AccountSkinCollectionItem: NSCollectionViewItem {

  var onUpload: ((LauncherSkinAsset) -> Void)?
  private var currentSkin: LauncherSkinAsset?

  private let thumbnailImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 4
    imageView.layer?.borderWidth = 1
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    return imageView
  }()

  private let nameLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.textColor = .labelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    label.lineBreakMode = .byTruncatingTail
    return label
  }()

  private let sizeLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 10)
    label.textColor = .secondaryLabelColor
    label.isEditable = false
    label.isBordered = false
    label.backgroundColor = .clear
    return label
  }()

  private lazy var uploadButton: NSButton = {
    let button = NSButton(title: Localized.Account.uploadToAccount, target: self, action: #selector(uploadClicked))
    button.bezelStyle = .rounded
    button.font = .systemFont(ofSize: 11)
    return button
  }()

  override func loadView() {
    view = NSView()
    view.wantsLayer = true

    view.addSubview(thumbnailImageView)
    view.addSubview(nameLabel)
    view.addSubview(sizeLabel)
    view.addSubview(uploadButton)

    thumbnailImageView.snp.makeConstraints { make in
      make.left.top.bottom.equalToSuperview().inset(8)
      make.width.equalTo(60)
      make.height.equalTo(74)
    }

    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.left.equalTo(thumbnailImageView.snp.right).offset(8)
      make.right.equalToSuperview().offset(-8)
    }

    sizeLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(2)
      make.left.equalTo(thumbnailImageView.snp.right).offset(8)
      make.right.equalToSuperview().offset(-8)
    }

    uploadButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-8)
      make.left.equalTo(thumbnailImageView.snp.right).offset(8)
      make.right.equalToSuperview().offset(-8)
      make.height.equalTo(24)
    }
  }

  func configure(with skin: LauncherSkinAsset) {
    currentSkin = skin
    nameLabel.stringValue = skin.name

    let sizeKB = Double(skin.fileSize) / 1024.0
    sizeLabel.stringValue = String(format: "%.1f KB", sizeKB)

    // Load thumbnail
    if let image = NSImage(contentsOf: skin.fileURL) {
      thumbnailImageView.image = image
    } else {
      thumbnailImageView.image = nil
    }
  }

  @objc private func uploadClicked() {
    guard let skin = currentSkin else { return }
    onUpload?(skin)
  }
}

// MARK: - Item Identifier Extension

fileprivate extension NSUserInterfaceItemIdentifier {
  static let accountSkinItem = NSUserInterfaceItemIdentifier("AccountSkinItem")
}
