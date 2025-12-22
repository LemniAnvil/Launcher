//
//  AccountRefreshStatusView.swift
//  Launcher
//
//  Status indicator view for account refresh operations
//

import AppKit
import SnapKit
import Yatagarasu

class AccountRefreshStatusView: NSView {
  // swiftlint:disable:previous type_body_length
  // MARK: - Refresh Steps

  enum RefreshStep: Hashable, Equatable {
    case refreshingToken
    case authenticatingXBL
    case authenticatingXSTS
    case authenticatingMinecraft
    case fetchingProfile
    case savingAccount
    case completed
    case failed(String)

    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.refreshingToken, .refreshingToken),
        (.authenticatingXBL, .authenticatingXBL),
        (.authenticatingXSTS, .authenticatingXSTS),
        (.authenticatingMinecraft, .authenticatingMinecraft),
        (.fetchingProfile, .fetchingProfile),
        (.savingAccount, .savingAccount),
        (.completed, .completed):
        return true
      case (.failed, .failed):
        return true
      default:
        return false
      }
    }

    func hash(into hasher: inout Hasher) {
      switch self {
      case .refreshingToken:
        hasher.combine(0)
      case .authenticatingXBL:
        hasher.combine(1)
      case .authenticatingXSTS:
        hasher.combine(2)
      case .authenticatingMinecraft:
        hasher.combine(3)
      case .fetchingProfile:
        hasher.combine(4)
      case .savingAccount:
        hasher.combine(5)
      case .completed:
        hasher.combine(6)
      case .failed:
        hasher.combine(7)
      }
    }

    var displayText: String {
      switch self {
      case .refreshingToken:
        return Localized.Account.refreshStepToken
      case .authenticatingXBL:
        return Localized.Account.refreshStepXBL
      case .authenticatingXSTS:
        return Localized.Account.refreshStepXSTS
      case .authenticatingMinecraft:
        return Localized.Account.refreshStepMinecraft
      case .fetchingProfile:
        return Localized.Account.refreshStepProfile
      case .savingAccount:
        return Localized.Account.refreshStepSaving
      case .completed:
        return Localized.Account.refreshStepCompleted
      case .failed(let error):
        return Localized.Account.refreshStepFailed(error)
      }
    }

    var icon: String {
      switch self {
      case .refreshingToken, .authenticatingXBL, .authenticatingXSTS,
        .authenticatingMinecraft, .fetchingProfile, .savingAccount:
        return "arrow.clockwise"
      case .completed:
        return "checkmark.circle.fill"
      case .failed:
        return "xmark.circle.fill"
      }
    }

    var color: NSColor {
      switch self {
      case .refreshingToken, .authenticatingXBL, .authenticatingXSTS,
        .authenticatingMinecraft, .fetchingProfile, .savingAccount:
        return .systemBlue
      case .completed:
        return .systemGreen
      case .failed:
        return .systemRed
      }
    }
  }

  // MARK: - Login Steps

  enum LoginStep: Hashable, Equatable {
    case gettingToken
    case authenticatingXBL
    case authenticatingXSTS
    case authenticatingMinecraft
    case fetchingProfile
    case savingAccount
    case completed
    case failed(String)

    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.gettingToken, .gettingToken),
        (.authenticatingXBL, .authenticatingXBL),
        (.authenticatingXSTS, .authenticatingXSTS),
        (.authenticatingMinecraft, .authenticatingMinecraft),
        (.fetchingProfile, .fetchingProfile),
        (.savingAccount, .savingAccount),
        (.completed, .completed):
        return true
      case (.failed, .failed):
        return true
      default:
        return false
      }
    }

    func hash(into hasher: inout Hasher) {
      switch self {
      case .gettingToken:
        hasher.combine(0)
      case .authenticatingXBL:
        hasher.combine(1)
      case .authenticatingXSTS:
        hasher.combine(2)
      case .authenticatingMinecraft:
        hasher.combine(3)
      case .fetchingProfile:
        hasher.combine(4)
      case .savingAccount:
        hasher.combine(5)
      case .completed:
        hasher.combine(6)
      case .failed:
        hasher.combine(7)
      }
    }

    var displayText: String {
      switch self {
      case .gettingToken:
        return Localized.Account.loginStepToken
      case .authenticatingXBL:
        return Localized.Account.refreshStepXBL
      case .authenticatingXSTS:
        return Localized.Account.refreshStepXSTS
      case .authenticatingMinecraft:
        return Localized.Account.refreshStepMinecraft
      case .fetchingProfile:
        return Localized.Account.refreshStepProfile
      case .savingAccount:
        return Localized.Account.refreshStepSaving
      case .completed:
        return Localized.Account.refreshStepCompleted
      case .failed(let error):
        return Localized.Account.refreshStepFailed(error)
      }
    }

    var icon: String {
      switch self {
      case .gettingToken, .authenticatingXBL, .authenticatingXSTS,
        .authenticatingMinecraft, .fetchingProfile, .savingAccount:
        return "arrow.clockwise"
      case .completed:
        return "checkmark.circle.fill"
      case .failed:
        return "xmark.circle.fill"
      }
    }

    var color: NSColor {
      switch self {
      case .gettingToken, .authenticatingXBL, .authenticatingXSTS,
        .authenticatingMinecraft, .fetchingProfile, .savingAccount:
        return .systemBlue
      case .completed:
        return .systemGreen
      case .failed:
        return .systemRed
      }
    }
  }

  // MARK: - Properties

  private var currentStep: RefreshStep = .refreshingToken
  private var currentLoginStep: LoginStep = .gettingToken
  private var isLoginMode: Bool = false

  private var stepLabelViews: [NSTextField] = []

  // MARK: - UI Components

  private let containerView: NSView = {
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    view.layer?.cornerRadius = BRSpacing.cornerRadiusMedium
    view.layer?.borderWidth = 1
    view.layer?.borderColor = NSColor.separatorColor.cgColor
    return view
  }()

  private let iconImageView: NSImageView = {
    let imageView = NSImageView()
    imageView.imageScaling = .scaleProportionallyDown
    return imageView
  }()

  private let statusLabel = BRLabel(
    text: "",
    font: .systemFont(ofSize: 13, weight: .medium),
    textColor: .labelColor,
    alignment: .left
  )

  private let progressIndicator: NSProgressIndicator = {
    let indicator = NSProgressIndicator()
    indicator.style = .spinning
    indicator.controlSize = .small
    indicator.isIndeterminate = true
    return indicator
  }()

  private let stepLabelsContainer: NSStackView = {
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.spacing = 4
    stack.alignment = .leading
    return stack
  }()

  private var stepLabels: [RefreshStep: NSTextField] = [:]

  // MARK: - Initialization

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    addSubview(containerView)

    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(BRSpacing.medium)
    }

    containerView.addSubview(progressIndicator)
    containerView.addSubview(iconImageView)
    containerView.addSubview(statusLabel)
    containerView.addSubview(stepLabelsContainer)

    progressIndicator.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.medium)
      make.width.height.equalTo(20)
    }

    iconImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(BRSpacing.medium)
      make.top.equalToSuperview().offset(BRSpacing.medium)
      make.width.height.equalTo(20)
    }

    statusLabel.snp.makeConstraints { make in
      make.left.equalTo(progressIndicator.snp.right).offset(BRSpacing.small)
      make.centerY.equalTo(progressIndicator)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
    }

    stepLabelsContainer.snp.makeConstraints { make in
      make.top.equalTo(statusLabel.snp.bottom).offset(BRSpacing.small)
      make.left.equalToSuperview().offset(BRSpacing.medium + 20 + BRSpacing.small)
      make.right.equalToSuperview().offset(-BRSpacing.medium)
      make.bottom.equalToSuperview().offset(-BRSpacing.medium)
    }

    // Initially hide
    isHidden = true
    iconImageView.isHidden = true
  }

  // MARK: - Public Methods

  func startRefresh(accountName: String) {
    isLoginMode = false

    // Show and expand the view
    isHidden = false
    snp.updateConstraints { make in
      make.height.equalTo(200)
    }

    progressIndicator.isHidden = false
    progressIndicator.startAnimation(nil)
    iconImageView.isHidden = true

    statusLabel.stringValue = Localized.Account.refreshingAccount(accountName)
    statusLabel.textColor = .labelColor

    // Clear previous steps
    stepLabelsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
    stepLabels.removeAll()

    // Add step labels
    let steps: [RefreshStep] = [
      .refreshingToken,
      .authenticatingXBL,
      .authenticatingXSTS,
      .authenticatingMinecraft,
      .fetchingProfile,
      .savingAccount,
    ]

    for step in steps {
      let label = createStepLabel(for: step, isActive: false)
      stepLabelsContainer.addArrangedSubview(label)
      stepLabels[step] = label
    }

    updateStep(.refreshingToken)
  }

  func startLogin(accountName: String) {
    isLoginMode = true

    // Show and expand the view
    isHidden = false
    snp.updateConstraints { make in
      make.height.equalTo(200)
    }

    progressIndicator.isHidden = false
    progressIndicator.startAnimation(nil)
    iconImageView.isHidden = true

    statusLabel.stringValue = Localized.Account.loggingInAccount(accountName)
    statusLabel.textColor = .labelColor

    // Clear previous steps
    stepLabelsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
    stepLabelViews.removeAll()

    // Add login step labels
    let steps: [LoginStep] = [
      .gettingToken,
      .authenticatingXBL,
      .authenticatingXSTS,
      .authenticatingMinecraft,
      .fetchingProfile,
      .savingAccount,
    ]

    for step in steps {
      let label = createLoginStepLabel(for: step, isActive: false)
      stepLabelsContainer.addArrangedSubview(label)
      stepLabelViews.append(label)
    }

    updateLoginStep(.gettingToken)
  }

  func updateLoginStep(_ step: LoginStep) {
    currentLoginStep = step
    statusLabel.stringValue = step.displayText
    statusLabel.textColor = step.color

    // Update step labels
    let steps: [LoginStep] = [
      .gettingToken,
      .authenticatingXBL,
      .authenticatingXSTS,
      .authenticatingMinecraft,
      .fetchingProfile,
      .savingAccount,
    ]

    for (index, loginStep) in steps.enumerated() {
      if index < stepLabelViews.count {
        updateLoginStepLabel(stepLabelViews[index], for: loginStep, currentStep: step)
      }
    }

    // Handle completion or failure
    switch step {
    case .completed, .failed:
      progressIndicator.stopAnimation(nil)
      progressIndicator.isHidden = true
      iconImageView.isHidden = false
      iconImageView.image = NSImage(
        systemSymbolName: step.icon,
        accessibilityDescription: nil
      )
      iconImageView.contentTintColor = step.color

      // Auto-hide after 3 seconds on success
      if case .completed = step {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
          self?.hide()
        }
      }
    default:
      break
    }
  }

  func updateStep(_ step: RefreshStep) {
    currentStep = step
    statusLabel.stringValue = step.displayText
    statusLabel.textColor = step.color

    // Update step labels
    for (stepKey, label) in stepLabels {
      updateStepLabel(label, for: stepKey, currentStep: step)
    }

    // Handle completion or failure
    switch step {
    case .completed, .failed:
      progressIndicator.stopAnimation(nil)
      progressIndicator.isHidden = true
      iconImageView.isHidden = false
      iconImageView.image = NSImage(
        systemSymbolName: step.icon,
        accessibilityDescription: nil
      )
      iconImageView.contentTintColor = step.color

      // Auto-hide after 3 seconds on success
      if case .completed = step {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
          self?.hide()
        }
      }
    default:
      break
    }
  }

  func hide() {
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.3
      animator().alphaValue = 0

      // Collapse height
      snp.updateConstraints { make in
        make.height.equalTo(0)
      }
      superview?.layoutSubtreeIfNeeded()
    } completionHandler: { [weak self] in
      self?.isHidden = true
      self?.alphaValue = 1
    }
  }

  // MARK: - Helper Methods

  private func createStepLabel(for step: RefreshStep, isActive: Bool) -> NSTextField {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingTail
    updateStepLabel(label, for: step, currentStep: currentStep)
    return label
  }

  private func updateStepLabel(
    _ label: NSTextField, for step: RefreshStep, currentStep: RefreshStep
  ) {
    let isCompleted = stepOrder(of: step) < stepOrder(of: currentStep)
    let isActive = step == currentStep
    let isFailed: Bool
    if case .failed = currentStep {
      isFailed = true
    } else {
      isFailed = false
    }

    if isFailed && isActive {
      label.stringValue = "❌ \(step.displayText)"
      label.textColor = .systemRed
      label.font = .systemFont(ofSize: 11, weight: .medium)
    } else if isCompleted {
      label.stringValue = "✓ \(step.displayText)"
      label.textColor = .systemGreen
      label.font = .systemFont(ofSize: 11, weight: .regular)
    } else if isActive {
      label.stringValue = "→ \(step.displayText)"
      label.textColor = .systemBlue
      label.font = .systemFont(ofSize: 11, weight: .medium)
    } else {
      label.stringValue = "○ \(step.displayText)"
      label.textColor = .secondaryLabelColor
      label.font = .systemFont(ofSize: 11, weight: .regular)
    }
  }

  private func stepOrder(of step: RefreshStep) -> Int {
    switch step {
    case .refreshingToken: return 0
    case .authenticatingXBL: return 1
    case .authenticatingXSTS: return 2
    case .authenticatingMinecraft: return 3
    case .fetchingProfile: return 4
    case .savingAccount: return 5
    case .completed: return 6
    case .failed: return 7
    }
  }

  private func createLoginStepLabel(for step: LoginStep, isActive: Bool) -> NSTextField {
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 11)
    label.textColor = .secondaryLabelColor
    label.lineBreakMode = .byTruncatingTail
    updateLoginStepLabel(label, for: step, currentStep: currentLoginStep)
    return label
  }

  private func updateLoginStepLabel(
    _ label: NSTextField, for step: LoginStep, currentStep: LoginStep
  ) {
    let isCompleted = loginStepOrder(of: step) < loginStepOrder(of: currentStep)
    let isActive = step == currentStep
    let isFailed: Bool
    if case .failed = currentStep {
      isFailed = true
    } else {
      isFailed = false
    }

    if isFailed && isActive {
      label.stringValue = "❌ \(step.displayText)"
      label.textColor = .systemRed
      label.font = .systemFont(ofSize: 11, weight: .medium)
    } else if isCompleted {
      label.stringValue = "✓ \(step.displayText)"
      label.textColor = .systemGreen
      label.font = .systemFont(ofSize: 11, weight: .regular)
    } else if isActive {
      label.stringValue = "→ \(step.displayText)"
      label.textColor = .systemBlue
      label.font = .systemFont(ofSize: 11, weight: .medium)
    } else {
      label.stringValue = "○ \(step.displayText)"
      label.textColor = .secondaryLabelColor
      label.font = .systemFont(ofSize: 11, weight: .regular)
    }
  }

  private func loginStepOrder(of step: LoginStep) -> Int {
    switch step {
    case .gettingToken: return 0
    case .authenticatingXBL: return 1
    case .authenticatingXSTS: return 2
    case .authenticatingMinecraft: return 3
    case .fetchingProfile: return 4
    case .savingAccount: return 5
    case .completed: return 6
    case .failed: return 7
    }
  }
}
