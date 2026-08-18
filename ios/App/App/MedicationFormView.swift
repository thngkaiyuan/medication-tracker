import SwiftUI

struct MedicationFormView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let medication: Medication?
  let onDelete: (() -> Void)?

  @State private var name: String
  @State private var hoursBetweenDoses: Int
  @State private var usesDailyLimit: Bool
  @State private var dailyLimit: Int
  @State private var showingDeleteConfirmation = false

  init(medication: Medication? = nil, onDelete: (() -> Void)? = nil) {
    self.medication = medication
    self.onDelete = onDelete
    _name = State(initialValue: medication?.name ?? "")
    _hoursBetweenDoses = State(initialValue: Int(medication?.timeBetweenHours ?? 4))
    _usesDailyLimit = State(initialValue: (medication?.maxDosesPerDay ?? 0) > 0)
    _dailyLimit = State(initialValue: max(1, Int(medication?.maxDosesPerDay ?? 1)))
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        formHeader
        Divider()

        Form {
          Section {
            TextField("Medication Name", text: $name, axis: .vertical)
              .textInputAutocapitalization(.words)
              .submitLabel(.done)
              .lineLimit(1...2)
              .accessibilityIdentifier("Medication Name")
          } header: {
            sectionHeader("Medication")
          }

          Section {
            Stepper(value: $hoursBetweenDoses, in: 1...48) {
              LabeledContent("Minimum hours between doses", value: "\(hoursBetweenDoses)")
            }

            Toggle(isOn: $usesDailyLimit.animation()) {
              Text("Set a daily dose limit")
                .fixedSize(horizontal: false, vertical: true)
            }

            if usesDailyLimit {
              Stepper(value: $dailyLimit, in: 1...24) {
                LabeledContent("Maximum in any 24 hours", value: "\(dailyLimit)")
              }
            }
          } header: {
            sectionHeader("Schedule")
          } footer: {
            Text(
              "Colors reflect only the minimum interval and rolling 24-hour limit you enter. They do not determine whether a dose is medically safe. Follow the medication label and your clinician’s or pharmacist’s instructions."
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.mutedText)
            .fixedSize(horizontal: false, vertical: true)
          }

          if medication != nil {
            Section {
              Button("Delete Medication", role: .destructive) {
                showingDeleteConfirmation = true
              }
              .frame(maxWidth: .infinity, alignment: .center)
            }
          }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
      }
      .toolbar(.hidden, for: .navigationBar)
    }
    .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
    .interactiveDismissDisabled(false)
    .alert(
      "Delete \(medication?.name ?? "this medication")?", isPresented: $showingDeleteConfirmation
    ) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let medication {
          store.deleteMedication(id: medication.id)
          onDelete?()
        }
        dismiss()
      }
      .accessibilityIdentifier("Confirm Delete")
    } message: {
      Text("This permanently deletes the medication and all of its dose records.")
    }
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.subheadline)
      .foregroundStyle(.primary)
  }

  private var formHeader: some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: 0) {
          formHeaderTitle
          formHeaderActions
        }
      } else {
        ZStack {
          formHeaderTitle
          formHeaderActions
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  private var formHeaderTitle: some View {
    Text(medication == nil ? "Add Medication" : "Edit Medication")
      .font(.system(.title3, design: .default, weight: .light))
      .foregroundStyle(AppTheme.header)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var formHeaderActions: some View {
    HStack {
      Button { dismiss() } label: {
        Text("Cancel")
          .frame(minWidth: 72, minHeight: 44, alignment: .leading)
          .contentShape(Rectangle())
      }

      Spacer()

      Button { save() } label: {
        Text("Save")
          .frame(minWidth: 72, minHeight: 44, alignment: .trailing)
          .contentShape(Rectangle())
      }
      .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      .accessibilityIdentifier(medication == nil ? "Add" : "Save Changes")
    }
    .font(.system(.body, design: .default, weight: .light))
    .foregroundStyle(AppTheme.control)
  }

  private func save() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let updated = Medication(
      id: medication?.id ?? UUID().uuidString,
      name: trimmedName,
      timeBetweenHours: Double(hoursBetweenDoses),
      maxDosesPerDay: usesDailyLimit ? Double(dailyLimit) : 0,
      records: medication?.records ?? []
    )

    if medication == nil {
      store.add(updated)
    } else {
      store.update(updated)
    }
    dismiss()
  }
}
