//
//  AccountCellView.swift
//  Launcher
//
//  Custom account cell view
//

import AppKit
import SnapKit
import Yatagarasu

class AccountCellView: NSView {

  // MARK: - Account Type

  enum AccountType {
    case microsoft(MicrosoftAccount)
    case offline(OfflineAccount)
  }

  // MARK: - Properties

  private var isHighlighted: Bool = false
  private var currentAccountType: AccountType?
  private var isDeveloperMode: Bool = false

  // MARK: - UI Components

  let containerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.cornerRadius = BRSpacing.cornerRadiusMedium
    view.layer?.backgroundColor = BRColorPalette.background.cgColor
    return view
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.cornerRadius = 6
    imageView.layer?.masksToBounds = true
    return imageView
  }()

  let nameLabel = DisplayLabel(
    text: "",
    font: .systemFont(ofSize: 14, weight: .medium),
    textColor: BRColorPalette.text,
    alignment: .left
  )

  private let defaultBadgeView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.systemGreen.cgColor
    view.layer?.cornerRadius = 3
    view.isHidden = true

    let label = NSTextField(labelWithString: Localized.Account.defaultBadge)
    label.font = .systemFont(ofSize: 10, weight: .semibold)
    label.textColor = .white
    label.alignment = .center
    view.addSubview(label)

    label.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
    }

    return view
  }()

  var detailLabels: [NSView] = []

  // MARK: - Initialization

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupUI() {
    addSubview(containerView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
    }

    containerView.addSubview(iconImageView)
    containerView.addSubview(nameLabel)
    containerView.addSubview(defaultBadgeView)

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.smallMedium)
      make.width.height.equalTo(36)
    }

    nameLabel.snp.makeConstraints { make in
      make.left.equalTo(iconImageView.snp.right).offset(BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.smallMedium)
      make.right.equalTo(defaultBadgeView.snp.left).offset(-BRSpacing.small)
    }

    defaultBadgeView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(BRSpacing.smallMedium)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.height.equalTo(18)
    }
  }

  // MARK: - Configuration

  func configure(with accountType: AccountType, isDeveloperMode: Bool, isDefault: Bool = false) {
    self.currentAccountType = accountType
    self.isDeveloperMode = isDeveloperMode

    // Update default badge visibility
    defaultBadgeView.isHidden = !isDefault

    // Clear previous detail labels
    detailLabels.forEach { $0.removeFromSuperview() }
    detailLabels.removeAll()

    switch accountType {
    case .microsoft(let account):
      configureMicrosoftAccount(account)
    case .offline(let account):
      configureOfflineAccount(account)
    }
  }

  private func configureMicrosoftAccount(_ account: MicrosoftAccount) {
    nameLabel.stringValue = account.name

    // Set default icon
    iconImageView.image = NSImage(
      systemSymbolName: BRIcons.accountFilled,
      accessibilityDescription: nil
    )
    iconImageView.contentTintColor = .systemGreen

    // Load avatar asynchronously
    loadMinecraftAvatar(uuid: account.id) { [weak self] image in
      DispatchQueue.main.async {
        self?.iconImageView.image = image
        self?.iconImageView.contentTintColor = nil
      }
    }

    // Add detail information
    if isDeveloperMode {
      addMicrosoftDeveloperModeDetails(account)
    } else {
      addMicrosoftNormalModeDetails(account)
    }
  }

  private func configureOfflineAccount(_ account: OfflineAccount) {
    nameLabel.stringValue = account.name

    // Set default icon
    iconImageView.image = NSImage(
      systemSymbolName: BRIcons.accountOutline,
      accessibilityDescription: nil
    )
    iconImageView.contentTintColor = .systemBlue

    // Load avatar asynchronously (offline accounts use Steve skin)
    loadMinecraftAvatar(uuid: nil, username: account.name) { [weak self] image in
      DispatchQueue.main.async {
        self?.iconImageView.image = image
        self?.iconImageView.contentTintColor = nil
      }
    }

    // Add detail information
    if isDeveloperMode {
      addOfflineDeveloperModeDetails(account)
    } else {
      addOfflineNormalModeDetails(account)
    }
  }

  // MARK: - Helper Methods

  func createDetailLabel(text: String, font: NSFont, color: NSColor) -> DisplayLabel {
    DisplayLabel(
      text: text,
      font: font,
      textColor: color,
      alignment: .left
    )
  }

  // MARK: - Selection Highlighting

  func setHighlighted(_ highlighted: Bool) {
    isHighlighted = highlighted
    updateAppearance()
  }

  private func updateAppearance() {
    if isHighlighted {
      let highlightColor: NSColor
      if NSApp.effectiveAppearance.name == .darkAqua {
        highlightColor = BRColorPalette.highlight
      } else {
        highlightColor = BRColorPalette.subtleHighlight
      }
      containerView.layer?.backgroundColor = highlightColor.cgColor
    } else {
      containerView.layer?.backgroundColor = BRColorPalette.background.cgColor
    }
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    updateAppearance()
  }
}
