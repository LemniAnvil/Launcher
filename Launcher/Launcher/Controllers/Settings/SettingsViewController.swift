//
//  SettingsViewController.swift
//  Launcher
//
//  Settings view controller
//

import AppKit
import SnapKit
import Yatagarasu

class SettingsViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  private let proxyManager = ProxyManager.shared
  private let downloadManager = DownloadManager.shared
  private let downloadSettingsManager = DownloadSettingsManager.shared

  // UI components
  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.title,
      font: .systemFont(ofSize: 20, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private let subtitleLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.subtitle,
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let headerSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // Proxy Settings Section
  private let proxySectionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.proxySectionTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

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

  // Download Settings Section
  private let downloadSectionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.downloadSectionTitle,
      font: .systemFont(ofSize: 16, weight: .semibold),
      textColor: .labelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var fileVerificationCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.Settings.enableFileVerification,
      target: self,
      action: #selector(fileVerificationChanged)
    )
    checkbox.state = downloadSettingsManager.fileVerificationEnabled ? .on : .off
    return checkbox
  }()

  private let fileVerificationDescriptionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.fileVerificationDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let maxConcurrentLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.maxConcurrentLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .right
    )
    return label
  }()

  private lazy var maxConcurrentSlider: NSSlider = {
    let slider = NSSlider()
    slider.minValue = 1
    slider.maxValue = 64
    slider.integerValue = downloadSettingsManager.maxConcurrentDownloads
    slider.numberOfTickMarks = 0
    slider.isContinuous = true
    slider.target = self
    slider.action = #selector(maxConcurrentSliderChanged)
    return slider
  }()

  private lazy var maxConcurrentValueLabel: BRLabel = {
    let label = BRLabel(
      text: "\(downloadSettingsManager.maxConcurrentDownloads)",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let maxConcurrentDescriptionLabel: BRLabel = {
    let label = BRLabel(
      text: Localized.Settings.concurrentDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let downloadSeparator: BRSeparator = {
    return BRSeparator.horizontal()
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 530))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(headerSeparator)
    view.addSubview(proxySectionLabel)
    view.addSubview(proxyEnableCheckbox)
    view.addSubview(typeLabel)
    view.addSubview(proxyTypePopup)
    view.addSubview(proxyHostField)
    view.addSubview(colonLabel)
    view.addSubview(proxyPortField)
    view.addSubview(proxySeparator)
    view.addSubview(applyProxyButton)
    view.addSubview(testProxyButton)
    view.addSubview(statusLabel)
    view.addSubview(downloadSeparator)
    view.addSubview(downloadSectionLabel)
    view.addSubview(fileVerificationCheckbox)
    view.addSubview(fileVerificationDescriptionLabel)
    view.addSubview(maxConcurrentLabel)
    view.addSubview(maxConcurrentSlider)
    view.addSubview(maxConcurrentValueLabel)
    view.addSubview(maxConcurrentDescriptionLabel)

    // Layout
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    headerSeparator.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    // Proxy section
    proxySectionLabel.snp.makeConstraints { make in
      make.top.equalTo(headerSeparator.snp.bottom).offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    proxyEnableCheckbox.snp.makeConstraints { make in
      make.top.equalTo(proxySectionLabel.snp.bottom).offset(12)
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

    applyProxyButton.snp.makeConstraints { make in
      make.centerY.equalTo(testProxyButton)
      make.right.equalTo(testProxyButton.snp.left).offset(-12)
      make.width.height.equalTo(36)
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(testProxyButton.snp.bottom).offset(16)
      make.left.right.equalToSuperview().inset(20)
    }

    // Download settings section
    downloadSeparator.snp.makeConstraints { make in
      make.top.equalTo(statusLabel.snp.bottom).offset(24)
      make.left.right.equalToSuperview().inset(20)
      make.height.equalTo(1)
    }

    downloadSectionLabel.snp.makeConstraints { make in
      make.top.equalTo(downloadSeparator.snp.bottom).offset(20)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    fileVerificationCheckbox.snp.makeConstraints { make in
      make.top.equalTo(downloadSectionLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(20)
    }

    fileVerificationDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(fileVerificationCheckbox.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(40)
      make.right.equalToSuperview().offset(-20)
    }

    // Max concurrent downloads row
    maxConcurrentLabel.snp.makeConstraints { make in
      make.top.equalTo(fileVerificationDescriptionLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(160)
    }

    maxConcurrentSlider.snp.makeConstraints { make in
      make.centerY.equalTo(maxConcurrentLabel)
      make.left.equalTo(maxConcurrentLabel.snp.right).offset(12)
      make.right.equalTo(maxConcurrentValueLabel.snp.left).offset(-12)
      make.height.equalTo(24)
    }

    maxConcurrentValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(maxConcurrentLabel)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(40)
    }

    maxConcurrentDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(maxConcurrentLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(40)
      make.right.equalToSuperview().offset(-20)
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

  @objc private func fileVerificationChanged() {
    let enabled = fileVerificationCheckbox.state == .on
    downloadSettingsManager.setFileVerification(enabled: enabled)
    downloadManager.reconfigureSession()

    Logger.shared.info(
      "File verification \(enabled ? "enabled" : "disabled")",
      category: "Settings"
    )
  }

  @objc private func maxConcurrentSliderChanged() {
    let count = maxConcurrentSlider.integerValue
    maxConcurrentValueLabel.stringValue = "\(count)"
    downloadSettingsManager.setMaxConcurrentDownloads(count)
    downloadManager.reconfigureSession()

    Logger.shared.info(
      "Max concurrent downloads set to \(count)",
      category: "Settings"
    )
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
