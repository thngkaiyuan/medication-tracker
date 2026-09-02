import SwiftUI

struct MedicationCard: View {
  let medication: Medication
  let now: Date
  let action: () -> Void

  private var statusText: String {
    let remaining = medication.timeUntilNextDose(at: now)
    return remaining == 0
      ? "Ready based on your limits"
      : "Wait limits clear in \(remaining.conciseDuration)"
  }

  private var lastDoseText: String {
    guard let lastDose = medication.lastDoseDate else { return "Last: Never" }
    let formattedDate = lastDose.formatted(
      .dateTime
        .weekday(.abbreviated)
        .month(.abbreviated)
        .day()
        .year()
        .hour()
        .minute()
    )
    return "Last: \(formattedDate)"
  }

  var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        Text(medication.name.uppercased())
          .font(.system(size: 24, weight: .light))
          .frame(minHeight: 38.4)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        VStack(spacing: 6) {
          Text(statusText)
            .font(.system(size: 12, weight: .light))
            .foregroundStyle(.white.opacity(0.85))
            .frame(minHeight: 19.2)

          Text(lastDoseText)
            .font(.system(size: 10, weight: .light))
            .foregroundStyle(.white.opacity(0.75))
            .frame(minHeight: 16)
        }
        .padding(.top, 8)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 128)
      .background(
        LinearGradient(
          colors: AppTheme.statusColors(for: medication, at: now),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(medication.name). \(statusText). \(lastDoseText)")
    .accessibilityHint(
      "Reflects only your entered interval and rolling 24-hour limit. Shows actions for this medication")
  }
}
