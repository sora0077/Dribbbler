//
//  UserShotsRepository.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/19.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation

public let repository = Repositories()

public final class Repositories {
    public let userShots = UserShotsRepository()
}

struct Weak<T: AnyObject> {
    let value: T?
    init(_ value: T) {
        self.value = value
    }
}

public final class UserShotsRepository {
    private var cache: [User.Identifier: Weak<UserShots>] = [:]

    public subscript(user user: User) -> UserShots {
        return self[userId: user.id]
    }

    public subscript(userId userId: User.Identifier) -> UserShots {
        if let shots = cache[userId]?.value { return shots }
        print("create new UserShots(userId: \(Int(userId)))")
        let shots = UserShots(userId: userId)
        cache[userId] = Weak(shots)
        return shots
    }
}
