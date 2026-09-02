import SwiftUI

struct RecordFormView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
              .font(.system(.caption, design: .default, weight: .light))
              .foregroundStyle(AppTheme.mutedText)
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
    Text(originalTimestamp == nil ? "Add Manual Record" : "Edit Record Entry")
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
      .accessibilityIdentifier(originalTimestamp == nil ? "Add Record" : "Save Changes")
    }
    .font(.system(.body, design: .default, weight: .light))
    .foregroundStyle(AppTheme.control)
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
