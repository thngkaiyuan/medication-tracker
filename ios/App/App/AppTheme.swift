import SwiftUI

enum AppTheme {
  static let tint = Color(red: 146 / 255, green: 163 / 255, blue: 167 / 255)
  static let header = Color(red: 74 / 255, green: 74 / 255, blue: 74 / 255)
  static let readyStart = Color(red: 46 / 255, green: 125 / 255, blue: 50 / 255)
  static let readyEnd = Color(red: 76 / 255, green: 175 / 255, blue: 80 / 255)

  static func statusColors(for medication: Medication, at date: Date = .now) -> [Color] {
    if medication.isReady(at: date) {
      return [readyStart, readyEnd]
    }

    let progress = medication.progress(at: date)
    let red = (230 + (46 - 230) * progress) / 255
    let green = (81 + (125 - 81) * progress) / 255
    let blue = (0 + (50 - 0) * progress) / 255
    let base = Color(red: red, green: green, blue: blue)
    return [base, base]
  }
}

extension TimeInterval {
  var conciseDuration: String {
    let totalSeconds = max(0, Int(self.rounded(.down)))
    let hours = totalSeconds / 3_600
    let minutes = (totalSeconds % 3_600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    if minutes > 0 {
      return "\(minutes)m \(seconds)s"
    }
    return "\(seconds)s"
  }
}
