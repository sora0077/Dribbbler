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

extension List {
    func distinctAppend<S: Sequence>(contentsOf elements: S) where S.Iterator.Element == T {
        var set = OrderedSet(self)
        set.append(contentsOf: elements)
        append(objectsIn: set.appendings)
    }
}

private struct OrderedSet<Element: Hashable> {
    private var set: Set<Element> = []
    private(set) var appendings: [Element] = []

    init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        set = Set(elements)
    }

    mutating func append<S: Sequence>(contentsOf elements: S) where S.Iterator.Element == Element {
        for e in elements where !set.contains(e) {
            set.insert(e)
            appendings.append(e)
        }
    }
}
