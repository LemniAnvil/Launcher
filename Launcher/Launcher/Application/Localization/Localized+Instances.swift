//
//  Localized+Instances.swift
//  Launcher
//

import Foundation

// MARK: - Instance-related Localizations
extension Localized {
  // MARK: - Instances
  enum Instances {
    // Window & Labels
    static let windowTitle = String(localized: "Instances", comment: "[Text] Instances window title.")
    static let title = String(localized: "Instances", comment: "[Text] Instances title.")
    static let refreshButton = String(localized: "Refresh", comment: "[Button] Refresh instances list.")
    static let emptyMessage = String(localized: "No instances", comment: "[Text] No instances message.")
    static let createInstanceButton = String(localized: "Create Instance", comment: "[Button] Create instance button.")

    // Count Labels
    static let countNone = String(localized: "No instances yet", comment: "[Text] No instances.")
    static let countOne = String(localized: "1 instance", comment: "[Text] One instance.")

    static func countMultiple(_ count: Int) -> String {
      String(localized: "\(count) instances", comment: "[Text] Multiple instances count.")
    }

    // Create Instance Dialog
    static let createInstanceTitle = String(localized: "Create Instance", comment: "[Text] Create instance dialog title.")
    static let instanceNameLabel = String(localized: "Instance Name:", comment: "[Label] Instance name label.")
    static let instanceNamePlaceholder = String(localized: "Enter instance name", comment: "[Placeholder] Instance name placeholder.")
    static let versionLabel = String(localized: "Version:", comment: "[Label] Version label.")
    static let noVersionsInstalled = String(localized: "No versions installed", comment: "[Text] No versions installed.")
    static let createButton = String(localized: "Create", comment: "[Button] Create button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Context Menu
    static let menuShowInFinder = String(localized: "Show in Finder", comment: "[Menu] Show instance in Finder.")
    static let menuLaunchGame = String(localized: "Launch Game", comment: "[Menu] Launch game.")
    static let menuDelete = String(localized: "Delete Instance", comment: "[Menu] Delete instance.")

    // Delete Confirmation
    static let deleteConfirmTitle = String(localized: "Confirm Deletion", comment: "[Alert] Delete confirmation title.")

    static func deleteConfirmMessage(_ name: String) -> String {
      String(localized: "Instance \"\(name)\" will be permanently deleted. This action cannot be undone.", comment: "[Alert] Delete confirmation message.")
    }

    static let deleteButton = String(localized: "Delete", comment: "[Button] Delete button.")

    // Notifications
    static let deleteSuccessTitle = String(localized: "Deletion Successful", comment: "[Notification] Delete success title.")

    static func deleteSuccessMessage(_ name: String) -> String {
      String(localized: "Instance \"\(name)\" has been deleted", comment: "[Notification] Delete success message.")
    }

    static let deleteFailedTitle = String(localized: "Deletion Failed", comment: "[Alert] Delete failed title.")

    static func deleteFailedMessage(_ name: String, _ error: String) -> String {
      String(localized: "Unable to delete instance \"\(name)\": \(error)", comment: "[Alert] Delete failed message.")
    }

    // Errors
    static let errorTitle = String(localized: "Error", comment: "[Alert] Error title.")
    static let errorEmptyName = String(localized: "Instance name cannot be empty.", comment: "[Error] Empty name error.")
    static let errorNoVersionSelected = String(localized: "Please select a version.", comment: "[Error] No version selected error.")

    static func errorInvalidName(_ reason: String) -> String {
      String(localized: "Invalid instance name: \(reason)", comment: "[Error] Invalid name error.")
    }

    static func errorDuplicateName(_ name: String) -> String {
      String(localized: "An instance with name \"\(name)\" already exists.", comment: "[Error] Duplicate name error.")
    }

    static func errorVersionNotInstalled(_ versionId: String) -> String {
      String(localized: "Version \(versionId) is not installed.", comment: "[Error] Version not installed error.")
    }

    static func errorVersionNotFound(_ versionId: String) -> String {
      String(localized: "Version \(versionId) not found in version manifest.", comment: "[Error] Version not found in manifest error.")
    }

    static func errorInstanceNotFound(_ id: String) -> String {
      String(localized: "Instance not found: \(id)", comment: "[Error] Instance not found error.")
    }

    static func errorSaveFailed(_ reason: String) -> String {
      String(localized: "Failed to save instance: \(reason)", comment: "[Error] Save failed error.")
    }

    // Cell Display
    static func versionInfo(_ versionId: String) -> String {
      String(localized: "Version: \(versionId)", comment: "[Text] Instance version label.")
    }
  }

