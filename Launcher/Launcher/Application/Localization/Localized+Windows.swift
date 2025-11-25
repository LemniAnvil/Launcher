//
//  Localized+Windows.swift
//  Launcher
//

import Foundation

// MARK: - Window-related Localizations
extension Localized {
  // MARK: - Main Window
  enum MainWindow {
    static let windowTitle = String(localized: "Minecraft Launcher", comment: "[Text] Main window title.")
    static let titleLabel = String(localized: "Minecraft Launcher", comment: "[Text] Main window title label.")
    static let subtitle = String(localized: "Version Management & Download Testing", comment: "[Text] Main window subtitle.")
    static let openVersionListWindowButton = String(localized: "Open Version List", comment: "[Button] Open version list window.")
    static let initialStatus = String(localized: "Click button to start", comment: "[Text] Initial status message.")
    static let versionListWindowOpened = String(localized: "Version list window opened", comment: "[Text] Version list window opened status.")
    static let versionListWindowClosed = String(localized: "Version list window closed, click button to reopen", comment: "[Text] Version list window closed status.")
    static let javaWindowOpened = String(localized: "Java detection window opened", comment: "[Text] Java window opened status.")
    static let javaWindowClosed = String(localized: "Java detection window closed, click button to reopen", comment: "[Text] Java window closed status.")
    static let minecraftAccessibility = String(localized: "Minecraft", comment: "[Accessibility] Minecraft icon description.")
  }

  // MARK: - Version List Window
  enum VersionListWindow {
    static let windowTitle = String(localized: "Version List", comment: "[Text] Version list window title.")

    // Table Column Headers
    static let columnVersion = String(localized: "Version", comment: "[Table] Version column header.")
    static let columnType = String(localized: "Type", comment: "[Table] Type column header.")
    static let columnReleaseTime = String(localized: "Release Time", comment: "[Table] Release time column header.")
    static let columnUpdateTime = String(localized: "Update Time", comment: "[Table] Update time column header.")

    // Filter Checkboxes
    static let checkboxRelease = String(localized: "🟢 Release", comment: "[Checkbox] Release filter.")
    static let checkboxSnapshot = String(localized: "🟡 Snapshot", comment: "[Checkbox] Snapshot filter.")
    static let checkboxBeta = String(localized: "🔵 Beta", comment: "[Checkbox] Beta filter.")
    static let checkboxAlpha = String(localized: "🟣 Alpha", comment: "[Checkbox] Alpha filter.")

    // Buttons
    static let refreshVersionsButton = String(localized: "1. Refresh Versions", comment: "[Button] Refresh versions list.")
    static let getVersionDetailsButton = String(localized: "2. Get Version Details", comment: "[Button] Get version details.")
    static let downloadTestFileButton = String(localized: "3. Download Test File", comment: "[Button] Download test file.")
    static let downloadVersionButton = String(localized: "5. Download Version", comment: "[Button] Download version.")
    static let createInstanceButton = String(localized: "Create Instance", comment: "[Button] Create instance button.")
    static let clearLogButton = String(localized: "Clear Log", comment: "[Button] Clear log.")

    // Labels
    static let versionLabel = String(localized: "Version:", comment: "[Label] Version selection label.")
    static let filterLabel = String(localized: "Filter:", comment: "[Label] Filter label.")
    static let statusReady = String(localized: "Ready", comment: "[Text] Ready status.")

    // Filter Options
    static let filterAllVersions = String(localized: "All Versions", comment: "[Filter] All versions option.")
    static let filterReleasesOnly = String(localized: "Releases Only", comment: "[Filter] Releases only option.")
    static let filterSnapshotsOnly = String(localized: "Snapshots Only", comment: "[Filter] Snapshots only option.")
    static let filterBetaOnly = String(localized: "Beta Only", comment: "[Filter] Beta only option.")
    static let filterAlphaOnly = String(localized: "Alpha Only", comment: "[Filter] Alpha only option.")
    static let noVersionsLoaded = String(localized: "No versions loaded", comment: "[Text] No versions loaded message.")

    static func statusDownloading(progress: String, speed: String, bytes: String) -> String {
      String(localized: "Downloading: \(progress) | Speed: \(speed)/s | \(bytes)", comment: "[Status] Downloading with progress.")
    }

