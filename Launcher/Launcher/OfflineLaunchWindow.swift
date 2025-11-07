//
//  OfflineLaunchWindow.swift
//  Launcher
//
//  Offline launch configuration window
//

import AppKit
import SnapKit
import Yatagarasu

/// Offline launch window controller
class OfflineLaunchWindowController: NSWindowController {

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = Localized.OfflineLaunch.windowTitle
    window.center()

    self.init(window: window)

    let viewController = OfflineLaunchViewController()
    window.contentViewController = viewController
  }
}

/// Offline launch view controller
class OfflineLaunchViewController: NSViewController {

  // MARK: - Properties

  var onLaunch: ((String) -> Void)?
  private var username: String = ""

  // UI components
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.title,
      font: .systemFont(ofSize: 18, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let descriptionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.description,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    return label
  }()

  private let usernameLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.OfflineLaunch.usernameLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var usernameField: NSTextField = {
    let field = NSTextField()
    field.placeholderString = Localized.OfflineLaunch.usernamePlaceholder
    field.font = .systemFont(ofSize: 13)
    field.delegate = self
    return field
  }()

  private lazy var launchButton: NSButton = {
    let button = NSButton()
    button.title = Localized.OfflineLaunch.launchButton
    button.bezelStyle = .rounded
    button.keyEquivalent = "\r"
    button.target = self
    button.action = #selector(launchGame)
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton()
    button.title = Localized.OfflineLaunch.cancelButton
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}"
    button.target = self
    button.action = #selector(cancel)
    return button
  }()

  private let separator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadSavedUsername()
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    view.window?.makeFirstResponder(usernameField)
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(titleLabel)
    view.addSubview(descriptionLabel)
    view.addSubview(usernameLabel)
    view.addSubview(usernameField)
    view.addSubview(separator)
    view.addSubview(launchButton)
    view.addSubview(cancelButton)

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.right.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(10)
      make.left.right.equalToSuperview().inset(20)
    }

    usernameLabel.snp.makeConstraints { make in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
      make.left.equalToSuperview().offset(20)
    }

    usernameField.snp.makeConstraints { make in
      make.top.equalTo(usernameLabel.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(24)
    }

    separator.snp.makeConstraints { make in
      make.bottom.equalTo(launchButton.snp.top).offset(-16)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-16)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(80)
    }

    launchButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-16)
      make.right.equalTo(cancelButton.snp.left).offset(-12)
      make.width.equalTo(80)
    }
  }

  // MARK: - Data

  private func loadSavedUsername() {
    if let savedUsername = UserDefaults.standard.string(forKey: "offlineUsername") {
      usernameField.stringValue = savedUsername
      username = savedUsername
    }
  }

  private func saveUsername(_ username: String) {
    UserDefaults.standard.set(username, forKey: "offlineUsername")
  }

  // MARK: - Actions

  @objc private func launchGame() {
    let username = usernameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    // Validate username
    guard !username.isEmpty else {
      showAlert(
        title: Localized.OfflineLaunch.errorTitle,
        message: Localized.OfflineLaunch.errorEmptyUsername
      )
      return
    }

    guard isValidUsername(username) else {
      showAlert(
        title: Localized.OfflineLaunch.errorTitle,
        message: Localized.OfflineLaunch.errorInvalidUsername
      )
      return
    }

    // Save username
    saveUsername(username)

    // Notify launch
    onLaunch?(username)

    // Close window
    view.window?.close()
  }

  @objc private func cancel() {
    view.window?.close()
  }

  // MARK: - Validation

  private func isValidUsername(_ username: String) -> Bool {
    // Username should be 3-16 characters, alphanumeric and underscore only
    let pattern = "^[a-zA-Z0-9_]{3,16}$"
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(location: 0, length: username.utf16.count)
    return regex?.firstMatch(in: username, options: [], range: range) != nil
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.OfflineLaunch.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}

// MARK: - NSTextFieldDelegate

extension OfflineLaunchViewController: NSTextFieldDelegate {

  func controlTextDidChange(_ obj: Notification) {
    username = usernameField.stringValue
  }
}
