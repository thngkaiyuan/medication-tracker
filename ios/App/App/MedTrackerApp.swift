import SwiftUI

@main
struct MedTrackerApp: App {
  @StateObject private var store: MedicationStore
  @StateObject private var notificationManager: NotificationManager

  init() {
    #if DEBUG
      if ProcessInfo.processInfo.environment["UITEST_RESET_NOTIFICATION_PREFERENCE"] == "1" {
        UserDefaults.standard.removeObject(forKey: "readyNotificationsEnabled")
      }
    #endif
    _notificationManager = StateObject(wrappedValue: NotificationManager())
    #if DEBUG
      if let storageID = ProcessInfo.processInfo.environment["UITEST_STORAGE_ID"] {
        let safeStorageID = storageID.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let applicationSupport = FileManager.default.urls(
          for: .applicationSupportDirectory,
          in: .userDomainMask
        ).first!
        let directory = applicationSupport.appendingPathComponent(
          "MedTrackerUITests",
          isDirectory: true
        )
        try? FileManager.default.createDirectory(
          at: directory,
          withIntermediateDirectories: true
        )
        let testStore = MedicationStore(
          storageURL: directory.appendingPathComponent("\(safeStorageID).json")
        )
        if ProcessInfo.processInfo.environment["UITEST_APP_PREVIEW_FIXTURE"] == "1" {
          let now = Date.now.timeIntervalSince1970 * 1_000
          let hour = 3_600_000.0
          testStore.replaceWithBackup([
            Medication(
              id: "app-preview-cetirizine",
              name: "Cetirizine",
              timeBetweenHours: 4
            ),
            Medication(
              id: "app-preview-acetaminophen",
              name: "Acetaminophen",
              timeBetweenHours: 1,
              maxDosesPerDay: 4,
              records: [now - hour + 7_000]
            ),
            Medication(
              id: "app-preview-ibuprofen",
              name: "Ibuprofen",
              timeBetweenHours: 8,
              maxDosesPerDay: 2,
              records: [now - (10 * hour)]
            ),
          ])
        } else if ProcessInfo.processInfo.environment["UITEST_NOTIFICATION_FIXTURE"] == "1" {
          testStore.replaceWithBackup([
            Medication(
              id: "notification-acetaminophen",
              name: "Acetaminophen",
              timeBetweenHours: 1,
              records: [Date.now.addingTimeInterval(-3_560).timeIntervalSince1970 * 1_000]
            )
          ])
        } else if ProcessInfo.processInfo.environment["UITEST_APP_STORE_FIXTURE"] == "1" {
          let now = Date.now.timeIntervalSince1970 * 1_000
          let hour = 3_600_000.0
          testStore.replaceWithBackup([
            Medication(
              id: "app-store-acetaminophen",
              name: "Acetaminophen",
              timeBetweenHours: 6,
              maxDosesPerDay: 4,
              records: [now - (58 * hour), now - (34 * hour), now - (10 * hour)]
            ),
            Medication(
              id: "app-store-ibuprofen",
              name: "Ibuprofen",
              timeBetweenHours: 8,
              maxDosesPerDay: 2,
              records: [now - (25 * hour), now - hour]
            ),
            Medication(
              id: "app-store-cetirizine",
              name: "Cetirizine",
              timeBetweenHours: 4
            ),
          ])
        } else if let recordCountText = ProcessInfo.processInfo.environment[
          "UITEST_SEED_RECORD_COUNT"
        ],
          let recordCount = Int(recordCountText), recordCount > 0
        {
          let records = (0..<recordCount).map { offset in
            Date.now.addingTimeInterval(Double(offset - recordCount) * 3_600)
              .timeIntervalSince1970 * 1_000
          }
          let medicationName = ProcessInfo.processInfo.environment[
            "UITEST_SEED_MEDICATION_NAME"
          ] ?? "Scroll Test Medication"
          testStore.replaceWithBackup([
            Medication(
              name: medicationName,
              timeBetweenHours: 4,
              records: records
            )
          ])
        }
        _store = StateObject(wrappedValue: testStore)
        return
      }
    #endif

    _store = StateObject(wrappedValue: MedicationStore())
  }

  var body: some Scene {
    WindowGroup {
      MedicationListView()
        .environmentObject(store)
        .environmentObject(notificationManager)
        .tint(AppTheme.control)
        .preferredColorScheme(testColorScheme)
        .task {
          await notificationManager.synchronize(medications: store.medications)
        }
        .onChange(of: store.medications) { medications in
          Task {
            await notificationManager.synchronize(medications: medications)
          }
        }
    }
  }

  private var testColorScheme: ColorScheme? {
    #if DEBUG
      ProcessInfo.processInfo.environment["UITEST_COLOR_SCHEME"] == "dark" ? .dark : nil
    #else
      nil
    #endif
  }
}
