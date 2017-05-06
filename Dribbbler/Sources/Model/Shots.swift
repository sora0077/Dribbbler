//
//  Shots.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import DribbbleKit

protocol Fetcher: NetworkStateHolder {
    associatedtype Request: PaginatorRequest

    func _request() -> Request?
    func _fetch()
}

//extension Fetcher {
//    func _fetch() {
//        guard let request = _request() else { return }
//        RequestController(request, stateHolder: self).run { response in
//            
//        }
//    }
//}

public final class Shots {
    public init() {

    }
}

public final class UserShots: NetworkStateHolder {
    private let userId: User.Identifier
    private var next: ListUserShots?
    var networkState: NetworkState = .waiting

    public convenience init(user: User) {
        self.init(userId: user.id)
    }

    public init(userId: User.Identifier) {
        self.userId = userId
    }

    public func reload(force: Bool = false) {
    }

    public func fetch() {
        guard let user = Realm().object(ofType: _User.self, forPrimaryKey: Int(userId)) else {
            RequestController(GetUser(id: userId), stateHolder: self).runNext { response in
                write { realm in
                    realm.add(response.data, update: true)
                }
                return (.waiting, self.fetch)
            }
            return
        }
        RequestController(next ?? ListUserShots(id: user.id), stateHolder: self).run { paginator in
            write { realm in
                let owner = realm.object(ofType: _User.self, forPrimaryKey: Int(self.userId))
                paginator.data.elements.forEach { shot, team in
                    shot._team = team
                    shot._user = owner
                    realm.add(shot, update: true)
                }
            }
            self.next = paginator.data.next
            return self.next == nil ? .done : .waiting
        }
    }
}