  // MARK: - Instance Detail
  enum InstanceDetail {
    // Window & Labels
    static let windowTitle = String(localized: "Instance Details", comment: "[Text] Instance detail window title.")
    static let configurationTitle = String(localized: "Configuration", comment: "[Text] Configuration section title.")

    static let nameLabel = String(localized: "Name:", comment: "[Label] Instance name label.")
    static let versionLabel = String(localized: "Version:", comment: "[Label] Version label.")
    static let idLabel = String(localized: "ID:", comment: "[Label] Instance ID label.")
    static let createdLabel = String(localized: "Created:", comment: "[Label] Created date label.")
    static let modifiedLabel = String(localized: "Modified:", comment: "[Label] Last modified date label.")

    static func versionInfo(_ version: String) -> String {
      String(localized: "Minecraft \(version)", comment: "[Text] Version info format.")
    }

    // Buttons
    static let editButton = String(localized: "Edit", comment: "[Button] Edit instance button.")
    static let saveButton = String(localized: "Save", comment: "[Button] Save changes button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel edit button.")
    static let openFolderButton = String(localized: "Open Folder", comment: "[Button] Open instance folder button.")
    static let closeButton = String(localized: "Close", comment: "[Button] Close button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Errors
    static let errorTitle = String(localized: "Error", comment: "[Alert] Error title.")
    static let errorEmptyName = String(localized: "Instance name cannot be empty.", comment: "[Error] Empty name error.")

    // Not Implemented
    static let notImplementedTitle = String(localized: "Feature Not Yet Implemented", comment: "[Alert] Not implemented title.")
    static let notImplementedMessage = String(localized: "Instance editing will be available in a future update.", comment: "[Alert] Not implemented message.")
  }

  // MARK: - Installed Versions
  enum InstalledVersions {
    // Window & Labels
    static let windowTitle = String(localized: "Installed Versions", comment: "[Text] Installed versions window title.")
    static let title = String(localized: "Installed Versions", comment: "[Text] Installed versions title.")
    static let refreshButton = String(localized: "Refresh", comment: "[Button] Refresh versions list.")
    static let emptyMessage = String(localized: "No installed versions", comment: "[Text] No installed versions message.")

    // Count Labels
    static let countNone = String(localized: "No versions installed yet", comment: "[Text] No versions installed.")
    static let countOne = String(localized: "1 installed version", comment: "[Text] One installed version.")

    static func countMultiple(_ count: Int) -> String {
      String(localized: "\(count) installed versions", comment: "[Text] Multiple installed versions count.")
    }

    // Context Menu
    static let menuShowInFinder = String(localized: "Show in Finder", comment: "[Menu] Show version in Finder.")
    static let menuLaunchGame = String(localized: "Launch Game", comment: "[Menu] Launch game.")
    static let menuDelete = String(localized: "Delete Version", comment: "[Menu] Delete version.")

    // Delete Confirmation
    static let deleteConfirmTitle = String(localized: "Confirm Deletion", comment: "[Alert] Delete confirmation title.")

    static func deleteConfirmMessage(_ version: String) -> String {
      String(localized: "Version \(version) will be permanently deleted. This action cannot be undone.", comment: "[Alert] Delete confirmation message.")
    }

    static let deleteButton = String(localized: "Delete", comment: "[Button] Delete button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Notifications
    static let deleteSuccessTitle = String(localized: "Deletion Successful", comment: "[Notification] Delete success title.")

    static func deleteSuccessMessage(_ version: String) -> String {
      String(localized: "Version \(version) has been deleted", comment: "[Notification] Delete success message.")
    }

    static let deleteFailedTitle = String(localized: "Deletion Failed", comment: "[Alert] Delete failed title.")

    static func deleteFailedMessage(_ version: String, _ error: String) -> String {
      String(localized: "Unable to delete version \(version): \(error)", comment: "[Alert] Delete failed message.")
    }

    // Version Types
    static let typeRelease = String(localized: "Release", comment: "[Text] Release version type.")
    static let typeSnapshot = String(localized: "Snapshot", comment: "[Text] Snapshot version type.")
    static let typeAlpha = String(localized: "Alpha", comment: "[Text] Alpha version type.")
    static let typeBeta = String(localized: "Beta", comment: "[Text] Beta version type.")
    static let typeUnknown = String(localized: "Unknown", comment: "[Text] Unknown version type.")
  }

  // MARK: - Game Launcher
  enum GameLauncher {
    // Status Messages
    static let statusPreparing = String(localized: "Preparing to launch game...", comment: "[Status] Preparing to launch game.")
    static let statusDetectingJava = String(localized: "Detecting Java installation...", comment: "[Status] Detecting Java installation.")
    static let statusExtractingNatives = String(localized: "Extracting native libraries...", comment: "[Status] Extracting native libraries.")
    static let statusLaunching = String(localized: "Launching game...", comment: "[Status] Launching game.")
    static let statusLaunched = String(localized: "Game launched successfully!", comment: "[Status] Game launched successfully.")

