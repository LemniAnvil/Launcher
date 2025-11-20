//
//  SettingsTabViewController.swift
//  Launcher
//
//  Tab view controller for settings
//

import AppKit

class SettingsTabViewController: NSViewController {
  // MARK: - Properties

  private let tabView: NSTabView = {
    let tabView = NSTabView()
    tabView.tabViewType = .topTabsBezelBorder
    return tabView
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 450))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(tabView)

    // Create tab view items
    let proxyTab = NSTabViewItem(viewController: ProxySettingsViewController())
    proxyTab.label = Localized.Settings.proxyTabTitle

    let downloadTab = NSTabViewItem(viewController: DownloadSettingsViewController())
    downloadTab.label = Localized.Settings.downloadTabTitle

    // Add tabs
    tabView.addTabViewItem(proxyTab)
    tabView.addTabViewItem(downloadTab)

    // Layout
    tabView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabView.topAnchor.constraint(equalTo: view.topAnchor),
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}
