//
//  SceneDelegate.swift
//  MinesWeeper
//
//  Created by Saavedra Lozano, Miguel on 10/8/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Signed-in players go straight to the game, as on Android.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let root: UIViewController = AuthService.currentUser != nil
            ? GameBoardViewController()
            : LogInViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: root)
        window.makeKeyAndVisible()
        self.window = window
    }
}
