import Foundation
import UserNotifications

struct MedicationNotification: Equatable {
  let identifier: String
  let title: String
  let body: String
  let date: Date
}

enum MedicationNotificationPlanner {
  static let identifierPrefix = "medtracker.ready."

  static func notifications(
    for medications: [Medication],
    at date: Date = .now
  ) -> [MedicationNotification] {
    medications.compactMap { medication in
      guard let nextDoseDate = medication.nextDoseDate(after: date), nextDoseDate > date else {
        return nil
      }

      return MedicationNotification(
        identifier: identifierPrefix + medication.id,
        title: "\(medication.name): wait limits cleared",
        body: "Ready based on the limits you entered.",
        date: nextDoseDate
      )
    }
  }
}

@MainActor
final class NotificationManager: ObservableObject {
  @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
  @Published private(set) var notificationsEnabled: Bool

  private let center: UNUserNotificationCenter
  private let defaults: UserDefaults
  private let enabledKey = "readyNotificationsEnabled"
  private var synchronizationGeneration = 0

  init(
    center: UNUserNotificationCenter = .current(),
    defaults: UserDefaults = .standard
  ) {
    self.center = center
    self.defaults = defaults
    notificationsEnabled = defaults.bool(forKey: enabledKey)
  }

  var statusText: String {
    guard notificationsEnabled else { return "Off" }
    switch authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return "On"
    case .denied:
      return "Blocked in Settings"
    case .notDetermined:
      return "Permission needed"
    @unknown default:
      return "Unavailable"
    }
  }

  func refreshAuthorizationStatus() async {
    authorizationStatus = await center.notificationSettings().authorizationStatus
    if authorizationStatus == .denied, notificationsEnabled {
      setEnabledPreference(false)
    }
  }

  @discardableResult
  func enable(for medications: [Medication]) async -> Bool {
    await refreshAuthorizationStatus()

    if authorizationStatus == .notDetermined {
      do {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
      } catch {
        setEnabledPreference(false)
        return false
      }
      await refreshAuthorizationStatus()
    }

    guard authorizationStatus == .authorized
      || authorizationStatus == .provisional
      || authorizationStatus == .ephemeral
    else {
      setEnabledPreference(false)
      return false
    }

    setEnabledPreference(true)
    await synchronize(medications: medications)
    return true
  }

  func disable() async {
    synchronizationGeneration += 1
    setEnabledPreference(false)
    await removeMedTrackerRequests()
  }

  func synchronize(medications: [Medication], at date: Date = .now) async {
    synchronizationGeneration += 1
    let generation = synchronizationGeneration

    await refreshAuthorizationStatus()
    guard generation == synchronizationGeneration else { return }

    guard notificationsEnabled,
      authorizationStatus == .authorized
        || authorizationStatus == .provisional
        || authorizationStatus == .ephemeral
    else {
      await removeMedTrackerRequests(ifCurrent: generation)
      return
    }

    let notifications = MedicationNotificationPlanner.notifications(for: medications, at: date)
    guard await removeMedTrackerRequests(ifCurrent: generation) else { return }

    for notification in notifications {
      guard generation == synchronizationGeneration else { return }

      let content = UNMutableNotificationContent()
      content.title = notification.title
      content.body = notification.body
      content.sound = .default

      let interval = max(1, notification.date.timeIntervalSince(date))
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
      let request = UNNotificationRequest(
        identifier: notification.identifier,
        content: content,
        trigger: trigger
      )
      try? await center.add(request)
    }
  }

  private func setEnabledPreference(_ enabled: Bool) {
    notificationsEnabled = enabled
    defaults.set(enabled, forKey: enabledKey)
  }

  private func removeMedTrackerRequests() async {
    let identifiers = await center.pendingNotificationRequests()
      .map(\.identifier)
      .filter { $0.hasPrefix(MedicationNotificationPlanner.identifierPrefix) }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  @discardableResult
  private func removeMedTrackerRequests(ifCurrent generation: Int) async -> Bool {
    let identifiers = await center.pendingNotificationRequests()
      .map(\.identifier)
      .filter { $0.hasPrefix(MedicationNotificationPlanner.identifierPrefix) }
    guard generation == synchronizationGeneration else { return false }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
    return true
  }
}
