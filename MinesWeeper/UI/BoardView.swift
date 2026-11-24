//
//  BoardView.swift
//  MinesWeeper
//
//  Draws a Board as a grid of cell images and reports taps and long presses by cell.
//

import UIKit

final class BoardView: UIView {

    static let cellSize: CGFloat = 30

    var onTap: ((Int, Int) -> Void)?
    var onLongPress: ((Int, Int) -> Void)?

    private var board: Board?
    private var cellViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(tap)
        addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize {
        guard let board else { return .zero }
        return CGSize(width: CGFloat(board.width) * Self.cellSize, height: CGFloat(board.height) * Self.cellSize)
    }

    /// Rebuilds the grid for [board] and draws its current state.
    func show(_ board: Board) {
        self.board = board
        cellViews.forEach { $0.removeFromSuperview() }
        cellViews = (0..<(board.width * board.height)).map { i in
            let imageView = UIImageView(frame: CGRect(
                x: CGFloat(i % board.width) * Self.cellSize,
                y: CGFloat(i / board.width) * Self.cellSize,
                width: Self.cellSize,
                height: Self.cellSize))
            imageView.contentMode = .scaleToFill
            addSubview(imageView)
            return imageView
        }
        for y in 0..<board.height {
            for x in 0..<board.width {
                render(x, y)
            }
        }
        invalidateIntrinsicContentSize()
    }

    func render(_ positions: [Board.Position]) {
        positions.forEach { render($0.x, $0.y) }
    }

    func render(_ x: Int, _ y: Int) {
        guard let board else { return }
        cellViews[y * board.width + x].image = UIImage(named: Self.imageName(board, x, y))
    }

    private static func imageName(_ board: Board, _ x: Int, _ y: Int) -> String {
        switch board.state(x, y) {
        case .covered:
            return "covered"
        case .flagged:
            return "flaged"
        case .revealed:
            if board.isMine(x, y) { return "mine" }
            let names = ["uncovered", "one", "two", "three", "four", "five", "six", "seven", "eight"]
            return names[board.adjacentMines(x, y)]
        }
    }

    private func cell(at point: CGPoint) -> (Int, Int)? {
        guard let board else { return nil }
        let x = Int(point.x / Self.cellSize)
        let y = Int(point.y / Self.cellSize)
        guard point.x >= 0, point.y >= 0, x < board.width, y < board.height else { return nil }
        return (x, y)
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let hit = cell(at: recognizer.location(in: self)) else { return }
        onTap?(hit.0, hit.1)
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, let hit = cell(at: recognizer.location(in: self)) else { return }
        onLongPress?(hit.0, hit.1)
    }
}
