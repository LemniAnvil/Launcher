//
//  DownloadProgressViewController.swift
//  Launcher
//
//  View controller for showing download progress
//

import AppKit
import Combine
import SnapKit
import Yatagarasu

class DownloadProgressViewController: NSViewController {
  // MARK: - Properties

  private let downloadManager = DownloadManager.shared
  private var cancellables = Set<AnyCancellable>()
  var onComplete: (() -> Void)?
  var onCancel: (() -> Void)?

  // MARK: - UI Components

  private let titleLabel: BRLabel = {
    let label = BRLabel(
      text: "Downloading Minecraft",
      font: .systemFont(ofSize: 18, weight: .semibold),
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

  private let progressIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .bar
    indicator.isIndeterminate = false
    indicator.minValue = 0
    indicator.maxValue = 100
    indicator.doubleValue = 0
    return indicator
  }()

  private let progressLabel: BRLabel = {
    let label = BRLabel(
      text: "0%",
      font: .systemFont(ofSize: 13, weight: .medium),
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let taskProgressLabel: BRLabel = {
    let label = BRLabel(
      text: "0 / 0 files",
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  private let bytesProgressLabel: BRLabel = {
    let label = BRLabel(
      text: "0 MB / 0 MB",
      font: .systemFont(ofSize: 12),
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  private let speedLabel: BRLabel = {
    let label = BRLabel(
      text: "Speed: 0 MB/s",
      font: .systemFont(ofSize: 12),
      textColor: .tertiaryLabelColor,
      alignment: .center
    )
    return label
  }()

  private let statusLabel: BRLabel = {
    let label = BRLabel(
      text: "Preparing download...",
      font: .systemFont(ofSize: 11),
      textColor: .tertiaryLabelColor,
      alignment: .center
    )
    label.maximumNumberOfLines = 2
    return label
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton(
      title: "Cancel",
      target: self,
      action: #selector(cancelDownload)
    )
    button.bezelStyle = .rounded
    return button
  }()

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    observeProgress()
  }

  // MARK: - Setup

  private func setupUI() {
    view.wantsLayer = true

    view.addSubview(titleLabel)
    view.addSubview(versionLabel)
    view.addSubview(progressIndicator)
    view.addSubview(progressLabel)
    view.addSubview(taskProgressLabel)
    view.addSubview(bytesProgressLabel)
    view.addSubview(speedLabel)
    view.addSubview(statusLabel)
    view.addSubview(cancelButton)

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(30)
      make.centerX.equalToSuperview()
    }

    versionLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
    }

    progressIndicator.snp.makeConstraints { make in
      make.top.equalTo(versionLabel.snp.bottom).offset(30)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(20)
    }

    progressLabel.snp.makeConstraints { make in
      make.top.equalTo(progressIndicator.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
    }

    taskProgressLabel.snp.makeConstraints { make in
      make.top.equalTo(progressLabel.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
    }

    bytesProgressLabel.snp.makeConstraints { make in
      make.top.equalTo(taskProgressLabel.snp.bottom).offset(4)
      make.centerX.equalToSuperview()
    }

    speedLabel.snp.makeConstraints { make in
      make.top.equalTo(bytesProgressLabel.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(speedLabel.snp.bottom).offset(12)
      make.left.right.equalToSuperview().inset(40)
    }

    cancelButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.centerX.equalToSuperview()
      make.width.equalTo(100)
    }
  }

  private func observeProgress() {
    // Observe current progress
    downloadManager.$currentProgress
      .receive(on: DispatchQueue.main)
      .sink { [weak self] progress in
        self?.updateProgress(progress)
      }
      .store(in: &cancellables)

    // Observe download speed
    downloadManager.$downloadSpeed
      .receive(on: DispatchQueue.main)
      .sink { [weak self] speed in
        self?.updateSpeed(speed)
      }
      .store(in: &cancellables)

    // Observe isDownloading state
    downloadManager.$isDownloading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isDownloading in
        if !isDownloading {
          self?.downloadComplete()
        }
      }
      .store(in: &cancellables)
  }

  private func updateProgress(_ progress: DownloadProgress) {
    let percentage = progress.bytesProgress * 100
    progressIndicator.doubleValue = percentage
    progressLabel.stringValue = String(format: "%.1f%%", percentage)

    taskProgressLabel.stringValue = "\(progress.completedTasks) / \(progress.totalTasks) files"
    bytesProgressLabel.stringValue = progress.bytesDisplay

    // Update status based on progress
    if progress.completedTasks == 0 {
      statusLabel.stringValue = "Preparing download..."
    } else if progress.failedTasks > 0 {
      statusLabel.stringValue = "Downloading... (\(progress.failedTasks) failed)"
    } else {
      statusLabel.stringValue = "Downloading game files..."
    }
  }

  private func updateSpeed(_ speed: Double) {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    formatter.allowedUnits = [.useKB, .useMB]
    let speedString = formatter.string(fromByteCount: Int64(speed))
    speedLabel.stringValue = "Speed: \(speedString)/s"
  }

  private func downloadComplete() {
    progressLabel.stringValue = "100%"
    statusLabel.stringValue = "Download complete!"
    cancelButton.title = "Close"
    cancelButton.action = #selector(closeWindow)

    // Notify completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.onComplete?()
    }
  }

  // MARK: - Public Methods

  func setVersion(_ versionId: String) {
    versionLabel.stringValue = "Version: \(versionId)"
  }

  // MARK: - Actions

  @objc private func cancelDownload() {
    let alert = NSAlert()
    alert.messageText = "Cancel Download?"
    alert.informativeText = "Are you sure you want to cancel the download?"
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Cancel Download")
    alert.addButton(withTitle: "Continue")

    if let window = view.window {
      alert.beginSheetModal(for: window) { [weak self] response in
        if response == .alertFirstButtonReturn {
          self?.onCancel?()
          self?.view.window?.close()
        }
      }
    }
  }

  @objc private func closeWindow() {
    view.window?.close()
  }
}
