//
//  ViewController.swift
//  Launcher
//

import AppKit

class ViewController: NSViewController {

  private var testWindowController: TestWindowController?

  // UI elements
  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.MainWindow.titleLabel)
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let subtitleLabel: NSTextField = {
    let label = NSTextField(
      labelWithString: Localized.MainWindow.subtitle
    )
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
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
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private let statusLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.MainWindow.initialStatus)
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.image = NSImage(
      systemSymbolName: "cube.box.fill",
      accessibilityDescription: Localized.MainWindow.minecraftAccessibility
    )
    imageView.contentTintColor = .systemBlue
    imageView.translatesAutoresizingMaskIntoConstraints = false
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

    // Layout constraints
    NSLayoutConstraint.activate([
      // Icon
      iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      iconImageView.centerYAnchor.constraint(
        equalTo: view.centerYAnchor,
        constant: -120
      ),
      iconImageView.widthAnchor.constraint(equalToConstant: 80),
      iconImageView.heightAnchor.constraint(equalToConstant: 80),

      // Title
      titleLabel.topAnchor.constraint(
        equalTo: iconImageView.bottomAnchor,
        constant: 20
      ),
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      titleLabel.widthAnchor.constraint(
        equalTo: view.widthAnchor,
        constant: -40
      ),

      // Subtitle
      subtitleLabel.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: 8
      ),
      subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      subtitleLabel.widthAnchor.constraint(
        equalTo: view.widthAnchor,
        constant: -40
      ),

      // Test button
      testButton.topAnchor.constraint(
        equalTo: subtitleLabel.bottomAnchor,
        constant: 40
      ),
      testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      testButton.widthAnchor.constraint(equalToConstant: 200),
      testButton.heightAnchor.constraint(equalToConstant: 36),

      // Status label
      statusLabel.topAnchor.constraint(
        equalTo: testButton.bottomAnchor,
        constant: 20
      ),
      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.widthAnchor.constraint(
        equalTo: view.widthAnchor,
        constant: -40
      ),
    ])
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
    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: testWindowController?.window,
      queue: .main
    ) { [weak self] _ in
      self?.testWindowController = nil
      self?.statusLabel.stringValue = Localized.MainWindow.testWindowClosed
    }
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
}
