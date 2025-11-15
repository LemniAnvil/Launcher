//
//  InstanceDetailViewController.swift
//  Launcher
//
//  Instance detail view controller - displays instance configuration
//

import AppKit
import SnapKit
import Yatagarasu

class InstanceDetailViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  private var instance: Instance
  private let instanceManager = InstanceManager.shared
  private var isEditMode = false

  var onClose: (() -> Void)?
  var onSaved: ((Instance) -> Void)?

  // MARK: - UI Components

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 16
    imageView.imageScaling = .scaleProportionallyUpOrDown
    let config = NSImage.SymbolConfiguration(pointSize: 80, weight: .regular)
    let image = NSImage(
      systemSymbolName: "cube.box.fill",
      accessibilityDescription: nil
    )
    imageView.image = image?.withSymbolConfiguration(config)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 24, weight: .bold),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let versionLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 14),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  private let separator1: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // Configuration section
  private let configTitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.configurationTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let nameFieldLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.nameLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let nameValueLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var nameTextField: NSTextField = {
    let field = NSTextField()
    field.font = .systemFont(ofSize: 13)
    field.isHidden = true
    return field
  }()

  private let versionFieldLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.versionLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let versionValueLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let idFieldLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.idLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let idValueLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 11, weight: .regular),
      textColor: .tertiaryLabelColor,
      alignment: .left
    )
    label.maximumNumberOfLines = 1
    return label
  }()

  private let createdFieldLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.createdLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let createdValueLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let modifiedFieldLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.InstanceDetail.modifiedLabel,
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let modifiedValueLabel: BRLabel = {
    let label = BRLabel(
      text: "",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let separator2: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // Actions section
  private lazy var editButton: NSButton = {
    let button = NSButton(
      title: Localized.InstanceDetail.editButton,
      target: self,
      action: #selector(toggleEditMode)
    )
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var saveButton: NSButton = {
    let button = NSButton(
      title: Localized.InstanceDetail.saveButton,
      target: self,
      action: #selector(saveChanges)
    )
    button.bezelStyle = .rounded
    button.isHidden = true
    return button
  }()

  private lazy var cancelEditButton: NSButton = {
    let button = NSButton(
      title: Localized.InstanceDetail.cancelButton,
      target: self,
      action: #selector(cancelEdit)
    )
    button.bezelStyle = .rounded
    button.isHidden = true
    button.keyEquivalent = "\u{1b}"
    return button
  }()

  private lazy var openFolderButton: NSButton = {
    let button = NSButton(
      title: Localized.InstanceDetail.openFolderButton,
      target: self,
      action: #selector(openInstanceFolder)
    )
    button.bezelStyle = .rounded
    return button
  }()

  private lazy var closeButton: NSButton = {
    let button = NSButton(
      title: Localized.InstanceDetail.closeButton,
      target: self,
      action: #selector(close)
    )
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    return button
  }()

  // MARK: - Initialization

  init(instance: Instance) {
    self.instance = instance
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 600))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureWithInstance()
  }

  // MARK: - Setup UI

  private func setupUI() {
    view.addSubview(iconImageView)
    view.addSubview(titleLabel)
    view.addSubview(versionLabel)
    view.addSubview(separator1)

    view.addSubview(configTitleLabel)
    view.addSubview(nameFieldLabel)
    view.addSubview(nameValueLabel)
    view.addSubview(nameTextField)
    view.addSubview(versionFieldLabel)
    view.addSubview(versionValueLabel)
    view.addSubview(idFieldLabel)
    view.addSubview(idValueLabel)
    view.addSubview(createdFieldLabel)
    view.addSubview(createdValueLabel)
    view.addSubview(modifiedFieldLabel)
    view.addSubview(modifiedValueLabel)

    view.addSubview(separator2)
    view.addSubview(editButton)
    view.addSubview(saveButton)
    view.addSubview(cancelEditButton)
    view.addSubview(openFolderButton)
    view.addSubview(closeButton)

    // Icon and title
    iconImageView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(40)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(120)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(20)
      make.left.right.equalToSuperview().inset(40)
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(40)
    }

    separator1.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(30)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(1)
    }

    // Configuration section
    configTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(separator1.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(40)
    }

    nameFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(configTitleLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    nameValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    nameTextField.snp.makeConstraints { make in
      make.centerY.equalTo(nameFieldLabel)
      make.left.equalTo(nameFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
      make.height.equalTo(24)
    }

    versionFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(nameFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    versionValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(versionFieldLabel)
      make.left.equalTo(versionFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    idFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(versionFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    idValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(idFieldLabel)
      make.left.equalTo(idFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    createdFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(idFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    createdValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(createdFieldLabel)
      make.left.equalTo(createdFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    modifiedFieldLabel.snp.makeConstraints { make in
      make.top.equalTo(createdFieldLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(100)
    }

    modifiedValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(modifiedFieldLabel)
      make.left.equalTo(modifiedFieldLabel.snp.right).offset(16)
      make.right.equalToSuperview().offset(-40)
    }

    separator2.snp.makeConstraints { make in
      make.top.equalTo(modifiedValueLabel.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(1)
    }

    // Buttons
    editButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(80)
    }

    saveButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalToSuperview().offset(40)
      make.width.equalTo(80)
    }

    cancelEditButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.equalTo(saveButton.snp.right).offset(12)
      make.width.equalTo(80)
    }

    openFolderButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalTo(closeButton.snp.left).offset(-12)
      make.width.equalTo(120)
    }

    closeButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.right.equalToSuperview().offset(-40)
      make.width.equalTo(80)
    }
  }

  // MARK: - Configuration

  private func configureWithInstance() {
    // Set basic info
    titleLabel.stringValue = instance.name
    versionLabel.stringValue = Localized.InstanceDetail.versionInfo(instance.versionId)

    nameValueLabel.stringValue = instance.name
    versionValueLabel.stringValue = instance.versionId
    idValueLabel.stringValue = instance.id

    // Format dates
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short

    createdValueLabel.stringValue = dateFormatter.string(from: instance.createdAt)
    modifiedValueLabel.stringValue = dateFormatter.string(from: instance.lastModified)

    // Set icon color based on version type
    updateIconForVersion(instance.versionId)
  }

  private func updateIconForVersion(_ versionId: String) {
    if versionId.contains("w") || versionId.contains("-pre") || versionId.contains("-rc") {
      iconImageView.contentTintColor = .systemOrange
    } else if versionId.hasPrefix("1.") {
      iconImageView.contentTintColor = .systemGreen
    } else if versionId.contains("a") || versionId.contains("alpha") {
      iconImageView.contentTintColor = .systemPurple
    } else if versionId.contains("b") || versionId.contains("beta") {
      iconImageView.contentTintColor = .systemBlue
    } else {
      iconImageView.contentTintColor = .systemGray
    }
  }

  // MARK: - Actions

  @objc private func toggleEditMode() {
    isEditMode = true
    updateUIForEditMode()
  }

  @objc private func cancelEdit() {
    isEditMode = false
    // Reset fields to original values
    nameTextField.stringValue = instance.name
    updateUIForEditMode()
  }

  @objc private func saveChanges() {
    let newName = nameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    // Validate name
    guard !newName.isEmpty else {
      showError(Localized.InstanceDetail.errorEmptyName)
      return
    }

    // Check if name changed
    guard newName != instance.name else {
      // No changes, just exit edit mode
      isEditMode = false
      updateUIForEditMode()
      return
    }

    // TODO: Implement instance renaming in InstanceManager
    // For now, we'll update the local instance and notify
    // This requires adding an update method to InstanceManager

    showNotImplementedAlert()
  }

  private func updateUIForEditMode() {
    if isEditMode {
      // Show edit fields and save/cancel buttons
      nameValueLabel.isHidden = true
      nameTextField.isHidden = false
      nameTextField.stringValue = instance.name

      editButton.isHidden = true
      saveButton.isHidden = false
      cancelEditButton.isHidden = false

      // Disable close button in edit mode
      closeButton.isEnabled = false
      openFolderButton.isEnabled = false
    } else {
      // Show view mode
      nameValueLabel.isHidden = false
      nameTextField.isHidden = true

      editButton.isHidden = false
      saveButton.isHidden = true
      cancelEditButton.isHidden = true

      closeButton.isEnabled = true
      openFolderButton.isEnabled = true
    }
  }

  private func showNotImplementedAlert() {
    let alert = NSAlert()
    alert.messageText = Localized.InstanceDetail.notImplementedTitle
    alert.informativeText = Localized.InstanceDetail.notImplementedMessage
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.InstanceDetail.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  private func showError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.InstanceDetail.errorTitle
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.InstanceDetail.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  @objc private func openInstanceFolder() {
    let instanceDir = instanceManager.getInstanceDirectory(for: instance)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: instanceDir.path)
  }

  @objc private func close() {
    onClose?()
    view.window?.close()
  }
}
