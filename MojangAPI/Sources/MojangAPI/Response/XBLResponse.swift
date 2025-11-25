//
//  XBLResponse.swift
//  MojangAPI
//

public struct XBLResponse: Codable {
  public let issueInstant: String
  public let notAfter: String
  public let token: String
  public let displayClaims: DisplayClaims

  public struct DisplayClaims: Codable {
    public let xui: [UserInfo]
  }

  public struct UserInfo: Codable {
    public let uhs: String
  }

  public enum CodingKeys: String, CodingKey {
    case issueInstant = "IssueInstant"
    case notAfter = "NotAfter"
    case token = "Token"
    case displayClaims = "DisplayClaims"
  }
}