    // Buttons
    static let launchButton = String(localized: "Launch", comment: "[Button] Launch game button.")
    static let downloadButton = String(localized: "Download", comment: "[Button] Download button.")

    // Alerts
    static let alertNoJavaTitle = String(localized: "Java Not Found", comment: "[Alert] Java not found title.")
    static let alertNoJavaMessage = String(localized: "No compatible Java installation found. Please install Java to run Minecraft.", comment: "[Alert] Java not found message.")
    static let alertLaunchFailedTitle = String(localized: "Launch Failed", comment: "[Alert] Launch failed title.")
    static let alertVersionNotInstalledTitle = String(localized: "Game Files Not Downloaded", comment: "[Alert] Version not installed title.")

    static func alertLaunchFailedMessage(_ error: String) -> String {
      String(localized: "Failed to launch game: \(error)", comment: "[Alert] Launch failed message.")
    }

    static func alertVersionNotInstalledMessage(_ instanceName: String, _ versionId: String) -> String {
      String(localized: "Instance \"\(instanceName)\" uses game version \(versionId) which has not been downloaded yet.\n\nWould you like to download it now?", comment: "[Alert] Version not installed message for instance.")
    }

    static func alertVersionFileMissingMessage(_ version: String) -> String {
      String(localized: "Game files for version \(version) are incomplete or missing. Please re-download this version.", comment: "[Alert] Version files missing message.")
    }

    static func alertJavaNotFoundMessage(_ path: String) -> String {
      String(localized: "Java not found at: \(path)", comment: "[Alert] Java not found at path.")
    }

    // Log Messages
    static func logLaunchingVersion(_ version: String) -> String {
      String(localized: "🚀 Launching version: \(version)", comment: "[Log] Launching version.")
    }

    static func logJavaDetected(_ path: String, _ version: String) -> String {
      String(localized: "☕️ Using Java: \(version) at \(path)", comment: "[Log] Java detected.")
    }

    static func logGameStarted(_ pid: Int32) -> String {
      String(localized: "✅ Game process started (PID: \(pid))", comment: "[Log] Game process started.")
    }
  }

  // MARK: - Offline Launch
  enum OfflineLaunch {
    // Window
    static let windowTitle = String(localized: "Select Account", comment: "[Text] Account selection window title.")
    static let title = String(localized: "Launch Game", comment: "[Text] Launch game title.")
    static let description = String(localized: "Select an account to launch the game.", comment: "[Text] Account selection description.")

    // Labels
    static let selectAccountLabel = String(localized: "Select Account:", comment: "[Label] Select account label.")
    static let usernameLabel = String(localized: "Username:", comment: "[Label] Username label.")
    static let usernamePlaceholder = String(localized: "Enter username (3-16 characters)", comment: "[Placeholder] Username placeholder.")

    // Account List
    static let noAccountsMessage = String(localized: "No saved accounts found. Please add an account first.", comment: "[Message] No saved accounts message.")
    static let offlineAccountSuffix = String(localized: "(Offline)", comment: "[Text] Offline account suffix.")

    // Buttons
    static let launchButton = String(localized: "Launch", comment: "[Button] Launch button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Errors
    static let errorTitle = String(localized: "Error", comment: "[Alert] Error title.")
    static let errorNoAccountSelected = String(localized: "Please select an account first", comment: "[Alert] No account selected error.")
    static let errorEmptyUsername = String(localized: "Username cannot be empty.", comment: "[Alert] Empty username error.")
    static let errorInvalidUsername = String(localized: "Username must be 3-16 characters long and contain only letters, numbers, and underscores.", comment: "[Alert] Invalid username error.")
  }

  // MARK: - Add Instance
  enum AddInstance {
    // Window & Labels
    static let windowTitle = String(localized: "New Instance", comment: "[Text] Add instance window title.")
    static let openAddInstanceButton = String(localized: "Add Instance", comment: "[Button] Open add instance window.")

    // Top Section
    static let nameLabel = String(localized: "Name:", comment: "[Label] Instance name label.")
    static let namePlaceholder = String(localized: "1.21.10", comment: "[Placeholder] Instance name placeholder.")
    static let groupLabel = String(localized: "Group:", comment: "[Label] Group label.")
    static let groupUncategorized = String(localized: "Uncategorized", comment: "[Text] Uncategorized group.")

