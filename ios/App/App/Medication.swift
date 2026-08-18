import Foundation

struct Medication: Identifiable, Codable, Equatable, Hashable {
  var id: String
  var name: String
  var timeBetweenHours: Double
  var maxDosesPerDay: Double
  var records: [Double]

  init(
    id: String = UUID().uuidString,
    name: String,
    timeBetweenHours: Double,
    maxDosesPerDay: Double = 0,
    records: [Double] = []
  ) {
    self.id = id
    self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.timeBetweenHours = timeBetweenHours
    self.maxDosesPerDay = maxDosesPerDay
    self.records = records
  }

  fileprivate enum CodingKeys: String, CodingKey {
    case id
    case name
    case timeBetweenHours
    case maxDosesPerDay
    case records
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let stringID = try? container.decode(String.self, forKey: .id) {
      id = stringID
    } else if let integerID = try? container.decode(Int64.self, forKey: .id) {
      id = String(integerID)
    } else {
      id = UUID().uuidString
    }

    name = try container.decode(String.self, forKey: .name)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    timeBetweenHours = try container.decodeFlexibleNumber(forKey: .timeBetweenHours)
    maxDosesPerDay = try container.decodeFlexibleNumberIfPresent(forKey: .maxDosesPerDay) ?? 0
    records = try container.decode([Double].self, forKey: .records)

    try validate()
  }

  func validate() throws {
    guard !name.isEmpty else {
      throw MedicationValidationError.emptyName
    }
    guard timeBetweenHours.isFinite, (1...48).contains(timeBetweenHours) else {
      throw MedicationValidationError.invalidDoseInterval
    }
    guard maxDosesPerDay.isFinite,
      maxDosesPerDay.rounded(.towardZero) == maxDosesPerDay,
      (0...24).contains(maxDosesPerDay)
    else {
      throw MedicationValidationError.invalidDailyLimit
    }
    guard records.allSatisfy(\.isFinite) else {
      throw MedicationValidationError.invalidRecords
    }
  }

  var sortedRecords: [Double] {
    records.sorted()
  }

  var lastDoseDate: Date? {
    records.max().map { Date(timeIntervalSince1970: $0 / 1_000) }
  }

  func nextDoseDate(after date: Date = .now) -> Date? {
    var nextDates: [Date] = []

    if let lastDoseDate {
      nextDates.append(lastDoseDate.addingTimeInterval(timeBetweenHours * 3_600))
    }

    let recentDoses = doseDatesInLast24Hours(at: date)
    let dailyLimit = Int(maxDosesPerDay)
    if dailyLimit > 0, recentDoses.count >= dailyLimit {
      let doseThatClearsLimit = recentDoses[recentDoses.count - dailyLimit]
      nextDates.append(doseThatClearsLimit.addingTimeInterval(24 * 3_600))
    }

    return nextDates.max()
  }

  func timeUntilNextDose(at date: Date = .now) -> TimeInterval {
    guard let nextDoseDate = nextDoseDate(after: date) else { return 0 }
    return max(0, nextDoseDate.timeIntervalSince(date))
  }

  func isReady(at date: Date = .now) -> Bool {
    timeUntilNextDose(at: date) == 0
  }

  func progress(at date: Date = .now) -> Double {
    guard let nextDoseDate = nextDoseDate(after: date),
      nextDoseDate > date,
      let lastDoseDate
    else {
      return 1
    }

    let totalWait = nextDoseDate.timeIntervalSince(lastDoseDate)
    guard totalWait > 0 else { return 1 }
    return min(1, max(0, date.timeIntervalSince(lastDoseDate) / totalWait))
  }

  func dosesInLast24Hours(at date: Date = .now) -> Int {
    doseDatesInLast24Hours(at: date).count
  }

  private func doseDatesInLast24Hours(at date: Date) -> [Date] {
    let cutoff = date.addingTimeInterval(-24 * 3_600)
    return records.lazy
      .map { Date(timeIntervalSince1970: $0 / 1_000) }
      .filter { $0 > cutoff && $0 <= date }
      .sorted()
  }
}

enum MedicationValidationError: LocalizedError {
  case emptyName
  case invalidDoseInterval
  case invalidDailyLimit
  case invalidRecords

  var errorDescription: String? {
    switch self {
    case .emptyName:
      return "A medication name is required."
    case .invalidDoseInterval:
      return "Hours between doses must be between 1 and 48."
    case .invalidDailyLimit:
      return "The daily dose limit must be between 0 and 24."
    case .invalidRecords:
      return "One or more dose records are invalid."
    }
  }
}

extension KeyedDecodingContainer where Key == Medication.CodingKeys {
  fileprivate func decodeFlexibleNumber(forKey key: Key) throws -> Double {
    if let value = try? decode(Double.self, forKey: key) {
      return value
    }
    if let value = try? decode(String.self, forKey: key), let number = Double(value) {
      return number
    }
    throw DecodingError.dataCorruptedError(
      forKey: key,
      in: self,
      debugDescription: "Expected a number or numeric string."
    )
  }

  fileprivate func decodeFlexibleNumberIfPresent(forKey key: Key) throws -> Double? {
    guard contains(key), !(try decodeNil(forKey: key)) else { return nil }
    return try decodeFlexibleNumber(forKey: key)
  }
}
