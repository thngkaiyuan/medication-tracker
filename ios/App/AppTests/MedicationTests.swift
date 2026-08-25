import XCTest

@testable import App

@MainActor
final class MedicationTests: XCTestCase {
  func testPWABackupDecodesAndKeepsItsJSONContract() throws {
    let storageURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("medtracker-tests-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: storageURL) }

    let store = MedicationStore(storageURL: storageURL)
    let pwaBackup = Data(
      #"[{"id":1723400000000,"name":"  Example  ","timeBetweenHours":"6","maxDosesPerDay":"4","records":[1723400000000,1723421600000]}]"#
        .utf8)

    let medications = try store.decodeBackup(pwaBackup)
    XCTAssertEqual(medications.count, 1)
    XCTAssertEqual(medications[0].id, "1723400000000")
    XCTAssertEqual(medications[0].name, "Example")
    XCTAssertEqual(medications[0].timeBetweenHours, 6)
    XCTAssertEqual(medications[0].maxDosesPerDay, 4)
    XCTAssertEqual(medications[0].records, [1_723_400_000_000, 1_723_421_600_000])

    store.replaceWithBackup(medications)
    let roundTrip = try XCTUnwrap(
      JSONSerialization.jsonObject(with: store.backupData()) as? [[String: Any]]
    ).first
    XCTAssertEqual(roundTrip?["id"] as? String, "1723400000000")
    XCTAssertEqual(roundTrip?["name"] as? String, "Example")
    XCTAssertEqual(roundTrip?["timeBetweenHours"] as? Double, 6)
    XCTAssertEqual(roundTrip?["maxDosesPerDay"] as? Double, 4)
    XCTAssertEqual((roundTrip?["records"] as? [Double])?.count, 2)
  }

  func testMedicationAndRecordsPersistAcrossStoreInstances() throws {
    let storageURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("medtracker-tests-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: storageURL) }

    let initialStore = MedicationStore(storageURL: storageURL)
    initialStore.add(Medication(id: "persistent", name: "Test", timeBetweenHours: 8))
    initialStore.logDose(for: "persistent", at: Date(timeIntervalSince1970: 123))

    let reloadedStore = MedicationStore(storageURL: storageURL)
    XCTAssertEqual(reloadedStore.medications.count, 1)
    XCTAssertEqual(reloadedStore.medications[0].id, "persistent")
    XCTAssertEqual(reloadedStore.medications[0].records, [123_000])
  }

  func testMalformedBackupIsRejected() throws {
    let store = MedicationStore(
      storageURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("medtracker-tests-\(UUID().uuidString).json")
    )

    XCTAssertThrowsError(
      try store.decodeBackup(
        Data(
          #"[{"id":"1","name":"Test","timeBetweenHours":0,"maxDosesPerDay":0,"records":[]}]"#.utf8))
    )
    XCTAssertThrowsError(
      try store.decodeBackup(
        Data(
          #"[{"id":"1","name":"Test","timeBetweenHours":4,"maxDosesPerDay":0,"records":["bad"]}]"#
            .utf8))
    )
  }

  func testReadinessWaitsForBothIntervalAndRolling24HourLimit() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
    let now = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 12)))
    let firstDose = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 8)))
    let secondDose = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 10)))
    let firstDoseClears = firstDose.addingTimeInterval(24 * 3_600)
    let medication = Medication(
      name: "Example",
      timeBetweenHours: 1,
      maxDosesPerDay: 2,
      records: [
        firstDose.timeIntervalSince1970 * 1_000,
        secondDose.timeIntervalSince1970 * 1_000,
      ]
    )

    XCTAssertFalse(medication.isReady(at: now))
    XCTAssertEqual(medication.nextDoseDate(after: now), firstDoseClears)
    XCTAssertEqual(
      medication.timeUntilNextDose(at: now),
      20 * 3_600,
      accuracy: 0.001
    )
  }

  func testFutureRecordsDoNotCountTowardRolling24HourLimit() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
    let now = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 12)))
    let earlierDose = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 8)))
    let futureRecord = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 18)))
    let medication = Medication(
      name: "Example",
      timeBetweenHours: 1,
      maxDosesPerDay: 2,
      records: [
        earlierDose.timeIntervalSince1970 * 1_000,
        futureRecord.timeIntervalSince1970 * 1_000,
      ]
    )

    XCTAssertEqual(medication.dosesInLast24Hours(at: now), 1)
  }

  func testNotificationPlannerSchedulesOnlyWaitingMedications() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let waiting = Medication(
      id: "waiting",
      name: "Acetaminophen",
      timeBetweenHours: 6,
      records: [now.addingTimeInterval(-3_600).timeIntervalSince1970 * 1_000]
    )
    let ready = Medication(
      id: "ready",
      name: "Cetirizine",
      timeBetweenHours: 4
    )

    let notifications = MedicationNotificationPlanner.notifications(
      for: [waiting, ready],
      at: now
    )

    XCTAssertEqual(notifications.count, 1)
    XCTAssertEqual(notifications[0].identifier, "medtracker.ready.waiting")
    XCTAssertEqual(notifications[0].title, "Acetaminophen: wait limits cleared")
    XCTAssertEqual(notifications[0].body, "Ready based on the limits you entered.")
    XCTAssertEqual(notifications[0].date, now.addingTimeInterval(5 * 3_600))
  }

  func testNotificationPlannerUsesRollingDailyLimitWhenItClearsLater() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let firstDose = now.addingTimeInterval(-5 * 3_600)
    let latestDose = now.addingTimeInterval(-3_600)
    let medication = Medication(
      id: "daily-limit",
      name: "Ibuprofen",
      timeBetweenHours: 4,
      maxDosesPerDay: 2,
      records: [
        firstDose.timeIntervalSince1970 * 1_000,
        latestDose.timeIntervalSince1970 * 1_000,
      ]
    )

    let notification = try XCTUnwrap(
      MedicationNotificationPlanner.notifications(for: [medication], at: now).first
    )

    XCTAssertEqual(notification.date, firstDose.addingTimeInterval(24 * 3_600))
  }
}
