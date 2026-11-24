//
//  CreateAccountViewController.swift
//  MinesWeeper
//
//  Email account creation, like CreateAccountFragment on Android. Firebase signs the new
//  account in, so success goes straight to the game.
//

import UIKit
import FirebaseAuth

final class CreateAccountViewController: UIViewController {

    private let emailField = Theme.textField(placeholder: "email")
    private let passwordField = Theme.textField(placeholder: "password", secure: true)
    private let createButton = Theme.button(title: "Create account")
    private let backButton = Theme.button(title: "Return to log in", filled: false)
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface1
        passwordField.textContentType = .newPassword

        let titleLabel = UILabel()
        titleLabel.text = "Create an account"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = Theme.surface3
        titleLabel.textAlignment = .center

        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, emailField, passwordField, createButton, backButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(32, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        spinner.color = Theme.primaryText
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func createTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Field is missing", message: "Email or Password cannot be both empty")
            return
        }
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
        AuthService.createAccount(email: email, password: password) { [weak self] error in
            guard let self else { return }
            self.spinner.stopAnimating()
            self.view.isUserInteractionEnabled = true
            if let error {
                self.showAlert(title: "Error", message: Self.message(for: error))
            } else {
                self.switchRoot(to: GameBoardViewController())
            }
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// Firebase's own message covers weak passwords and bad emails, not just "already in use".
    private static func message(for error: Error) -> String {
        // 17007 is FIRAuthErrorCodeEmailAlreadyInUse.
        let nsError = error as NSError
        if nsError.code == 17007 {
            return "The email address is already in use by another account."
        }
        return error.localizedDescription
    }
}
