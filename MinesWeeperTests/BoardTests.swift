//
//  BoardTests.swift
//  MinesWeeperTests
//
//  Mirrors BoardTest.kt in the Android app so both platforms are held to the same rules.
//

import XCTest
@testable import MinesWeeper

/// Deterministic generator (SplitMix64) so tests can loop over many seeds.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

final class BoardTests: XCTestCase {

    private func board(_ width: Int, _ height: Int, _ mines: (Int, Int)...) -> Board {
        let positions = Set(mines.map { Board.Position(x: $0.0, y: $0.1) })
        return Board.withMines(width: width, height: height, mines: positions)!
    }

    private func mineCount(_ b: Board) -> Int {
        var count = 0
        for y in 0..<b.height { for x in 0..<b.width where b.isMine(x, y) { count += 1 } }
        return count
    }

    func testAdjacentCountsAreComputed() {
        let b = board(3, 3, (0, 0), (2, 0))
        XCTAssertEqual(b.adjacentMines(0, 1), 1)
        XCTAssertEqual(b.adjacentMines(1, 0), 2)
        XCTAssertEqual(b.adjacentMines(1, 1), 2)
        XCTAssertEqual(b.adjacentMines(1, 2), 0)
    }

    func testFirstRevealIsNeverAMineAndPlacesAllMines() {
        for seed in 0..<200 {
            let b = Board(width: 5, height: 5, mineCount: 20, generator: SeededGenerator(seed: UInt64(seed)))!
            b.reveal(2, 2)
            XCTAssertFalse(b.isMine(2, 2))
            XCTAssertNotEqual(b.status, .lost)
            XCTAssertEqual(mineCount(b), 20)
        }
    }

    func testFirstRevealOpensAnAreaWhenThereIsRoom() {
        for seed in 0..<50 {
            let b = Board(width: 9, height: 9, mineCount: 10, generator: SeededGenerator(seed: UInt64(seed)))!
            b.reveal(4, 4)
            XCTAssertEqual(b.adjacentMines(4, 4), 0)
        }
    }

    func testMaximumMineCountStillTerminates() {
        let b = Board(width: 4, height: 4, mineCount: Board.maxMines(width: 4, height: 4),
                      generator: SeededGenerator(seed: 1))!
        b.reveal(0, 0)
        XCTAssertEqual(b.status, .won)
    }

    func testInvalidBoardsAreRejected() {
        XCTAssertNil(Board(width: 3, height: 3, mineCount: 9))
        XCTAssertNil(Board(width: 3, height: 3, mineCount: 0))
        XCTAssertNil(Board(width: 0, height: 3, mineCount: 1))
    }

    func testMaxMinesIsCappedByCounterDigits() {
        XCTAssertEqual(Board.maxMines(width: 3, height: 3), 8)
        XCTAssertEqual(Board.maxMines(width: 40, height: 40), 999)
    }

    func testRevealingEmptyCellFloodFillsUpToNumbers() {
        let b = board(4, 4, (3, 3))
        let changed = b.reveal(0, 0)
        XCTAssertEqual(changed.count, 15)
        XCTAssertEqual(b.state(3, 3), .covered)
        XCTAssertEqual(b.status, .won)
    }

    func testRevealingNumberOpensOnlyThatCell() {
        let b = board(3, 3, (0, 0))
        let changed = b.reveal(1, 1)
        XCTAssertEqual(changed, [Board.Position(x: 1, y: 1)])
        XCTAssertEqual(b.state(1, 1), .revealed)
    }

    func testRevealingMineLosesAndRevealsEverything() {
        let b = board(3, 3, (0, 0))
        let changed = b.reveal(0, 0)
        XCTAssertEqual(b.status, .lost)
        XCTAssertEqual(changed.count, 9)
        XCTAssertTrue(b.reveal(1, 1).isEmpty)
        XCTAssertFalse(b.toggleFlag(2, 2))
    }

    func testFlaggedCellCannotBeRevealed() {
        let b = board(3, 3, (0, 0), (2, 2))
        XCTAssertTrue(b.toggleFlag(0, 0))
        XCTAssertTrue(b.reveal(0, 0).isEmpty)
        XCTAssertEqual(b.status, .playing)
        XCTAssertEqual(b.state(0, 0), .flagged)
    }

    func testRevealedCellCannotBeFlagged() {
        let b = board(3, 3, (0, 0), (2, 2))
        b.reveal(1, 1)
        XCTAssertFalse(b.toggleFlag(1, 1))
        XCTAssertEqual(b.flagsPlaced, 0)
    }

    func testReflaggingSameMineDoesNotWin() {
        let b = board(3, 3, (0, 0), (2, 2))
        for _ in 0..<5 {
            b.toggleFlag(0, 0)
            b.toggleFlag(0, 0)
        }
        b.toggleFlag(0, 0)
        XCTAssertEqual(b.status, .playing)
        XCTAssertEqual(b.flagsRemaining, 1)
    }

    func testFlagsCannotExceedMinesAndAreNotLost() {
        let b = board(3, 3, (0, 0))
        XCTAssertTrue(b.toggleFlag(1, 1))
        XCTAssertFalse(b.toggleFlag(2, 2))
        XCTAssertFalse(b.toggleFlag(2, 2))
        XCTAssertEqual(b.flagsRemaining, 0)
        XCTAssertTrue(b.toggleFlag(1, 1))
        XCTAssertEqual(b.flagsRemaining, 1)
        XCTAssertTrue(b.toggleFlag(0, 0))
        XCTAssertEqual(b.status, .won)
    }

    func testWrongFlagsDoNotWin() {
        let b = board(3, 3, (0, 0), (2, 2))
        b.toggleFlag(0, 0)
        b.toggleFlag(1, 1)
        XCTAssertEqual(b.status, .playing)
    }

    func testRevealingAllSafeCellsWins() {
        let b = board(3, 1, (0, 0))
        b.reveal(1, 0)
        XCTAssertEqual(b.status, .playing)
        b.reveal(2, 0)
        XCTAssertEqual(b.status, .won)
    }

    func testFlagsBeforeFirstRevealCannotWin() {
        let b = Board(width: 2, height: 1, mineCount: 1, generator: SeededGenerator(seed: 0))!
        b.toggleFlag(0, 0)
        XCTAssertEqual(b.status, .ready)
        b.toggleFlag(0, 0)
        b.reveal(0, 0)
        XCTAssertEqual(b.status, .won)
    }
}
