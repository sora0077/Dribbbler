//
//  UserShots.swift
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
private final class UserShotsCache: PaginatorCache, TimelineCache {
    private dynamic var _userId: Int = 0
    let shots = List<_Shot>()
    override var liftime: TimeInterval { return 30.min }

    var objects: List<_Shot> { return shots }

    var userId: User.Identifier { return DribbbleKit.User.Identifier(_userId) }

    override class func primaryKey() -> String? { return "_userId" }

    convenience init(userId: User.Identifier) {
        self.init()
        _userId = Int(userId)
    }
}

extension UserShotsCache {
    static let user = Attribute<User.Identifier>("_userId")
}

extension Model {
    public final class UserShots: Timeline, TimelineDelegate {
        typealias Request = ListUserShots
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var changes: Driver<Changes> { return impl.changes }
        fileprivate let impl: _TimelineModel<UserShotsCache, Model.UserShots>
        fileprivate let userId: Dribbbler.User.Identifier

        init(userId: Dribbbler.User.Identifier) {
            self.userId = userId
            impl = _TimelineModel(
                request: ListUserShots(id: userId),
                cache: UserShotsCache(userId: userId),
                predicate: UserShotsCache.user == userId)
            impl.delegate = self
        }

        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        private func userFetcher() -> Single<Void> {
            guard Realm().objects(_User.self).filter(_User.id == userId).first != nil else {
                return session.send(GetUser(id: userId)).map { $0.data }.do(onNext: { user in
                    write { realm in
                        realm.add(user, update: true)
                    }
                }).map { _ in }
            }
            return .just()
        }

        func timelineFetcher(from request: Request) -> Single<Request.Response>? {
            return userFetcher().flatMap { session.send(request) }
        }

        func timelineProcessResponse(_ response: Request.Response, refreshing: Bool, realm: Realm) throws -> [_Shot] {
            let owner = realm.object(ofType: _User.self, forPrimaryKey: Int(userId))
            let shots = response.data.elements.map { shot, team -> _Shot in
                shot._team = team
                shot._user = owner
                return shot
            }
            realm.add(shots, update: true)
            return shots
        }
    }
}

extension Model.UserShots {
    public var count: Int { return impl.cache.shots.count }
    public var startIndex: Int { return impl.cache.shots.startIndex }
    public var endIndex: Int { return impl.cache.shots.endIndex }
    public subscript(idx: Int) -> Shot { return impl.cache.shots[idx] }

    public func index(after i: Int) -> Int { return impl.cache.shots.index(after: i) }
}
