import SwiftUI

struct NotificationSettingsView: View {
  @EnvironmentObject private var store: MedicationStore
  @EnvironmentObject private var notificationManager: NotificationManager
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @State private var isChangingSetting = false
  @State private var showingDeniedAlert = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        notificationHeader
        Divider()

        Form {
          Section {
            Toggle(isOn: notificationsToggle) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Notify when wait limits clear")
                Text(notificationManager.statusText)
                  .font(.caption)
                  .foregroundStyle(AppTheme.mutedText)
              }
            }
            .disabled(isChangingSetting)
            .accessibilityIdentifier("Ready Notifications Toggle")
          } header: {
            sectionHeader("Ready notifications")
          } footer: {
            Text(
              "MedTracker can alert you when a medication’s waiting period clears based on the limits you entered. Notifications do not determine whether another dose is medically safe."
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.mutedText)
            .fixedSize(horizontal: false, vertical: true)
          }

          Section {
            VStack(alignment: .leading, spacing: 8) {
              Text("Acetaminophen: wait limits cleared")
                .font(.subheadline.weight(.semibold))
              Text("Ready based on the limits you entered.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
          } header: {
            sectionHeader("Example notification")
          } footer: {
            Text(
              "Medication names may appear on your Lock Screen depending on your iPhone notification-preview settings."
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.mutedText)
            .fixedSize(horizontal: false, vertical: true)
          }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
      }
      .toolbar(.hidden, for: .navigationBar)
    }
    .task {
      await notificationManager.refreshAuthorizationStatus()
    }
    .alert("Notifications are turned off", isPresented: $showingDeniedAlert) {
      Button("Not Now", role: .cancel) {}
      Button("Open Settings") {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
          openURL(settingsURL)
        }
      }
    } message: {
      Text("Allow notifications for MedTracker in Settings to turn on ready notifications.")
    }
  }

  private var notificationsToggle: Binding<Bool> {
    Binding(
      get: { notificationManager.notificationsEnabled },
      set: { enabled in
        isChangingSetting = true
        Task {
          if enabled {
            let didEnable = await notificationManager.enable(for: store.medications)
            showingDeniedAlert = !didEnable
          } else {
            await notificationManager.disable()
          }
          isChangingSetting = false
        }
      }
    )
  }

  private var notificationHeader: some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: 0) {
          notificationHeaderTitle
          HStack {
            Spacer()
            doneButton
          }
        }
      } else {
        ZStack {
          notificationHeaderTitle
          HStack {
            Spacer()
            doneButton
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  private var notificationHeaderTitle: some View {
    Text("Notifications")
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
    .foregroundStyle(AppTheme.control)
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.subheadline)
      .foregroundStyle(.primary)
  }
}
