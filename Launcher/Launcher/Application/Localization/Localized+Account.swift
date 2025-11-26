//
//  Localized+Account.swift
//  Launcher
//

import Foundation

// MARK: - Account-related Localizations
extension Localized {
  // MARK: - Account Management
  enum Account {
    // Window & Labels
    static let windowTitle = String(localized: "Account Management", comment: "[Text] Account management window title.")
    static let title = String(localized: "Account Management", comment: "[Text] Account management title.")
    static let subtitle = String(localized: "Manage offline mode usernames for quick launch", comment: "[Text] Account management subtitle.")
    static let openAccountButton = String(localized: "Account Management", comment: "[Button] Open account management window.")

    // Input
    static let usernamePlaceholder = String(localized: "Enter username (3-16 characters)", comment: "[Placeholder] Account username placeholder.")
    static let addButton = String(localized: "Add Account", comment: "[Button] Add account button.")

    // Empty State
    static let emptyMessage = String(localized: "No accounts saved yet", comment: "[Text] No accounts message.")

    // Context Menu
    static let menuDelete = String(localized: "Delete Account", comment: "[Menu] Delete account.")
    static let menuRefresh = String(localized: "Refresh Account", comment: "[Menu] Refresh account menu item.")

    // Buttons
    static let signInMicrosoftButton = String(localized: "Sign in with Microsoft", comment: "[Button] Sign in with Microsoft button.")
    static let addOfflineAccountButton = String(localized: "Add Offline Account", comment: "[Button] Add offline account button.")

    // Empty State
    static let emptyMicrosoftMessage = String(localized: "No Microsoft accounts\nClick the button above to sign in", comment: "[Text] Empty state message for Microsoft accounts.")
    static let emptyOfflineMessage = String(localized: "No offline accounts\nClick the button above to add an offline account", comment: "[Text] Empty state message for offline accounts.")

    // Offline Account
    static let offlineAccountTitle = String(localized: "Add Offline Account", comment: "[Alert] Add offline account title.")
    static let offlineAccountMessage = String(localized: "Enter a username for the offline account:", comment: "[Alert] Add offline account message.")
    static let offlineAccountPlaceholder = String(localized: "Username (3-16 characters)", comment: "[Placeholder] Offline account username placeholder.")
    static let offlineAccountAdded = String(localized: "Offline account added successfully", comment: "[Status] Offline account added.")
    static let offlineAccountType = String(localized: "Offline", comment: "[Label] Offline account type.")

    // Developer Mode
    static let developerModeLabel = String(localized: "Developer Mode", comment: "[Label] Developer mode toggle label.")

    // Refresh
    static let refreshSuccessTitle = String(localized: "Refresh Successful", comment: "[Alert] Refresh successful title.")

    static func refreshSuccessMessage(_ name: String) -> String {
      String(localized: "Account \(name) has been refreshed", comment: "[Alert] Account refresh success message.")
    }

    static let refreshFailedTitle = String(localized: "Refresh Failed", comment: "[Alert] Refresh failed title.")

    // Delete Account
    static func deleteAccountConfirmMessage(_ name: String) -> String {
      String(localized: "Are you sure you want to delete account \(name)?", comment: "[Alert] Delete account confirmation message.")
    }

    // Status Labels
    static func loginTime(_ time: String) -> String {
      String(localized: "Login Time: \(time)", comment: "[Label] Login timestamp label.")
    }

    static let statusExpired = String(localized: "⚠️ Expired", comment: "[Status] Token expired status.")

    static func statusValid(_ hours: Int) -> String {
      String(localized: "✓ Valid (\(hours) hours remaining)", comment: "[Status] Token valid status with hours remaining.")
    }

    static let statusLoggedIn = String(localized: "✓ Logged In", comment: "[Status] Logged in status.")

    // Delete Confirmation
    static let deleteConfirmTitle = String(localized: "Confirm Deletion", comment: "[Alert] Delete account confirmation title.")

    static func deleteConfirmMessage(_ username: String) -> String {
      String(localized: "Account \"\(username)\" will be permanently deleted. This action cannot be undone.", comment: "[Alert] Delete account confirmation message.")
    }