    // Categories
    static let categoriesTitle = String(localized: "Categories", comment: "[Text] Categories title.")
    static let categoryCustom = String(localized: "Custom", comment: "[Category] Custom category.")
    static let categoryImport = String(localized: "Import", comment: "[Category] Import category.")
    static let categoryFTBImport = String(localized: "FTB Import", comment: "[Category] FTB Import category.")

    // Custom Content
    static let customTitle = String(localized: "Custom", comment: "[Text] Custom section title.")
    static let filterLabel = String(localized: "Filter:", comment: "[Label] Filter label.")
    static let filterRelease = String(localized: "Release", comment: "[Checkbox] Release filter.")
    static let filterSnapshot = String(localized: "Snapshot", comment: "[Checkbox] Snapshot filter.")
    static let filterBeta = String(localized: "Beta", comment: "[Checkbox] Beta filter.")
    static let filterAlpha = String(localized: "Alpha", comment: "[Checkbox] Alpha filter.")
    static let refreshButton = String(localized: "Refresh", comment: "[Button] Refresh button.")

    // Version Table
    static let columnVersion = String(localized: "Version", comment: "[Table] Version column.")
    static let columnRelease = String(localized: "Released", comment: "[Table] Release column.")
    static let columnType = String(localized: "Type", comment: "[Table] Type column.")

    // Mod Loader
    static let modLoaderTitle = String(localized: "Mod Loader", comment: "[Text] Mod loader title.")
    static let modLoaderPlaceholder = String(localized: "No mod loader selected.", comment: "[Text] Mod loader placeholder.")
    static let modLoaderNone = String(localized: "None", comment: "[Option] No mod loader.")
    static let modLoaderDescription = String(localized: "Select a mod loader and version to enable mod support for this instance.", comment: "[Text] Mod loader description.")
    static let modLoaderVersionLabel = String(localized: "Loader Version:", comment: "[Label] Mod loader version label.")
    static let modLoaderVersionPlaceholder = String(localized: "Please select a mod loader first", comment: "[Text] Mod loader version placeholder when no loader selected.")
    static let loaderVersionColumn = String(localized: "Version", comment: "[Table] Loader version column.")

    // Buttons
    static let helpButton = String(localized: "Help", comment: "[Button] Help button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let confirmButton = String(localized: "OK", comment: "[Button] Confirm button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Alert Titles
    static let alertFailedToRefresh = String(localized: "Failed to Refresh", comment: "[Alert] Failed to refresh title.")
    static let alertFailedToLoadVersions = String(localized: "Failed to Load Versions", comment: "[Alert] Failed to load versions title.")

    // Errors
    static let errorTitle = String(localized: "Error", comment: "[Alert] Error title.")
    static let errorEmptyName = String(localized: "Instance name cannot be empty.", comment: "[Error] Empty name error.")
    static let errorNoVersionSelected = String(localized: "Please select a version.", comment: "[Error] No version selected error.")

    // MARK: - CurseForge Section

    static let curseForgeTitle = String(localized: "CurseForge Modpacks", comment: "[Text] CurseForge section title.")
    static let searchPlaceholder = String(localized: "Search modpacks...", comment: "[Placeholder] Search modpacks placeholder.")
    static let sortByLabel = String(localized: "Sort by:", comment: "[Label] Sort by label.")

    // Sort Options
    static let sortFeatured = String(localized: "Featured", comment: "[Sort] Featured sort option.")
    static let sortPopularity = String(localized: "Popularity", comment: "[Sort] Popularity sort option.")
    static let sortLastUpdated = String(localized: "Last Updated", comment: "[Sort] Last Updated sort option.")
    static let sortName = String(localized: "Name", comment: "[Sort] Name sort option.")
    static let sortAuthor = String(localized: "Author", comment: "[Sort] Author sort option.")
    static let sortDownloads = String(localized: "Downloads", comment: "[Sort] Downloads sort option.")

    // Table Columns
    static let columnModpackName = String(localized: "Modpack", comment: "[Table] Modpack name column.")
    static let columnModpackAuthor = String(localized: "Author", comment: "[Table] Author column.")
    static let columnModpackDownloads = String(localized: "Downloads", comment: "[Table] Downloads column.")

    // Status Messages
    static let loadingModpacks = String(localized: "Loading modpacks...", comment: "[Status] Loading modpacks status.")
    static let noModpacksFound = String(localized: "No modpacks found", comment: "[Status] No modpacks found.")
    static let loadMoreResults = String(localized: "Loading more...", comment: "[Status] Loading more results.")

    // Errors
    static let errorLoadModpacksFailed = String(localized: "Failed to load modpacks", comment: "[Error] Failed to load modpacks.")
    static let errorNoAPIKey = String(localized: "CurseForge API key not configured", comment: "[Error] No API key configured.")
  }
}
