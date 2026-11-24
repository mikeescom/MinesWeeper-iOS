//
//  Theme.swift
//  MinesWeeper
//
//  Colors and control styles shared by all screens. Values match the Android app's colors.xml.
//

import UIKit

enum Theme {
    static let surface1 = UIColor(hex: 0x001F3F)
    static let surface2 = UIColor(hex: 0x3A6D8C)
    static let surface3 = UIColor(hex: 0x6A9AB0)
    static let primaryText = UIColor(hex: 0xEAD8B1)

    static func textField(placeholder: String, secure: Bool = false) -> UITextField {
        let field = UITextField()
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: primaryText.withAlphaComponent(0.6)])
        field.textColor = primaryText
        field.backgroundColor = surface1
        field.layer.cornerRadius = 15
        field.layer.borderWidth = 2
        field.layer.borderColor = surface3.cgColor
        field.isSecureTextEntry = secure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = secure ? .default : .emailAddress
        field.textContentType = secure ? .password : .username
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return field
    }

    static func button(title: String, filled: Bool = true) -> UIButton {
        var config = filled ? UIButton.Configuration.filled() : UIButton.Configuration.plain()
        config.title = title.uppercased()
        config.baseForegroundColor = primaryText
        config.baseBackgroundColor = surface1
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 18, weight: filled ? .regular : .bold)
            return attributes
        }
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }
}

extension UINavigationController {
    /// Shows the navigation bar in the app's colors, for pushed screens like Records and Settings.
    func showThemedNavigationBar(animated: Bool) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.surface1
        appearance.titleTextAttributes = [.foregroundColor: Theme.primaryText]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = Theme.primaryText
        setNavigationBarHidden(false, animated: animated)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension UIViewController {

    /// Replaces the window's root so the previous flow (login or game) can't be navigated back to.
    func switchRoot(to viewController: UIViewController) {
        // A screen pushed on top (like Settings) leaves this view out of the window, so fall back
        // to the navigation controller's.
        guard let window = view.window ?? navigationController?.view.window else { return }
        window.rootViewController = UINavigationController(rootViewController: viewController)
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

    /// Shows an alert with an OK button, or with Yes/Cancel when [onConfirm] is given.
    func showAlert(title: String, message: String? = nil, onConfirm: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let onConfirm {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in onConfirm() })
        } else {
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
        }
        present(alert, animated: true)
    }
}
