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

        let nameField = app.textFields.matching(
            NSPredicate(format: "label == %@", "Medication Name")
        ).firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(medicationName)
        dismissKeyboard(in: app)
        submitAddMedication(named: medicationName, in: app)

        openMedicationActions(named: medicationName, in: app, expecting: "Log Dose")
        app.buttons["Log Dose"].tap()

        openMedicationActions(named: medicationName, in: app, expecting: "View Records")
        app.buttons["View Records"].tap()
        XCTAssertTrue(app.buttons["Edit Medication"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "1.")
        ).firstMatch.waitForExistence(timeout: 10))

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

        let nameField = app.textFields.matching(
            NSPredicate(format: "label == %@", "Medication Name")
        ).firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(medicationName)
        dismissKeyboard(in: app)
        submitAddMedication(named: medicationName, in: app)

        app.buttons["More options"].tap()
        XCTAssertTrue(app.buttons["Export Data"].waitForExistence(timeout: 5))
        app.buttons["Export Data"].tap()

        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10))
    }

    private func button(containing text: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
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

    private func openMedicationActions(named name: String, in app: XCUIApplication, expecting action: String) {
        let medication = element(containing: name, in: app)
        let actionButton = app.buttons[action]
        medication.tap()
        if !actionButton.waitForExistence(timeout: 1) {
            medication.tap()
        }
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
    }

    private func removeTestMedicationIfPresent(in app: XCUIApplication, named name: String) {
        let medication = element(containing: name, in: app)
        guard medication.exists else { return }

        openMedicationActions(named: name, in: app, expecting: "View Records")
        app.buttons["View Records"].tap()
        let nameField = app.textFields.matching(
            NSPredicate(format: "label == %@", "Medication Name")
        ).firstMatch
        openEditForm(in: app, nameField: nameField)
        let deleteButton = app.buttons["Delete Medication"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmButton = app.buttons["Confirm Delete"]
        if !confirmButton.waitForExistence(timeout: 1) {
            deleteButton.tap()
        }
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()
        XCTAssertTrue(button(containing: "Add Medication", in: app).waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let currentValue = value as? String else {
            typeText(text)
            return
        }

        coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteSequence)
        typeText(text)
    }
}
