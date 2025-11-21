//
//  ProxySettingsViewController.swift
//  Launcher
//
//  Network proxy settings view controller
//

import AppKit
import SnapKit
import Yatagarasu

class ProxySettingsViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  private let proxyManager = ProxyManager.shared
  private let downloadManager = DownloadManager.shared

  // UI components
  private lazy var proxyEnableCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.Settings.enableProxy,
      target: self,
      action: #selector(proxyEnableChanged)
    )
    checkbox.state = proxyManager.proxyEnabled ? .on : .off
    return checkbox
  }()

  private let typeLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.proxyTypeLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .right
    )
    return label
  }()

  private lazy var proxyTypePopup: NSPopUpButton = {
    let popup = NSPopUpButton()
    popup.addItems(withTitles: ProxyManager.ProxyType.allCases.map { $0.displayName })
    popup.selectItem(at: ProxyManager.ProxyType.allCases.firstIndex(of: proxyManager.proxyType) ?? 0)
    popup.isEnabled = proxyManager.proxyEnabled
    return popup
  }()

  private lazy var proxyHostField: NSTextField = {
    let field = NSTextField(string: proxyManager.proxyHost)
    field.placeholderString = Localized.Settings.hostPlaceholder
    field.isEnabled = proxyManager.proxyEnabled
    field.font = .systemFont(ofSize: 13)
    field.focusRingType = .none
    return field
  }()

  private lazy var colonLabel: BRLabel = {
    let label = BRLabel(
      text: ":",
      font: .systemFont(ofSize: 13),
      textColor: proxyManager.proxyEnabled ? .labelColor : .disabledControlTextColor,
      alignment: .center
    )
    return label
  }()

  private lazy var proxyPortField: NSTextField = {
    let field = NSTextField(string: proxyManager.proxyPort > 0 ? "\(proxyManager.proxyPort)" : "")
    field.placeholderString = Localized.Settings.portPlaceholder
    field.isEnabled = proxyManager.proxyEnabled
    field.font = .systemFont(ofSize: 13)
    field.focusRingType = .none
    return field
  }()

  private let proxySeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  private lazy var applyProxyButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "checkmark.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemGreen,
      accessibilityLabel: Localized.Settings.applyButton
    )
    button.target = self
    button.action = #selector(applyProxy)
    return button
  }()

  private lazy var detectSystemProxyButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "wifi.circle.fill",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemOrange,
      accessibilityLabel: Localized.Settings.detectSystemProxyButton
    )
    button.target = self
    button.action = #selector(detectSystemProxy)
    return button
  }()

  private lazy var testProxyButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "network",
      cornerRadius: 6,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
        ? NSColor.white.withAlphaComponent(0.1)
        : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.Settings.testButton
    )
    button.target = self
    button.action = #selector(testProxy)
    return button
  }()

  private let statusLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.statusReady,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(proxyEnableCheckbox)
    view.addSubview(typeLabel)
    view.addSubview(proxyTypePopup)
    view.addSubview(proxyHostField)
    view.addSubview(colonLabel)
    view.addSubview(proxyPortField)
    view.addSubview(proxySeparator)
    view.addSubview(applyProxyButton)
    view.addSubview(detectSystemProxyButton)
    view.addSubview(testProxyButton)
    view.addSubview(statusLabel)

    // Layout
    proxyEnableCheckbox.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
    }

    // Proxy settings in one row
    typeLabel.snp.makeConstraints { make in
      make.top.equalTo(proxyEnableCheckbox.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
    }

    proxyTypePopup.snp.makeConstraints { make in
      make.centerY.equalTo(typeLabel)
      make.left.equalTo(typeLabel.snp.right).offset(8)
      make.width.equalTo(100)
      make.height.equalTo(28)
    }

    proxyHostField.snp.makeConstraints { make in
      make.centerY.equalTo(typeLabel)
      make.left.equalTo(proxyTypePopup.snp.right).offset(16)
      make.width.equalTo(160)
      make.height.equalTo(28)
    }

    colonLabel.snp.makeConstraints { make in
      make.centerY.equalTo(typeLabel)
      make.left.equalTo(proxyHostField.snp.right).offset(4)
      make.width.equalTo(10)
    }

    proxyPortField.snp.makeConstraints { make in
      make.centerY.equalTo(typeLabel)
      make.left.equalTo(colonLabel.snp.right).offset(4)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(28)
    }

    proxySeparator.snp.makeConstraints { make in
      make.top.equalTo(typeLabel.snp.bottom).offset(20)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    // Buttons
    testProxyButton.snp.makeConstraints { make in
      make.top.equalTo(proxySeparator.snp.bottom).offset(16)
      make.right.equalToSuperview().offset(-20)
      make.width.height.equalTo(36)
    }

    detectSystemProxyButton.snp.makeConstraints { make in
      make.centerY.equalTo(testProxyButton)
      make.right.equalTo(testProxyButton.snp.left).offset(-12)
      make.width.height.equalTo(36)
    }

    applyProxyButton.snp.makeConstraints { make in
      make.centerY.equalTo(testProxyButton)
      make.right.equalTo(detectSystemProxyButton.snp.left).offset(-12)
      make.width.height.equalTo(36)
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(testProxyButton.snp.bottom).offset(16)
      make.left.right.equalToSuperview().inset(20)
    }
  }

  // MARK: - Actions

  @objc private func proxyEnableChanged() {
    let enabled = proxyEnableCheckbox.state == .on
    proxyHostField.isEnabled = enabled
    proxyPortField.isEnabled = enabled
    proxyTypePopup.isEnabled = enabled
    colonLabel.textColor = enabled ? .labelColor : .disabledControlTextColor

    if !enabled {
      proxyManager.disableProxy()
      downloadManager.reconfigureSession()
      statusLabel.stringValue = Localized.Settings.statusDisabled
      Logger.shared.info("Proxy disabled", category: "Settings")
    } else {
      statusLabel.stringValue = Localized.Settings.statusReady
    }
  }

  @objc private func applyProxy() {
    let enabled = proxyEnableCheckbox.state == .on
    let host = proxyHostField.stringValue.trimmingCharacters(in: .whitespaces)
    let port = Int(proxyPortField.stringValue) ?? 0

    // Validate input
    if enabled && (host.isEmpty || port <= 0 || port > 65535) {
      showAlert(
        title: Localized.Settings.alertInvalidConfigTitle,
        message: Localized.Settings.alertInvalidConfigMessage
      )
      return
    }

    // Get proxy type
    let selectedIndex = proxyTypePopup.indexOfSelectedItem
    let proxyType = ProxyManager.ProxyType.allCases[selectedIndex]

    // Configure proxy
    proxyManager.configureProxy(enabled: enabled, host: host, port: port, type: proxyType)
    downloadManager.reconfigureSession()

    if enabled {
      statusLabel.stringValue = Localized.Settings.statusApplied(host, port)
      Logger.shared.info("Proxy applied: \(host):\(port)", category: "Settings")
    } else {
      statusLabel.stringValue = Localized.Settings.statusDisabled
      Logger.shared.info("Proxy disabled", category: "Settings")
    }
  }

  @objc private func detectSystemProxy() {
    statusLabel.stringValue = Localized.Settings.statusDetecting
    Logger.shared.info("Detecting system proxy...", category: "Settings")

    // Detect system proxy on background thread
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      let success = self.proxyManager.applySystemProxy()

      DispatchQueue.main.async {
        if success {
          // Update UI with detected proxy settings
          self.proxyEnableCheckbox.state = .on
          self.proxyHostField.stringValue = self.proxyManager.proxyHost
          self.proxyPortField.stringValue = "\(self.proxyManager.proxyPort)"

          // Update proxy type popup
          if let index = ProxyManager.ProxyType.allCases.firstIndex(of: self.proxyManager.proxyType) {
            self.proxyTypePopup.selectItem(at: index)
          }

          // Enable input fields
          self.proxyHostField.isEnabled = true
          self.proxyPortField.isEnabled = true
          self.proxyTypePopup.isEnabled = true
          self.colonLabel.textColor = .labelColor

          // Reconfigure download session
          self.downloadManager.reconfigureSession()

          self.statusLabel.stringValue = Localized.Settings.statusSystemProxyApplied
          Logger.shared.info(
            "System proxy applied: \(self.proxyManager.proxyType.rawValue) \(self.proxyManager.proxyHost):\(self.proxyManager.proxyPort)",
            category: "Settings"
          )
        } else {
          self.statusLabel.stringValue = Localized.Settings.statusNoSystemProxy
          Logger.shared.warning("No system proxy detected", category: "Settings")
        }
      }
    }
  }

  @objc private func testProxy() {
    statusLabel.stringValue = Localized.Settings.statusTesting

    Task {
      do {
        let success = try await proxyManager.testProxyConnection()

        await MainActor.run {
          if success {
            statusLabel.stringValue = Localized.Settings.statusTestSuccess
            Logger.shared.info("Proxy test successful", category: "Settings")

            showAlert(
              title: Localized.Settings.alertTestSuccessTitle,
              message: Localized.Settings.alertTestSuccessMessage
            )
          }
        }
      } catch {
        await MainActor.run {
          statusLabel.stringValue = Localized.Settings.statusTestFailed
          Logger.shared.error("Proxy test failed: \(error.localizedDescription)", category: "Settings")

          showAlert(
            title: Localized.Settings.alertTestFailedTitle,
            message: Localized.Settings.alertTestFailedMessage(error.localizedDescription)
          )
        }
      }
    }
  }

  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.Settings.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}
