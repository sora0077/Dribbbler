//
//  Timeline.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/19.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa

public protocol Timeline: class, Collection, ReactiveCompatible {
    typealias Element = Iterator.Element
    typealias Changes = TimelineChanges

    var count: Int { get }
    var changes: Driver<Changes> { get }
    var isLoading: Driver<Bool> { get }

    subscript (idx: Int) -> Element { get }

    @discardableResult
    func reload(force: Bool) -> Bool
    func fetch()
}

extension Timeline {
    @discardableResult
    public func reload() -> Bool {
        return reload(force: false)
    }
}

extension Reactive where Base: Timeline {
    public func reload(force: Bool = false) -> UIBindingObserver<Base, Void> {
        return UIBindingObserver(UIElement: base, binding: { (base, _) in
            base.reload(force: force)
        })
    }

    public func fetch() -> UIBindingObserver<Base, Void> {
        return UIBindingObserver(UIElement: base, binding: { (base, _) in
            base.fetch()
        })
    }
}

public enum TimelineChanges {
    case initial
    case update(deletions: [Int], insertions: [Int], modifications: [Int])

    init<T>(_ changes: RealmCollectionChange<T>) {
        switch changes {
        case .initial:
            self = .initial
        case let .update(_, deletions, insertions, modifications):
            self = .update(deletions: deletions, insertions: insertions, modifications: modifications)
        case let .error(error):
            fatalError("\(error)")
        }
    }
}
