//
//  Localized.swift
//  Launcher
//

import Foundation

// swiftlint:disable type_body_length
enum Localized {
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
      String(localized: "\n📊 Version type statistics:", comment: "[Log] Version statistics title.")
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

  // MARK: - Proxy Settings
  enum Proxy {
    // Labels
    static let sectionTitle = String(localized: "Proxy Settings", comment: "[Label] Proxy settings section title.")
    static let enableProxy = String(localized: "Enable Proxy", comment: "[Checkbox] Enable proxy checkbox.")
    static let hostLabel = String(localized: "Host:", comment: "[Label] Proxy host label.")
    static let portLabel = String(localized: "Port:", comment: "[Label] Proxy port label.")
    static let typeLabel = String(localized: "Type:", comment: "[Label] Proxy type label.")
    static let hostPlaceholder = String(localized: "e.g., 127.0.0.1", comment: "[Placeholder] Proxy host placeholder.")
    static let portPlaceholder = String(localized: "e.g., 7890", comment: "[Placeholder] Proxy port placeholder.")

    // Buttons
    static let applyButton = String(localized: "Apply Proxy", comment: "[Button] Apply proxy settings.")
    static let testButton = String(localized: "Test Proxy", comment: "[Button] Test proxy connection.")

    // Types
    static let typeHTTP = String(localized: "HTTP", comment: "[Text] HTTP proxy type.")
    static let typeHTTPS = String(localized: "HTTPS", comment: "[Text] HTTPS proxy type.")
    static let typeSOCKS5 = String(localized: "SOCKS5", comment: "[Text] SOCKS5 proxy type.")

    // Status Messages
    static let statusEnabled = String(localized: "Proxy enabled", comment: "[Status] Proxy enabled.")
    static let statusDisabled = String(localized: "Proxy disabled", comment: "[Status] Proxy disabled.")
    static let statusTesting = String(localized: "Testing proxy connection...", comment: "[Status] Testing proxy connection.")
    static let statusTestSuccess = String(localized: "Proxy connection test successful", comment: "[Status] Proxy connection test successful.")
    static let statusTestFailed = String(localized: "Proxy connection test failed", comment: "[Status] Proxy connection test failed.")

    static func statusApplied(_ host: String, _ port: Int) -> String {
      String(localized: "Proxy applied: \(host):\(port)", comment: "[Status] Proxy applied with host and port.")
    }

    // Log Messages
    static func logEnabled(_ type: String, _ host: String, _ port: Int) -> String {
      String(localized: "✅ Proxy enabled: \(type) \(host):\(port)", comment: "[Log] Proxy enabled.")
    }

    static let logDisabled = String(localized: "❌ Proxy disabled", comment: "[Log] Proxy disabled.")
    static let logTesting = String(localized: "🔄 Testing proxy connection...", comment: "[Log] Testing proxy connection.")
    static let logTestSuccess = String(localized: "✅ Proxy test successful", comment: "[Log] Proxy test successful.")

    static func logTestFailed(_ error: String) -> String {
      String(localized: "❌ Proxy test failed: \(error)", comment: "[Log] Proxy test failed.")
    }

    // Alerts
    static let alertTestSuccessTitle = String(localized: "Proxy Test Successful", comment: "[Alert] Proxy test successful title.")
    static let alertTestSuccessMessage = String(localized: "Proxy connection is working correctly.", comment: "[Alert] Proxy test successful message.")
    static let alertTestFailedTitle = String(localized: "Proxy Test Failed", comment: "[Alert] Proxy test failed title.")

    static func alertTestFailedMessage(_ error: String) -> String {
      String(localized: "Failed to connect through proxy:\n\(error)", comment: "[Alert] Proxy test failed message.")
    }

    static let alertInvalidConfigTitle = String(localized: "Invalid Configuration", comment: "[Alert] Invalid proxy configuration title.")
    static let alertInvalidConfigMessage = String(localized: "Please enter valid host and port.", comment: "[Alert] Invalid proxy configuration message.")

    // Errors
    enum Errors {
      static let invalidConfiguration = String(localized: "Invalid proxy configuration", comment: "[Error] Invalid proxy configuration.")

      static func connectionFailed(_ reason: String) -> String {
        String(localized: "Proxy connection failed: \(reason)", comment: "[Error] Proxy connection failed.")
      }
    }
  }

  // MARK: - Java Detection
  enum JavaDetection {
    static let windowTitle = String(localized: "Java Detection", comment: "[Text] Java detection window title.")
    static let title = String(localized: "Java Installation Detection", comment: "[Text] Java detection title.")
    static let subtitle = String(localized: "Detect and manage Java installations for running Minecraft", comment: "[Text] Java detection subtitle.")

    // Buttons
    static let detectButton = String(localized: "Detect Java", comment: "[Button] Detect Java installations.")
    static let refreshButton = String(localized: "Refresh", comment: "[Button] Refresh Java detection.")
    static let openJavaDetectionButton = String(localized: "Java Detection", comment: "[Button] Open Java detection window.")

