//
//  LogInViewController.swift
//  MinesWeeper
//
//  Google or email sign-in, password reset and a link to account creation, like LoginFragment
//  on Android.
//

import UIKit
import GoogleSignIn

final class LogInViewController: UIViewController {

    private let emailField = Theme.textField(placeholder: "email")
    private let passwordField = Theme.textField(placeholder: "password", secure: true)
    private let googleButton = GIDSignInButton()
    private let logInButton = Theme.button(title: "Log In")
    private let resetPasswordButton = Theme.button(title: "Reset password", filled: false)
    private let createAccountButton = Theme.button(title: "Create account", filled: false)
    private let spinner = UIActivityIndicatorView(style: .large)

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface1
        navigationController?.setNavigationBarHidden(true, animated: false)
        setUpViews()
    }

    private func setUpViews() {
        let titleLabel = UILabel()
        titleLabel.text = "MinesWeeper"
        titleLabel.font = .systemFont(ofSize: 40, weight: .bold)
        titleLabel.textColor = Theme.surface3
        titleLabel.textAlignment = .center

        let googleLabel = Self.label("Log in with:")
        let orLabel = Self.label("OR")

        googleButton.style = .wide
        googleButton.colorScheme = .dark
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        logInButton.addTarget(self, action: #selector(logInTapped), for: .touchUpInside)
        resetPasswordButton.addTarget(self, action: #selector(resetPasswordTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)

        let emailBox = UIStackView(arrangedSubviews: [emailField, passwordField, logInButton])
        emailBox.axis = .vertical
        emailBox.spacing = 12
        emailBox.isLayoutMarginsRelativeArrangement = true
        emailBox.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        emailBox.backgroundColor = Theme.surface2
        emailBox.layer.cornerRadius = 20

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, googleLabel, googleButton, orLabel, emailBox, resetPasswordButton, createAccountButton,
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(40, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        spinner.color = Theme.primaryText
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private static func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = Theme.primaryText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        return label
    }

    private func setBusy(_ busy: Bool) {
        if busy {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        view.isUserInteractionEnabled = !busy
    }

    private func goToGame() {
        switchRoot(to: GameBoardViewController(container: container))
    }

    @objc private func googleTapped() {
        // No spinner here: Google shows its own sheet, and a cancelled sign-in never calls back.
        container.auth.signInWithGoogle(presenting: self) { [weak self] error in
            guard let self else { return }
            if let error {
                print("LogInViewController: Google sign-in failed: \(error)")
                self.showAlert(title: "Error", message: "Login failed")
            } else {
                self.goToGame()
            }
        }
    }

    @objc private func logInTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Field is missing", message: "Email or Password cannot be both empty")
            return
        }
        setBusy(true)
        container.auth.signIn(email: email, password: password) { [weak self] error in
            guard let self else { return }
            self.setBusy(false)
            if let error {
                print("LogInViewController: email sign-in failed: \(error)")
                self.showAlert(title: "Error", message: "Email or Password is incorrect. Please try again.")
            } else {
                self.goToGame()
            }
        }
    }

    @objc private func resetPasswordTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !email.isEmpty else {
            showAlert(title: "Field is missing", message: "Email cannot be empty")
            return
        }
        container.auth.sendPasswordReset(email: email) { [weak self] error in
            guard let self else { return }
            if error != nil {
                self.showAlert(title: "Error", message: "Cannot send reset link. Please try again.")
            } else {
                self.emailField.text = ""
                self.passwordField.text = ""
                self.showAlert(title: "Email sent",
                               message: "Reset password email was sent. Please check your email and try again.")
            }
        }
    }

    @objc private func createAccountTapped() {
        navigationController?.pushViewController(CreateAccountViewController(container: container), animated: true)
    }
}
