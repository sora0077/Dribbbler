//
//  EntityFollow.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

final class _Follow: Object, FollowerData {  // swiftlint:disable:this type_name
    private(set) dynamic var id: Int = 0
    private(set) dynamic var createdAt: Date = .distantPast

    override class func primaryKey() -> String? { return "id" }

    convenience init(
        id: Int,
        createdAt: Date
        ) throws {
        self.init()
        self.id = id
        self.createdAt = createdAt
    }
}
