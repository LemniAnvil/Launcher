//
//  ViewController.swift
//  Launcher
//

import AppKit
import SnapKit

class ViewController: NSViewController {

  private var testWindowController: TestWindowController?
  private var windowObserver: NSObjectProtocol?

  // UI elements
  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.MainWindow.titleLabel)
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.alignment = .center
    return label
  }()

  private let subtitleLabel: NSTextField = {
    let label = NSTextField(
      labelWithString: Localized.MainWindow.subtitle
    )
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    return label
  }()

  private lazy var testButton: NSButton = {
    let button = NSButton(
      title: Localized.MainWindow.openTestWindowButton,
      target: self,
      action: #selector(openTestWindow)
    )
    button.bezelStyle = .rounded
    button.font = .systemFont(ofSize: 14, weight: .medium)
    button.contentTintColor = .systemBlue
    return button
  }()

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.MainWindow.initialStatus)
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    return label
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(
      systemSymbolName: "cube.box.fill",
      accessibilityDescription: Localized.MainWindow.minecraftAccessibility
    )
    imageView.contentTintColor = .systemBlue
    return imageView
  }()

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    self.view.wantsLayer = true
    self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    // Add all UI elements
    view.addSubview(iconImageView)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(testButton)
    view.addSubview(statusLabel)

    // Layout constraints using SnapKit
    iconImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-120)
      make.width.height.equalTo(80)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(20)
      make.centerX.equalToSuperview()
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }

    testButton.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
      make.centerX.equalToSuperview()
      make.width.equalTo(200)
      make.height.equalTo(36)
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(testButton.snp.bottom).offset(20)
      make.centerX.equalToSuperview()
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
    }
  }

  @objc private func openTestWindow() {
    // If window already exists, show it
    if let existingController = testWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new test window
    testWindowController = TestWindowController()
    testWindowController?.showWindow(nil)
    testWindowController?.window?.makeKeyAndOrderFront(nil)

    // Update status
    statusLabel.stringValue = Localized.MainWindow.testWindowOpened

    // Window close callback
    windowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: testWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.testWindowController = nil
      self?.statusLabel.stringValue = Localized.MainWindow.testWindowClosed
      if let observer = self?.windowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.windowObserver = nil
      }
    }
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
}
