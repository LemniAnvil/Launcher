import Foundation

// MARK: - Microsoft Authentication

/// Microsoft OAuth Token Response
public struct MicrosoftTokenResponse: Codable {
    public let tokenType: String
    public let expiresIn: Int
    public let scope: String
    public let accessToken: String
    public let refreshToken: String?
    public let extExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case extExpiresIn = "ext_expires_in"
    }

    public init(
        tokenType: String,
        expiresIn: Int,
        scope: String,
        accessToken: String,
        refreshToken: String? = nil,
        extExpiresIn: Int? = nil
    ) {
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.extExpiresIn = extExpiresIn
    }
}

// MARK: - Xbox Live Authentication

/// Xbox Live Authentication Request
public struct XBLAuthRequest: Codable {
    public let properties: XBLProperties
    public let relyingParty: String
    public let tokenType: String

    enum CodingKeys: String, CodingKey {
        case properties
        case relyingParty
        case tokenType
    }

    public init(accessToken: String) {
        self.properties = XBLProperties(authMethod: "RPS", siteName: "user.auth.xboxlive.com", rpsTicket: "d=\(accessToken)")
        self.relyingParty = "http://auth.xboxlive.com"
        self.tokenType = "JWT"
    }
}

/// Xbox Live Properties
public struct XBLProperties: Codable {
    public let authMethod: String
    public let siteName: String
    public let rpsTicket: String

    enum CodingKeys: String, CodingKey {
        case authMethod
        case siteName
        case rpsTicket
    }

    public init(authMethod: String, siteName: String, rpsTicket: String) {
        self.authMethod = authMethod
        self.siteName = siteName
        self.rpsTicket = rpsTicket
    }
}

/// Xbox Live Authentication Response
public struct XBLAuthResponse: Codable {
    public let issueInstant: String
    public let notAfter: String
    public let token: String
    public let displayClaims: DisplayClaims

    enum CodingKeys: String, CodingKey {
        case issueInstant
        case notAfter
        case token
        case displayClaims
    }

    public init(issueInstant: String, notAfter: String, token: String, displayClaims: DisplayClaims) {
        self.issueInstant = issueInstant
        self.notAfter = notAfter
        self.token = token
        self.displayClaims = displayClaims
    }
}

/// Display Claims
public struct DisplayClaims: Codable {
    public let xui: [XUIElement]

    enum CodingKeys: String, CodingKey {
        case xui
    }

    public init(xui: [XUIElement]) {
        self.xui = xui
    }
}

/// XUI Element
public struct XUIElement: Codable {
    public let uhs: String

    enum CodingKeys: String, CodingKey {
        case uhs
    }

    public init(uhs: String) {
        self.uhs = uhs
    }
}

// MARK: - XSTS Authentication

/// XSTS Authentication Request
public struct XSTSAuthRequest: Codable {
    public let properties: XSTSProperties
    public let relyingParty: String
    public let tokenType: String

    enum CodingKeys: String, CodingKey {
        case properties
        case relyingParty
        case tokenType
    }

    public init(xblToken: String) {
        self.properties = XSTSProperties(sandboxId: "RETAIL", userTokens: [xblToken])
        self.relyingParty = "rp://api.minecraftservices.com/"
        self.tokenType = "JWT"
    }
}

/// XSTS Properties
public struct XSTSProperties: Codable {
    public let sandboxId: String
    public let userTokens: [String]

    enum CodingKeys: String, CodingKey {
        case sandboxId
        case userTokens
    }

    public init(sandboxId: String, userTokens: [String]) {
        self.sandboxId = sandboxId
        self.userTokens = userTokens
    }
}

/// XSTS Authentication Response
public typealias XSTSAuthResponse = XBLAuthResponse

// MARK: - Minecraft Authentication

/// Minecraft Service Authentication Request
public struct MinecraftAuthRequest: Codable {
    public let identityToken: String

    enum CodingKeys: String, CodingKey {
        case identityToken
    }

    public init(identityToken: String) {
        self.identityToken = identityToken
    }
}

/// Minecraft Service Authentication Response
public struct MinecraftAuthResponse: Codable {
    public let username: String
    public let roles: [String]?
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case username
        case roles
        case accessToken
        case tokenType
        case expiresIn
    }

    public init(
        username: String,
        roles: [String]? = nil,
        accessToken: String,
        tokenType: String,
        expiresIn: Int
    ) {
        self.username = username
        self.roles = roles
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
    }
}

// MARK: - Mojang Authentication (Legacy)

/// Mojang Authentication Request
public struct MojangAuthRequest: Codable {
    public let username: String
    public let password: String
    public let clientToken: String
    public let requestUser: Bool

    enum CodingKeys: String, CodingKey {
        case username
        case password
        case clientToken
        case requestUser
    }

    public init(username: String, password: String, clientToken: String, requestUser: Bool = true) {
        self.username = username
        self.password = password
        self.clientToken = clientToken
        self.requestUser = requestUser
    }
}

/// Mojang Authentication Response
public struct MojangAuthResponse: Codable {
    public let accessToken: String
    public let clientToken: String
    public let availableProfiles: [GameProfile]
    public let selectedProfile: GameProfile
    public let user: UserInfo?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case clientToken
        case availableProfiles
        case selectedProfile
        case user
    }

    public init(
        accessToken: String,
        clientToken: String,
        availableProfiles: [GameProfile],
        selectedProfile: GameProfile,
        user: UserInfo? = nil
    ) {
        self.accessToken = accessToken
        self.clientToken = clientToken
        self.availableProfiles = availableProfiles
        self.selectedProfile = selectedProfile
        self.user = user
    }
}

/// Game Profile
public struct GameProfile: Codable {
    public let id: String
    public let name: String
    public let legacy: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case legacy
    }

    public init(id: String, name: String, legacy: Bool? = nil) {
        self.id = id
        self.name = name
        self.legacy = legacy
    }
}

/// User Information
public struct UserInfo: Codable {
    public let id: String
    public let properties: [UserProperty]?

    enum CodingKeys: String, CodingKey {
        case id
        case properties
    }

    public init(id: String, properties: [UserProperty]? = nil) {
        self.id = id
        self.properties = properties
    }
}

/// User Properties
public struct UserProperty: Codable {
    public let name: String
    public let value: String

    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