    // Status Messages
    static let statusRefreshing = String(localized: "Refreshing version list...", comment: "[Status] Refreshing version list.")
    static let statusRefreshCompleted = String(localized: "Version list refresh completed", comment: "[Status] Version list refresh completed.")
    static let statusGettingDetails = String(localized: "Getting version details...", comment: "[Status] Getting version details.")
    static let statusDetailsCompleted = String(localized: "Version details retrieval completed", comment: "[Status] Version details retrieval completed.")
    static let statusDetailsFailed = String(localized: "Failed to get details", comment: "[Status] Failed to get details.")
    static let statusDownloadingTestFile = String(localized: "Downloading test file...", comment: "[Status] Downloading test file.")
    static let statusTestFileCompleted = String(localized: "Test file download completed", comment: "[Status] Test file download completed.")
    static let statusDownloadFailed = String(localized: "Download failed", comment: "[Status] Download failed.")
    static let statusDownloadingVersion = String(localized: "Downloading version...", comment: "[Status] Downloading version.")
    static let statusDownloadCompleted = String(localized: "Download completed!", comment: "[Status] Download completed.")

    // Format strings
    static func statusRefreshFailed(_ error: String) -> String {
      String(localized: "Refresh failed: \(error)", comment: "[Status] Refresh failed with error.")
    }
  }

  // MARK: - Log Messages
  enum LogMessages {
    // Initialization
    static let initialized = String(localized: "✅ Version list window initialized", comment: "[Log] Version list window initialized.")
    static let pleaseClickButtons = String(localized: "📝 Please click buttons in order to test functions", comment: "[Log] Please click buttons in order.")
    static let logCleared = String(localized: "📝 Log cleared", comment: "[Log] Log cleared.")

    // Version Manager Status
    static let checkingVersionManager = String(localized: "🔍 Checking version manager status...", comment: "[Log] Checking version manager status.")
    static let versionDataLoaded = String(localized: "✅ Version data loaded, updating version list...", comment: "[Log] Version data loaded.")
    static let updatingVersionList = String(localized: "📋 Updating version list...", comment: "[Log] Updating version list.")
    static let refreshVersionListToUpdate = String(localized: "🔄 Refresh version list to update installation status...", comment: "[Log] Refresh version list.")
    static let refreshVersionListToShow = String(localized: "🔄 Refresh version list to show installed status...", comment: "[Log] Refresh version list to show status.")
    static let versionListEmpty = String(localized: "⚠️ Version list is empty", comment: "[Log] Version list is empty.")
    static let versionListUpdated = String(localized: "📝 Version list updated", comment: "[Log] Version list updated.")
    static let filterCleared = String(localized: "📋 Filter cleared, showing all version types", comment: "[Log] Filter cleared.")
    static let mouseDoubleClickVersion = String(localized: "🖱️ Double-clicked version:", comment: "[Log] Double-clicked version.")
    static let defaultSelectedLatestRelease = String(localized: "🎯 Default selected latest release:", comment: "[Log] Default selected latest release.")
    static let latestReleaseNotFound = String(localized: "⚠️ Latest release not found, selected first item", comment: "[Log] Latest release not found.")

    static func currentLoadedVersions(_ count: Int) -> String {
      String(localized: "📊 Currently loaded versions: \(count)", comment: "[Log] Currently loaded versions count.")
    }

    static func versionStatisticsTitle() -> String {
      String(localized: "📊 Version type statistics:", comment: "[Log] Version statistics title.")
    }

    static func releaseCount(_ count: Int) -> String {
      String(localized: "  🟢 Release: \(count)", comment: "[Log] Release version count.")
    }

    static func snapshotCount(_ count: Int) -> String {
      String(localized: "  🟡 Snapshot: \(count)", comment: "[Log] Snapshot version count.")
    }

    static func betaCount(_ count: Int) -> String {
      String(localized: "  🔵 Beta: \(count)", comment: "[Log] Beta version count.")
    }

    static func alphaCount(_ count: Int) -> String {
      String(localized: "  🟣 Alpha: \(count)", comment: "[Log] Alpha version count.")
    }

    static func totalCount(_ count: Int) -> String {
      String(localized: "  📋 Total: \(count)", comment: "[Log] Total version count.")
    }

    static func filterApplied(_ types: String) -> String {
      String(localized: "🔍 Filter applied: \(types)", comment: "[Log] Filter applied.")
    }

    static func showingAllVersions(_ count: Int) -> String {
      String(localized: "📋 Showing all versions, total: \(count)", comment: "[Log] Showing all versions.")
    }

    static func filteringAfterCount(_ types: String, _ count: Int) -> String {
      String(localized: "🔍 Applying filter: \(types), filtered count: \(count)", comment: "[Log] Filtering results.")
    }

    static func displayedVersionsCount(_ count: Int) -> String {
      String(localized: "📊 Displayed versions: \(count)", comment: "[Log] Displayed versions count.")
    }

    static func defaultSelectedIndex(_ version: String, _ index: Int) -> String {
      String(localized: "🎯 Default selected latest release: \(version) (index: \(index))", comment: "[Log] Default selected with index.")
    }

