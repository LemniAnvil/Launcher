//
//  ViewController+CollectionView.swift
//  Launcher
//
//  NSCollectionView DataSource and Delegate extensions for ViewController
//

import AppKit
import Yatagarasu

// MARK: - NSCollectionViewDataSource

extension ViewController: NSCollectionViewDataSource {

  func collectionView(
    _ collectionView: NSCollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return instances.count
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    guard
      let item = collectionView.makeItem(
        withIdentifier: InstanceCollectionViewItem.identifier,
        for: indexPath
      ) as? InstanceCollectionViewItem
    else {
      return NSCollectionViewItem()
    }

    let instance = instances[indexPath.item]
    item.configure(with: instance)

    return item
  }
}

// MARK: - NSCollectionViewDelegate

extension ViewController: NSCollectionViewDelegate {

  func collectionView(
    _ collectionView: NSCollectionView,
    didSelectItemsAt indexPaths: Set<IndexPath>
  ) {
    guard let indexPath = indexPaths.first,
      indexPath.item < instances.count
    else { return }

    let selectedInstance = instances[indexPath.item]
    Logger.shared.info("Selected instance: \(selectedInstance.name)", category: "MainWindow")

    // Update sidebar with selected instance
    sidebarView.configure(with: selectedInstance)
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    didDeselectItemsAt indexPaths: Set<IndexPath>
  ) {
    // Clear sidebar when deselecting
    sidebarView.clearSelection()
  }
}
