//
//  MicrosoftAuthViewController.swift
//  Launcher
//
//  Microsoft authentication view controller
//  Opens default browser for authentication and handles callback URL
//

import AppKit
import SnapKit
import Yatagarasu

class MicrosoftAuthViewController: NSViewController {

  // MARK: - Properties

  private let authManager = MicrosoftAuthManager.shared
  private var loginData: SecureLoginData?

  var onAuthSuccess: ((CompleteLoginResponse) -> Void)?
  var onAuthFailure: ((Error) -> Void)?

  // UI components
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.MicrosoftAuth.title,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let subtitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.MicrosoftAuth.subtitle,
      font: .systemFont(ofSize: 13),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    return label
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(systemSymbolName: "person.crop.circle.badge.checkmark", accessibilityDescription: nil)
    imageView.contentTintColor = .systemGreen
    return imageView
  }()

  private let statusLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.MicrosoftAuth.statusReady,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 0
    return label
  }()

  private lazy var loginButton: NSButton = {
    let button = NSButton()
    button.title = Localized.MicrosoftAuth.loginButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(startLogin)
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton()
    button.title = Localized.MicrosoftAuth.cancelButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(cancel)
    return button
  }()

  private let progressIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.isIndeterminate = true
    indicator.isHidden = true
    return indicator
  }()

  private let separator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 700))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override func viewWillDisappear() {
    super.viewWillDisappear()
    // Clean up auth callback handler
    AppDelegate.pendingAuthCallback = nil
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(iconImageView)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(separator)
    view.addSubview(statusLabel)
    view.addSubview(progressIndicator)
    view.addSubview(loginButton)
    view.addSubview(cancelButton)

    iconImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(80)
      make.width.height.equalTo(100)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(40)
    }

    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(40)
    }

    separator.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(1)
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(separator.snp.bottom).offset(32)
      make.left.right.equalToSuperview().inset(40)
    }

    progressIndicator.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(statusLabel.snp.bottom).offset(20)
    }

    loginButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(progressIndicator.snp.bottom).offset(40)
      make.width.equalTo(200)
      make.height.equalTo(32)
    }

    cancelButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(loginButton.snp.bottom).offset(12)
      make.width.equalTo(200)
      make.height.equalTo(32)
    }
  }

  // MARK: - Actions

  @objc private func startLogin() {
    Task { @MainActor in
      await performLogin()
    }
  }

  @objc private func cancel() {
    view.window?.close()
  }

  // MARK: - Login Flow

  private func performLogin() async {
    updateStatus(Localized.MicrosoftAuth.statusGeneratingURL)
    setLoading(true)

    do {
      // Step 1: Generate login URL
      loginData = authManager.getSecureLoginData()

      guard let loginData = loginData else {
        throw MicrosoftAuthError.invalidURL
      }

      Logger.shared.info("Generated login URL", category: "MicrosoftAuth")

      // Set up callback handler for when the app receives the URL
      AppDelegate.pendingAuthCallback = { [weak self] callbackURL in
        Task { @MainActor in
          await self?.handleCallback(callbackURL)
        }
      }

      // Step 2: Open browser for user authentication
      updateStatus(Localized.MicrosoftAuth.statusOpeningBrowser)
      guard let url = URL(string: loginData.url) else {
        throw MicrosoftAuthError.invalidURL
      }

      NSWorkspace.shared.open(url)
      Logger.shared.info("Opened browser for Microsoft authentication", category: "MicrosoftAuth")
      updateStatus(Localized.MicrosoftAuth.statusWaitingForAuth)
    } catch {
      Logger.shared.error("Login failed: \(error.localizedDescription)", category: "MicrosoftAuth")
      setLoading(false)
      updateStatus(Localized.MicrosoftAuth.statusError(error.localizedDescription))
      showAlert(
        title: Localized.MicrosoftAuth.alertLoginFailedTitle,
        message: Localized.MicrosoftAuth.alertLoginFailedMessage(error.localizedDescription)
      )
      onAuthFailure?(error)
    }
  }

  // MARK: - Callback Handling

  private func handleCallback(_ callbackURL: String) async {
    guard let loginData = loginData else {
      Logger.shared.error("Login data not found", category: "MicrosoftAuth")
      return
    }

    do {
      updateStatus(Localized.MicrosoftAuth.statusProcessingCallback)

      // Step 3: Parse authorization code
      let authCode = try authManager.parseAuthCodeURL(callbackURL, expectedState: loginData.state)
      Logger.shared.info("Authorization code received", category: "MicrosoftAuth")

      updateStatus(Localized.MicrosoftAuth.statusCompletingLogin)

      // Step 4-7: Complete login flow
      let loginResponse = try await authManager.completeLogin(
        authCode: authCode,
        codeVerifier: loginData.codeVerifier
      )

      Logger.shared.info("Login successful: \(loginResponse.name)", category: "MicrosoftAuth")
      updateStatus(Localized.MicrosoftAuth.statusSuccess(loginResponse.name))
      setLoading(false)

      // Save account information
      saveAccount(loginResponse)

      // Call success callback
      onAuthSuccess?(loginResponse)

      // Show success message
      showSuccessAlert(username: loginResponse.name, uuid: loginResponse.id)

      // Close window after delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        self?.view.window?.close()
      }
    } catch {
      Logger.shared.error("Callback handling failed: \(error.localizedDescription)", category: "MicrosoftAuth")
      setLoading(false)
      updateStatus(Localized.MicrosoftAuth.statusError(error.localizedDescription))
      showAlert(
        title: Localized.MicrosoftAuth.alertLoginFailedTitle,
        message: Localized.MicrosoftAuth.alertLoginFailedMessage(error.localizedDescription)
      )
      onAuthFailure?(error)
    }
  }

  // MARK: - Account Storage

  private func saveAccount(_ response: CompleteLoginResponse) {
    let accountData: [String: Any] = [
      "id": response.id,
      "name": response.name,
      "accessToken": response.accessToken,
      "refreshToken": response.refreshToken,
      "timestamp": Date().timeIntervalSince1970,
    ]

    // Save to UserDefaults
    var accounts = UserDefaults.standard.dictionary(forKey: "MicrosoftAccounts") ?? [:]
    accounts[response.id] = accountData
    UserDefaults.standard.set(accounts, forKey: "MicrosoftAccounts")

    Logger.shared.info("Saved Microsoft account: \(response.name)", category: "MicrosoftAuth")
  }

  // MARK: - UI Updates

  private func updateStatus(_ status: String) {
    statusLabel.stringValue = status
  }

  private func setLoading(_ isLoading: Bool) {
    if isLoading {
      progressIndicator.isHidden = false
      progressIndicator.startAnimation(nil)
      loginButton.isEnabled = false
    } else {
      progressIndicator.isHidden = true
      progressIndicator.stopAnimation(nil)
      loginButton.isEnabled = true
    }
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.MicrosoftAuth.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  private func showSuccessAlert(username: String, uuid: String) {
    let alert = NSAlert()
    alert.messageText = Localized.MicrosoftAuth.alertSuccessTitle
    alert.informativeText = Localized.MicrosoftAuth.alertSuccessMessage(username, uuid)
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.MicrosoftAuth.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}
