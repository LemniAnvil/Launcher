//
//  PKCEHelperTests.swift
//  MojangAPITests
//

import CryptoKit
import XCTest

@testable import MojangAPI

final class PKCEHelperTests: XCTestCase {

  // MARK: - Code Verifier Tests

  func testGenerateCodeVerifier() {
    let verifier = PKCEHelper.generateCodeVerifier()

    // Should not be empty
    XCTAssertFalse(verifier.isEmpty, "Code verifier should not be empty")

    // Should be within valid length range (43-128 characters per RFC 7636)
    XCTAssertGreaterThanOrEqual(verifier.count, 43, "Code verifier should be at least 43 characters")
    XCTAssertLessThanOrEqual(verifier.count, 128, "Code verifier should be at most 128 characters")

    // Should be URL-safe (no +, /, =)
    XCTAssertFalse(verifier.contains("+"), "Code verifier should not contain +")
    XCTAssertFalse(verifier.contains("/"), "Code verifier should not contain /")
    XCTAssertFalse(verifier.contains("="), "Code verifier should not contain =")
  }

  func testGenerateCodeVerifierUniqueness() {
    let verifier1 = PKCEHelper.generateCodeVerifier()
    let verifier2 = PKCEHelper.generateCodeVerifier()

    // Each call should generate a unique verifier
    XCTAssertNotEqual(verifier1, verifier2, "Each call should generate a unique code verifier")
  }

  func testGenerateCodeVerifierConsistentLength() {
    // Generate multiple verifiers and check they're all valid length
    for _ in 0..<10 {
      let verifier = PKCEHelper.generateCodeVerifier()
      XCTAssertGreaterThanOrEqual(verifier.count, 43)
      XCTAssertLessThanOrEqual(verifier.count, 128)
    }
  }

  // MARK: - Code Challenge Tests

  func testGenerateCodeChallenge() {
    let verifier = "test_verifier_123"
    let challenge = PKCEHelper.generateCodeChallenge(from: verifier)

    // Should not be empty
    XCTAssertFalse(challenge.isEmpty, "Code challenge should not be empty")

    // Should be URL-safe
    XCTAssertFalse(challenge.contains("+"), "Code challenge should not contain +")
    XCTAssertFalse(challenge.contains("/"), "Code challenge should not contain /")
    XCTAssertFalse(challenge.contains("="), "Code challenge should not contain =")
  }

  func testGenerateCodeChallengeDeterministic() {
    let verifier = "test_verifier_123"
    let challenge1 = PKCEHelper.generateCodeChallenge(from: verifier)
    let challenge2 = PKCEHelper.generateCodeChallenge(from: verifier)

    // Same verifier should produce same challenge
    XCTAssertEqual(challenge1, challenge2, "Same verifier should produce same challenge")
  }

  func testGenerateCodeChallengeDifferentVerifiers() {
    let verifier1 = "test_verifier_1"
    let verifier2 = "test_verifier_2"
    let challenge1 = PKCEHelper.generateCodeChallenge(from: verifier1)
    let challenge2 = PKCEHelper.generateCodeChallenge(from: verifier2)

    // Different verifiers should produce different challenges
    XCTAssertNotEqual(
      challenge1, challenge2, "Different verifiers should produce different challenges")
  }

  func testGenerateCodeChallengeCorrectSHA256() {
    let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    let challenge = PKCEHelper.generateCodeChallenge(from: verifier)

    // Manually compute expected SHA256 hash
    let data = Data(verifier.utf8)
    let hash = SHA256.hash(data: data)
    let expected = Data(hash).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")

    // Should match
    XCTAssertEqual(challenge, expected, "Challenge should be correctly computed SHA256 hash")
  }

  // MARK: - Code Pair Tests

  func testGenerateCodePair() {
    let codePair = PKCEHelper.generateCodePair()

    // Verifier should be valid
    XCTAssertFalse(codePair.verifier.isEmpty)
    XCTAssertGreaterThanOrEqual(codePair.verifier.count, 43)
    XCTAssertLessThanOrEqual(codePair.verifier.count, 128)

    // Challenge should be valid
    XCTAssertFalse(codePair.challenge.isEmpty)

    // Challenge should be derived from verifier
    let expectedChallenge = PKCEHelper.generateCodeChallenge(from: codePair.verifier)
    XCTAssertEqual(codePair.challenge, expectedChallenge, "Challenge should be derived from verifier")
  }

  func testGenerateCodePairUniqueness() {
    let codePair1 = PKCEHelper.generateCodePair()
    let codePair2 = PKCEHelper.generateCodePair()

    // Each call should generate unique pairs
    XCTAssertNotEqual(codePair1.verifier, codePair2.verifier)
    XCTAssertNotEqual(codePair1.challenge, codePair2.challenge)
  }

  // MARK: - State Tests

  func testGenerateState() {
    let state = PKCEHelper.generateState()

    // Should not be empty
    XCTAssertFalse(state.isEmpty, "State should not be empty")

    // Should be URL-safe
    XCTAssertFalse(state.contains("+"), "State should not contain +")
    XCTAssertFalse(state.contains("/"), "State should not contain /")
    XCTAssertFalse(state.contains("="), "State should not contain =")
  }

  func testGenerateStateUniqueness() {
    let state1 = PKCEHelper.generateState()
    let state2 = PKCEHelper.generateState()

    // Each call should generate a unique state
    XCTAssertNotEqual(state1, state2, "Each call should generate a unique state")
  }

  func testGenerateStateRandomness() {
    // Generate multiple states and ensure they're all unique
    var states = Set<String>()
    for _ in 0..<100 {
      let state = PKCEHelper.generateState()
      states.insert(state)
    }

    // All should be unique
    XCTAssertEqual(states.count, 100, "All generated states should be unique")
  }

  // MARK: - RFC 7636 Compliance Tests

  func testRFC7636Example() {
    // Example from RFC 7636 Appendix B
    // Note: We can't test the exact example since it uses a specific random value,
    // but we can test the transformation works correctly

    let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    let challenge = PKCEHelper.generateCodeChallenge(from: verifier)

    // The expected challenge from RFC 7636
    let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

    XCTAssertEqual(challenge, expectedChallenge, "Should match RFC 7636 example")
  }

  func testCodeVerifierCharacterSet() {
    // RFC 7636 requires verifier to use [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
    let verifier = PKCEHelper.generateCodeVerifier()
    let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    for character in verifier {
      XCTAssertTrue(
        character.unicodeScalars.allSatisfy { allowedCharacters.contains($0) },
        "Verifier should only contain allowed characters"
      )
    }
  }

  // MARK: - Integration Tests

  func testCodePairCanBeUsedInOAuthFlow() {
    // Simulate OAuth flow
    let codePair = PKCEHelper.generateCodePair()

    // In a real OAuth flow, the challenge would be sent to the authorization server
    // and the verifier would be kept secret and sent later

    // Verify that we can reconstruct the challenge from the verifier
    let reconstructedChallenge = PKCEHelper.generateCodeChallenge(from: codePair.verifier)
    XCTAssertEqual(codePair.challenge, reconstructedChallenge, "Challenge should be reproducible from verifier")
  }
}