    // Table Columns
    static let columnPath = String(localized: "Installation Path", comment: "[Table] Java installation path column.")
    static let columnVersion = String(localized: "Version", comment: "[Table] Java version column.")
    static let columnType = String(localized: "Type", comment: "[Table] Java type column.")
    static let columnStatus = String(localized: "Status", comment: "[Table] Java status column.")

    // Status Messages
    static let statusReady = String(localized: "Ready to detect Java installations", comment: "[Status] Ready to detect Java.")
    static let statusDetecting = String(localized: "Detecting Java installations...", comment: "[Status] Detecting Java installations.")
    static let statusNoJavaFound = String(localized: "No Java installations found", comment: "[Status] No Java found.")

    static func statusFoundJava(_ count: Int) -> String {
      String(localized: "Found \(count) Java installation(s)", comment: "[Status] Found Java installations.")
    }

    // Messages
    static let noJavaMessage = String(localized: "No Java installations were detected on your system. Please install Java to run Minecraft.", comment: "[Message] No Java installations found message.")

    // Java Home
    static let javaHomeLabel = String(localized: "JAVA_HOME:", comment: "[Label] JAVA_HOME environment variable label.")
    static let javaHomeNotSet = String(localized: "Not set", comment: "[Text] JAVA_HOME not set.")
  }

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

    // Alerts
    static let alertNoJavaTitle = String(localized: "Java Not Found", comment: "[Alert] Java not found title.")
    static let alertNoJavaMessage = String(localized: "No compatible Java installation found. Please install Java to run Minecraft.", comment: "[Alert] Java not found message.")
    static let alertLaunchFailedTitle = String(localized: "Launch Failed", comment: "[Alert] Launch failed title.")

    static func alertLaunchFailedMessage(_ error: String) -> String {
      String(localized: "Failed to launch game: \(error)", comment: "[Alert] Launch failed message.")
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
    static let windowTitle = String(localized: "Offline Launch", comment: "[Text] Offline launch window title.")
    static let title = String(localized: "Offline Mode", comment: "[Text] Offline mode title.")
    static let description = String(localized: "Select a saved account to launch in offline mode.", comment: "[Text] Offline mode description.")

    // Labels
    static let selectAccountLabel = String(localized: "Select Account:", comment: "[Label] Select account label.")
    static let usernameLabel = String(localized: "Username:", comment: "[Label] Username label.")
    static let usernamePlaceholder = String(localized: "Enter username (3-16 characters)", comment: "[Placeholder] Username placeholder.")

    // Account Selection
    static let manualInputOption = String(localized: "Manual Input...", comment: "[Option] Manual input option.")
    static let noAccountsMessage = String(localized: "No saved accounts", comment: "[Message] No saved accounts message.")

    // Buttons
    static let launchButton = String(localized: "Launch", comment: "[Button] Launch button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Errors
    static let errorTitle = String(localized: "Invalid Username", comment: "[Alert] Invalid username title.")
    static let errorEmptyUsername = String(localized: "Username cannot be empty.", comment: "[Alert] Empty username error.")
    static let errorInvalidUsername = String(localized: "Username must be 3-16 characters long and contain only letters, numbers, and underscores.", comment: "[Alert] Invalid username error.")
  }

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

    // Empty State
    static let emptyMicrosoftMessage = String(localized: "No Microsoft accounts\nClick the button above to sign in", comment: "[Text] Empty state message for Microsoft accounts.")

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
  }

  // MARK: - Settings
  enum Settings {
    // Window & Labels
    static let windowTitle = String(localized: "Settings", comment: "[Text] Settings window title.")
    static let title = String(localized: "Settings", comment: "[Text] Settings title.")
    static let subtitle = String(localized: "Configure application settings", comment: "[Text] Settings subtitle.")
    static let openSettingsButton = String(localized: "Settings", comment: "[Button] Open settings window.")

    // Proxy Section
    static let proxySectionTitle = String(localized: "Network Proxy", comment: "[Text] Proxy section title.")
    static let enableProxy = String(localized: "Enable Proxy", comment: "[Checkbox] Enable proxy checkbox.")
    static let proxyTypeLabel = String(localized: "Type:", comment: "[Label] Proxy type label.")
    static let proxyHostLabel = String(localized: "Host:", comment: "[Label] Proxy host label.")
    static let proxyPortLabel = String(localized: "Port:", comment: "[Label] Proxy port label.")
    static let hostPlaceholder = String(localized: "e.g., 127.0.0.1", comment: "[Placeholder] Proxy host placeholder.")
    static let portPlaceholder = String(localized: "e.g., 7890", comment: "[Placeholder] Proxy port placeholder.")

