import SwiftUI
import UniformTypeIdentifiers

struct MedicationListView: View {
  @EnvironmentObject private var store: MedicationStore

  @State private var navigationPath: [String] = []
  @State private var actionMedicationID: String?
  @State private var showingAddMedication = false
  @State private var showingImporter = false
  @State private var showingImportConfirmation = false
  @State private var showingAbout = false
  @State private var pendingImport: [Medication]?
  @State private var shareItem: BackupShareItem?
  @State private var lastSharedBackupURL: URL?

  private var showingMedicationActions: Binding<Bool> {
    Binding(
      get: { actionMedicationID != nil },
      set: { if !$0 { actionMedicationID = nil } }
    )
  }

  private var showingStoreError: Binding<Bool> {
    Binding(
      get: { store.errorMessage != nil },
      set: { if !$0 { store.errorMessage = nil } }
    )
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        Text("MedTracker")
          .font(.system(size: 24, weight: .light))
          .tracking(-0.5)
          .foregroundStyle(AppTheme.header)
          .frame(maxWidth: .infinity)
          .padding(.top, 8)
          .padding(.bottom, 20)

        Group {
          if store.medications.isEmpty {
            emptyState
          } else {
            medicationList
          }
        }
      }
      .background(Color(uiColor: .systemBackground))
      .toolbar(.hidden, for: .navigationBar)
      .navigationDestination(for: String.self) { medicationID in
        MedicationDetailView(medicationID: medicationID)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        bottomBar
      }
    }
    .sheet(isPresented: $showingAddMedication) {
      MedicationFormView()
        .environmentObject(store)
    }
    .sheet(item: $shareItem, onDismiss: cleanUpSharedBackup) { item in
      ShareSheet(activityItems: [item.url])
        .ignoresSafeArea()
    }
    .sheet(isPresented: $showingAbout) {
      AboutView()
    }
    .fileImporter(
      isPresented: $showingImporter,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false,
      onCompletion: handleImportSelection
    )
    .confirmationDialog(
      actionMedication?.name ?? "Medication",
      isPresented: showingMedicationActions,
      titleVisibility: .visible
    ) {
      if let medication = actionMedication {
        Button {
          store.logDose(for: medication.id)
          actionMedicationID = nil
        } label: {
          Label("Log Dose", systemImage: "checkmark.circle")
        }
        Button {
          actionMedicationID = nil
          navigationPath.append(medication.id)
        } label: {
          Label("View Records", systemImage: "list.bullet.rectangle")
        }
      }
      Button("Cancel", role: .cancel) {
        actionMedicationID = nil
      }
    }
    .alert("Replace current data?", isPresented: $showingImportConfirmation) {
      Button("Cancel", role: .cancel) {
        pendingImport = nil
      }
      Button("Import", role: .destructive) {
        if let pendingImport {
          store.replaceWithBackup(pendingImport)
        }
        pendingImport = nil
      }
    } message: {
      Text(
        "Importing this backup replaces all medications and dose records currently on this device.")
    }
    .alert("Something went wrong", isPresented: showingStoreError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(store.errorMessage ?? "Please try again.")
    }
  }

  private var actionMedication: Medication? {
    guard let actionMedicationID else { return nil }
    return store.medication(id: actionMedicationID)
  }

  private var medicationList: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      ScrollView {
        LazyVStack(spacing: 1) {
          ForEach(store.medications) { medication in
            MedicationCard(medication: medication, now: context.date) {
              actionMedicationID = medication.id
            }
          }
        }
        .frame(maxWidth: .infinity)
      }
      .background(Color(uiColor: .systemBackground))
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "pills.circle.fill")
        .font(.system(size: 58))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(AppTheme.tint)

      VStack(spacing: 6) {
        Text("No medications yet")
          .font(.title3.weight(.semibold))
        Text("Add a medication to start keeping a private dose history on this device.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: 340)
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var bottomBar: some View {
    HStack(spacing: 0) {
      Menu {
        Button {
          exportBackup()
        } label: {
          Label("Export Backup", systemImage: "square.and.arrow.up")
        }
        .disabled(store.medications.isEmpty)

        Button {
          showingImporter = true
        } label: {
          Label("Import Backup", systemImage: "square.and.arrow.down")
        }

        Divider()

        Button {
          showingAbout = true
        } label: {
          Label("Privacy & About", systemImage: "info.circle")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.body.weight(.light))
          .frame(width: 65, height: 58)
      }
      .accessibilityLabel("More options")
      .overlay(alignment: .trailing) { Divider() }

      Button {
        showingAddMedication = true
      } label: {
        Label("Add Medication", systemImage: "plus")
          .font(.system(size: 17, weight: .light))
          .frame(maxWidth: .infinity)
          .frame(height: 58)
      }
      .accessibilityIdentifier("Add Medication")
    }
    .foregroundStyle(AppTheme.tint)
    .frame(maxWidth: 760)
    .frame(maxWidth: .infinity)
    .background(Color(uiColor: .systemBackground).ignoresSafeArea(edges: .bottom))
    .overlay(alignment: .top) { Divider() }
    .overlay(alignment: .bottom) { Divider() }
  }

  private func exportBackup() {
    do {
      cleanUpSharedBackup()
      let url = try store.makeTemporaryBackup()
      lastSharedBackupURL = url
      shareItem = BackupShareItem(url: url)
    } catch {
      store.errorMessage = error.localizedDescription
    }
  }

  private func cleanUpSharedBackup() {
    guard let url = lastSharedBackupURL else { return }
    try? FileManager.default.removeItem(at: url)
    lastSharedBackupURL = nil
  }

  private func handleImportSelection(_ result: Result<[URL], Error>) {
    do {
      guard let url = try result.get().first else { return }
      let hasAccess = url.startAccessingSecurityScopedResource()
      defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
      pendingImport = try store.decodeBackup(Data(contentsOf: url))
      showingImportConfirmation = true
    } catch {
      store.errorMessage = "This backup could not be imported. \(error.localizedDescription)"
    }
  }
}

private struct BackupShareItem: Identifiable {
  let id = UUID()
  let url: URL
}
