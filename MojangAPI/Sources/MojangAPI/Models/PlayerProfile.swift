import Foundation

/// Player Profile Information
public struct PlayerProfile: Codable {
    public let id: UUID
    public let name: String
    public let skins: [Skin]
    public let capes: [Cape]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case skins
        case capes
    }

    public init(id: UUID, name: String, skins: [Skin] = [], capes: [Cape] = []) {
        self.id = id
        self.name = name
        self.skins = skins
        self.capes = capes
    }
}

/// Player Skin
public struct Skin: Codable, Identifiable {
    public let id: String
    public let url: URL
    public let metadata: SkinMetadata?
    public let state: TextureState

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case metadata
        case state
    }

    public init(id: String, url: URL, metadata: SkinMetadata? = nil, state: TextureState = .active) {
        self.id = id
        self.url = url
        self.metadata = metadata
        self.state = state
    }
}

/// Skin Metadata
public struct SkinMetadata: Codable {
    public let model: SkinModel

    enum CodingKeys: String, CodingKey {
        case model
    }

    public init(model: SkinModel) {
        self.model = model
    }
}

/// Skin Model Type
public enum SkinModel: String, Codable {
    case steve = "default"
    case alex = "slim"
}

/// Player Cape
public struct Cape: Codable, Identifiable {
    public let id: String
    public let url: URL
    public let state: TextureState

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case state
    }

    public init(id: String, url: URL, state: TextureState = .active) {
        self.id = id
        self.url = url
        self.state = state
    }
}

/// Texture State
public enum TextureState: String, Codable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
}

/// Player UUID Response
public struct PlayerUUIDResponse: Codable {
    public let id: UUID
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

/// Player Name History Record
public struct NameHistory: Codable {
    public let name: String
    public let changedToAt: Date?

    enum CodingKeys: String, CodingKey {
        case name
        case changedToAt
    }

    public init(name: String, changedToAt: Date? = nil) {
        self.name = name
        self.changedToAt = changedToAt
    }
}
