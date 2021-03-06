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

extension Single {
    static func create<M: ModelOperation>(_ model: M) -> Single<M.Data?> {
        if let data = model.data {
            return .just(data)
        }
        return Single.create { observer in
            let disposable = model.change.filter { $0 == .update }.drive(onNext: { _ in
                observer(.success(model.data))
            })
            model.reload(force: false)

            return Disposables.create([disposable])
        }
    }
}

extension Model {
    public final class User: ModelOperation, EntityDelegate {
        typealias Request = GetUser
        typealias Element = _User
        public var data: Dribbbler.User? { return impl.data }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<EntityChange> { return impl.change }
        fileprivate let impl: _EntityModel<_User, Model.User>

        public init(id: Dribbbler.User.Identifier) {
            impl = stateRepository(forKey: id, default: .init(request: GetUser(id: id), predicate: _User.id == id))
            impl.delegate = self
        }

        deinit {
            print("deinit", self)
        }

        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
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
    public final class Authenticated: ModelOperation, EntityDelegate {
        typealias Request = GetAuthenticatedUser
        typealias Element = _User
        public var data: Dribbbler.User? { return impl.data?.user }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<EntityChange> { return impl.change }
        fileprivate let impl: Model._EntityModel<AuthenticatedUserCache, Model.User.Authenticated>

        public init() {
            impl = stateRepository(.init(request: GetAuthenticatedUser(), predicate: nil))
            impl.delegate = self
        }

        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
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
