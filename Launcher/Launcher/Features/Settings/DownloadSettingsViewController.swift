//
//  DownloadSettingsViewController.swift
//  Launcher
//
//  Download settings view controller
//

import AppKit
import SnapKit
import Yatagarasu

class DownloadSettingsViewController: NSViewController {
  // swiftlint:disable:previous type_body_length
  // MARK: - Properties

  private let downloadManager = DownloadManager.shared
  private let downloadSettingsManager = DownloadSettingsManager.shared

  // UI components
  private lazy var fileVerificationCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.Settings.enableFileVerification,
      target: self,
      action: #selector(fileVerificationChanged)
    )
    checkbox.state = downloadSettingsManager.fileVerificationEnabled ? .on : .off
    return checkbox
  }()

  private let fileVerificationDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.fileVerificationDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let maxConcurrentLabel: DisplayLabel = {
    let label = DisplayLabel(
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

  private lazy var maxConcurrentValueLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "\(downloadSettingsManager.maxConcurrentDownloads)",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let maxConcurrentDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.concurrentDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let requestTimeoutLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.requestTimeoutLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .right
    )
    return label
  }()

  private lazy var requestTimeoutSlider: NSSlider = {
    let slider = NSSlider()
    slider.minValue = 5
    slider.maxValue = 120
    slider.integerValue = downloadSettingsManager.requestTimeout
    slider.numberOfTickMarks = 0
    slider.isContinuous = true
    slider.target = self
    slider.action = #selector(requestTimeoutSliderChanged)
    return slider
  }()

  private lazy var requestTimeoutValueLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "\(downloadSettingsManager.requestTimeout)s",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let requestTimeoutDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.requestTimeoutDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private let resourceTimeoutLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.resourceTimeoutLabel,
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .right
    )
    return label
  }()

  private lazy var resourceTimeoutSlider: NSSlider = {
    let slider = NSSlider()
    slider.minValue = 60
    slider.maxValue = 600
    slider.integerValue = downloadSettingsManager.resourceTimeout
    slider.numberOfTickMarks = 0
    slider.isContinuous = true
    slider.target = self
    slider.action = #selector(resourceTimeoutSliderChanged)
    return slider
  }()

  private lazy var resourceTimeoutValueLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "\(downloadSettingsManager.resourceTimeout)s",
      font: .systemFont(ofSize: 13),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let resourceTimeoutDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.resourceTimeoutDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  private lazy var useV2ManifestCheckbox: NSButton = {
    let checkbox = NSButton(
      checkboxWithTitle: Localized.Settings.useV2Manifest,
      target: self,
      action: #selector(v2ManifestChanged)
    )
    checkbox.state = downloadSettingsManager.useV2Manifest ? .on : .off
    return checkbox
  }()

  private let v2ManifestDescriptionLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: Localized.Settings.v2ManifestDescription,
      font: .systemFont(ofSize: 11),
      textColor: .secondaryLabelColor,
      alignment: .left
    )
    return label
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 400))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    view.addSubview(fileVerificationCheckbox)
    view.addSubview(fileVerificationDescriptionLabel)
    view.addSubview(maxConcurrentLabel)
    view.addSubview(maxConcurrentSlider)
    view.addSubview(maxConcurrentValueLabel)
    view.addSubview(maxConcurrentDescriptionLabel)
    view.addSubview(requestTimeoutLabel)
    view.addSubview(requestTimeoutSlider)
    view.addSubview(requestTimeoutValueLabel)
    view.addSubview(requestTimeoutDescriptionLabel)
    view.addSubview(resourceTimeoutLabel)
    view.addSubview(resourceTimeoutSlider)
    view.addSubview(resourceTimeoutValueLabel)
    view.addSubview(resourceTimeoutDescriptionLabel)
    view.addSubview(useV2ManifestCheckbox)
    view.addSubview(v2ManifestDescriptionLabel)

    // Layout
    fileVerificationCheckbox.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
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

    // Request timeout row
    requestTimeoutLabel.snp.makeConstraints { make in
      make.top.equalTo(maxConcurrentDescriptionLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(160)
    }

    requestTimeoutSlider.snp.makeConstraints { make in
      make.centerY.equalTo(requestTimeoutLabel)
      make.left.equalTo(requestTimeoutLabel.snp.right).offset(12)
      make.right.equalTo(requestTimeoutValueLabel.snp.left).offset(-12)
      make.height.equalTo(24)
    }

    requestTimeoutValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(requestTimeoutLabel)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(40)
    }

    requestTimeoutDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(requestTimeoutLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(40)
      make.right.equalToSuperview().offset(-20)
    }

    // Resource timeout row
    resourceTimeoutLabel.snp.makeConstraints { make in
      make.top.equalTo(requestTimeoutDescriptionLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
      make.width.equalTo(160)
    }

    resourceTimeoutSlider.snp.makeConstraints { make in
      make.centerY.equalTo(resourceTimeoutLabel)
      make.left.equalTo(resourceTimeoutLabel.snp.right).offset(12)
      make.right.equalTo(resourceTimeoutValueLabel.snp.left).offset(-12)
      make.height.equalTo(24)
    }

    resourceTimeoutValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(resourceTimeoutLabel)
      make.right.equalToSuperview().offset(-20)
      make.width.equalTo(40)
    }

    resourceTimeoutDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(resourceTimeoutLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(40)
      make.right.equalToSuperview().offset(-20)
    }

    // V2 Manifest checkbox
    useV2ManifestCheckbox.snp.makeConstraints { make in
      make.top.equalTo(resourceTimeoutDescriptionLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(20)
    }

    v2ManifestDescriptionLabel.snp.makeConstraints { make in
      make.top.equalTo(useV2ManifestCheckbox.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(40)
      make.right.equalToSuperview().offset(-20)
    }
  }

  // MARK: - Actions

  @objc private func fileVerificationChanged() {
    let enabled = fileVerificationCheckbox.state == .on
    downloadSettingsManager.setFileVerification(enabled: enabled)

    Logger.shared.info(
      "File verification \(enabled ? "enabled" : "disabled")",
      category: "Settings"
    )
  }

  @objc private func v2ManifestChanged() {
    let enabled = useV2ManifestCheckbox.state == .on
    downloadSettingsManager.setUseV2Manifest(enabled)

    Logger.shared.info(
      "V2 Manifest API \(enabled ? "enabled" : "disabled")",
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

  @objc private func requestTimeoutSliderChanged() {
    let timeout = requestTimeoutSlider.integerValue
    requestTimeoutValueLabel.stringValue = "\(timeout)s"
    downloadSettingsManager.setRequestTimeout(timeout)
    downloadManager.reconfigureSession()

    Logger.shared.info(
      "Request timeout set to \(timeout)s",
      category: "Settings"
    )
  }

  @objc private func resourceTimeoutSliderChanged() {
    let timeout = resourceTimeoutSlider.integerValue
    resourceTimeoutValueLabel.stringValue = "\(timeout)s"
    downloadSettingsManager.setResourceTimeout(timeout)
    downloadManager.reconfigureSession()

    Logger.shared.info(
      "Resource timeout set to \(timeout)s",
      category: "Settings"
    )
  }
}
