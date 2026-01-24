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
    static let menuShowInFinder = String(localized: "Show in Finder", comment: "[Menu] Show skin in Finder.")

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

    // Account Info Window
    static let accountInfoWindowTitle = String(localized: "Account Info", comment: "[Text] Account info window title.")
    static let accountInfoSubtitle = String(localized: "Microsoft Account Details", comment: "[Text] Account info subtitle.")
    static let openAccountInfoButton = String(localized: "View Account Info", comment: "[Button] Open account info window.")
    static let noMicrosoftAccounts = String(localized: "No Microsoft Accounts", comment: "[Text] No Microsoft accounts message.")
    static let accountDetails = String(localized: "Account Details", comment: "[Text] Account details label.")
    static let selectAccountPrompt = String(localized: "Select an account from the left to view details", comment: "[Text] Select account prompt.")
    static let playerName = String(localized: "Player Name", comment: "[Label] Player name.")
    static let playerUUID = String(localized: "UUID", comment: "[Label] Player UUID.")
    static let shortUUID = String(localized: "Short UUID", comment: "[Label] Short UUID.")
    static let loginTimestamp = String(localized: "Login Time", comment: "[Label] Login timestamp.")
    static let tokenExpiration = String(localized: "Token Expiration", comment: "[Label] Token expiration.")
    static let accessTokenStatus = String(localized: "Access Token Status", comment: "[Label] Access token status.")
    static let refreshTokenStatus = String(localized: "Refresh Token Status", comment: "[Label] Refresh token status.")
    static let skinsCount = String(localized: "Skins Count", comment: "[Label] Skins count.")
    static let capesCount = String(localized: "Capes Count", comment: "[Label] Capes count.")
    static let activeSkin = String(localized: "Active Skin", comment: "[Label] Active skin.")
    static let activeCape = String(localized: "Active Cape", comment: "[Label] Active cape.")
    static let tokenValid = String(localized: "Valid", comment: "[Status] Token valid.")
    static let tokenExpired = String(localized: "Expired", comment: "[Status] Token expired.")
    static let noActiveSkin = String(localized: "Default Skin", comment: "[Text] No active skin.")
    static let noActiveCape = String(localized: "No Cape", comment: "[Text] No active cape.")

    // Skin and Cape Details
    static let allSkinsTitle = String(localized: "All Skins", comment: "[Label] All skins title.")
    static let allCapesTitle = String(localized: "All Capes", comment: "[Label] All capes title.")
    static let skinVariant = String(localized: "Variant", comment: "[Label] Skin variant.")
    static let skinState = String(localized: "State", comment: "[Label] Skin state.")
    static let skinAlias = String(localized: "Alias", comment: "[Label] Skin alias.")
    static let skinID = String(localized: "ID", comment: "[Label] Skin ID.")
    static let skinURL = String(localized: "URL", comment: "[Label] Skin URL.")
    static let capeAlias = String(localized: "Cape Name", comment: "[Label] Cape alias.")
    static let capeID = String(localized: "ID", comment: "[Label] Cape ID.")
    static let capeURL = String(localized: "URL", comment: "[Label] Cape URL.")
    static let capeState = String(localized: "State", comment: "[Label] Cape state.")
    static let stateActive = String(localized: "✓ Active", comment: "[Status] Active state.")
    static let stateInactive = String(localized: "Inactive", comment: "[Status] Inactive state.")
    static let noSkins = String(localized: "No Skins", comment: "[Text] No skins.")
    static let noCapes = String(localized: "No Capes", comment: "[Text] No capes.")
    static let unnamedSkin = String(localized: "Unnamed Skin", comment: "[Text] Unnamed skin fallback.")
    static let unnamedCape = String(localized: "Unnamed Cape", comment: "[Text] Unnamed cape fallback.")

    // Tab Labels
    static let accountInfoTab = String(localized: "Account Info", comment: "[Tab] Account info tab")
    static let skinManagementTab = String(localized: "Skin Management", comment: "[Tab] Skin management tab")

    // Skin Management Buttons
    static let uploadToAccount = String(localized: "Upload to Account", comment: "[Button] Upload skin to account")
    static let activateSkin = String(localized: "Activate", comment: "[Button] Activate skin")
    static let downloadSkin = String(localized: "Download", comment: "[Button] Download skin to local")
    static let resetSkin = String(localized: "Reset to Default", comment: "[Button] Reset skin")
    static let importFromFile = String(localized: "Import from File", comment: "[Button] Import skin from file")
    static let refreshSkins = String(localized: "Refresh", comment: "[Button] Refresh skin list")
    static let openSkinsFolder = String(localized: "Open Folder", comment: "[Button] Open skins folder")
    static let searchLocalSkinsPlaceholder = String(localized: "Search local skins", comment: "[Search] Local skins placeholder.")
    static let searchOnlineSkinsPlaceholder = String(localized: "Search online skins", comment: "[Search] Online skins placeholder.")
    static let searchModeLocal = String(localized: "Local", comment: "[Search] Local search mode.")
    static let searchModeOnline = String(localized: "Online", comment: "[Search] Online search mode.")
    static let searchSkinsButton = String(localized: "Search", comment: "[Button] Search skins.")
    static let searchNoResults = String(localized: "No results", comment: "[Search] No search results.")
    static let searchOnlineHint = String(localized: "Online search", comment: "[Search] Online search hint.")
    static let searchOnlineSearching = String(localized: "Searching online...", comment: "[Search] Online search in progress.")

    // Skin Library
    static let noLocalSkins = String(localized: "No local skins found", comment: "[Text] No local skins")
    static let skinCount = String(localized: "%d local skins", comment: "[Text] Count of local skins")
    static let skinSearchCount = String(localized: "%d of %d skins", comment: "[Text] Filtered skin count")

    // Progress Messages
    static let uploadingSkin = String(localized: "Uploading skin...", comment: "[Progress] Uploading skin")
    static let activatingSkin = String(localized: "Activating skin...", comment: "[Progress] Activating skin")
    static let downloadingSkin = String(localized: "Downloading skin...", comment: "[Progress] Downloading skin")
    static let resettingSkin = String(localized: "Resetting skin...", comment: "[Progress] Resetting skin")

    // Success Messages
    static let skinUploadSuccess = String(localized: "Skin uploaded successfully!", comment: "[Success] Skin upload success")
    static let skinActivated = String(localized: "Skin activated successfully!", comment: "[Success] Skin activated")
    static let skinDownloadSuccess = String(localized: "Skin downloaded to library!", comment: "[Success] Skin download success")
    static let skinReset = String(localized: "Skin reset to default!", comment: "[Success] Skin reset")

    // Confirmation Dialogs
    static let confirmResetSkin = String(localized: "Reset Skin?", comment: "[Alert] Confirm reset skin title")
    static let confirmResetSkinMessage = String(localized: "This will remove your custom skin and restore the default skin.", comment: "[Alert] Confirm reset skin message")

    // Error Messages
    static let errorNoAccountSelected = String(localized: "No account selected", comment: "[Error] No account selected")
    static let errorInvalidURL = String(localized: "Invalid skin URL", comment: "[Error] Invalid URL")
    static let errorFileTooLarge = String(localized: "File size is %d KB, maximum is 24 KB", comment: "[Error] File too large")
    static let errorInvalidFormat = String(localized: "Invalid file format. Must be PNG.", comment: "[Error] Invalid format")
    static let errorInvalidDimensions = String(localized: "Invalid dimensions %dx%d. Must be 64x32 or 64x64.", comment: "[Error] Invalid dimensions")
    static let errorTokenExpired = String(localized: "Access token expired", comment: "[Error] Token expired")

    // Suggestions
    static let suggestionCompressSkin = String(localized: "Try compressing the PNG file or use a smaller image.", comment: "[Suggestion] Compress skin")
    static let suggestionResizeSkin = String(localized: "Resize the image to 64x32 or 64x64 pixels.", comment: "[Suggestion] Resize skin")
    static let suggestionRefreshAccount = String(localized: "Try refreshing the account or logging in again.", comment: "[Suggestion] Refresh account")

    // Variant Selection
    static let selectSkinVariant = String(localized: "Select Skin Model", comment: "[Dialog] Select skin variant")
    static let classicVariant = String(localized: "Classic (Steve)", comment: "[Variant] Classic Steve model")
    static let slimVariant = String(localized: "Slim (Alex)", comment: "[Variant] Slim Alex model")
    static let selectSkinFile = String(localized: "Select a skin file", comment: "[Dialog] Select skin file")

    // Common
    static let success = String(localized: "Success", comment: "[Alert] Success title")
    static let error = String(localized: "Error", comment: "[Alert] Error title")

    // Cape Management
    static let equipCape = String(localized: "Equip", comment: "[Button] Equip cape")
    static let hideCape = String(localized: "Hide Cape", comment: "[Button] Hide cape")
    static let refreshCapes = String(localized: "Refresh", comment: "[Button] Refresh cape list")
    static let capeEquipped = String(localized: "Cape equipped successfully!", comment: "[Success] Cape equipped")
    static let capeHidden = String(localized: "Cape hidden successfully!", comment: "[Success] Cape hidden")
    static let confirmHideCape = String(localized: "Hide Cape?", comment: "[Alert] Confirm hide cape title")
    static let confirmHideCapeMessage = String(localized: "This will hide your cape. You can equip it again anytime.", comment: "[Alert] Confirm hide cape message")
    static let capeCount = String(localized: "%d capes available", comment: "[Text] Count of capes")
    static let noCapeInfo = String(localized: "Capes are obtained through Minecraft events, Minecon, or account migration rewards.", comment: "[Text] Info about how to get capes")
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
