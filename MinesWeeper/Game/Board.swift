//
//  Board.swift
//  MinesWeeper
//
//  Pure game state for one Minesweeper round, ported from the Android app's Board.kt so both
//  platforms play by the same rules. Has no UIKit dependency, so it is unit tested directly.
//
//  Mines are placed lazily on the first reveal so the first tap is never a mine (and, when the
//  board has room, never next to one either).
//

import Foundation

final class Board {

    struct Position: Hashable {
        let x: Int
        let y: Int
    }

    enum CellState {
        case covered, flagged, revealed
    }

    enum Status {
        case ready, playing, won, lost
    }

    /// The mines counter shows three digits.
    static let maxDisplayableMines = 999

    /// Largest valid mine count for a board: at least one safe cell, and fits the counter.
    static func maxMines(width: Int, height: Int) -> Int {
        min(width * height - 1, maxDisplayableMines)
    }

    let width: Int
    let height: Int
    let mineCount: Int

    private(set) var status: Status = .ready
    private(set) var flagsPlaced = 0

    var flagsRemaining: Int { mineCount - flagsPlaced }
    var isOver: Bool { status == .won || status == .lost }

    private var mines: [Bool]
    private var adjacent: [Int]
    private var states: [CellState]
    private var revealedSafeCells = 0
    private var generator: RandomNumberGenerator

    private var size: Int { width * height }

    /// Returns nil when the dimensions or mine count are invalid.
    convenience init?(width: Int, height: Int, mineCount: Int,
                      generator: RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.init(width: width, height: height, mineCount: mineCount, generator: generator, presetMines: nil)
    }

    /// Builds a board with mines at fixed positions. For tests.
    static func withMines(width: Int, height: Int, mines: Set<Position>) -> Board? {
        Board(width: width, height: height, mineCount: mines.count,
              generator: SystemRandomNumberGenerator(), presetMines: mines)
    }

    private init?(width: Int, height: Int, mineCount: Int,
                  generator: RandomNumberGenerator, presetMines: Set<Position>?) {
        guard width > 0, height > 0, mineCount >= 1,
              mineCount <= Board.maxMines(width: width, height: height) else { return nil }
        self.width = width
        self.height = height
        self.mineCount = mineCount
        self.generator = generator
        mines = Array(repeating: false, count: width * height)
        adjacent = Array(repeating: 0, count: width * height)
        states = Array(repeating: .covered, count: width * height)

        if let presetMines {
            for mine in presetMines {
                guard inBounds(mine.x, mine.y) else { return nil }
                mines[index(mine.x, mine.y)] = true
            }
            computeAdjacency()
            status = .playing
        }
    }

    func state(_ x: Int, _ y: Int) -> CellState { states[index(x, y)] }

    func isMine(_ x: Int, _ y: Int) -> Bool { mines[index(x, y)] }

    func adjacentMines(_ x: Int, _ y: Int) -> Int { adjacent[index(x, y)] }

    /// Opens the cell at x,y. Opening an empty cell flood-fills its empty neighbours.
    /// Flagged or already-open cells are ignored. Returns the cells whose state changed.
    /// If a mine is opened the game is lost and every cell is revealed.
    @discardableResult
    func reveal(_ x: Int, _ y: Int) -> [Position] {
        guard !isOver, state(x, y) == .covered else { return [] }
        if status == .ready {
            placeMines(safeX: x, safeY: y)
            status = .playing
        }

        if isMine(x, y) {
            status = .lost
            return revealAll()
        }

        var changed: [Position] = []
        var queue: [Position] = []
        var head = 0
        open(x, y, &changed)
        if adjacentMines(x, y) == 0 { queue.append(Position(x: x, y: y)) }
        while head < queue.count {
            let current = queue[head]
            head += 1
            forEachNeighbour(current.x, current.y) { nx, ny in
                if state(nx, ny) == .covered && !isMine(nx, ny) {
                    open(nx, ny, &changed)
                    if adjacentMines(nx, ny) == 0 { queue.append(Position(x: nx, y: ny)) }
                }
            }
        }

        if revealedSafeCells == size - mineCount { status = .won }
        return changed
    }

    /// Flags or unflags a covered cell. Returns false (and changes nothing) for open cells, when
    /// the game is over, or when no flags are left. Flagging exactly every mine also wins.
    @discardableResult
    func toggleFlag(_ x: Int, _ y: Int) -> Bool {
        guard !isOver else { return false }
        let i = index(x, y)
        switch states[i] {
        case .revealed:
            return false
        case .flagged:
            states[i] = .covered
            flagsPlaced -= 1
        case .covered:
            guard flagsRemaining > 0 else { return false }
            states[i] = .flagged
            flagsPlaced += 1
        }
        if status == .playing && flagsPlaced == mineCount && allFlagsOnMines() {
            status = .won
        }
        return true
    }

    // MARK: - Private

    private func open(_ x: Int, _ y: Int, _ changed: inout [Position]) {
        states[index(x, y)] = .revealed
        revealedSafeCells += 1
        changed.append(Position(x: x, y: y))
    }

    private func allFlagsOnMines() -> Bool {
        (0..<size).allSatisfy { states[$0] != .flagged || mines[$0] }
    }

    private func revealAll() -> [Position] {
        var all: [Position] = []
        all.reserveCapacity(size)
        for y in 0..<height {
            for x in 0..<width {
                states[index(x, y)] = .revealed
                all.append(Position(x: x, y: y))
            }
        }
        return all
    }

    private func placeMines(safeX: Int, safeY: Int) {
        var excluded: Set<Int> = [index(safeX, safeY)]
        // Keep the first tap's neighbours clear too when there's room, so it opens an area.
        if size - 9 >= mineCount {
            forEachNeighbour(safeX, safeY) { nx, ny in excluded.insert(index(nx, ny)) }
        }
        var candidates = (0..<size).filter { !excluded.contains($0) }
        // Fisher-Yates shuffle driven by the injected generator, so tests can be deterministic.
        for i in stride(from: candidates.count - 1, to: 0, by: -1) {
            let j = Int(generator.next() % UInt64(i + 1))
            candidates.swapAt(i, j)
        }
        for i in candidates.prefix(mineCount) {
            mines[i] = true
        }
        computeAdjacency()
    }

    private func computeAdjacency() {
        for y in 0..<height {
            for x in 0..<width {
                var count = 0
                forEachNeighbour(x, y) { nx, ny in if isMine(nx, ny) { count += 1 } }
                adjacent[index(x, y)] = count
            }
        }
    }

    private func forEachNeighbour(_ x: Int, _ y: Int, _ action: (Int, Int) -> Void) {
        for dy in -1...1 {
            for dx in -1...1 where !(dx == 0 && dy == 0) {
                let nx = x + dx
                let ny = y + dy
                if inBounds(nx, ny) { action(nx, ny) }
            }
        }
    }

    private func inBounds(_ x: Int, _ y: Int) -> Bool {
        (0..<width).contains(x) && (0..<height).contains(y)
    }

    private func index(_ x: Int, _ y: Int) -> Int {
        precondition(inBounds(x, y), "(\(x), \(y)) is outside a \(width)x\(height) board")
        return y * width + x
    }
}
