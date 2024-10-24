//
//  GameBoardViewController.swift
//  MinesWeeper
//
//  Created by Saavedra Lozano, Miguel on 10/8/24.
//

import UIKit
import Foundation

class GameBoardViewController: UIViewController {
    let containerView = UIView() // View to hold all the buttons
    let buttonSize: CGFloat = 30 // Size of each button
    let buttonSpacing: CGFloat = 1 // Spacing between buttons

    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtonBoard()
    }

    func setupButtonBoard() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 200) // Adjust based on button count
        ])

        let numRows = 3
        let numCols = 4

        let wholeButtonWidth = (containerView.frame.width - CGFloat((numCols - 1)) * buttonSpacing)
        let wholeButtonHeight = (containerView.frame.height - CGFloat((numRows - 1)) * buttonSpacing)
        
        let buttonWidth = wholeButtonWidth / CGFloat(numCols)
        let buttonHeight = wholeButtonHeight / CGFloat(numRows)

        for row in 0..<numRows {
            for col in 0..<numCols {
                print("Button \(row * numCols + col + 1)")
                let button = UIButton(type: .system)
                button.setTitle("Button \(row * numCols + col + 1)", for: .normal)
                button.frame = CGRect(x: CGFloat(col) * (buttonWidth + buttonSpacing),y: CGFloat(row) * (buttonHeight + buttonSpacing),                                width: buttonWidth, height: buttonHeight)
                button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
                containerView.addSubview(button)
            }

        }

    }



    @objc func buttonTapped(_ sender: UIButton) {
        print("Button tapped: \(sender.titleLabel?.text ?? "Unknown")")
    }
}
