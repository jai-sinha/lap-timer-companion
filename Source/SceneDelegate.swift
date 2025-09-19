//
//  SceneDelegate.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.
//  Copyright © 2025 Jai Sinha. All rights reserved.
//


import UIKit
import SwiftUI
import ConnectIQ

class SceneDelegate: UIResponder, UIWindowSceneDelegate, IQUIOverrideDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let rootView = AppView()
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
    }

    // MARK: - AppDelegate logic migrated here
    
    // SDK and device initialization
    override init() {
        super.init()
        ConnectIQ.sharedInstance().initialize(withUrlScheme: ReturnURLScheme, uiOverrideDelegate: self)
        DeviceManager.sharedInstance.restoreDevicesFromFileSystem()
    }

    // URL handling
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        let options = urlContext.options
        print("SceneDelegate received URL: \(url)")
        print("Source application: \(options.sourceApplication ?? "nil")")
        let result = DeviceManager.sharedInstance.handleOpenURL(url, options: [
            .sourceApplication: options.sourceApplication as Any
        ])
        print("DeviceManager handled URL with result: \(result)")
        if result {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("DeviceManagerDevicesChanged"), object: nil)
            }
        }
    }

    // needsToInstallConnectMobile logic
    func needsToInstallConnectMobile() {
        print("needsToInstallConnectMobile called - showing GCM install prompt")
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Install Garmin Connect Mobile",
                message: "This app requires Garmin Connect Mobile to communicate with your device. Would you like to install it?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Install", style: .default) { _ in
                ConnectIQ.sharedInstance().showAppStoreForConnectMobile()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.window?.rootViewController?.present(alert, animated: true)
        }
    }

    // MARK: - Lifecycle stubs (optional, for completeness)
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillTerminate(_ scene: UIScene) {}
}
