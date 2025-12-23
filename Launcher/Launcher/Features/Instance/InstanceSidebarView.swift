//
//  InstanceSidebarView.swift
//  Launcher
//
//  Instance sidebar view displaying selected instance information and actions
//

import AppKit
import SnapKit
import Yatagarasu

/// Sidebar view for displaying instance details and actions
class InstanceSidebarView: NSView {
  // MARK: - UI Components

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 12
    imageView.layer?.masksToBounds = true
    return imageView
  }()

  private let instanceNameLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )
    label.lineBreakMode = .byTruncatingTail
    return label
  }()

  private let versionLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  /// Badge for external instance source
  private let sourceBadge: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 10, weight: .medium),
      textColor: .white,
      alignment: .center
    )
    label.wantsLayer = true
    label.layer?.cornerRadius = 4
    label.isHidden = true
    return label
  }()

  private let separator1: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private let actionButtonsStackView: NSStackView = {
    let stackView = NSStackView()
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 8
    return stackView
  }()

  private lazy var launchButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarLaunch
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(launchButtonClicked)
    return button
  }()

  private lazy var killButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarKill
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(killButtonClicked)
    button.isEnabled = false
    return button
  }()

  private lazy var editButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarEdit
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(editButtonClicked)
    return button
  }()

  private lazy var renameButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarChangeGroup
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(renameButtonClicked)
    return button
  }()

  private lazy var folderButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarOpenFolder
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(folderButtonClicked)
    return button
  }()

  private lazy var exportButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarExport
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(exportButtonClicked)
    return button
  }()

  private lazy var copyButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarCopy
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(copyButtonClicked)
    return button
  }()

  private lazy var deleteButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarDelete
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(deleteButtonClicked)
    return button
  }()

  private lazy var shortcutButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Instances.sidebarCreateShortcut
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(shortcutButtonClicked)
    return button
  }()

  private let emptyStateLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Instances.sidebarEmptyState,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  // MARK: - Properties

  private var currentInstance: Instance?

  // Callbacks
  var onLaunch: ((Instance) -> Void)?
  var onKill: ((Instance) -> Void)?
  var onEdit: ((Instance) -> Void)?
  var onRename: ((Instance) -> Void)?
  var onOpenFolder: ((Instance) -> Void)?
  var onExport: ((Instance) -> Void)?
  var onCopy: ((Instance) -> Void)?
  var onDelete: ((Instance) -> Void)?
  var onCreateShortcut: ((Instance) -> Void)?

  // MARK: - Initialization

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    wantsLayer = true
    // Set a distinct darker background for better visibility
    layer?.backgroundColor = NSColor(calibratedWhite: 0.15, alpha: 1.0).cgColor

    addSubview(iconImageView)
    addSubview(instanceNameLabel)
    addSubview(versionLabel)
    addSubview(sourceBadge)
    addSubview(separator1)
    addSubview(actionButtonsStackView)
    addSubview(emptyStateLabel)

    // Add buttons to stack view
    actionButtonsStackView.addArrangedSubview(launchButton)
    actionButtonsStackView.addArrangedSubview(killButton)
    actionButtonsStackView.addArrangedSubview(editButton)
    actionButtonsStackView.addArrangedSubview(renameButton)
    actionButtonsStackView.addArrangedSubview(folderButton)
    actionButtonsStackView.addArrangedSubview(exportButton)
    actionButtonsStackView.addArrangedSubview(copyButton)
    actionButtonsStackView.addArrangedSubview(deleteButton)
    actionButtonsStackView.addArrangedSubview(shortcutButton)

    setupConstraints()
    showEmptyState()
  }

  private func setupConstraints() {
    // Add top padding to account for the header area (approximately 68px)
    let headerHeight: CGFloat = 68

    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(headerHeight + 20)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(80)
    }

    instanceNameLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(16)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(instanceNameLabel.snp.bottom).offset(4)
      make.left.right.equalToSuperview().inset(16)
    }

    sourceBadge.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
      make.width.equalTo(80)
      make.height.equalTo(20)
    }

    separator1.snp.makeConstraints { make in
      make.top.equalTo(sourceBadge.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(16)
      make.height.equalTo(1)
    }

    actionButtonsStackView.snp.makeConstraints { make in
      make.top.equalTo(separator1.snp.bottom).offset(16)
      make.left.right.equalToSuperview().inset(16)
    }

    // Make all buttons full width
    [
      launchButton,
      killButton,
      editButton,
      renameButton,
      folderButton,
      exportButton,
      copyButton,
      deleteButton,
      shortcutButton,
    ].forEach { button in
      button.snp.makeConstraints { make in
        make.left.right.equalToSuperview()
        make.height.equalTo(32)
      }
    }

    emptyStateLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.left.right.equalToSuperview().inset(20)
    }
  }

  // MARK: - Public Methods

  func configure(with instance: Instance) {
    currentInstance = instance

    instanceNameLabel.stringValue = instance.name
    versionLabel.stringValue = instance.versionId

    // Configure icon
    configureIcon(for: instance)

    // Configure source badge
    configureSourceBadge(for: instance)

    // Configure button states based on instance editability
    configureButtonStates(for: instance)

    showInstanceDetails()
  }

  /// Configure icon based on instance
  private func configureIcon(for instance: Instance) {
    // Check for custom icon path first (external instances)
    if let iconPath = instance.iconPath,
      let iconImage = NSImage(contentsOf: iconPath)
    {
      iconImageView.image = iconImage
      return
    }

    // Load instance icon - use default Minecraft grass block icon
    if let defaultIcon = NSImage(named: "minecraft_icon") {
      iconImageView.image = defaultIcon
    } else {
      // Fallback to system icon
      iconImageView.image = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: nil)
    }
  }

  /// Configure source badge for external instances
  private func configureSourceBadge(for instance: Instance) {
    switch instance.source {
    case .prism:
      sourceBadge.stringValue = "PrismLauncher"
      sourceBadge.layer?.backgroundColor = NSColor.systemPurple.withAlphaComponent(0.8).cgColor
      sourceBadge.isHidden = false
    case .native:
      sourceBadge.isHidden = true
    }
  }

  /// Configure button enabled states based on instance editability
  private func configureButtonStates(for instance: Instance) {
    let isEditable = instance.isEditable

    // These actions are always available
    launchButton.isEnabled = true
    folderButton.isEnabled = true

    // These actions are only available for native instances
    editButton.isEnabled = isEditable
    renameButton.isEnabled = isEditable
    exportButton.isEnabled = isEditable
    copyButton.isEnabled = isEditable
    deleteButton.isEnabled = isEditable
    shortcutButton.isEnabled = isEditable

    // Update button appearance for disabled state
    let disabledButtons = [
      editButton, renameButton, exportButton, copyButton, deleteButton, shortcutButton,
    ]
    for button in disabledButtons {
      button.alphaValue = button.isEnabled ? 1.0 : 0.5
    }
  }

  func clearSelection() {
    currentInstance = nil
    showEmptyState()
  }

  private func showEmptyState() {
    iconImageView.isHidden = true
    instanceNameLabel.isHidden = true
    versionLabel.isHidden = true
    sourceBadge.isHidden = true
    separator1.isHidden = true
    actionButtonsStackView.isHidden = true
    emptyStateLabel.isHidden = false
  }

  private func showInstanceDetails() {
    iconImageView.isHidden = false
    instanceNameLabel.isHidden = false
    versionLabel.isHidden = false
    // sourceBadge visibility is controlled by configureSourceBadge
    separator1.isHidden = false
    actionButtonsStackView.isHidden = false
    emptyStateLabel.isHidden = true
  }
}

// MARK: - Actions

extension InstanceSidebarView {

  @objc private func launchButtonClicked() {
    guard let instance = currentInstance else { return }
    onLaunch?(instance)
  }

  @objc private func killButtonClicked() {
    guard let instance = currentInstance else { return }
    onKill?(instance)
  }

  @objc private func editButtonClicked() {
    guard let instance = currentInstance else { return }
    onEdit?(instance)
  }

  @objc private func renameButtonClicked() {
    guard let instance = currentInstance else { return }
    onRename?(instance)
  }

  @objc private func folderButtonClicked() {
    guard let instance = currentInstance else { return }
    onOpenFolder?(instance)
  }

  @objc private func exportButtonClicked() {
    guard let instance = currentInstance else { return }
    onExport?(instance)
  }

  @objc private func copyButtonClicked() {
    guard let instance = currentInstance else { return }
    onCopy?(instance)
  }

  @objc private func deleteButtonClicked() {
    guard let instance = currentInstance else { return }
    onDelete?(instance)
  }

  @objc private func shortcutButtonClicked() {
    guard let instance = currentInstance else { return }
    onCreateShortcut?(instance)
  }
}
