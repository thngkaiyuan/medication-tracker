import SwiftUI

struct MedicationCard: View {
  let medication: Medication
  let now: Date
  let action: () -> Void

  private var statusText: String {
    let remaining = medication.timeUntilNextDose(at: now)
    return remaining == 0 ? "Ready to take" : "Next dose in \(remaining.conciseDuration)"
  }

  private var lastDoseText: String {
    guard let lastDose = medication.lastDoseDate else { return "No doses recorded" }
    return "Last \(lastDose.formatted(date: .abbreviated, time: .shortened))"
  }

  var body: some View {
    Button(action: action) {
      VStack(spacing: 7) {
        Text(medication.name.uppercased())
          .font(.title2.weight(.light))
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        Text(statusText)
          .font(.system(.subheadline, design: .default, weight: .light))
          .foregroundStyle(.white)

        Text(lastDoseText)
          .font(.system(.caption, design: .default, weight: .light))
          .foregroundStyle(.white)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 124)
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
    .accessibilityHint("Shows actions for this medication")
  }
}
