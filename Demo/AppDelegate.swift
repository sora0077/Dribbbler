//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let realm = try? Realm()
        return true
    }
}
