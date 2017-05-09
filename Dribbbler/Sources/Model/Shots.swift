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

extension Realm {
    func recreate<T: Cache>(_ object: T, of predicateFormat: String, _ args: Any...) {
        delete(objects(T.self).filter(NSPredicate(format: predicateFormat, argumentArray: args)))
        add(object)
    }
}

final class UserShotsCache: Cache {
    dynamic var _user: _User?
    let shots = List<_Shot>()

    convenience init(user: _User) {
        self.init()
        _user = user
    }
}

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
                    let user = response.data
                    realm.add(user, update: true)
                    realm.recreate(UserShotsCache(user: user), of: "_user._id == %@", Int(user.id))
                }
                return (.waiting, self.fetch)
            }
            return
        }
        RequestController(next ?? ListUserShots(id: user.id), stateHolder: self).run { paginator in
            let userId = Int(self.userId)
            write { realm in
                let owner = realm.object(ofType: _User.self, forPrimaryKey: userId)
                let shots = paginator.data.elements.map { shot, team -> _Shot in
                    shot._team = team
                    shot._user = owner
                    return shot
                }
                realm.add(shots, update: true)

                if let cache = realm.objects(UserShotsCache.self).filter("_user._id == %@", userId).first {
                    cache.update {
                        cache.shots.append(objectsIn: shots)
                    }
                }
            }
            self.next = paginator.data.next
            return self.next == nil ? .done : .waiting
        }
    }
}
