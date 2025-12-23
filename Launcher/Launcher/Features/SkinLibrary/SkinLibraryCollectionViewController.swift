//
//  SkinLibraryCollectionViewController.swift
//  Launcher
//

import AppKit
import SnapKit
import SkinRenderKit

final class SkinLibraryCollectionViewController: NSViewController {
  private let library = SkinLibrary()
  private var dataSource: NSCollectionViewDiffableDataSource<Int, LauncherSkinAsset>!
  private var previewController: NSViewController?
  private var currentSkinPath: String?
  private var currentCapePath: String?

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingMiddle
    return label
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

  private lazy var collectionView: NSCollectionView = {
    let layout = NSCollectionViewFlowLayout()
    layout.itemSize = NSSize(width: 240, height: 100)
    layout.minimumInteritemSpacing = 12
    layout.minimumLineSpacing = 12

    let view = NSCollectionView()
    view.collectionViewLayout = layout
    view.register(SkinCollectionViewItem.self, forItemWithIdentifier: .skinItem)
    view.backgroundColors = [.clear]
    view.allowsMultipleSelection = false
    view.allowsEmptySelection = false
    view.isSelectable = true
    view.delegate = self
    return view
  }()

  private let scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.scrollerStyle = .overlay
    return scrollView
  }()

  private let previewContainer: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureDataSource()
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

    scrollView.documentView = collectionView

    view.addSubview(headerStack)
    view.addSubview(previewContainer)
    view.addSubview(scrollView)

    headerStack.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(12)
      make.left.equalToSuperview().offset(12)
      make.right.lessThanOrEqualToSuperview().offset(-12)
    }

    scrollView.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(8)
      make.right.equalToSuperview().inset(12)
      make.bottom.equalToSuperview().inset(12)
      make.width.equalTo(320)
    }

    previewContainer.snp.makeConstraints { make in
      make.top.equalTo(headerStack.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(12)
      make.right.equalTo(scrollView.snp.left).offset(-12)
      make.bottom.equalToSuperview().inset(12)
      make.height.greaterThanOrEqualTo(320)
    }
  }

  private func configureDataSource() {
    dataSource = NSCollectionViewDiffableDataSource<Int, LauncherSkinAsset>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      guard let item = collectionView.makeItem(withIdentifier: .skinItem, for: indexPath) as? SkinCollectionViewItem else {
        return nil
      }
      item.configure(with: itemIdentifier)
      return item
    }
  }

  @objc private func refresh() {
    do {
      let skins = try library.listSkins()
      let countText = skins.isEmpty ? "No skins found" : "Loaded \(skins.count) skins"
      statusLabel.stringValue = "\(countText) • \(library.libraryDirectory.path)"

      var snapshot = NSDiffableDataSourceSnapshot<Int, LauncherSkinAsset>()
      snapshot.appendSections([0])
      snapshot.appendItems(skins, toSection: 0)
      dataSource.apply(snapshot, animatingDifferences: true)

      if let first = skins.first {
        collectionView.selectItems(
          at: [IndexPath(item: 0, section: 0)],
          scrollPosition: .top
        )
        updatePreview(with: first)
      } else {
        clearPreview(message: "No skins to display")
      }
    } catch {
      statusLabel.stringValue = "Failed to load skins: \(error.localizedDescription)"
      var snapshot = NSDiffableDataSourceSnapshot<Int, LauncherSkinAsset>()
      dataSource.apply(snapshot, animatingDifferences: false)
      clearPreview(message: "Failed to load skins")
    }
  }

  @objc private func openFolder() {
    NSWorkspace.shared.activateFileViewerSelecting([library.libraryDirectory])
  }

  private func clearPreview(message: String) {
    previewController?.view.removeFromSuperview()
    previewController?.removeFromParent()
    previewController = nil

    previewContainer.subviews.forEach { $0.removeFromSuperview() }
    let label = NSTextField(labelWithString: message)
    label.alignment = .center
    label.textColor = .secondaryLabelColor
    previewContainer.addSubview(label)
    label.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }

  private func updatePreview(with skin: LauncherSkinAsset) {
    #if canImport(SkinRenderKit)
    // Track current selections
    switch skin.kind {
    case .skin:
      currentSkinPath = skin.fileURL.path
    case .cape:
      currentCapePath = skin.fileURL.path
    }

    let renderer: SceneKitCharacterViewController
    if let existing = previewController as? SceneKitCharacterViewController {
      renderer = existing
    } else {
      renderer = SceneKitCharacterViewController(
        texturePath: currentSkinPath ?? "",
        capeTexturePath: currentCapePath ?? "",
        playerModel: .steve,
        rotationDuration: 15,
        backgroundColor: .windowBackgroundColor
      )
      previewController?.view.removeFromSuperview()
      previewController?.removeFromParent()
      previewController = nil

      addChild(renderer)
      previewContainer.subviews.forEach { $0.removeFromSuperview() }
      previewContainer.addSubview(renderer.view)
      renderer.view.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(8)
      }
      previewController = renderer
    }

    // Apply textures based on selection, preserving the other asset if present.
    if let skinPath = currentSkinPath {
      renderer.updateTexture(path: skinPath)
    }
    if let capePath = currentCapePath {
      renderer.updateCapeTexture(path: capePath)
    }
    #else
    previewController?.view.removeFromSuperview()
    previewController?.removeFromParent()
    previewController = nil

    previewContainer.subviews.forEach { $0.removeFromSuperview() }
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.image = NSImage(contentsOf: skin.fileURL)
    previewContainer.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(8)
    }
    #endif
  }

  @objc private func didClickCollectionItem() {
    guard let indexPath = collectionView.selectionIndexPaths.first,
          let skin = dataSource.itemIdentifier(for: indexPath) else { return }
    updatePreview(with: skin)
  }
}

private extension NSUserInterfaceItemIdentifier {
  static let skinItem = NSUserInterfaceItemIdentifier("skinItem")
}

extension SkinLibraryCollectionViewController: NSCollectionViewDelegate {
  func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    guard let indexPath = indexPaths.first,
          let skin = dataSource.itemIdentifier(for: indexPath) else { return }
    updatePreview(with: skin)
  }

  func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    if collectionView.selectionIndexPaths.isEmpty {
      clearPreview(message: "No selection")
    }
  }
}

#Preview {
  SkinLibraryCollectionViewController()
}