    // Download Section
    static let downloadSectionTitle = String(localized: "Download Settings", comment: "[Text] Download section title.")
    static let enableFileVerification = String(localized: "Verify File Integrity", comment: "[Checkbox] Enable file verification checkbox.")
    static let fileVerificationDescription = String(localized: "Verify SHA1 checksums when downloading files", comment: "[Text] File verification description.")
    static let maxConcurrentLabel = String(localized: "Max Concurrent Downloads:", comment: "[Label] Max concurrent downloads label.")
    static let concurrentDescription = String(localized: "Number of simultaneous downloads (1-64)", comment: "[Text] Concurrent downloads description.")
    static let requestTimeoutLabel = String(localized: "Request Timeout:", comment: "[Label] Request timeout label.")
    static let requestTimeoutDescription = String(localized: "Timeout for download requests (5-120 seconds)", comment: "[Text] Request timeout description.")
    static let resourceTimeoutLabel = String(localized: "Resource Timeout:", comment: "[Label] Resource timeout label.")
    static let resourceTimeoutDescription = String(localized: "Maximum time for downloads (60-600 seconds)", comment: "[Text] Resource timeout description.")
    static let useV2Manifest = String(localized: "Use V2 Manifest API", comment: "[Checkbox] Use V2 manifest API checkbox.")
    static let v2ManifestDescription = String(localized: "Use Piston Meta API instead of launcher meta", comment: "[Text] V2 manifest description.")

    // Buttons
    static let applyButton = String(localized: "Apply Settings", comment: "[Button] Apply settings button.")
    static let testButton = String(localized: "Test Proxy", comment: "[Button] Test proxy button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Status Messages
    static let statusReady = String(localized: "Ready", comment: "[Status] Ready status.")
    static let statusDisabled = String(localized: "Proxy disabled", comment: "[Status] Proxy disabled.")
    static let statusTesting = String(localized: "Testing proxy connection...", comment: "[Status] Testing proxy.")
    static let statusTestSuccess = String(localized: "Proxy connection test successful", comment: "[Status] Proxy test success.")
    static let statusTestFailed = String(localized: "Proxy connection test failed", comment: "[Status] Proxy test failed.")

    static func statusApplied(_ host: String, _ port: Int) -> String {
      String(localized: "Proxy applied: \(host):\(port)", comment: "[Status] Proxy applied.")
    }

    // Alerts
    static let alertInvalidConfigTitle = String(localized: "Invalid Configuration", comment: "[Alert] Invalid proxy configuration title.")
    static let alertInvalidConfigMessage = String(localized: "Please enter valid host and port.", comment: "[Alert] Invalid proxy configuration message.")
    static let alertTestSuccessTitle = String(localized: "Proxy Test Successful", comment: "[Alert] Proxy test successful title.")
    static let alertTestSuccessMessage = String(localized: "Proxy connection is working correctly.", comment: "[Alert] Proxy test successful message.")
    static let alertTestFailedTitle = String(localized: "Proxy Test Failed", comment: "[Alert] Proxy test failed title.")

    static func alertTestFailedMessage(_ error: String) -> String {
      String(localized: "Failed to connect through proxy:\n\(error)", comment: "[Alert] Proxy test failed message.")
    }
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

    // Buttons
    static let helpButton = String(localized: "Help", comment: "[Button] Help button.")
    static let cancelButton = String(localized: "Cancel", comment: "[Button] Cancel button.")
    static let confirmButton = String(localized: "OK", comment: "[Button] Confirm button.")
    static let okButton = String(localized: "OK", comment: "[Button] OK button.")

    // Errors
    static let errorTitle = String(localized: "Error", comment: "[Alert] Error title.")
    static let errorEmptyName = String(localized: "Instance name cannot be empty.", comment: "[Error] Empty name error.")
    static let errorNoVersionSelected = String(localized: "Please select a version.", comment: "[Error] No version selected error.")
  }

  // MARK: - Errors
  enum Errors {
    // VersionManager Errors
    static func versionNotFound(_ version: String) -> String {
      String(localized: "Version not found: \(version)", comment: "[Error] Version not found.")
    }

    static func invalidURL(_ url: String) -> String {
      String(localized: "Invalid URL: \(url)", comment: "[Error] Invalid URL.")
    }

    static func downloadFailed(_ reason: String) -> String {
      String(localized: "Download failed: \(reason)", comment: "[Error] Download failed.")
    }

    static func parseFailed(_ reason: String) -> String {
      String(localized: "Parse failed: \(reason)", comment: "[Error] Parse failed.")
    }

    // DownloadManager Errors
    static func httpError(_ code: Int) -> String {
      String(localized: "HTTP error: \(code)", comment: "[Error] HTTP error.")
    }

    static let sha1Mismatch = String(localized: "SHA1 verification failed", comment: "[Error] SHA1 verification failed.")

    static func assetIndexNotFound(_ id: String) -> String {
      String(localized: "Asset index not found: \(id)", comment: "[Error] Asset index not found.")
    }

    static let downloadCancelled = String(localized: "Download cancelled", comment: "[Error] Download cancelled.")

    static func fileNotFound(_ path: String) -> String {
      String(localized: "File not found: \(path)", comment: "[Error] File not found.")
    }
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
// swiftlint:enable type_body_length
