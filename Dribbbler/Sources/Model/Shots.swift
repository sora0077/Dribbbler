//
//  Shots.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import DribbbleKit
import RealmSwift
import RxSwift
import RxCocoa
import PredicateKit

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

final class UserShotsCache: PaginatorCache {
    private dynamic var _userId: Int = 0
    let shots = List<_Shot>()
    override var liftime: TimeInterval { return 30.min }

    var userId: User.Identifier { return DribbbleKit.User.Identifier(_userId) }

    convenience init(userId: User.Identifier) {
        self.init()
        _userId = Int(userId)
    }
}

extension UserShotsCache {
    static let user = Attribute<User.Identifier>("_userId")
}

public protocol Timeline {
    associatedtype Element
    typealias Changes = _TimelineChanges

    var count: Int { get }
    var changes: Driver<Changes> { get }
    subscript (idx: Int) -> Element { get }
    func reload(force: Bool)
    func fetch()
}

extension Timeline {
    public func reload() {
        reload(force: false)
    }
}

public final class Shots {
    public init() {

    }
}

public enum _TimelineChanges {  // swiftlint:disable:this type_name
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

public final class UserShots: Timeline, NetworkStateHolder {
    public typealias Element = Shot
    public subscript(idx: Int) -> Shot { return cache.shots[idx] }
    public private(set) lazy var changes: Driver<Changes> = self._changes.asDriver(onErrorDriveWith: .empty())
    private let _changes = PublishSubject<Changes>()
    private let userId: User.Identifier
    private let cache: UserShotsCache
    private var token: NotificationToken!
    private var next: ListUserShots?
    var networkState: NetworkState = .waiting

    public var count: Int { return cache.shots.count }

    public convenience init(user: User) {
        self.init(userId: user.id)
    }

    public init(userId: User.Identifier) {
        self.userId = userId
        let realm = Realm()
        cache = realm.objects(UserShotsCache.self).filter(UserShotsCache.user == userId).first ?? realm.write {
            UserShotsCache(userId: userId)
        }
        if !cache.next.isDone {
            next = cache.next.request() ?? ListUserShots(id: userId)
        }
        token = cache.shots.addNotificationBlock { [weak self] ch in
            self?._changes.onNext(_TimelineChanges(ch))
        }
    }

    public func reload(force: Bool = false) {
        _fetch(refreshing: force || cache.isOutdated)
    }

    public func fetch() {
        _fetch(refreshing: cache.isOutdated)
    }

    private func _fetch(refreshing: Bool) {
        guard Realm().objects(_User.self).filter(_User.id == userId).first != nil else {
            RequestController(GetUser(id: userId), stateHolder: self).runNext { response in
                write { realm in
                    let user = response.data
                    realm.add(user, update: true)
                }
                return (.waiting, self.fetch)
            }
            return
        }
        if refreshing { next = ListUserShots(id: userId) }
        guard let next = next else { return }
        RequestController(next, stateHolder: self).run { paginator in
            write { realm in
                let owner = realm.object(ofType: _User.self, forPrimaryKey: Int(self.userId))
                let shots = paginator.data.elements.map { shot, team -> _Shot in
                    shot._team = team
                    shot._user = owner
                    return shot
                }
                realm.add(shots, update: true)

                if let cache = realm.objects(UserShotsCache.self).filter(UserShotsCache.user == self.userId).first {
                    cache.update {
                        if refreshing {
                            cache.shots.removeAll()
                        }
                        cache.shots.append(objectsIn: shots)
                        cache.next.setRequest(paginator.data.next)
                    }
                }
            }
            self.next = paginator.data.next
            print(self.next)
            return self.next == nil ? .done : .waiting
        }
    }
}

extension UserShots {

}
