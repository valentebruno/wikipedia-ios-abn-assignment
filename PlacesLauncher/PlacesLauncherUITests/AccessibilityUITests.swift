import XCTest

final class AccessibilityUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-test-mode"]
        app.launch()
    }

    func test_homeScreen_hasAccessibleCoreElements() {
        XCTAssertTrue(app.buttons["toolbar.reload"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toolbar.customCoordinates"].exists)
        XCTAssertTrue(app.buttons["toolbar.accessibility"].exists)

        XCTAssertTrue(app.descendants(matching: .any)["list.locations"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons.matching(identifier: "locationRow").count, 1)
    }

    func test_customCoordinatesSheet_accessibilityFieldsExist() {
        let customCoordinatesButton = app.buttons["toolbar.customCoordinates"]
        XCTAssertTrue(customCoordinatesButton.waitForExistence(timeout: 5))
        customCoordinatesButton.tap()

        XCTAssertTrue(app.textFields["customCoordinates.latitude"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["customCoordinates.longitude"].exists)
        XCTAssertTrue(app.buttons["customCoordinates.openButton"].exists)
        XCTAssertTrue(app.buttons["customCoordinates.doneButton"].exists)

        app.buttons["customCoordinates.doneButton"].tap()
        XCTAssertTrue(customCoordinatesButton.waitForExistence(timeout: 5))
    }

    func test_accessibilitySettingsSheet_exposesExpectedToggles() {
        let accessibilityButton = app.buttons["toolbar.accessibility"]
        XCTAssertTrue(accessibilityButton.waitForExistence(timeout: 5))
        accessibilityButton.tap()

        let largerTextToggle = app.switches["accessibility.largerText"]
        XCTAssertTrue(largerTextToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["accessibility.higherContrast"].exists)
        XCTAssertTrue(app.switches["accessibility.reduceMotion"].exists)
        XCTAssertTrue(app.switches["accessibility.readCoordinates"].exists)

        largerTextToggle.tap()
        app.switches["accessibility.higherContrast"].tap()

        app.buttons["accessibility.doneButton"].tap()
        XCTAssertTrue(accessibilityButton.waitForExistence(timeout: 5))
    }

    func test_searchBar_andGeocodeAction_areAccessible() {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        searchField.tap()
        searchField.typeText("Lisbon")

        XCTAssertTrue(app.buttons["geocode.findButton"].waitForExistence(timeout: 5))
    }
}
