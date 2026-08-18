import SwiftUI

struct MedicationFormView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss

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
            TextField("Medication Name", text: $name)
              .textInputAutocapitalization(.words)
              .submitLabel(.done)
              .accessibilityIdentifier("Medication Name")
          } header: {
            sectionHeader("Medication")
          }

          Section {
            Stepper(value: $hoursBetweenDoses, in: 1...48) {
              LabeledContent("Hours between doses", value: "\(hoursBetweenDoses)")
            }

            Toggle("Set a daily dose limit", isOn: $usesDailyLimit.animation())

            if usesDailyLimit {
              Stepper(value: $dailyLimit, in: 1...24) {
                LabeledContent("Maximum per day", value: "\(dailyLimit)")
              }
            }
          } header: {
            sectionHeader("Schedule")
          } footer: {
            Text(
              "MedTracker records your schedule but does not recommend or enforce a dosage. Follow your clinician’s or pharmacist’s instructions."
            )
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
        .font(.system(size: 16, weight: .light))
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
      }
      .toolbar(.hidden, for: .navigationBar)
    }
    .presentationDetents([.medium, .large])
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
      .font(.system(size: 13, weight: .light))
      .foregroundStyle(Color(uiColor: .systemGray))
  }

  private var formHeader: some View {
    ZStack {
      Text(medication == nil ? "Add Medication" : "Edit Medication")
        .font(.system(size: 19, weight: .light))
        .foregroundStyle(AppTheme.header)

      HStack {
        Button("Cancel") { dismiss() }
          .frame(width: 72, height: 44, alignment: .leading)

        Spacer()

        Button("Save") { save() }
          .frame(width: 72, height: 44, alignment: .trailing)
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityIdentifier(medication == nil ? "Add" : "Save Changes")
      }
    }
    .font(.system(size: 16, weight: .light))
    .foregroundStyle(AppTheme.tint)
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
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
