//
//  SceneDelegate.swift
//  MinesWeeper
//
//  Created by Saavedra Lozano, Miguel on 10/8/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Built once per scene, after AppDelegate has configured Firebase.
    private lazy var container = AppContainer.live()

    /// Signed-in players go straight to the game, as on Android.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let root: UIViewController = container.auth.currentUserId != nil
            ? GameBoardViewController(container: container)
            : LogInViewController(container: container)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: root)
        window.makeKeyAndVisible()
        self.window = window
    }
}
