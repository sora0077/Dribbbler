//
//  EntityAuthorization.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/10.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

final class _Authorization: Entity {  // swiftlint:disable:this type_name
    dynamic var accessToken: String = ""
    dynamic var tokenType: String = ""
    private dynamic var _scope: String = ""

    var scopes: [OAuth.Scope] {
        get { return _scope.components(separatedBy: " ").flatMap(OAuth.Scope.init(rawValue:)) }
        set { _scope = newValue.map { $0.rawValue }.joined(separator: " ") }
    }

    override class func primaryKey() -> String? {
        return "accessToken"
    }
}
