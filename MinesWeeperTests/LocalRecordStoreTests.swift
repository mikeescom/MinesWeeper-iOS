//
//  LocalRecordStoreTests.swift
//  MinesWeeperTests
//

import XCTest
@testable import MinesWeeper

final class LocalRecordStoreTests: XCTestCase {

    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("records.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        super.tearDown()
    }

    private func record(_ seconds: Int, at timeStamp: Int64) -> RecordItem {
        RecordItem(numberOfMines: 15, fieldSize: 240, timeInSeconds: seconds, timeStamp: timeStamp)
    }

    func testStartsEmpty() {
        XCTAssertTrue(LocalRecordStore(fileURL: fileURL).allRecords().isEmpty)
    }

    func testInsertedRecordsComeBackNewestFirst() {
        let store = LocalRecordStore(fileURL: fileURL)
        store.insert(record(50, at: 1_000), id: "a")
        store.insert(record(40, at: 3_000), id: "b")
        store.insert(record(60, at: 2_000), id: "c")
        XCTAssertEqual(store.allRecords().map(\.timeInSeconds), [40, 60, 50])
        XCTAssertEqual(store.allIds(), ["a", "b", "c"])
    }

    func testExistingIdIsNotOverwritten() {
        let store = LocalRecordStore(fileURL: fileURL)
        XCTAssertTrue(store.insert(record(50, at: 1_000), id: "a"))
        XCTAssertFalse(store.insert(record(99, at: 1_000), id: "a"))
        XCTAssertEqual(store.allRecords().map(\.timeInSeconds), [50])
    }

    func testRecordsPersistAcrossInstances() {
        LocalRecordStore(fileURL: fileURL).insert(record(50, at: 1_000), id: "a")
        XCTAssertEqual(LocalRecordStore(fileURL: fileURL).allRecords(), [record(50, at: 1_000)])
    }

    func testDeleteAllRemovesRecordsFromDisk() {
        let store = LocalRecordStore(fileURL: fileURL)
        store.insert(record(50, at: 1_000), id: "a")
        store.deleteAll()
        XCTAssertTrue(store.allRecords().isEmpty)
        XCTAssertTrue(LocalRecordStore(fileURL: fileURL).allRecords().isEmpty)
    }
}
