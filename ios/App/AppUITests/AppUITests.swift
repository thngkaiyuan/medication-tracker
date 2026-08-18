import XCTest

final class AppUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testMedicationLifecyclePersistsAcrossLaunches() throws {
    let suffix = String(UUID().uuidString.prefix(8))
    let medicationName = "UI Test \(suffix)"
    let renamedMedicationName = "Updated UI Test \(suffix)"
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(button(containing: "Add Medication", in: app).waitForExistence(timeout: 10))

    button(containing: "Add Medication", in: app).tap()

    let nameField = app.textFields["Medication Name"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    attachScreenshot(named: "add-medication")
    nameField.tap()
    nameField.typeText(medicationName)
    dismissKeyboard(in: app)
    submitAddMedication(named: medicationName, in: app)

    openMedicationActions(named: medicationName, in: app, expecting: "Log Dose")
    exactButton("Log Dose", in: app).tap()

    openMedicationActions(named: medicationName, in: app, expecting: "View Records")
    exactButton("View Records", in: app).tap()
    XCTAssertTrue(app.buttons["Edit Medication"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts["1."].waitForExistence(timeout: 10))
    attachScreenshot(named: "dose-history")

    app.buttons["Add Manual Record"].tap()
    let addRecordButton = app.buttons["Add Record"]
    XCTAssertTrue(addRecordButton.waitForExistence(timeout: 5))
    Thread.sleep(forTimeInterval: 0.5)
    attachScreenshot(named: "add-manual-record")
    addRecordButton.tap()
    XCTAssertTrue(app.staticTexts["2."].waitForExistence(timeout: 5))

    openRecordMenu(number: 2, in: app, expecting: "Edit Record")
    exactButton("Edit Record", in: app).tap()
    let saveRecordButton = app.buttons["Save Changes"]
    XCTAssertTrue(saveRecordButton.waitForExistence(timeout: 5))
    attachScreenshot(named: "edit-record")
    saveRecordButton.tap()
    XCTAssertTrue(app.staticTexts["2."].waitForExistence(timeout: 5))

    openRecordMenu(number: 2, in: app, expecting: "Delete Record")
    exactButton("Delete Record", in: app).tap()
    let confirmRecordDeletion = exactButton("Delete", in: app)
    XCTAssertTrue(confirmRecordDeletion.waitForExistence(timeout: 5))
    confirmRecordDeletion.tap()
    XCTAssertFalse(app.staticTexts["2."].exists)

    openEditForm(in: app, nameField: nameField)
    nameField.tap()
    nameField.clearAndTypeText(renamedMedicationName)
    dismissKeyboard(in: app)
    let renamedTitle = staticText(equalTo: renamedMedicationName, in: app)
    app.buttons["Save Changes"].tap()
    if !renamedTitle.waitForExistence(timeout: 1) {
      app.buttons["Save Changes"].tap()
    }
    XCTAssertTrue(renamedTitle.waitForExistence(timeout: 5))

    app.terminate()
    app.launch()
    XCTAssertTrue(element(containing: renamedMedicationName, in: app).waitForExistence(timeout: 5))

    removeTestMedicationIfPresent(in: app, named: renamedMedicationName)
    XCTAssertFalse(element(containing: renamedMedicationName, in: app).exists)
  }

  func testNativeExportPresentsShareSheet() throws {
    let medicationName = "Export Test \(String(UUID().uuidString.prefix(8)))"
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(button(containing: "Add Medication", in: app).waitForExistence(timeout: 10))
    button(containing: "Add Medication", in: app).tap()

    let nameField = app.textFields["Medication Name"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    nameField.tap()
    nameField.typeText(medicationName)
    dismissKeyboard(in: app)
    submitAddMedication(named: medicationName, in: app)

    app.buttons["More options"].tap()
    XCTAssertTrue(exactButton("Privacy & About", in: app).waitForExistence(timeout: 5))
    exactButton("Privacy & About", in: app).tap()
    XCTAssertTrue(app.staticTexts["Privacy & About"].waitForExistence(timeout: 5))
    attachScreenshot(named: "privacy-and-about")
    exactButton("Done", in: app).tap()

    app.buttons["More options"].tap()
    XCTAssertTrue(app.buttons["Export Backup"].waitForExistence(timeout: 5))
    exactButton("Export Backup", in: app).tap()

    let shareSheet = app.otherElements["ActivityListView"]
    XCTAssertTrue(shareSheet.waitForExistence(timeout: 10))
  }

  private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
  }

  private func attachScreenshot(named name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func exactButton(_ text: String, in app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label == %@", text)).firstMatch
  }

  private func element(containing text: String, in app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(text)."))
      .firstMatch
  }

  private func staticText(equalTo text: String, in app: XCUIApplication) -> XCUIElement {
    app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", text)).firstMatch
  }

  private func dismissKeyboard(in app: XCUIApplication) {
    let doneButton = app.buttons["Done"]
    if doneButton.waitForExistence(timeout: 1) {
      doneButton.tap()
      return
    }

    let hideKeyboardButton = app.buttons["Hide keyboard"]
    if hideKeyboardButton.waitForExistence(timeout: 1) {
      hideKeyboardButton.tap()
    }
  }

  private func openEditForm(in app: XCUIApplication, nameField: XCUIElement) {
    let editButton = app.buttons["Edit Medication"]
    editButton.tap()
    if !nameField.waitForExistence(timeout: 1) {
      editButton.tap()
    }
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
  }

  private func submitAddMedication(named name: String, in app: XCUIApplication) {
    let medication = element(containing: name, in: app)
    let addButton = app.buttons["Add"]
    addButton.tap()
    if !medication.waitForExistence(timeout: 1) {
      addButton.tap()
    }
    XCTAssertTrue(medication.waitForExistence(timeout: 5))
  }

  private func openMedicationActions(
    named name: String, in app: XCUIApplication, expecting action: String
  ) {
    let medication = element(containing: name, in: app)
    let actionButton = exactButton(action, in: app)
    medication.tap()
    if !actionButton.waitForExistence(timeout: 1) {
      medication.tap()
    }
    XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
  }

  private func openRecordMenu(number: Int, in app: XCUIApplication, expecting action: String) {
    let recordMenu = app.buttons["Edit or delete record \(number)"]
    let actionButton = exactButton(action, in: app)
    recordMenu.tap()
    if !actionButton.waitForExistence(timeout: 1) {
      recordMenu.tap()
    }
    XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
  }

  private func removeTestMedicationIfPresent(in app: XCUIApplication, named name: String) {
    let medication = element(containing: name, in: app)
    guard medication.exists else { return }

    openMedicationActions(named: name, in: app, expecting: "View Records")
    exactButton("View Records", in: app).tap()
    let nameField = app.textFields["Medication Name"]
    openEditForm(in: app, nameField: nameField)
    let deleteButton = app.buttons["Delete Medication"]
    XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
    deleteButton.tap()

    let confirmButton = app.buttons.matching(identifier: "Confirm Delete").firstMatch
    if !confirmButton.waitForExistence(timeout: 1) {
      deleteButton.tap()
    }
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
    confirmButton.tap()
    XCTAssertTrue(button(containing: "Add Medication", in: app).waitForExistence(timeout: 5))
  }
}

extension XCUIElement {
  fileprivate func clearAndTypeText(_ text: String) {
    guard let currentValue = value as? String else {
      typeText(text)
      return
    }

    coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    let deleteSequence = String(
      repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
    typeText(deleteSequence)
    typeText(text)
  }
}
