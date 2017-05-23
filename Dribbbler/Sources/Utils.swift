//
//  Utils.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/19.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

extension Int {
    var min: TimeInterval {
        return TimeInterval(self) * 60
    }
}

extension Realm {
    func recreate<T: Cache>(_ object: T, of predicateFormat: String, _ args: Any...) {
        recreate(object, of: NSPredicate(format: predicateFormat, argumentArray: args))
    }

    func recreate<T: Cache>(_ object: T, of predicate: NSPredicate) {
        delete(objects(T.self).filter(predicate))
        add(object)
    }

    func write<T: Object>(_ block: () -> T) -> T {
        beginWrite()
        let ret = block()
        add(ret)
        try! commitWrite()  // swiftlint:disable:this force_try
        return ret
    }
}

extension Date {
    var dateWithoutTime: Date {
        let timeZone = TimeZone.current
        let timeIntervalWithTimeZone = timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86400) * 86400
        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
}
