//
//  DisplayLabel.swift
//  Launcher
//

import AppKit

public class DisplayLabel: NSTextField {

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupDefaults()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init() {
    super.init(frame: .zero)
    setupDefaults()
  }

  private func setupDefaults() {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    drawsBackground = false
    isBordered = false
    isBezeled = false
    isEditable = false
    isSelectable = false
  }

  public convenience init(
    text: String = "",
    font: NSFont = .systemFont(ofSize: 14),
    textColor: NSColor = .labelColor,
    alignment: NSTextAlignment = .left,
    lineBreakMode: NSLineBreakMode = .byTruncatingTail,
    maximumNumberOfLines: Int = 1
  ) {
    self.init()
    self.stringValue = text
    self.font = font
    self.textColor = textColor
    self.alignment = alignment
    self.lineBreakMode = lineBreakMode
    self.maximumNumberOfLines = maximumNumberOfLines
  }
}
