//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RealmSwift
import Dribbbler
import PINRemoteImage
import RxSwift

func print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items.map(String.init(describing:)), separator: separator, terminator: terminator)
}

extension DisposeBag {
    func insert(_ disposables: Disposable...) {
        disposables.forEach(insert(_:))
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print(String(describing: try? Realm().configuration.fileURL))
        OAuth().activate()
//        let user = repository.users[id: 1]
        print(USE_FLANIMATED_IMAGE)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            try OAuth().fetchToken(from: url)
            return true
        } catch {

        }
        return false
    }
}
