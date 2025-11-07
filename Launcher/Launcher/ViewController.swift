//
//  ViewController.swift
//  Launcher
//

import AppKit
import SnapKit
import Yatagarasu

class ViewController: NSViewController {

  private var testWindowController: TestWindowController?
  private var javaDetectionWindowController: JavaDetectionWindowController?
  private var windowObserver: NSObjectProtocol?
  private var javaWindowObserver: NSObjectProtocol?

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

  private lazy var testButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "play.circle.fill",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemBlue,
      accessibilityLabel: Localized.MainWindow.openTestWindowButton
    )
    button.target = self
    button.action = #selector(openTestWindow)
    return button
  }()

  private lazy var javaDetectionButton: BRImageButton = {
    let button = BRImageButton(
      symbolName: "cup.and.saucer.fill",
      cornerRadius: 8,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: .systemOrange,
      accessibilityLabel: Localized.JavaDetection.openJavaDetectionButton
    )
    button.target = self
    button.action = #selector(openJavaDetectionWindow)
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
    view.addSubview(javaDetectionButton)
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

    // Create button container for horizontal layout
    let buttonStack = NSStackView(views: [testButton, javaDetectionButton])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 16
    buttonStack.distribution = .gravityAreas
    view.addSubview(buttonStack)

    testButton.snp.makeConstraints { make in
      make.width.height.equalTo(44)
    }

    javaDetectionButton.snp.makeConstraints { make in
      make.width.height.equalTo(44)
    }

    buttonStack.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
      make.centerX.equalToSuperview()
    }

    statusLabel.snp.makeConstraints { make in
      make.top.equalTo(buttonStack.snp.bottom).offset(20)
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

  @objc private func openJavaDetectionWindow() {
    // If window already exists, show it
    if let existingController = javaDetectionWindowController {
      existingController.showWindow(nil)
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new Java detection window
    javaDetectionWindowController = JavaDetectionWindowController()
    javaDetectionWindowController?.showWindow(nil)
    javaDetectionWindowController?.window?.makeKeyAndOrderFront(nil)

    // Update status
    statusLabel.stringValue = Localized.MainWindow.javaWindowOpened

    // Window close callback
    javaWindowObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: javaDetectionWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.javaDetectionWindowController = nil
      self?.statusLabel.stringValue = Localized.MainWindow.javaWindowClosed
      if let observer = self?.javaWindowObserver {
        NotificationCenter.default.removeObserver(observer)
        self?.javaWindowObserver = nil
      }
    }
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
}
