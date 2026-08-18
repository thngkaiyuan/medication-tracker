import SwiftUI

@main
struct MedTrackerApp: App {
  @StateObject private var store = MedicationStore()

  var body: some Scene {
    WindowGroup {
      MedicationListView()
        .environmentObject(store)
        .tint(AppTheme.tint)
    }
  }
}
