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

extension Model {
    public final class Shot: EntityDelegate {
        typealias Request = GetShot
        typealias Element = _Shot
        public var data: Dribbbler.Shot? { return impl.data }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var change: Driver<Void> { return impl.change }
        fileprivate let impl: _EntityModel<_Shot, Model.Shot>

        init(id: Dribbbler.Shot.Identifier) {
            impl = _EntityModel(request: GetShot(id: id), predicate: _Shot.id == id)
            impl.delegate = self
        }

        public func reload(force: Bool = false) {
            impl.reload(force: force)
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
    public final class Like {
        private let id: Shot.Identifier
        private let disposeBag = DisposeBag()

        public init(id: Shot.Identifier) {
            self.id = id
        }

        public func toggle() {
            let user = Model.User.Authenticated()
            if user.data == nil {
                user.fetch()
            }
            disposeBag.insert(
                session.send(LikeShot(id: id)).subscribe(onSuccess: { print($0) })
            )
        }
    }
}
