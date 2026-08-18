import SwiftUI

@main
struct MedTrackerApp: App {
  @StateObject private var store: MedicationStore

  init() {
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
        if ProcessInfo.processInfo.environment["UITEST_APP_STORE_FIXTURE"] == "1" {
          let now = Date.now.timeIntervalSince1970 * 1_000
          let hour = 3_600_000.0
          testStore.replaceWithBackup([
            Medication(
              id: "app-store-morning",
              name: "Morning Medication",
              timeBetweenHours: 6,
              maxDosesPerDay: 4,
              records: [now - (58 * hour), now - (34 * hour), now - (10 * hour)]
            ),
            Medication(
              id: "app-store-evening",
              name: "Evening Medication",
              timeBetweenHours: 8,
              maxDosesPerDay: 2,
              records: [now - (25 * hour), now - hour]
            ),
            Medication(
              id: "app-store-needed",
              name: "As Needed Medication",
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
        .tint(AppTheme.control)
        .preferredColorScheme(testColorScheme)
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
