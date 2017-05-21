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

@objc(UserShotsCache)
private final class UserShotsCache: PaginatorCache {
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

public final class Shots {
    public init() {

    }
}

extension Model {
    public final class UserShots: Timeline, NetworkStateHolder {
        public subscript(idx: Int) -> Shot { return cache.shots[idx] }
        public private(set) lazy var changes: Driver<Changes> = self._changes.asDriver(onErrorDriveWith: .empty())
        fileprivate let _changes = PublishSubject<Changes>()
        fileprivate let userId: Dribbbler.User.Identifier
        fileprivate var token: NotificationToken!
        fileprivate var next: ListUserShots?
        fileprivate let cache: UserShotsCache
        var networkState: NetworkState = .waiting

        init(userId: Dribbbler.User.Identifier) {
            self.userId = userId
            let realm = Realm()
            cache = realm.objects(UserShotsCache.self).filter(UserShotsCache.user == userId).first ?? realm.write {
                UserShotsCache(userId: userId)
            }
            if !cache.next.isDone {
                next = cache.next.request() ?? ListUserShots(id: userId)
            }
            token = cache.shots.addNotificationBlock { [weak self] ch in
                self?._changes.onNext(TimelineChanges(ch))
            }
        }
    }
}

// MARK: - UserShots
extension Model.UserShots {
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
                    realm.add(response.data, update: true)
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

extension Model.UserShots {
    public var startIndex: Int { return cache.shots.startIndex }
    public var endIndex: Int { return cache.shots.endIndex }
    public func index(after i: Int) -> Int { return cache.shots.index(after: i) }

    public var count: Int { return cache.shots.count }
}
