//
//  DigitDisplayView.swift
//  MinesWeeper
//
//  A row of 7-segment style digit images, used for the mines counter and the timer.
//

import UIKit

final class DigitDisplayView: UIStackView {

    private static let digitImageNames = [
        "zero_digit", "one_digit", "two_digit", "three_digit", "four_digit",
        "five_digit", "six_digit", "seven_digit", "eight_digit", "nine_digit",
    ]

    private let digitViews: [UIImageView]

    init(digits: Int) {
        digitViews = (0..<digits).map { _ in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            return imageView
        }
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fillEqually
        spacing = 1
        backgroundColor = Theme.surface1
        digitViews.forEach { addArrangedSubview($0) }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Shows the digits of [value], zero-padded on the left.
    func show(digitsOf value: Int) {
        var remaining = max(0, value)
        for imageView in digitViews.reversed() {
            imageView.image = UIImage(named: Self.digitImageNames[remaining % 10])
            remaining /= 10
        }
    }

    /// Shows [seconds] as MMSS, capped at 99:59.
    func show(seconds: Int) {
        let clamped = min(max(0, seconds), 99 * 60 + 59)
        show(digitsOf: (clamped / 60) * 100 + clamped % 60)
    }
}
