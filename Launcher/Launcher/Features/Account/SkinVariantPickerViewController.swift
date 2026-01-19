//
//  SkinVariantPickerViewController.swift
//  Launcher
//
//  Dialog for selecting skin variant (CLASSIC/SLIM) before upload
//

import AppKit
import CraftKit
import SnapKit

final class SkinVariantPickerViewController: NSViewController {

  // MARK: - Properties

  private var skinImage: NSImage?
  private(set) var selectedVariant: SkinVariant = .classic
  var onConfirm: ((SkinVariant) -> Void)?

  // MARK: - UI Components

  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.Account.selectSkinVariant)
    label.font = .systemFont(ofSize: 16, weight: .semibold)
    label.alignment = .center
    return label
  }()

  private let previewImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 8
    imageView.layer?.borderWidth = 1
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    return imageView
  }()

  private lazy var classicButton: NSButton = {
    let button = NSButton(radioButtonWithTitle: Localized.Account.classicVariant, target: self, action: #selector(variantSelected(_:)))
    button.tag = 0
    button.state = .on
    return button
  }()

  private lazy var slimButton: NSButton = {
    let button = NSButton(radioButtonWithTitle: Localized.Account.slimVariant, target: self, action: #selector(variantSelected(_:)))
    button.tag = 1
    return button
  }()

  private lazy var cancelButton: NSButton = {
    let button = NSButton(title: Localized.Common.cancel, target: self, action: #selector(cancelClicked))
    button.bezelStyle = .rounded
    button.keyEquivalent = "\u{1b}" // ESC
    return button
  }()

  private lazy var confirmButton: NSButton = {
    let button = NSButton(title: Localized.Account.uploadToAccount, target: self, action: #selector(confirmClicked))
    button.bezelStyle = .rounded
    button.keyEquivalent = "\r" // Enter
    return button
  }()

  // MARK: - Lifecycle

  override func loadView() {
    view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 350))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    let variantStack = NSStackView(views: [classicButton, slimButton])
    variantStack.orientation = .vertical
    variantStack.alignment = .left
    variantStack.spacing = 8

    let buttonStack = NSStackView(views: [cancelButton, confirmButton])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 12
    buttonStack.distribution = .fillEqually

    view.addSubview(titleLabel)
    view.addSubview(previewImageView)
    view.addSubview(variantStack)
    view.addSubview(buttonStack)

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.left.right.equalToSuperview().inset(20)
    }

    previewImageView.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(16)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(150)
    }

    variantStack.snp.makeConstraints { make in
      make.top.equalTo(previewImageView.snp.bottom).offset(20)
      make.left.right.equalToSuperview().inset(40)
    }

    buttonStack.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-20)
      make.left.right.equalToSuperview().inset(40)
      make.height.equalTo(32)
    }
  }

  // MARK: - Public Methods

  func configure(with image: NSImage) {
    skinImage = image
    previewImageView.image = image
  }

  // MARK: - Actions

  @objc private func variantSelected(_ sender: NSButton) {
    selectedVariant = sender.tag == 0 ? .classic : .slim
  }

  @objc private func cancelClicked() {
    dismiss(nil)
  }

  @objc private func confirmClicked() {
    onConfirm?(selectedVariant)
    dismiss(nil)
  }
}