    // Test 1: Refresh Versions
    static let test1Title = String(localized: "🔄 Test 1: Refresh version list", comment: "[Log] Test 1 title.")
    static let versionListRefreshed = String(localized: "✅ Version list refreshed successfully", comment: "[Log] Version list refreshed successfully.")
    static let firstReleasesTitle = String(localized: "📋 First 10 releases:", comment: "[Log] First 10 releases title.")

    static func latestRelease(_ version: String) -> String {
      String(localized: "📊 Latest release: \(version)", comment: "[Log] Latest release version.")
    }

    static func latestSnapshot(_ version: String) -> String {
      String(localized: "📊 Latest snapshot: \(version)", comment: "[Log] Latest snapshot version.")
    }

    static func totalVersions(_ count: Int) -> String {
      String(localized: "📊 Total versions: \(count)", comment: "[Log] Total versions count.")
    }

    static func versionDropdownUpdated(_ count: Int) -> String {
      String(localized: "📋 Version dropdown updated with \(count) versions", comment: "[Log] Version dropdown updated.")
    }

    static func error(_ message: String) -> String {
      String(localized: "❌ Error: \(message)", comment: "[Log] Error message.")
    }

    // Test 2: Get Version Details
    static func test2Title(_ versionId: String) -> String {
      String(localized: "📦 Test 2: Get version details - \(versionId)", comment: "[Log] Test 2 title.")
    }

    static let pleaseSelectVersion = String(localized: "❌ Please select a version from dropdown", comment: "[Log] Please select a version.")
    static let versionListEmptyRefreshing = String(localized: "📋 Version list empty, refreshing...", comment: "[Log] Version list empty, refreshing.")
    static let versionDetailsRetrieved = String(localized: "✅ Version details retrieved successfully", comment: "[Log] Version details retrieved successfully.")
    static let libraryInfo = String(localized: "📚 Library information:", comment: "[Log] Library information title.")
    static let clientFile = String(localized: "💾 Client file:", comment: "[Log] Client file title.")

    static func versionId(_ id: String) -> String {
      String(localized: "📌 Version ID: \(id)", comment: "[Log] Version ID.")
    }

    static func versionType(_ type: String) -> String {
      String(localized: "📌 Type: \(type)", comment: "[Log] Version type.")
    }

    static func mainClass(_ className: String) -> String {
      String(localized: "📌 Main class: \(className)", comment: "[Log] Main class.")
    }

    static func assetIndex(_ index: String) -> String {
      String(localized: "📌 Asset index: \(index)", comment: "[Log] Asset index.")
    }

    static func javaVersion(_ version: Int) -> String {
      String(localized: "☕️ Java version: \(version)", comment: "[Log] Java version.")
    }

    static func libraryTotal(_ count: Int) -> String {
      String(localized: "  Total: \(count)", comment: "[Log] Total libraries.")
    }

    static func libraryApplicable(_ count: Int) -> String {
      String(localized: "  Applicable to macOS: \(count)", comment: "[Log] Applicable libraries for macOS.")
    }

    static func clientSize(_ size: String) -> String {
      String(localized: "  Size: \(size)", comment: "[Log] Client file size.")
    }

    static func clientSHA1(_ sha1: String) -> String {
      String(localized: "  SHA1: \(sha1)", comment: "[Log] Client file SHA1.")
    }

    // Test 3: Download Test File
    static let test3Title = String(localized: "⬇️ Test 3: Download test file", comment: "[Log] Test 3 title.")
    static let startingDownloadManifest = String(localized: "📥 Starting download of version manifest...", comment: "[Log] Starting download of version manifest.")
    static let fileDownloadedSuccessfully = String(localized: "✅ File downloaded successfully", comment: "[Log] File downloaded successfully.")

    static func saveLocation(_ path: String) -> String {
      String(localized: "📍 Save location: \(path)", comment: "[Log] Save location.")
    }

    static func fileSize(_ size: String) -> String {
      String(localized: "💾 File size: \(size)", comment: "[Log] File size.")
    }

    static func filePath(_ path: String) -> String {
      String(localized: "📂 File path: \(path)", comment: "[Log] File path.")
    }

    // Test 4: Check Installed
    static let test4Title = String(localized: "🔍 Test 4: Check installed versions", comment: "[Log] Test 4 title.")
    static let noInstalledVersions = String(localized: "📭 No installed versions", comment: "[Log] No installed versions.")

    static func installedVersions(_ count: Int) -> String {
      String(localized: "✅ Installed versions (\(count)):", comment: "[Log] Installed versions count.")
    }

    static func minecraftDirectory(_ path: String) -> String {
      String(localized: "📁 Minecraft directory: \(path)", comment: "[Log] Minecraft directory path.")
    }

