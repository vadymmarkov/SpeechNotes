//
//  AppDelegate.swift
//  SpeechNotes
//
//  Created by Vadym Markov on 09/01/2018.
//  Copyright © 2018 Vadym Markov. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?


  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)

    let navigationController = UINavigationController(rootViewController: ViewController())
    navigationController.navigationBar.prefersLargeTitles = true

    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
    return true
  }
}
