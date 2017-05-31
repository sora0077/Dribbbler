//
//  StateRepository.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/31.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation

struct Weak<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

private struct Hash<T>: Hashable {
    let hashValue: Int
    init() { hashValue = 0 }
    init<H: Hashable>(_ hash: H) {
        hashValue = hash.hashValue
    }
    static func == (lhs: Hash<T>, rhs: Hash<T>) -> Bool { return lhs.hashValue == rhs.hashValue }
}

func stateRepository<H: Hashable, T: AnyObject>(forKey key: H, `default`: @autoclosure () -> T) -> T {
    return StateRepositoryImpl.value(forKey: Hash<T>(key), default: `default`())
}

func stateRepository<T: AnyObject>(_ `default`: @autoclosure () -> T) -> T {
    return StateRepositoryImpl.value(forKey: Hash<T>(), default: `default`())
}

private final class StateRepositoryImpl {
    private static let shared = StateRepositoryImpl()
    private var cache: [AnyHashable: Weak<AnyObject>] = [:]

    static func value<H: Hashable, T: AnyObject>(forKey key: H, `default`: @autoclosure () -> T) -> T {
        return shared.get(forKey: key) ?? shared.set(`default`(), forKey: key)
    }

    private init() {}

    private func get<H: Hashable, T>(forKey key: H) -> T? {
        return cache[AnyHashable(key)]?.value as? T
    }

    private func set<H: Hashable, T: AnyObject>(_ value: T, forKey key: H) -> T {
        cache[AnyHashable(key)] = Weak(value)
        return value
    }
}
