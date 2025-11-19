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
  // MARK: - Properties

  var instance: Instance
  let instanceManager = InstanceManager.shared
  var isEditMode = false

  var onClose: (() -> Void)?
  var onSaved: ((Instance) -> Void)?

  // MARK: - UI Components

  lazy var iconImageView = createIconImageView()
  lazy var titleLabel = createTitleLabel()
  lazy var versionLabel = createVersionLabel()
  lazy var separator1 = createSeparator1()

  // Configuration section
  lazy var configTitleLabel = createConfigTitleLabel()
  lazy var nameFieldLabel = createNameFieldLabel()
  lazy var nameValueLabel = createNameValueLabel()
  lazy var nameTextField = createNameTextField()
  lazy var versionFieldLabel = createVersionFieldLabel()
  lazy var versionValueLabel = createVersionValueLabel()
  lazy var idFieldLabel = createIdFieldLabel()
  lazy var idValueLabel = createIdValueLabel()
  lazy var createdFieldLabel = createCreatedFieldLabel()
  lazy var createdValueLabel = createCreatedValueLabel()
  lazy var modifiedFieldLabel = createModifiedFieldLabel()
  lazy var modifiedValueLabel = createModifiedValueLabel()

  lazy var separator2 = createSeparator2()

  // Actions section
  lazy var editButton = createEditButton()
  lazy var saveButton = createSaveButton()
  lazy var cancelEditButton = createCancelEditButton()
  lazy var openFolderButton = createOpenFolderButton()
  lazy var closeButton = createCloseButton()

  // MARK: - Initialization

  init(instance: Instance) {
    self.instance = instance
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
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
}
