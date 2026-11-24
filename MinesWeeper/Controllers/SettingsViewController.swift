//
//  SettingsViewController.swift
//  MinesWeeper
//
//  Number of mines, the signed-in account with a log out button, and the app version, like
//  SettingsFragment on Android. Opened from the account menu on the game screen.
//

import UIKit

final class SettingsViewController: UIViewController {

    private let container: AppContainer
    private let maxMines: Int
    private let onNumberOfMinesChanged: () -> Void
    private let onLogOut: () -> Void

    private let minesField = Theme.textField(placeholder: "Number of mines")
    private let minesHelpLabel = UILabel()
    private let saveButton = Theme.button(title: "Save and return")
    private let logOutButton = Theme.button(title: "Log Out")

    /// [maxMines] is the most the current board allows. [onNumberOfMinesChanged] runs after a
    /// new count is saved; [onLogOut] runs when the player taps Log Out.
    init(container: AppContainer, maxMines: Int,
         onNumberOfMinesChanged: @escaping () -> Void, onLogOut: @escaping () -> Void) {
        self.container = container
        self.maxMines = max(1, maxMines)
        self.onNumberOfMinesChanged = onNumberOfMinesChanged
        self.onLogOut = onLogOut
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = Theme.surface1

        minesField.keyboardType = .numberPad
        minesField.textContentType = nil
        minesField.text = "\(container.settings.numberOfMines)"
        minesHelpLabel.numberOfLines = 0
        minesHelpLabel.font = .systemFont(ofSize: 14)
        showHelp()

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(logOutTapped), for: .touchUpInside)

        let accountLabel = Self.label("Account", size: 18, weight: .bold, color: Theme.primaryText)
        let signedInLabel = Self.label(container.auth.currentUserEmail.map { "Signed in as \($0)" } ?? "",
                                       size: 16, color: Theme.surface3)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let versionLabel = Self.label("Version \(version)", size: 14, color: Theme.surface3)
        versionLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            Self.label("Number of mines", size: 16, weight: .semibold, color: Theme.primaryText),
            minesField, minesHelpLabel, saveButton,
            accountLabel, signedInLabel, logOutButton,
            versionLabel,
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: minesHelpLabel)
        stack.setCustomSpacing(40, after: saveButton)
        stack.setCustomSpacing(16, after: signedInLabel)
        stack.setCustomSpacing(40, after: logOutButton)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.showThemedNavigationBar(animated: animated)
    }

    private func showHelp(error: String? = nil) {
        minesHelpLabel.text = error ?? "Between 1 and \(maxMines). Changing it starts a new game."
        minesHelpLabel.textColor = error == nil ? Theme.surface3 : UIColor(hex: 0xF85454)
    }

    @objc private func saveTapped() {
        let text = minesField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        if text.isEmpty {
            showHelp(error: "Number of mines must be entered")
        } else if let value = Int(text), (1...maxMines).contains(value) {
            container.settings.numberOfMines = value
            onNumberOfMinesChanged()
            navigationController?.popViewController(animated: true)
        } else {
            showHelp(error: "Number of mines must be between 1 and \(maxMines)")
        }
    }

    @objc private func logOutTapped() {
        onLogOut()
    }

    private static func label(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular,
                              color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
