import Foundation

/// Player Information Service
public class PlayerService {
    private let client: MojangAPIClientProtocol

    public init(client: MojangAPIClientProtocol = MojangAPIClient()) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Get Player UUID by Username
    /// - Parameter name: Player Username
    /// - Returns: Player UUID and Name
    public func getPlayerUUID(name: String) async throws -> PlayerUUIDResponse {
        try await client.request(.getPlayerUUID(name: name))
    }

    /// Get Player Profile by UUID
    /// - Parameter uuid: Player UUID
    /// - Returns: Player Profile Information
    public func getPlayerProfile(uuid: UUID) async throws -> PlayerProfile {
        let response: SessionProfile = try await client.request(.getSessionProfile(uuid: uuid))
        return try parseSessionProfile(response)
    }

    /// Get Player Name History
    /// - Parameter uuid: Player UUID
    /// - Returns: Array of Name History Records
    public func getNameHistory(uuid: UUID) async throws -> [NameHistory] {
        try await client.request(.getNameHistory(uuid: uuid))
    }

    /// Get Player Session Profile (includes Texture Information)
    /// - Parameter uuid: Player UUID
    /// - Returns: Session Profile
    public func getSessionProfile(uuid: UUID) async throws -> SessionProfile {
        try await client.request(.getSessionProfile(uuid: uuid))
    }

    // MARK: - Private Methods

    private func parseSessionProfile(_ response: SessionProfile) throws -> PlayerProfile {
        var skins: [Skin] = []
        var capes: [Cape] = []

        for property in response.properties {
            if property.name == "textures" {
                let texturesData = try decodeTexturesProperty(property.value)
                if let skinInfo = texturesData.textures.skin {
                    let skin = Skin(
                        id: UUID().uuidString,
                        url: skinInfo.url,
                        metadata: SkinMetadata(model: skinInfo.metadata?.model == "slim" ? .alex : .steve),
                        state: .active
                    )
                    skins.append(skin)
                }
                if let capeInfo = texturesData.textures.cape {
                    let cape = Cape(
                        id: UUID().uuidString,
                        url: capeInfo.url,
                        state: .active
                    )
                    capes.append(cape)
                }
            }
        }

        return PlayerProfile(
            id: UUID(uuidString: response.id) ?? UUID(),
            name: response.name,
            skins: skins,
            capes: capes
        )
    }

    private func decodeTexturesProperty(_ base64String: String) throws -> TexturesProperty {
        guard let data = Data(base64Encoded: base64String) else {
            throw MojangAPIError.decodingError(
                DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Invalid Base64 Encoding"
                    )
                )
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(TexturesProperty.self, from: data)
    }
}

// MARK: - JSONDecoder Extension

extension JSONDecoder {
    static let mojangDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
}
