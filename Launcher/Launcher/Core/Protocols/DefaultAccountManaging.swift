//
//  DefaultAccountManaging.swift
//  Launcher
//
//  Default account management protocol for dependency injection
//

import Foundation

protocol DefaultAccountManaging: AnyObject {
  func setDefaultAccount(id: String, type: DefaultAccountType)
  func getDefaultAccountId() -> String?
  func getDefaultAccountType() -> DefaultAccountType?
  func clearDefaultAccount()
  func isDefaultAccount(id: String, type: DefaultAccountType) -> Bool
  func getDefaultAccountInfo() async -> (username: String, uuid: String, accessToken: String)?
}
