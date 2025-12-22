//
//  InstanceDetailViewController+Actions.swift
//  Launcher
//
//  Action handlers for instance detail view
//

import AppKit

// MARK: - Actions
extension InstanceDetailViewController {
  @objc func toggleEditMode() {
    isEditMode = true
    updateUIForEditMode()
  }

  @objc func cancelEdit() {
    isEditMode = false
    // Reset fields to original values
    nameTextField.stringValue = instance.name
    updateUIForEditMode()
  }

  @objc func saveChanges() {
    let newName = nameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

    // Validate name
    guard !newName.isEmpty else {
      showError(Localized.InstanceDetail.errorEmptyName)
      return
    }

    // Check if name changed
    guard newName != instance.name else {
      // No changes, just exit edit mode
      isEditMode = false
      updateUIForEditMode()
      return
    }

    // TODO: Implement instance renaming in InstanceManager
    // For now, we'll update the local instance and notify
    // This requires adding an update method to InstanceManager

    showNotImplementedAlert()
  }

  @objc func openInstanceFolder() {
    let instanceDir = instanceManager.getInstanceDirectory(for: instance)
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: instanceDir.path)
  }

  @objc func close() {
    onClose?()
    view.window?.close()
  }

  // MARK: - Helper Methods

  func updateUIForEditMode() {
    if isEditMode {
      // Show edit fields and save/cancel buttons
      nameValueLabel.isHidden = true
      nameTextField.isHidden = false
      nameTextField.stringValue = instance.name

      editButton.isHidden = true
      saveButton.isHidden = false
      cancelEditButton.isHidden = false

      // Disable close button in edit mode
      closeButton.isEnabled = false
      openFolderButton.isEnabled = false
    } else {
      // Show view mode
      nameValueLabel.isHidden = false
      nameTextField.isHidden = true

      editButton.isHidden = false
      saveButton.isHidden = true
      cancelEditButton.isHidden = true

      closeButton.isEnabled = true
      openFolderButton.isEnabled = true
    }
  }

  func showNotImplementedAlert() {
    let alert = NSAlert()
    alert.messageText = Localized.InstanceDetail.notImplementedTitle
    alert.informativeText = Localized.InstanceDetail.notImplementedMessage
    alert.alertStyle = .informational
    alert.addButton(withTitle: Localized.InstanceDetail.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }

  func showError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.InstanceDetail.errorTitle
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: Localized.InstanceDetail.okButton)

    if let window = view.window {
      alert.beginSheetModal(for: window)
    } else {
      alert.runModal()
    }
  }
}
