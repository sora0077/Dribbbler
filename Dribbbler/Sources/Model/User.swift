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
    public final class User: NetworkStateHolder {
        public var data: Dribbbler.User? { return cache.first }
        public private(set) lazy var change: Driver<Void> = self._change.asDriver(onErrorDriveWith: .empty())
        private let _change = PublishSubject<Void>()
        fileprivate let id: Dribbbler.User.Identifier
        fileprivate var cache: Results<_User>
        private var token: NotificationToken!
        var networkState: NetworkState = .waiting

        init(id: Dribbbler.User.Identifier) {
            self.id = id
            cache = Realm().objects(_User.self).filter(_User.id == id)
            token = cache.addNotificationBlock { [weak self] _ in
                self?._change.onNext(())
            }
            networkState = data == nil ? .waiting : .done
        }
    }
}

extension Model.User {
    public func reload(force: Bool) {
        _fetch(refreshing: force || cache.first?.isOutdated ?? true)
    }

    public func fetch() {
        _fetch(refreshing: cache.first?.isOutdated ?? true)
    }

    private func _fetch(refreshing: Bool) {
        if refreshing && networkState == .done { networkState = .waiting }
        RequestController(GetUser(id: id), stateHolder: self).run { response in
            write { realm in
                realm.add(response.data, update: true)
            }
            return .done
        }
    }
}
