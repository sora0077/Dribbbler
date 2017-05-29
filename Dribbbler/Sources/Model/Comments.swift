//
//  Comments.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import DribbbleKit
import PredicateKit

@objc(CommentsCache)
private class CommentsCache: PaginatorCache, TimelineCache {
    private dynamic var _shotId: Int = 0
    let comments = List<_Comment>()
    override var liftime: TimeInterval { return 30.min }

    var shotId: Shot.Identifier { return DribbbleKit.Shot.Identifier(_shotId) }
    var objects: List<_Comment> { return comments }

    override class func primaryKey() -> String? { return "_shotId" }

    convenience init(shotId: Shot.Identifier) {
        self.init()
        _shotId = Int(shotId)
    }
}

extension CommentsCache {
    static let id = Attribute<Shot.Identifier>("_shotId")
}

extension Model {
    public final class Comments: Timeline, TimelineDelegate {
        typealias Request = ListShotComments
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var changes: Driver<Changes> { return impl.changes }
        fileprivate let impl: _TimelineModel<CommentsCache, Model.Comments>

        public init(id: Shot.Identifier) {
            impl = _TimelineModel(
                request: ListShotComments(id: id),
                cache: CommentsCache(shotId: id),
                predicate: CommentsCache.id == id)
            impl.delegate = self
        }

        @discardableResult
        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        func timelineProcessResponse(_ response: Request.Response, refreshing: Bool, realm: Realm) throws -> [_Comment] {
            return response.data.elements.map { comment, user in
                comment._user = user
                return comment
            }
        }
    }
}

extension Model.Comments {
    public var count: Int { return impl.cache.objects.count }
    public var startIndex: Int { return impl.cache.objects.startIndex }
    public var endIndex: Int { return impl.cache.objects.endIndex }
    public subscript(idx: Int) -> Comment { return impl.cache.objects[idx] }

    public func index(after i: Int) -> Int { return impl.cache.objects.index(after: i) }
}
