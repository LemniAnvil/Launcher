//
//  AccountInfoViewController+CapeManagement.swift
//  Launcher
//
//  Cape management API integration using CraftKit
//

import AppKit
import CraftKit
import Foundation

extension AccountInfoViewController {

  // MARK: - Cape Equip

  /// Equip a cape from the account's cape library
  func equipCape(_ cape: Cape) async throws {
    guard let account = selectedAccount else {
      throw SkinManagementError.noAccountSelected
    }

    let validToken = try await refreshTokenIfNeeded(account)
    let client = MinecraftAuthenticatedClient(bearerToken: validToken)

    try await client.equipCape(id: cape.id)

    // Refresh profile to get updated state
    await refreshAccountProfile(account)

    await MainActor.run {
      showSuccessAlert(message: Localized.Account.capeEquipped)
    }
  }

  // MARK: - Cape Hide

  /// Hide the currently active cape
  func hideCape() async throws {
    guard let account = selectedAccount else {
      throw SkinManagementError.noAccountSelected
    }

    let validToken = try await refreshTokenIfNeeded(account)
    let client = MinecraftAuthenticatedClient(bearerToken: validToken)

    try await client.disableCape()

    // Refresh profile to get updated state
    await refreshAccountProfile(account)

    await MainActor.run {
      showSuccessAlert(message: Localized.Account.capeHidden)
    }
  }

  // MARK: - Button Actions

  @objc func refreshCapesButtonClicked() {
    guard let account = selectedAccount else { return }

    Task {
      await refreshAccountProfile(account)
      await MainActor.run {
        showAccountDetails(account)
      }
    }
  }

  @objc func hideCapeButtonClicked() {
    showConfirmationAlert(
      title: Localized.Account.confirmHideCape,
      message: Localized.Account.confirmHideCapeMessage
    ) { [weak self] confirmed in
      guard confirmed, let self = self else { return }

      Task {
        do {
          try await self.hideCape()
          await MainActor.run {
            if let account = self.selectedAccount {
              self.showAccountDetails(account)
            }
          }
        } catch {
          await MainActor.run {
            self.showErrorAlert(error)
          }
        }
      }
    }
  }
}
