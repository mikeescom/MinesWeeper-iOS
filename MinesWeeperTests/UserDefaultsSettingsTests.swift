//
//  UserDefaultsSettingsTests.swift
//  MinesWeeperTests
//

import XCTest
@testable import MinesWeeper

final class UserDefaultsSettingsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsSettingsTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testNumberOfMinesDefaultsTo15() {
        XCTAssertEqual(UserDefaultsSettings(defaults: defaults).numberOfMines, 15)
    }

    func testValuesPersistAndClear() {
        let settings = UserDefaultsSettings(defaults: defaults)
        settings.numberOfMines = 40
        settings.fieldSize = 240
        XCTAssertEqual(UserDefaultsSettings(defaults: defaults).numberOfMines, 40)
        XCTAssertEqual(UserDefaultsSettings(defaults: defaults).fieldSize, 240)
        settings.clear()
        XCTAssertEqual(settings.numberOfMines, 15)
        XCTAssertEqual(settings.fieldSize, 0)
    }
}
