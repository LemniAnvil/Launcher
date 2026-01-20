//
//  StorageMaintenanceSettingsViewController.swift
//  Launcher
//
//  Storage and maintenance settings view controller
//

import AppKit
import SnapKit
import Yatagarasu

final class StorageMaintenanceSettingsViewController: NSViewController {

  // MARK: - Design System Aliases

  private typealias Spacing = DesignSystem.Spacing
  private typealias Fonts = DesignSystem.Fonts
  private typealias Size = DesignSystem.Size

  // MARK: - Properties

  private let pathManager = PathManager.shared

  // MARK: - UI Components

  private let storageTitleLabel = DisplayLabel(
    text: Localized.Settings.storageSectionTitle,
    font: Fonts.title,
    textColor: .labelColor,
    alignment: .left
  )

  private let storageSeparator = BRSeparator.horizontal()

  private let maintenanceTitleLabel = DisplayLabel(
    text: Localized.Settings.maintenanceSectionTitle,
    font: Fonts.title,
    textColor: .labelColor,
    alignment: .left
  )

  private let maintenanceSeparator = BRSeparator.horizontal()

  private let minecraftLabel = DisplayLabel(
    text: Localized.Settings.pathMinecraftLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var minecraftPathLabel = makePathLabel(pathManager.getPath(for: .minecraftRoot, createIfNeeded: false).path)

  private lazy var openMinecraftButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let launcherLabel = DisplayLabel(
    text: Localized.Settings.pathLauncherLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var launcherPathLabel = makePathLabel(pathManager.getPath(for: .launcherRoot, createIfNeeded: false).path)

  private lazy var openLauncherButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let instancesLabel = DisplayLabel(
    text: Localized.Settings.pathInstancesLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var instancesPathLabel = makePathLabel(pathManager.getPath(for: .instances, createIfNeeded: false).path)

  private lazy var openInstancesButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let cacheLabel = DisplayLabel(
    text: Localized.Settings.pathCacheLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var cachePathLabel = makePathLabel(pathManager.getPath(for: .cache, createIfNeeded: false).path)

  private lazy var openCacheButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let logsLabel = DisplayLabel(
    text: Localized.Settings.pathLogsLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var logsPathLabel = makePathLabel(pathManager.getPath(for: .logs, createIfNeeded: false).path)

  private lazy var openLogsButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let tempLabel = DisplayLabel(
    text: Localized.Settings.pathTempLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private lazy var tempPathLabel = makePathLabel(pathManager.getPath(for: .temp, createIfNeeded: false).path)

  private lazy var openTempButton = makeIconButton(
    symbolName: "folder",
    tintColor: .systemBlue,
    accessibilityLabel: Localized.Settings.openInFinder
  )

  private let cacheSizeLabel = DisplayLabel(
    text: Localized.Settings.cacheSizeLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private let cacheSizeValueLabel = DisplayLabel(
    text: Localized.Settings.sizeUnknown,
    font: Fonts.body,
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  private let tempSizeLabel = DisplayLabel(
    text: Localized.Settings.tempSizeLabel,
    font: Fonts.body,
    textColor: .labelColor,
    alignment: .left
  )

  private let tempSizeValueLabel = DisplayLabel(
    text: Localized.Settings.sizeUnknown,
    font: Fonts.body,
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  private lazy var refreshSizesButton = makeIconButton(
    symbolName: "arrow.clockwise",
    tintColor: .systemGray,
    accessibilityLabel: Localized.Settings.refreshSizesButton
  )

  private lazy var clearCacheButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Settings.clearCacheButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(clearCache)
    return button
  }()

  private lazy var clearTempButton: NSButton = {
    let button = NSButton()
    button.title = Localized.Settings.clearTempButton
    button.bezelStyle = .rounded
    button.target = self
    button.action = #selector(clearTempFiles)
    return button
  }()

  private let maintenanceStatusLabel = DisplayLabel(
    text: Localized.Settings.maintenanceStatusReady,
    font: Fonts.caption,
    textColor: .secondaryLabelColor,
    alignment: .left
  )

  // MARK: - Lifecycle

  override func loadView() {
    self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 450))
    self.view.wantsLayer = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    refreshSizes()
  }

  // MARK: - Setup

  private func setupUI() {
    openMinecraftButton.target = self
    openMinecraftButton.action = #selector(openMinecraftFolder)

    openLauncherButton.target = self
    openLauncherButton.action = #selector(openLauncherFolder)

    openInstancesButton.target = self
    openInstancesButton.action = #selector(openInstancesFolder)

    openCacheButton.target = self
    openCacheButton.action = #selector(openCacheFolder)

    openLogsButton.target = self
    openLogsButton.action = #selector(openLogsFolder)

    openTempButton.target = self
    openTempButton.action = #selector(openTempFolder)

    refreshSizesButton.target = self
    refreshSizesButton.action = #selector(refreshSizesTapped)

    view.addSubview(storageTitleLabel)
    view.addSubview(storageSeparator)

    view.addSubview(minecraftLabel)
    view.addSubview(minecraftPathLabel)
    view.addSubview(openMinecraftButton)

    view.addSubview(launcherLabel)
    view.addSubview(launcherPathLabel)
    view.addSubview(openLauncherButton)

    view.addSubview(instancesLabel)
    view.addSubview(instancesPathLabel)
    view.addSubview(openInstancesButton)

    view.addSubview(cacheLabel)
    view.addSubview(cachePathLabel)
    view.addSubview(openCacheButton)

    view.addSubview(logsLabel)
    view.addSubview(logsPathLabel)
    view.addSubview(openLogsButton)

    view.addSubview(tempLabel)
    view.addSubview(tempPathLabel)
    view.addSubview(openTempButton)

    view.addSubview(maintenanceTitleLabel)
    view.addSubview(maintenanceSeparator)
    view.addSubview(cacheSizeLabel)
    view.addSubview(cacheSizeValueLabel)
    view.addSubview(tempSizeLabel)
    view.addSubview(tempSizeValueLabel)
    view.addSubview(refreshSizesButton)
    view.addSubview(clearCacheButton)
    view.addSubview(clearTempButton)
    view.addSubview(maintenanceStatusLabel)

    storageTitleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(Spacing.standard)
      make.left.equalToSuperview().offset(Spacing.standard)
    }

    storageSeparator.snp.makeConstraints { make in
      make.top.equalTo(storageTitleLabel.snp.bottom).offset(Spacing.section)
      make.left.right.equalToSuperview().inset(Spacing.standard)
      make.height.equalTo(Size.separatorHeight)
    }

    layoutPathRow(
      label: minecraftLabel,
      value: minecraftPathLabel,
      button: openMinecraftButton,
      topAnchor: storageSeparator.snp.bottom
    )

    layoutPathRow(
      label: launcherLabel,
      value: launcherPathLabel,
      button: openLauncherButton,
      topAnchor: minecraftLabel.snp.bottom
    )

    layoutPathRow(
      label: instancesLabel,
      value: instancesPathLabel,
      button: openInstancesButton,
      topAnchor: launcherLabel.snp.bottom
    )

    layoutPathRow(
      label: cacheLabel,
      value: cachePathLabel,
      button: openCacheButton,
      topAnchor: instancesLabel.snp.bottom
    )

    layoutPathRow(
      label: logsLabel,
      value: logsPathLabel,
      button: openLogsButton,
      topAnchor: cacheLabel.snp.bottom
    )

    layoutPathRow(
      label: tempLabel,
      value: tempPathLabel,
      button: openTempButton,
      topAnchor: logsLabel.snp.bottom
    )

    maintenanceTitleLabel.snp.makeConstraints { make in
      make.top.equalTo(tempLabel.snp.bottom).offset(Spacing.medium)
      make.left.equalToSuperview().offset(Spacing.standard)
    }

    maintenanceSeparator.snp.makeConstraints { make in
      make.top.equalTo(maintenanceTitleLabel.snp.bottom).offset(Spacing.section)
      make.left.right.equalToSuperview().inset(Spacing.standard)
      make.height.equalTo(Size.separatorHeight)
    }

    cacheSizeLabel.snp.makeConstraints { make in
      make.top.equalTo(maintenanceSeparator.snp.bottom).offset(Spacing.section)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.equalTo(140)
    }

    cacheSizeValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(cacheSizeLabel)
      make.left.equalTo(cacheSizeLabel.snp.right).offset(Spacing.small)
      make.right.equalTo(refreshSizesButton.snp.left).offset(-Spacing.small)
    }

    refreshSizesButton.snp.makeConstraints { make in
      make.centerY.equalTo(cacheSizeLabel)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.width.height.equalTo(28)
    }

    tempSizeLabel.snp.makeConstraints { make in
      make.top.equalTo(cacheSizeLabel.snp.bottom).offset(Spacing.small)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.equalTo(140)
    }

    tempSizeValueLabel.snp.makeConstraints { make in
      make.centerY.equalTo(tempSizeLabel)
      make.left.equalTo(tempSizeLabel.snp.right).offset(Spacing.small)
      make.right.equalToSuperview().offset(-Spacing.standard)
    }

    clearCacheButton.snp.makeConstraints { make in
      make.top.equalTo(tempSizeLabel.snp.bottom).offset(Spacing.medium)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.height.equalTo(Size.button)
      make.width.equalTo(140)
    }

    clearTempButton.snp.makeConstraints { make in
      make.centerY.equalTo(clearCacheButton)
      make.left.equalTo(clearCacheButton.snp.right).offset(Spacing.small)
      make.height.equalTo(Size.button)
      make.width.equalTo(180)
    }

    maintenanceStatusLabel.snp.makeConstraints { make in
      make.top.equalTo(clearCacheButton.snp.bottom).offset(Spacing.small)
      make.left.right.equalToSuperview().inset(Spacing.standard)
    }
  }

  private func layoutPathRow(
    label: DisplayLabel,
    value: DisplayLabel,
    button: BRImageButton,
    topAnchor: ConstraintRelatableTarget
  ) {
    label.snp.makeConstraints { make in
      make.top.equalTo(topAnchor).offset(Spacing.section)
      make.left.equalToSuperview().offset(Spacing.standard)
      make.width.equalTo(140)
    }

    value.snp.makeConstraints { make in
      make.centerY.equalTo(label)
      make.left.equalTo(label.snp.right).offset(Spacing.small)
      make.right.equalTo(button.snp.left).offset(-Spacing.small)
    }

    button.snp.makeConstraints { make in
      make.centerY.equalTo(label)
      make.right.equalToSuperview().offset(-Spacing.standard)
      make.width.height.equalTo(28)
    }
  }

  private func makePathLabel(_ text: String) -> DisplayLabel {
    DisplayLabel(
      text: text,
      font: Fonts.codeSmall,
      textColor: .secondaryLabelColor,
      alignment: .left,
      lineBreakMode: .byTruncatingMiddle
    )
  }

  private func makeIconButton(
    symbolName: String,
    tintColor: NSColor,
    accessibilityLabel: String
  ) -> BRImageButton {
    let button = BRImageButton(
      symbolName: symbolName,
      cornerRadius: DesignSystem.CornerRadius.medium,
      highlightColorProvider: { [weak self] in
        self?.view.effectiveAppearance.name == .darkAqua
          ? NSColor.white.withAlphaComponent(0.1)
          : NSColor.black.withAlphaComponent(0.06)
      },
      tintColor: tintColor,
      accessibilityLabel: accessibilityLabel
    )
    return button
  }

  // MARK: - Actions

  @objc private func openMinecraftFolder() {
    openFolder(pathManager.getPath(for: .minecraftRoot, createIfNeeded: false))
  }

  @objc private func openLauncherFolder() {
    openFolder(pathManager.getPath(for: .launcherRoot, createIfNeeded: false))
  }

  @objc private func openInstancesFolder() {
    openFolder(pathManager.getPath(for: .instances, createIfNeeded: false))
  }

  @objc private func openCacheFolder() {
    openFolder(pathManager.getPath(for: .cache, createIfNeeded: false))
  }

  @objc private func openLogsFolder() {
    openFolder(pathManager.getPath(for: .logs, createIfNeeded: false))
  }

  @objc private func openTempFolder() {
    openFolder(pathManager.getPath(for: .temp, createIfNeeded: false))
  }

  @objc private func refreshSizesTapped() {
    refreshSizes()
  }

  private func refreshSizes(finalStatus: String? = nil) {
    cacheSizeValueLabel.stringValue = Localized.Settings.sizeCalculating
    tempSizeValueLabel.stringValue = Localized.Settings.sizeCalculating
    maintenanceStatusLabel.stringValue = Localized.Settings.maintenanceStatusRefreshing

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      let cacheSize = self.directorySizeString(for: .cache)
      let tempSize = self.directorySizeString(for: .temp)

      DispatchQueue.main.async {
        self.cacheSizeValueLabel.stringValue = cacheSize
        self.tempSizeValueLabel.stringValue = tempSize
        self.maintenanceStatusLabel.stringValue = finalStatus ?? Localized.Settings.maintenanceStatusReady
      }
    }
  }

  @objc private func clearCache() {
    confirmAction(
      title: Localized.Settings.clearCacheConfirmTitle,
      message: Localized.Settings.clearCacheConfirmMessage
    ) { [weak self] in
      guard let self = self else { return }
      self.performMaintenanceAction {
        try self.pathManager.cleanOldCache(olderThanDays: 0)
      } successMessage: {
        Localized.Settings.maintenanceStatusCacheCleared
      }
    }
  }

  @objc private func clearTempFiles() {
    confirmAction(
      title: Localized.Settings.clearTempConfirmTitle,
      message: Localized.Settings.clearTempConfirmMessage
    ) { [weak self] in
      guard let self = self else { return }
      self.performMaintenanceAction {
        try self.pathManager.cleanTemporaryFiles()
      } successMessage: {
        Localized.Settings.maintenanceStatusTempCleared
      }
    }
  }

  private func performMaintenanceAction(
    _ action: @escaping () throws -> Void,
    successMessage: @escaping () -> String
  ) {
    maintenanceStatusLabel.stringValue = Localized.Settings.maintenanceStatusCleaning

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      do {
        try action()
        DispatchQueue.main.async {
          self.refreshSizes(finalStatus: successMessage())
        }
      } catch {
        DispatchQueue.main.async {
          self.maintenanceStatusLabel.stringValue = Localized.Settings.maintenanceStatusFailed(error.localizedDescription)
        }
      }
    }
  }

  private func confirmAction(title: String, message: String, action: @escaping () -> Void) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.Settings.okButton)
    alert.addButton(withTitle: Localized.Settings.cancelButton)

    if let window = view.window {
      alert.beginSheetModal(for: window) { response in
        if response == .alertFirstButtonReturn {
          action()
        }
      }
    } else {
      if alert.runModal() == .alertFirstButtonReturn {
        action()
      }
    }
  }

  private func openFolder(_ url: URL) {
    NSWorkspace.shared.open(url)
  }

  private func directorySizeString(for type: PathType) -> String {
    let url = pathManager.getPath(for: type, createIfNeeded: false)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return FileUtils.formatBytes(0)
    }

    do {
      let size = try pathManager.getDirectorySize(at: url)
      return FileUtils.formatBytes(size)
    } catch {
      return Localized.Settings.sizeUnknown
    }
  }
}
