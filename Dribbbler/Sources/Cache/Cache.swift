//
//  Cache.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/09.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

class Cache: Object {
    private(set) dynamic var createAt: Date = Date()
    private(set) dynamic var updateAt: Date = .distantPast

    func update(_ block: () -> Void) {
        block()
        updateAt = Date()
    }
}
