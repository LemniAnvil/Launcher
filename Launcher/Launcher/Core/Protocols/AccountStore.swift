//
//  AccountStore.swift
//  Launcher
//
//  Account storage protocols for dependency injection
//

import Foundation

// MARK: - Microsoft Account Storage

protocol MicrosoftAccountStoring: AnyObject {
  func loadAccounts() -> [MicrosoftAccount]
  func saveAccount(_ account: MicrosoftAccount)
  func updateAccount(id: String, accessToken: String)
  func updateAccountFromRefresh(
    id: String,
    name: String,
    accessToken: String,
    refreshToken: String,
    skins: [SkinResponse]?,
    capes: [Cape]?
  )
  func deleteAccount(id: String)
  func getAccount(id: String) -> MicrosoftAccount?
}

// MARK: - Offline Account Storage

protocol OfflineAccountStoring: AnyObject {
  func loadAccounts() -> [OfflineAccount]
  func saveAccount(_ account: OfflineAccount)
  func deleteAccount(id: String)
  func getAccount(id: String) -> OfflineAccount?
  func generateOfflineUUID(for username: String) -> String
}
