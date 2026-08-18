import SwiftUI

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        aboutHeader
        Divider()

        List {
          Section {
            VStack(spacing: 14) {
              Image(systemName: "pills.circle.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.control)
                .accessibilityHidden(true)
              Text("MedTracker")
                .font(.system(.title2, design: .default, weight: .light))
                .foregroundStyle(AppTheme.header)
              Text("Private medication dose history, stored entirely on your device.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
          }

          Section {
            privacyLabel("No accounts, analytics, ads, or tracking", icon: "hand.raised.fill")
            privacyLabel("Medication data stays on this device", icon: "iphone")
            privacyLabel("Data leaves only when you export a backup", icon: "square.and.arrow.up")

            Link(
              "Read the full privacy policy",
              destination: URL(
                string: "https://thngkaiyuan.github.io/medication-tracker/privacy.html")!
            )
            .font(.body)
          } header: {
            sectionHeader("Privacy")
          }

          Section {
            Text(
              "A tile’s color progresses as its waiting period elapses. The wait clears only after both the minimum hours since the latest logged dose and the optional maximum you entered for any rolling 24-hour period. This calculation uses only your entries and does not determine whether another dose is medically safe."
            )
            .fixedSize(horizontal: false, vertical: true)
          } header: {
            sectionHeader("How colors work")
          }

          Section {
            Text(
              "MedTracker is a personal record-keeping tool, not a medical device and not a substitute for professional medical advice. Follow the instructions of your clinician and pharmacist."
            )
            .fixedSize(horizontal: false, vertical: true)
          } header: {
            sectionHeader("Medical disclaimer")
          }

          Section {
            Link(
              "Get support on GitHub",
              destination: URL(string: "https://github.com/thngkaiyuan/medication-tracker/issues")!
            )
            .font(.body)
          } header: {
            sectionHeader("Support")
          }
        }
      }
      .toolbar(.hidden, for: .navigationBar)
    }
  }

  private var aboutHeader: some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: 0) {
          aboutHeaderTitle
          HStack {
            Spacer()
            doneButton
          }
        }
      } else {
        ZStack {
          aboutHeaderTitle
          HStack {
            Spacer()
            doneButton
          }
        }
      }
    }
    .foregroundStyle(AppTheme.control)
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  private var aboutHeaderTitle: some View {
    Text("Privacy & About")
      .font(.system(.title3, design: .default, weight: .light))
      .foregroundStyle(AppTheme.header)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var doneButton: some View {
    Button { dismiss() } label: {
      Text("Done")
        .frame(minWidth: 72, minHeight: 44, alignment: .trailing)
        .contentShape(Rectangle())
    }
    .font(.body)
  }

  private func privacyLabel(_ title: String, icon: String) -> some View {
    Label {
      Text(title)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: icon)
    }
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.subheadline)
      .foregroundStyle(.primary)
      .fixedSize(horizontal: false, vertical: true)
  }
}
