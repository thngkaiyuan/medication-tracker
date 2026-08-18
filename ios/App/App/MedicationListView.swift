import SwiftUI
import UniformTypeIdentifiers

struct MedicationListView: View {
  @EnvironmentObject private var store: MedicationStore
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @State private var navigationPath: [String] = []
  @State private var actionMedicationID: String?
  @State private var showingAddMedication = false
  @State private var showingImporter = false
  @State private var showingImportConfirmation = false
  @State private var showingAbout = false
  @State private var pendingImport: [Medication]?
  @State private var shareItem: BackupShareItem?
  @State private var lastSharedBackupURL: URL?

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
          .font(.system(.title2, design: .default, weight: .light))
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
      .safeAreaInset(edge: .bottom, spacing: -footerOverlap) {
        bottomBar
          .offset(y: footerOverlap)
      }
    }
    .blur(radius: actionMedicationID == nil ? 0 : 8)
    .allowsHitTesting(actionMedicationID == nil)
    .accessibilityHidden(actionMedicationID != nil)
    .overlay {
      if let medication = actionMedication {
        medicationActionDialog(for: medication)
          .transition(.opacity.combined(with: .scale(scale: 0.97)))
      }
    }
    .animation(.easeOut(duration: 0.16), value: actionMedicationID)
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

  private func medicationActionDialog(for medication: Medication) -> some View {
    ZStack {
      Color.black.opacity(0.24)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
          actionMedicationID = nil
        }

      VStack(spacing: 0) {
        Text("Choose Action for \(medication.name)")
          .font(.system(.title3, design: .default, weight: .light))
          .foregroundStyle(AppTheme.header)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 24)
          .padding(.vertical, 20)

        Divider()

        HStack(spacing: 0) {
          Button {
            actionMedicationID = nil
            navigationPath.append(medication.id)
          } label: {
            Text("View Records")
              .frame(maxWidth: .infinity, minHeight: 56)
              .contentShape(Rectangle())
          }
          .foregroundStyle(AppTheme.mutedText)

          Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(width: 0.5, height: 56)

          Button {
            store.logDose(for: medication.id)
            actionMedicationID = nil
          } label: {
            Text("Log Dose")
              .frame(maxWidth: .infinity, minHeight: 56)
              .contentShape(Rectangle())
          }
          .foregroundStyle(AppTheme.control)
        }
        .font(.system(.body, design: .default, weight: .light))
      }
      .background(Color(uiColor: .systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .shadow(color: .black.opacity(0.14), radius: 14, y: 5)
      .frame(maxWidth: 400)
      .padding(20)
      .accessibilityElement(children: .contain)
      .accessibilityAddTraits(.isModal)
      .accessibilityLabel("Medication actions for \(medication.name)")
      .accessibilityAction(.escape) {
        actionMedicationID = nil
      }
    }
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
        .font(.largeTitle)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(AppTheme.tint)
        .accessibilityHidden(true)

      VStack(spacing: 6) {
        Text("No medications yet")
          .font(.title3.weight(.semibold))
          .fixedSize(horizontal: false, vertical: true)
        Text("Add a medication to start keeping a private dose history on this device.")
          .font(.subheadline)
          .foregroundStyle(AppTheme.mutedText)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
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
          .frame(width: 65)
          .padding(.top, footerTopPadding)
          .padding(.bottom, footerBottomPadding)
      }
      .accessibilityLabel("More options")

      Button {
        showingAddMedication = true
      } label: {
        Label("Add Medication", systemImage: "plus")
          .font(.system(.body, design: .default, weight: .light))
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
          .padding(.top, footerTopPadding)
          .padding(.bottom, footerBottomPadding)
      }
      .accessibilityIdentifier("Add Medication")
    }
    .foregroundStyle(AppTheme.control)
    .frame(maxWidth: 760)
    .overlay(alignment: .leading) {
      Rectangle()
        .fill(Color(uiColor: .separator))
        .frame(width: 0.5)
        .offset(x: 65)
        .ignoresSafeArea(edges: .bottom)
    }
    .frame(maxWidth: .infinity)
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
