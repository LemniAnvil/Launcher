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

  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Size = DesignSystem.Size
  private typealias Fonts = DesignSystem.Fonts

  // MARK: - Properties

  private var skinImage: NSImage?
  private(set) var selectedVariant: SkinVariant = .classic
  var onConfirm: ((SkinVariant) -> Void)?

  // MARK: - UI Components

  private let titleLabel: NSTextField = {
    let label = NSTextField(labelWithString: Localized.Account.selectSkinVariant)
    label.font = Fonts.title
    label.alignment = .center
    return label
  }()

  private let previewImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = Radius.standard
    imageView.layer?.borderWidth = Size.separatorHeight
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
    variantStack.spacing = Spacing.tiny

    let buttonStack = NSStackView(views: [cancelButton, confirmButton])
    buttonStack.orientation = .horizontal
    buttonStack.spacing = Spacing.section
    buttonStack.distribution = .fillEqually

    view.addSubview(titleLabel)
    view.addSubview(previewImageView)
    view.addSubview(variantStack)
    view.addSubview(buttonStack)

    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.standard)
      make.left.right.equalToSuperview().inset(Spacing.standard)
    }

    previewImageView.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.medium)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(150)
    }

    variantStack.snp.makeConstraints { make in
      make.top.equalTo(previewImageView.snp.bottom).offset(Spacing.standard)
      make.left.right.equalToSuperview().inset(Spacing.large)
    }

    buttonStack.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-Spacing.standard)
      make.left.right.equalToSuperview().inset(Spacing.large)
      make.height.equalTo(Size.button)
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
