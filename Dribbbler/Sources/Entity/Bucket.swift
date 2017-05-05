//
//  Bucket.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

final class _Bucket: Object, BucketData {  // swiftlint:disable:this type_name
    private(set) dynamic var id: Int = 0
    private(set) dynamic var name: String = ""
    private(set) dynamic var shotsCount: Int = 0
    private(set) dynamic var createdAt: Date = .distantPast
    private(set) dynamic var updatedAt: Date = .distantPast

    override var description: String { return _description }

    private dynamic var _description: String = ""

    override class func primaryKey() -> String? { return "id" }

    convenience init(
        id: Identifier,
        name: String,
        description: String,
        shotsCount: Int,
        createdAt: Date,
        updatedAt: Date
        ) throws {
        self.init()
        self.id = Int(id)
        self.name = name
        self._description = description
        self.shotsCount = shotsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
