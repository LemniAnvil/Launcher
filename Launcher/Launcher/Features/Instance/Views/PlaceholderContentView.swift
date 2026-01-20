//
//  PlaceholderContentView.swift
//  Launcher
//
//  Simple placeholder for unavailable categories.
//

import AppKit
import CraftKit
import SnapKit
import Yatagarasu

final class PlaceholderContentView: NSView {
  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Radius = DesignSystem.CornerRadius
  private typealias Fonts = DesignSystem.Fonts

  private let titleText: String

  // MARK: - UI Components

  private lazy var titleLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: titleText,
      font: Fonts.title,
      textColor: .labelColor,
      alignment: .center
    )
    return label
  }()

  private let comingSoonLabel: DisplayLabel = {
    let label = DisplayLabel(
      text: "Coming Soon",
      font: Fonts.subtitle,
      textColor: .secondaryLabelColor,
      alignment: .center
    )
    return label
  }()

  // MARK: - Initialization

  init(title: String) {
    self.titleText = title
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    self.titleText = ""
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Setup

  private func setupUI() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    layer?.cornerRadius = Radius.standard
    layer?.borderWidth = 1
    layer?.borderColor = NSColor.separatorColor.cgColor

    addSubview(titleLabel)
    addSubview(comingSoonLabel)

    titleLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-Spacing.standard)
    }

    comingSoonLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.section)
    }
  }
}
