//
//  RecordRankingTests.swift
//  MinesWeeperTests
//
//  Mirrors RecordRankingTest.kt on Android.
//

import XCTest
@testable import MinesWeeper

final class RecordRankingTests: XCTestCase {

    private func record(mines: Int, fieldSize: Int, seconds: Int, timeStamp: Int64 = 0) -> RecordItem {
        RecordItem(numberOfMines: mines, fieldSize: fieldSize, timeInSeconds: seconds, timeStamp: timeStamp)
    }

    func testDenserGamesRankFirstThenFasterTimes() {
        let easyFast = record(mines: 10, fieldSize: 200, seconds: 20)
        let hardSlow = record(mines: 40, fieldSize: 200, seconds: 300)
        let hardFast = record(mines: 40, fieldSize: 200, seconds: 120)
        XCTAssertEqual(RecordRanking.rank([easyFast, hardSlow, hardFast]), [hardFast, hardSlow, easyFast])
    }

    func testTiesGoToTheNewerRecord() {
        let older = record(mines: 10, fieldSize: 100, seconds: 30, timeStamp: 1_000)
        let newer = record(mines: 10, fieldSize: 100, seconds: 30, timeStamp: 2_000)
        XCTAssertEqual(RecordRanking.rank([older, newer]), [newer, older])
    }

    func testZeroFieldSizeDoesNotDivideByZero() {
        XCTAssertEqual(RecordRanking.density(record(mines: 10, fieldSize: 0, seconds: 30)), 0)
    }
}
