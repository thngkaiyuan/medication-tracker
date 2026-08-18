import SwiftUI

struct MedicationDetailView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss

  let medicationID: String

  @State private var showingEditMedication = false
  @State private var recordEditor: RecordEditor?
  @State private var recordPendingDeletion: Double?
  @State private var showingDeleteRecordConfirmation = false

  var body: some View {
    Group {
      if let medication = store.medication(id: medicationID) {
        VStack(spacing: 0) {
          detailHeader(for: medication)
          Divider()

          List {
            if medication.records.isEmpty {
              Text("No records yet.")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color(uiColor: .systemGray2))
                .frame(maxWidth: .infinity)
                .padding(.top, 72)
                .listRowSeparator(.hidden)
            } else {
              ForEach(Array(medication.sortedRecords.enumerated()), id: \.offset) {
                index, timestamp in
                recordRow(number: index + 1, timestamp: timestamp)
                  .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 10))
                  .listRowSeparatorTint(Color(uiColor: .systemGray5))
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
        }
        .background(Color(uiColor: .systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          bottomBar
        }
        .sheet(isPresented: $showingEditMedication) {
          MedicationFormView(medication: medication) {
            dismiss()
          }
          .environmentObject(store)
        }
        .sheet(item: $recordEditor) { editor in
          RecordFormView(
            medicationID: medicationID,
            originalTimestamp: editor.timestamp
          )
          .environmentObject(store)
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
          Text("Medication Not Found")
            .font(.headline)
          Text("It may have been deleted or replaced during an import.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
      }
    }
    .alert("Delete this dose record?", isPresented: $showingDeleteRecordConfirmation) {
      Button("Cancel", role: .cancel) {
        recordPendingDeletion = nil
      }
      Button("Delete", role: .destructive) {
        if let recordPendingDeletion {
          store.deleteRecord(for: medicationID, timestamp: recordPendingDeletion)
        }
        recordPendingDeletion = nil
      }
    } message: {
      Text("This action cannot be undone.")
    }
  }

  private func detailHeader(for medication: Medication) -> some View {
    HStack(spacing: 8) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.title3.weight(.regular))
          .frame(width: 44, height: 44)
      }
      .accessibilityLabel("Back")

      Spacer(minLength: 0)

      Text(medication.name.uppercased())
        .font(.system(size: 19, weight: .light))
        .tracking(-0.3)
        .foregroundStyle(AppTheme.header)
        .lineLimit(1)

      Spacer(minLength: 0)

      Button {
        showingEditMedication = true
      } label: {
        Image(systemName: "pencil")
          .font(.body.weight(.light))
          .frame(width: 44, height: 44)
      }
      .accessibilityLabel("Edit Medication")
    }
    .foregroundStyle(AppTheme.tint)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }

  private func recordRow(number: Int, timestamp: Double) -> some View {
    let date = Date(timeIntervalSince1970: timestamp / 1_000)

    return HStack(spacing: 12) {
      Text("\(number).")
        .font(.system(size: 17, weight: .light))
        .frame(minWidth: 30, alignment: .trailing)

      Text(date.formatted(date: .abbreviated, time: .shortened))
        .font(.system(size: 17, weight: .light))

      Spacer()

      Menu {
        Button {
          recordEditor = RecordEditor(timestamp: timestamp)
        } label: {
          Label("Edit Record", systemImage: "pencil")
        }
        Button(role: .destructive) {
          recordPendingDeletion = timestamp
          showingDeleteRecordConfirmation = true
        } label: {
          Label("Delete Record", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.body)
          .foregroundStyle(Color(uiColor: .systemGray))
          .frame(width: 44, height: 52)
      }
      .accessibilityLabel("Edit or delete record \(number)")
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button(role: .destructive) {
        recordPendingDeletion = timestamp
        showingDeleteRecordConfirmation = true
      } label: {
        Label("Delete", systemImage: "trash")
      }

      Button {
        recordEditor = RecordEditor(timestamp: timestamp)
      } label: {
        Label("Edit", systemImage: "pencil")
      }
      .tint(AppTheme.tint)
    }
  }

  private var bottomBar: some View {
    Button {
      recordEditor = RecordEditor(timestamp: nil)
    } label: {
      Label("Add Manual Record", systemImage: "plus")
        .font(.system(size: 17, weight: .light))
        .frame(maxWidth: .infinity)
        .frame(height: 58)
    }
    .accessibilityLabel("Add Manual Record")
    .foregroundStyle(AppTheme.tint)
    .background(Color(uiColor: .systemBackground).ignoresSafeArea(edges: .bottom))
    .overlay(alignment: .top) { Divider() }
    .overlay(alignment: .bottom) { Divider() }
  }
}

private struct RecordEditor: Identifiable {
  let id = UUID()
  let timestamp: Double?
}
