//
//  User.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/20.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import PredicateKit

extension Model {
    public final class User: EntityDelegate {
        typealias Request = GetUser
        typealias Element = _User
        public var data: Dribbbler.User? { return impl.data }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<Void> { return impl.change }
        fileprivate let impl: _EntityModel<_User, Model.User>

        init(id: Dribbbler.User.Identifier) {
            impl = .init(request: GetUser(id: id), predicate: _User.id == id)
            impl.delegate = self
        }

        public func reload(force: Bool = false) {
            impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }
    }
}

@objc(AuthenticatedUserCache)
private class AuthenticatedUserCache: Entity {
    private dynamic var pk: Int = 0
    dynamic var user: _User?

    override class func primaryKey() -> String? { return "pk" }
}

extension Model.User {
    public final class Authenticated: EntityDelegate {
        typealias Request = GetAuthenticatedUser
        typealias Element = _User
        public var data: Dribbbler.User? { return impl.data?.user }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<Void> { return impl.change }
        fileprivate let impl: Model._EntityModel<AuthenticatedUserCache, Model.User.Authenticated>

        init() {
            impl = .init(request: GetAuthenticatedUser(), predicate: nil)
            impl.delegate = self
        }

        public func reload(force: Bool = false) {
            impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        func entityProcessResponse(_ response: Request.Response, realm: Realm) throws {
            let cache = AuthenticatedUserCache()
            cache.user = response.data
            realm.add(cache, update: true)
        }
    }
}
