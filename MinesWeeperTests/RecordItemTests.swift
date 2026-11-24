//
//  RecordItemTests.swift
//  MinesWeeperTests
//

import XCTest
@testable import MinesWeeper

final class RecordItemTests: XCTestCase {

    func testDictionaryRoundTrips() {
        let record = RecordItem(numberOfMines: 15, fieldSize: 240, timeInSeconds: 73, timeStamp: 1_700_000_000_000)
        XCTAssertEqual(RecordItem(dictionary: record.dictionary), record)
    }

    func testMalformedDictionaryIsRejected() {
        XCTAssertNil(RecordItem(dictionary: ["numberOfMines": "fifteen", "fieldSize": 240]))
    }
}
