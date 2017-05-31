//
//  Shot.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import PredicateKit

extension Shot {
    public var model: Model.Shot { return .init(id: id) }
}

extension Model {
    public final class Shot: ModelOperation, EntityDelegate {
        typealias Request = GetShot
        typealias Element = _Shot
        public var data: Dribbbler.Shot? { return impl.data }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<EntityChange> { return impl.change }
        fileprivate let id: Dribbbler.Shot.Identifier
        fileprivate let impl: _EntityModel<_Shot, Model.Shot>

        public init(id: Dribbbler.Shot.Identifier) {
            self.id = id
            impl = stateRepository(forKey: id, default: .init(request: GetShot(id: id), predicate: _Shot.id == id))
            impl.delegate = self
        }

        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        func entityProcessResponse(_ response: Request.Response, realm: Realm) throws {
            response.data.shot._user = response.data.userOrTeam.user
            response.data.shot._team = response.data.team
            realm.add(response.data.shot, update: true)
        }
    }
}

extension Model.Shot {
    public final class Like: ActionDelegate {
        private let id: Shot.Identifier
        private let disposeBag = DisposeBag()
        private let impl: Model._ActionModel<Model.Shot.Like>

        public init(id: Shot.Identifier) {
            self.id = id
            impl = stateRepository(forKey: id, default: .init())
            impl.delegate = self
        }

        deinit {
            print("deinit Model.Shot.Like")
        }

        public func action() {
            impl.action()
        }

        func actionGeberator() -> Observable<Void> {
            let id = self.id
            let precond = Observable.combineLatest(
                Single<User?>.create(Model.User.Authenticated()).map { $0?.impl }.map(reference).asObservable(),
                session.send(GetLike(id: id)).map { $0.data }.asObservable())

            let likeAction = { (user: ThreadSafeReference<_User>?) -> Observable<Void> in
                session.send(LikeShot(id: id))
                    .map { $0.data }
                    .do(onNext: { like in
                        write(user) { realm, user in
                            like._user = user
                            realm.add(like, update: true)
                        }
                    })
                    .map { _ in }.asObservable()
            }
            let unlikeAction = { (like: _Like?) -> Observable<Void> in
                session.send(UnlikeShot(id: id))
                    .do(onNext: { _ in
                        write { realm in
                            if let like = like {
                                realm.add(like, update: true)
                                realm.delete(like)
                            }
                        }
                    })
                    .map { _ in }.asObservable()
            }
            return precond.flatMap { user, like in like == nil ? likeAction(user) : unlikeAction(like) }
        }
    }

    public var like: Like { return Like(id: id) }
}
