//
//  SceneDelegate.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 31.05.2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties

    var window: UIWindow?

    // MARK: - UIWindowSceneDelegate

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        window?.rootViewController = CustomViewController()
        window?.makeKeyAndVisible()
    }

}

