//
//  AppDelegate.swift
//  MySwiftEntryKit
//
//  Created by liaoya on 2020/7/13.
//  Copyright © 2020 杨建祥. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        self.window = window

        let viewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        let navBar = UINavigationBar.appearance()
        navBar.isTranslucent = false

        return true
    }

}

