//
//  Entity.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

class Entity: Object {
    private dynamic var cachedAt: Date = Date()
    var liftime: TimeInterval { return 120.min }
    var isOutdated: Bool { return Date().timeIntervalSince(cachedAt) > liftime }
}