    // Test 5: Download Version
    static func test5Title(_ versionId: String) -> String {
      String(localized: "🚀 Test 5: Download full version - \(versionId)", comment: "[Log] Test 5 title.")
    }

    static let downloadWarning = String(localized: "⚠️ Note: This will download complete game files, may take a while", comment: "[Log] Download warning.")
    static let userCancelledDownload = String(localized: "❌ User cancelled download", comment: "[Log] User cancelled download.")
    static let refreshingVersionList = String(localized: "📋 Refreshing version list...", comment: "[Log] Refreshing version list.")
    static let gettingVersionDetails = String(localized: "📦 Getting version details...", comment: "[Log] Getting version details.")
    static let versionDetailsRetrievedSuccessfully = String(localized: "✅ Version details retrieved successfully", comment: "[Log] Version details retrieved successfully.")
    static let downloadingCoreAndLibraries = String(localized: "⬇️ Step 1: Downloading game core and libraries...", comment: "[Log] Downloading game core and libraries.")
    static let coreAndLibrariesCompleted = String(localized: "✅ Game core and library files download completed", comment: "[Log] Game core and library files download completed.")
    static let downloadingAssets = String(localized: "⬇️ Step 2: Downloading game assets...", comment: "[Log] Downloading game assets.")
    static let assetsCompleted = String(localized: "✅ Game assets download completed", comment: "[Log] Game assets download completed.")

    static func needToDownloadLibraries(_ count: Int) -> String {
      String(localized: "📊 Need to download \(count) libraries", comment: "[Log] Need to download libraries count.")
    }

    static func downloadCompleted(_ versionId: String) -> String {
      String(localized: "🎉 Version \(versionId) download completed!", comment: "[Log] Version download completed.")
    }

    static func downloadFailed(_ error: String) -> String {
      String(localized: "❌ Download failed: \(error)", comment: "[Log] Download failed.")
    }

    static func selectedVersion(_ version: String) -> String {
      String(localized: "📌 Selected version: \(version)", comment: "[Log] Selected version.")
    }

    static let filterAllVersions = String(localized: "🔍 Filter: All versions", comment: "[Log] Filter all versions.")
    static let filterReleasesOnly = String(localized: "🔍 Filter: Releases only", comment: "[Log] Filter releases only.")
    static let filterSnapshotsOnly = String(localized: "🔍 Filter: Snapshots only", comment: "[Log] Filter snapshots only.")
    static let filterBetaOnly = String(localized: "🔍 Filter: Beta only", comment: "[Log] Filter beta only.")
    static let filterAlphaOnly = String(localized: "🔍 Filter: Alpha only", comment: "[Log] Filter alpha only.")

    static let loadingCachedVersions = String(localized: "📋 Loading cached versions...", comment: "[Log] Loading cached versions.")

    // Instance Creation
    static func creatingInstanceForVersion(_ versionId: String) -> String {
      String(localized: "Creating instance for version: \(versionId)", comment: "[Log] Creating instance for version.")
    }

    static func versionNotInstalledDownloading(_ versionId: String) -> String {
      String(localized: "Version \(versionId) is not installed. Downloading...", comment: "[Log] Version not installed, downloading.")
    }

    static func instanceCreatedSuccessfully(_ name: String) -> String {
      String(localized: "Instance created successfully: \(name)", comment: "[Log] Instance created successfully.")
    }

    static func instanceId(_ id: String) -> String {
      String(localized: "Instance ID: \(id)", comment: "[Log] Instance ID.")
    }

    static func instanceVersion(_ versionId: String) -> String {
      String(localized: "Version: \(versionId)", comment: "[Log] Instance version.")
    }

    static let failedToCreateInstanceDialog = String(localized: "Failed to create instance dialog", comment: "[Log] Failed to create instance dialog.")
  }

  // MARK: - Alert Dialogs
  enum Alerts {
    // Download Confirmation
    static let confirmDownloadTitle = String(localized: "Confirm Download", comment: "[Alert] Confirm download title.")

    static func confirmDownloadMessage(_ versionId: String) -> String {
      String(localized: "Are you sure you want to download \(versionId)?\nThis will download game core, libraries and assets.", comment: "[Alert] Confirm download message.")
    }

    static let confirmButton = String(localized: "Confirm", comment: "[Button] Confirm button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")

    // Download Completed
    static let downloadCompletedTitle = String(localized: "Download Completed", comment: "[Alert] Download completed title.")

    static func downloadCompletedMessage(_ versionId: String) -> String {
      String(localized: "Version \(versionId) has been downloaded successfully!", comment: "[Alert] Download completed message.")
    }

    // Download Failed
    static let downloadFailedTitle = String(localized: "Download Failed", comment: "[Alert] Download failed title.")
  }
}
