import Foundation

/// Main Entry Point of Mojang API Library
public class MojangAPI {
    public let playerService: PlayerService
    public let authenticationService: AuthenticationService
    public let client: MojangAPIClientProtocol

    public init(client: MojangAPIClientProtocol = MojangAPIClient()) {
        self.client = client
        self.playerService = PlayerService(client: client)
        self.authenticationService = AuthenticationService(client: client)
    }
}
