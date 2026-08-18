import SwiftUI

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        aboutHeader
        Divider()

        List {
          Section {
            VStack(spacing: 14) {
              Image(systemName: "pills.circle.fill")
                .font(.system(size: 58))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.tint)
              Text("MedTracker")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(AppTheme.header)
              Text("Private medication dose history, stored entirely on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
          }

          Section("Privacy") {
            Label("No accounts, analytics, ads, or tracking", systemImage: "hand.raised.fill")
            Label("Medication data stays on this device", systemImage: "iphone")
            Label("Data leaves only when you export a backup", systemImage: "square.and.arrow.up")

            Link(
              "Read the full privacy policy",
              destination: URL(
                string: "https://thngkaiyuan.github.io/medication-tracker/privacy.html")!
            )
          }

          Section("Medical disclaimer") {
            Text(
              "MedTracker is a personal record-keeping tool, not a medical device and not a substitute for professional medical advice. Follow the instructions of your clinician and pharmacist."
            )
          }

          Section("Support") {
            Link(
              "Get support on GitHub",
              destination: URL(string: "https://github.com/thngkaiyuan/medication-tracker/issues")!
            )
          }
        }
        .font(.system(size: 16, weight: .light))
      }
      .toolbar(.hidden, for: .navigationBar)
    }
  }

  private var aboutHeader: some View {
    ZStack {
      Text("Privacy & About")
        .font(.system(size: 19, weight: .light))
        .foregroundStyle(AppTheme.header)

      HStack {
        Spacer()
        Button("Done") { dismiss() }
          .frame(width: 72, height: 44, alignment: .trailing)
      }
    }
    .font(.system(size: 16, weight: .light))
    .foregroundStyle(AppTheme.tint)
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }
}
