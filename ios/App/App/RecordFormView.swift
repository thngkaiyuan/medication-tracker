import SwiftUI

struct RecordFormView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss

  let medicationID: String
  let originalTimestamp: Double?

  @State private var date: Date
  @State private var showingDeleteConfirmation = false

  init(medicationID: String, originalTimestamp: Double?) {
    self.medicationID = medicationID
    self.originalTimestamp = originalTimestamp
    _date = State(
      initialValue: originalTimestamp.map { Date(timeIntervalSince1970: $0 / 1_000) } ?? .now
    )
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        formHeader
        Divider()

        Form {
          Section {
            DatePicker(
              "Date and time",
              selection: $date,
              displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
          } header: {
            Text("Dose time")
              .font(.system(size: 13, weight: .light))
              .foregroundStyle(Color(uiColor: .systemGray))
          }

          if originalTimestamp != nil {
            Section {
              Button("Delete Record", role: .destructive) {
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
    .presentationDetents([.large])
    .alert("Delete this dose record?", isPresented: $showingDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let originalTimestamp {
          store.deleteRecord(for: medicationID, timestamp: originalTimestamp)
        }
        dismiss()
      }
    } message: {
      Text("This action cannot be undone.")
    }
  }

  private var formHeader: some View {
    ZStack {
      Text(originalTimestamp == nil ? "Add Manual Record" : "Edit Record Entry")
        .font(.system(size: 19, weight: .light))
        .foregroundStyle(AppTheme.header)

      HStack {
        Button("Cancel") { dismiss() }
          .frame(width: 72, height: 44, alignment: .leading)

        Spacer()

        Button("Save") { save() }
          .frame(width: 72, height: 44, alignment: .trailing)
          .accessibilityIdentifier(originalTimestamp == nil ? "Add Record" : "Save Changes")
      }
    }
    .font(.system(size: 16, weight: .light))
    .foregroundStyle(AppTheme.tint)
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  private func save() {
    if let originalTimestamp {
      store.updateRecord(for: medicationID, originalTimestamp: originalTimestamp, to: date)
    } else {
      store.addRecord(to: medicationID, at: date)
    }
    dismiss()
  }
}