    static let deleteButton = String(localized: "Delete", comment: "[Button] Delete button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Validation Errors
    static let invalidUsernameTitle = String(localized: "Invalid Username", comment: "[Alert] Invalid username title.")
    static let emptyUsernameMessage = String(localized: "Username cannot be empty.", comment: "[Alert] Empty username error.")
    static let invalidUsernameLengthMessage = String(localized: "Username must be 3-16 characters long.", comment: "[Alert] Invalid username length error.")
    static let invalidUsernameFormatMessage = String(localized: "Username can only contain letters, numbers, and underscores.", comment: "[Alert] Invalid username format error.")
    static let duplicateUsernameTitle = String(localized: "Duplicate Username", comment: "[Alert] Duplicate username title.")
    static let duplicateUsernameMessage = String(localized: "This username already exists.", comment: "[Alert] Duplicate username error.")

    // Refresh Steps
    static func refreshingAccount(_ name: String) -> String {
      String(localized: "Refreshing account: \(name)", comment: "[Status] Refreshing account.")
    }

    static func loggingInAccount(_ name: String) -> String {
      String(localized: "Logging in: \(name)", comment: "[Status] Logging in account.")
    }

    static let refreshStepToken = String(localized: "Refreshing authorization token...", comment: "[Status] Refresh step: token.")
    static let loginStepToken = String(localized: "Obtaining authorization token...", comment: "[Status] Login step: token.")
    static let refreshStepXBL = String(localized: "Authenticating with Xbox Live...", comment: "[Status] Refresh step: XBL.")
    static let refreshStepXSTS = String(localized: "Obtaining XSTS token...", comment: "[Status] Refresh step: XSTS.")
    static let refreshStepMinecraft = String(localized: "Authenticating with Minecraft...", comment: "[Status] Refresh step: Minecraft.")
    static let refreshStepProfile = String(localized: "Fetching player profile...", comment: "[Status] Refresh step: profile.")
    static let refreshStepSaving = String(localized: "Saving account data...", comment: "[Status] Refresh step: saving.")
    static let refreshStepCompleted = String(localized: "✓ Account refreshed successfully!", comment: "[Status] Refresh completed.")

    static func refreshStepFailed(_ error: String) -> String {
      String(localized: "❌ Refresh failed: \(error)", comment: "[Status] Refresh failed.")
    }

    // Default Account
    static let menuSetDefault = String(localized: "Set as Default Account", comment: "[Menu] Set as default account.")
    static let menuClearDefault = String(localized: "Clear Default Account", comment: "[Menu] Clear default account.")
    static let defaultBadge = String(localized: "Default", comment: "[Badge] Default account badge.")
    static let defaultAccountSetTitle = String(localized: "Default Account Set", comment: "[Alert] Default account set title.")
    static let defaultAccountSetMessage = String(localized: "This account will be automatically used when launching games.", comment: "[Alert] Default account set message.")
    static let defaultAccountClearedTitle = String(localized: "Default Account Cleared", comment: "[Alert] Default account cleared title.")
    static let defaultAccountClearedMessage = String(localized: "You will be prompted to select an account when launching games.", comment: "[Alert] Default account cleared message.")
  }

  // MARK: - Microsoft Authentication
  enum MicrosoftAuth {
    // Window & Labels
    static let windowTitle = String(localized: "Microsoft Account Login", comment: "[Text] Microsoft auth window title.")
    static let title = String(localized: "Microsoft Account", comment: "[Text] Microsoft auth title.")
    static let subtitle = String(localized: "Sign in with your Microsoft account to access Minecraft. The authentication will be performed in your default browser for enhanced security.", comment: "[Text] Microsoft auth subtitle.")
    static let openMicrosoftAuthButton = String(localized: "Microsoft Login", comment: "[Button] Open Microsoft authentication window.")

    // Buttons
    static let loginButton = String(localized: "Sign In with Microsoft", comment: "[Button] Start Microsoft login.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel login.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Status Messages
    static let statusReady = String(localized: "Ready to sign in", comment: "[Status] Ready to sign in.")
    static let statusGeneratingURL = String(localized: "Generating secure login URL...", comment: "[Status] Generating login URL.")
    static let statusStartingServer = String(localized: "Starting local callback server...", comment: "[Status] Starting callback server.")
    static let statusOpeningBrowser = String(localized: "Opening browser for authentication...", comment: "[Status] Opening browser.")
    static let statusWaitingForAuth = String(localized: "Waiting for authentication in browser...\nPlease complete the sign-in process in your browser.", comment: "[Status] Waiting for authentication.")
    static let statusProcessingCallback = String(localized: "Processing authentication response...", comment: "[Status] Processing callback.")
    static let statusCompletingLogin = String(localized: "Completing Microsoft authentication...\nThis may take a few moments.", comment: "[Status] Completing login.")

    static func statusSuccess(_ username: String) -> String {
      String(localized: "Successfully signed in as \(username)!", comment: "[Status] Sign in successful.")
    }

    static func statusError(_ error: String) -> String {
      String(localized: "Error: \(error)", comment: "[Status] Error occurred.")
    }

    // Alerts
    static let alertLoginFailedTitle = String(localized: "Login Failed", comment: "[Alert] Login failed title.")

    static func alertLoginFailedMessage(_ error: String) -> String {
      String(localized: "Failed to sign in with Microsoft account:\n\(error)", comment: "[Alert] Login failed message.")
    }

    static let alertSuccessTitle = String(localized: "Login Successful", comment: "[Alert] Login successful title.")

    static func alertSuccessMessage(_ username: String, _ uuid: String) -> String {
      String(localized: "Successfully signed in!\n\nUsername: \(username)\nUUID: \(uuid)\n\nYour account has been saved and you can now launch Minecraft.", comment: "[Alert] Login successful message.")
    }

    // Instructions
    static let instructionsTitle = String(localized: "How it works:", comment: "[Text] Instructions title.")
    static let instructionStep1 = String(localized: "1. Click \"Sign In with Microsoft\" button", comment: "[Text] Instruction step 1.")
    static let instructionStep2 = String(localized: "2. Your default browser will open Microsoft login page", comment: "[Text] Instruction step 2.")
    static let instructionStep3 = String(localized: "3. Sign in with your Microsoft account", comment: "[Text] Instruction step 3.")
    static let instructionStep4 = String(localized: "4. Grant permission to access Minecraft", comment: "[Text] Instruction step 4.")
    static let instructionStep5 = String(localized: "5. Return to this window after authorization completes", comment: "[Text] Instruction step 5.")

    // Security Notes
    static let securityNote = String(localized: "Your password is never shared with this application. Authentication is handled securely by Microsoft.", comment: "[Text] Security note.")
  }
}
