import Foundation

@MainActor
final class MedicationStore: ObservableObject {
  @Published private(set) var medications: [Medication] = []
  @Published var errorMessage: String?

  private let storageURL: URL
  private let encoder: JSONEncoder

  init(storageURL: URL? = nil) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    self.encoder = encoder

    if let storageURL {
      self.storageURL = storageURL
    } else {
      let applicationSupport = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first!
      let directory = applicationSupport.appendingPathComponent("MedTracker", isDirectory: true)
      try? FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      self.storageURL = directory.appendingPathComponent("medications.json")
    }

    load()
  }

  func medication(id: String) -> Medication? {
    medications.first { $0.id == id }
  }

  func add(_ medication: Medication) {
    do {
      try medication.validate()
      medications.append(medication)
      save()
    } catch {
      report(error)
    }
  }

  func update(_ medication: Medication) {
    do {
      try medication.validate()
      guard let index = medications.firstIndex(where: { $0.id == medication.id }) else {
        throw StoreError.medicationNotFound
      }
      medications[index] = medication
      save()
    } catch {
      report(error)
    }
  }

  func deleteMedication(id: String) {
    medications.removeAll { $0.id == id }
    save()
  }

  func logDose(for id: String, at date: Date = .now) {
    mutateMedication(id: id) { medication in
      medication.records.append(date.timeIntervalSince1970 * 1_000)
      medication.records.sort()
    }
  }

  func addRecord(to id: String, at date: Date) {
    logDose(for: id, at: date)
  }

  func updateRecord(for id: String, originalTimestamp: Double, to date: Date) {
    mutateMedication(id: id) { medication in
      guard let recordIndex = medication.records.firstIndex(of: originalTimestamp) else {
        throw StoreError.recordNotFound
      }
      medication.records[recordIndex] = date.timeIntervalSince1970 * 1_000
      medication.records.sort()
    }
  }

  func deleteRecord(for id: String, timestamp: Double) {
    mutateMedication(id: id) { medication in
      guard let recordIndex = medication.records.firstIndex(of: timestamp) else {
        throw StoreError.recordNotFound
      }
      medication.records.remove(at: recordIndex)
    }
  }

  func backupData() throws -> Data {
    try encoder.encode(medications)
  }

  func makeTemporaryBackup() throws -> URL {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    let fileName = "medication_tracker_backup_\(formatter.string(from: .now)).json"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try backupData().write(to: url, options: .atomic)
    return url
  }

  func decodeBackup(_ data: Data) throws -> [Medication] {
    let decoded = try JSONDecoder().decode([Medication].self, from: data)
    for medication in decoded {
      try medication.validate()
    }
    return decoded
  }

  func replaceWithBackup(_ medications: [Medication]) {
    self.medications = medications
    save()
  }

  private func mutateMedication(
    id: String,
    mutation: (inout Medication) throws -> Void
  ) {
    do {
      guard let index = medications.firstIndex(where: { $0.id == id }) else {
        throw StoreError.medicationNotFound
      }
      try mutation(&medications[index])
      save()
    } catch {
      report(error)
    }
  }

  private func load() {
    guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
    do {
      let data = try Data(contentsOf: storageURL)
      medications = try decodeBackup(data)
    } catch {
      report(StoreError.couldNotLoad(error.localizedDescription))
    }
  }

  private func save() {
    do {
      let data = try encoder.encode(medications)
      try data.write(to: storageURL, options: .atomic)
    } catch {
      report(StoreError.couldNotSave(error.localizedDescription))
    }
  }

  private func report(_ error: Error) {
    errorMessage = error.localizedDescription
  }
}

enum StoreError: LocalizedError {
  case medicationNotFound
  case recordNotFound
  case couldNotLoad(String)
  case couldNotSave(String)

  var errorDescription: String? {
    switch self {
    case .medicationNotFound:
      return "That medication could not be found."
    case .recordNotFound:
      return "That dose record could not be found."
    case .couldNotLoad(let details):
      return "Medication data could not be loaded. \(details)"
    case .couldNotSave(let details):
      return "Medication data could not be saved. \(details)"
    }
  }
}
