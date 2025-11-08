//
//  CreateInstanceViewController.swift
//  Launcher
//
//  View controller for creating new instance
//

import AppKit
import SnapKit
import Yatagarasu

class CreateInstanceViewController: NSViewController {

  // MARK: - Properties

  var onInstanceCreated: ((Instance) -> Void)?
  var onCancel: (() -> Void)?

  private let instanceManager = InstanceManager.shared
  private let versionManager = VersionManager.shared
  private var preselectedVersionId: String?

  // MARK: - UI Components

  // Instance info container
  private let infoContainerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = 8
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.imageScaling = .scaleProportionallyUpOrDown

    // Create a simple grass block-like icon using system symbols
    let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .regular)
    let cubeImage = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: nil)
    let configuredImage = cubeImage?.withSymbolConfiguration(config)
    imageView.image = configuredImage
    imageView.contentTintColor = .systemGreen

    return imageView
  }()

  private let nameLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Instances.instanceNameLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var nameTextField: NSTextField = {
    let field = NSTextField()
    field.placeholderString = Localized.Instances.instanceNamePlaceholder
    field.font = .systemFont(ofSize: 13)
    field.lineBreakMode = .byTruncatingTail
    return field
  }()

  private let versionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Instances.versionLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var versionPopUpButton: NSPopUpButton = {
    let button = NSPopUpButton()
    button.font = .systemFont(ofSize: 13)
    button.target = self
    button.action = #selector(versionSelectionChanged)
    return button
  }()

  private lazy var createButton: NSButton = {
    let button = NSButton(title: Localized.Instances.createButton, target: self, action: #selector(createInstance))
    button.bezelStyle = .rounded
    button.keyEquivalent = "\r"
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton(title: Localized.Instances.cancelButton, target: self, action: #selector(cancel))
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    return button
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 680))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadInstalledVersions()
  }

  // MARK: - Setup

  private func setupUI() {
    // Add main container
    view.addSubview(infoContainerView)

    // Add components to info container
    infoContainerView.addSubview(iconImageView)
    infoContainerView.addSubview(nameLabel)
    infoContainerView.addSubview(nameTextField)

    // Add other components
    view.addSubview(versionLabel)
    view.addSubview(versionPopUpButton)
    view.addSubview(cancelButton)
    view.addSubview(createButton)

    // Layout info container
    infoContainerView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(160)
    }

    // Layout icon
    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(20)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(120)
    }

    // Layout name label and text field
    nameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(40)
      make.left.equalTo(iconImageView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    nameTextField.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(8)
      make.left.equalTo(iconImageView.snp.right).offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(28)
    }

    // Layout version selection
    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(infoContainerView.snp.bottom).offset(24)
      make.left.equalToSuperview().offset(20)
    }

    versionPopUpButton.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(24)
    }

    // Layout buttons
    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalTo(createButton.snp.left).offset(-12)
      make.width.equalTo(100)
    }

    createButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(100)
    }
  }

  private func loadInstalledVersions() {
    let installedVersions = versionManager.getInstalledVersions()
      .sorted { version1, version2 in
        version1.compare(version2, options: .numeric) == .orderedDescending
      }

    versionPopUpButton.removeAllItems()

    if installedVersions.isEmpty {
      versionPopUpButton.addItem(withTitle: Localized.Instances.noVersionsInstalled)
      versionPopUpButton.isEnabled = false
      createButton.isEnabled = false
    } else {
      versionPopUpButton.addItems(withTitles: installedVersions)
      versionPopUpButton.isEnabled = true
      createButton.isEnabled = true

      // If there's a preselected version, select it
      if let preselectedVersionId = preselectedVersionId {
        if let index = installedVersions.firstIndex(of: preselectedVersionId) {
          versionPopUpButton.selectItem(at: index)
        } else {
          // Version not in installed list, add it and select it
          versionPopUpButton.insertItem(withTitle: preselectedVersionId, at: 0)
          versionPopUpButton.selectItem(at: 0)
        }
      }

      // Auto-fill name with selected version if name is empty
      updateNameFromVersion()
    }
  }

  private func updateNameFromVersion() {
    // Only update if name field is empty
    if nameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      if let selectedVersion = versionPopUpButton.selectedItem?.title {
        nameTextField.stringValue = selectedVersion
      }
    }
  }

  /// Set the selected version in the popup button
  func setSelectedVersion(_ versionId: String) {
    preselectedVersionId = versionId
    loadInstalledVersions()
  }

  // MARK: - Actions

  @objc private func versionSelectionChanged() {
    updateNameFromVersion()
  }

  @objc private func createInstance() {
    guard let name = nameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty else {
      showError(Localized.Instances.errorEmptyName)
      return
    }

    guard let selectedVersion = versionPopUpButton.selectedItem?.title.nonEmpty else {
      showError(Localized.Instances.errorNoVersionSelected)
      return
    }

    do {
      let instance = try instanceManager.createInstance(name: name, versionId: selectedVersion)
      onInstanceCreated?(instance)
      view.window?.close()
    } catch {
      showError(error.localizedDescription)
    }
  }

  @objc private func cancel() {
    onCancel?()
    view.window?.close()
  }

  private func showError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.Instances.errorTitle
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Instances.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}

// MARK: - String Extension

private extension String {
  var nonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
