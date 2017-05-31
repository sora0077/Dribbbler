//
//  ShotLikes.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import DribbbleKit
import PredicateKit

@objc(ShotLikesCache)
private class ShotLikesCache: PaginatorCache, TimelineCache {
    private dynamic var _shotId: Int = 0
    let objects = List<_Like>()
    override var liftime: TimeInterval { return 30.min }

    var shotId: Shot.Identifier { return DribbbleKit.Shot.Identifier(_shotId) }

    override class func primaryKey() -> String? { return "_shotId" }

    convenience init(shotId: Shot.Identifier) {
        self.init()
        _shotId = Int(shotId)
    }
}

extension ShotLikesCache {
    static let id = Attribute<Shot.Identifier>("_shotId")
}

extension Model {
    public final class ShotLikes: Timeline, TimelineDelegate {
        typealias Request = ListShotLikes
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var changes: Driver<Changes> { return impl.changes }
        private let id: Dribbbler.Shot.Identifier
        fileprivate let impl: _TimelineModel<ShotLikesCache, Model.ShotLikes>

        public init(id: Dribbbler.Shot.Identifier) {
            self.id = id
            impl = stateRepository(forKey: id, default: .init(
                request: ListShotLikes(id: id),
                cache: ShotLikesCache(shotId: id),
                predicate: ShotLikesCache.id == id))
            impl.delegate = self
        }

        @discardableResult
        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        func timelineFetcher(from request: ListShotLikes) -> Single<Request.Response>? {
            return Single<Shot?>.create(Shot(id: id)).flatMap { _ in session.send(request) }
        }

        func timelineProcessResponse(_ response: Request.Response, refreshing: Bool, realm: Realm) throws -> [_Like] {
            return response.data.elements.map { like, user in
                like._user = user
                return like
            }
        }
    }
}

extension Model.ShotLikes {
    public var count: Int { return impl.cache.objects.count }
    public var startIndex: Int { return impl.cache.objects.startIndex }
    public var endIndex: Int { return impl.cache.objects.endIndex }
    public subscript(idx: Int) -> Like { return impl.cache.objects[idx] }

    public func index(after i: Int) -> Int { return impl.cache.objects.index(after: i) }
}
