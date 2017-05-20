//
//  EntityClient.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/10.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import PredicateKit

final class _Client: Object {  // swiftlint:disable:this type_name
    dynamic var id: String = ""
    dynamic var secret: String = ""
    dynamic var state: String?
    private dynamic var _redirectUrl: String?
    dynamic var authorization: _Authorization?
    private(set) dynamic var createAt: Date = Date()

    var redirectURL: URL? {
        get { return _redirectUrl.flatMap(URL.init(string:)) }
        set { _redirectUrl = newValue?.absoluteString }
    }

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func ignoredProperties() -> [String] {
        return ["redirectURL"]
    }
}

extension _Client {
    static let createAt = Attribute<Date>("createAt")
}
