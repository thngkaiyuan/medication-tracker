import SwiftUI

struct MedicationDetailView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

          ScrollViewReader { scrollProxy in
            List {
              if medication.records.isEmpty {
                Text("No records yet.")
                  .font(.system(.body, design: .default, weight: .light))
                  .foregroundStyle(AppTheme.mutedText)
                  .frame(maxWidth: .infinity)
                  .padding(.top, 72)
                  .listRowSeparator(.hidden)
              } else {
                ForEach(Array(medication.sortedRecords.enumerated()), id: \.offset) {
                  index, timestamp in
                  recordRow(number: index + 1, timestamp: timestamp)
                    .id(index)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 10))
                    .listRowSeparatorTint(Color(uiColor: .systemGray5))
                }
              }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onAppear {
              scrollToLatestRecord(in: medication, using: scrollProxy)
            }
            .onChange(of: medication.records.count) { _ in
              scrollToLatestRecord(in: medication, using: scrollProxy)
            }
          }
        }
        .background(Color(uiColor: .systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: -footerOverlap) {
          bottomBar
            .offset(y: footerOverlap)
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
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) {
        backButton
        Spacer(minLength: 0)
        detailTitle(for: medication)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: true)
        Spacer(minLength: 0)
        editButton
      }

      VStack(spacing: 0) {
        HStack {
          backButton
          Spacer()
          editButton
        }

        detailTitle(for: medication)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 16)
          .padding(.bottom, 8)
      }
    }
    .foregroundStyle(AppTheme.control)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }

  private var backButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "chevron.left")
        .font(.title3.weight(.regular))
        .frame(width: 44, height: 44)
    }
    .accessibilityLabel("Back")
  }

  private var editButton: some View {
    Button {
      showingEditMedication = true
    } label: {
      Image(systemName: "pencil")
        .font(.body.weight(.light))
        .frame(width: 44, height: 44)
    }
    .accessibilityLabel("Edit Medication")
  }

  private func detailTitle(for medication: Medication) -> some View {
    Text(medication.name.uppercased())
      .font(.system(.title3, design: .default, weight: .light))
      .tracking(-0.3)
      .foregroundStyle(AppTheme.header)
      .multilineTextAlignment(.center)
      .layoutPriority(1)
  }

  private func recordRow(number: Int, timestamp: Double) -> some View {
    let date = Date(timeIntervalSince1970: timestamp / 1_000)

    return HStack(spacing: 12) {
      Text("\(number).")
        .font(.system(.body, design: .default, weight: .light))
        .frame(minWidth: 30, alignment: .trailing)

      Text(date.formatted(date: .abbreviated, time: .shortened))
        .font(.system(.body, design: .default, weight: .light))

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
      .tint(AppTheme.control)
    }
  }

  private var bottomBar: some View {
    Button {
      recordEditor = RecordEditor(timestamp: nil)
    } label: {
      Label("Add Manual Record", systemImage: "plus")
        .font(.system(.body, design: .default, weight: .light))
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.top, footerTopPadding)
        .padding(.bottom, footerBottomPadding)
    }
    .accessibilityLabel("Add Manual Record")
    .foregroundStyle(AppTheme.control)
    .background(Color(uiColor: .systemBackground).ignoresSafeArea(edges: .bottom))
    .overlay(alignment: .top) { Divider() }
  }

  private var footerOverlap: CGFloat {
    dynamicTypeSize.isAccessibilitySize ? 0 : 15
  }

  private var footerTopPadding: CGFloat {
    dynamicTypeSize.isAccessibilitySize ? 16 : 24
  }

  private var footerBottomPadding: CGFloat {
    dynamicTypeSize.isAccessibilitySize ? 16 : 8
  }

  private func scrollToLatestRecord(
    in medication: Medication,
    using proxy: ScrollViewProxy
  ) {
    guard !medication.records.isEmpty else { return }
    let latestIndex = medication.records.count - 1
    DispatchQueue.main.async {
      proxy.scrollTo(latestIndex, anchor: .bottom)
    }
  }
}

private struct RecordEditor: Identifiable {
  let id = UUID()
  let timestamp: Double?
}
