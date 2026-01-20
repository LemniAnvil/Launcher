//
//  DesignSystem.swift
//  Launcher
//
//  Global design system constants for consistent UI styling
//

import AppKit

// MARK: - Design System

/// Global design system providing consistent styling across the application
enum DesignSystem {
  // MARK: - Spacing

  /// Spacing constants for consistent layout
  enum Spacing {
    /// 4pt - Micro spacing for tight elements
    static let micro: CGFloat = 4
    /// 6pt - Minimal spacing
    static let minimal: CGFloat = 6
    /// 8pt - Tiny spacing
    static let tiny: CGFloat = 8
    /// 10pt - Small spacing
    static let small: CGFloat = 10
    /// 12pt - Section spacing
    static let section: CGFloat = 12
    /// 15pt - Content padding
    static let content: CGFloat = 15
    /// 16pt - Medium spacing
    static let medium: CGFloat = 16
    /// 20pt - Standard padding
    static let standard: CGFloat = 20
    /// 40pt - Large spacing (e.g., indented descriptions)
    static let large: CGFloat = 40
  }

  // MARK: - Corner Radius

  /// Corner radius constants
  enum CornerRadius {
    /// 3pt - Extra small radius
    static let extraSmall: CGFloat = 3
    /// 4pt - Small radius
    static let small: CGFloat = 4
    /// 6pt - Medium radius
    static let medium: CGFloat = 6
    /// 8pt - Standard radius
    static let standard: CGFloat = 8
    /// 10pt - Large radius
    static let large: CGFloat = 10
    /// 12pt - Extra large radius
    static let extraLarge: CGFloat = 12
    /// 16pt - Huge radius (for large icons)
    static let huge: CGFloat = 16
  }

  // MARK: - Sizes

  /// Common size constants
  enum Size {
    /// 1pt - Separator height
    static let separatorHeight: CGFloat = 1
    /// 16pt - Small indicator size
    static let smallIndicator: CGFloat = 16
    /// 20pt - Category icon size
    static let categoryIcon: CGFloat = 20
    /// 24pt - Popup button height
    static let popupHeight: CGFloat = 24
    /// 28pt - Text field height
    static let textFieldHeight: CGFloat = 28
    /// 32pt - Standard button size
    static let button: CGFloat = 32
    /// 60pt - Large icon size
    static let largeIcon: CGFloat = 60
    /// 100pt - Instance icon size
    static let instanceIcon: CGFloat = 100
  }

  // MARK: - Widths

  /// Common width constants
  enum Width {
    /// 60pt - Short label width
    static let shortLabel: CGFloat = 60
    /// 100pt - Action button width
    static let actionButton: CGFloat = 100
    /// 120pt - Filter checkbox width
    static let filterCheckbox: CGFloat = 120
    /// 150pt - Popup button width
    static let popup: CGFloat = 150
    /// 180pt - Sidebar width
    static let sidebar: CGFloat = 180
    /// 200pt - Panel width
    static let panel: CGFloat = 200
    /// 220pt - Filter panel width
    static let filterPanel: CGFloat = 220
    /// 240pt - Placeholder width
    static let placeholder: CGFloat = 240
    /// 280pt - Large placeholder width
    static let largePlaceholder: CGFloat = 280
  }

  // MARK: - Heights

  /// Common height constants
  enum Height {
    /// 140pt - Instance info panel height
    static let instanceInfo: CGFloat = 140
    /// 250pt - Table view height
    static let table: CGFloat = 250
  }

  // MARK: - Fonts

  /// Font constants for consistent typography
  enum Fonts {
    // MARK: Display

    /// 24pt bold - Large title
    static let largeTitle = NSFont.systemFont(ofSize: 24, weight: .bold)
    /// 20pt semibold - Window title
    static let windowTitle = NSFont.systemFont(ofSize: 20, weight: .semibold)
    /// 18pt semibold - Dialog title
    static let dialogTitle = NSFont.systemFont(ofSize: 18, weight: .semibold)

    // MARK: Headings

    /// 16pt semibold - Section title
    static let title = NSFont.systemFont(ofSize: 16, weight: .semibold)
    /// 14pt semibold - Subsection title
    static let subtitle = NSFont.systemFont(ofSize: 14, weight: .semibold)
    /// 14pt medium - Emphasized label
    static let labelMedium = NSFont.systemFont(ofSize: 14, weight: .medium)
    /// 14pt regular - Standard label
    static let label = NSFont.systemFont(ofSize: 14)

    // MARK: Body

    /// 13pt semibold - Table header
    static let tableHeader = NSFont.systemFont(ofSize: 13, weight: .semibold)
    /// 13pt medium - Emphasized body text
    static let bodyMedium = NSFont.systemFont(ofSize: 13, weight: .medium)
    /// 13pt regular - Standard body text
    static let body = NSFont.systemFont(ofSize: 13)

    // MARK: Small

    /// 12pt medium - Small emphasized text
    static let smallMedium = NSFont.systemFont(ofSize: 12, weight: .medium)
    /// 12pt regular - Small text
    static let small = NSFont.systemFont(ofSize: 12)

    // MARK: Caption

    /// 11pt medium - Emphasized caption
    static let captionMedium = NSFont.systemFont(ofSize: 11, weight: .medium)
    /// 11pt regular - Caption text
    static let caption = NSFont.systemFont(ofSize: 11)
    /// 10pt semibold - Badge text
    static let badge = NSFont.systemFont(ofSize: 10, weight: .semibold)

    // MARK: Monospaced

    /// 11pt monospaced - Code text
    static let code = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    /// 10pt monospaced - Small code text
    static let codeSmall = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
  }

  // MARK: - Symbol Sizes

  /// SF Symbol configuration sizes
  enum SymbolSize {
    /// 16pt - Medium symbol size
    static let medium: CGFloat = 16
    /// 60pt - Large symbol size
    static let large: CGFloat = 60
  }
}
