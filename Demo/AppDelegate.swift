//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RealmSwift
import DribbbleKit

extension UserDefaults {
    var clientId: String? {
        get { return string(forKey: "DRIBBBLE_CLIENT_ID") }
        set { set(newValue, forKey: "DRIBBBLE_CLIENT_ID") }
    }

    var clientSecret: String? {
        get { return string(forKey: "DRIBBBLE_CLIENT_SECRET") }
        set { set(newValue, forKey: "DRIBBBLE_CLIENT_SECRET") }
    }

    var authorization: Authorization? {
        get {
            guard let dict = dictionary(forKey: "DRIBBBLE_ACCESS_TOKEN") else { return nil }
            guard
                let accessToken = dict["access_token"] as? String,
                let tokenType = dict["token_type"] as? String,
                let scope = dict["scope"] as? String
                else {
                    return nil
            }
            let scopes = scope.components(separatedBy: " ").flatMap(OAuth.Scope.init(rawValue:))
            return Authorization(accessToken: accessToken, tokenType: tokenType, scopes: scopes)
        }
        set { set(newValue?.encode(), forKey: "DRIBBBLE_ACCESS_TOKEN") }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let (code, _) = try? OAuth.parse(from: url) {
            let defaults = UserDefaults.standard
            guard let clientId = defaults.clientId, let clientSecret = defaults.clientSecret else {
                return false
            }
            Session.shared.send(OAuth.GetToken(clientId: clientId, clientSecret: clientSecret, code: code)) { result in
                switch result {
                case .success(let response):
                    defaults.authorization = response.data
                case .failure(let error):
                    print(error)
                }
            }
            return true
        }
        return false
    }
}
