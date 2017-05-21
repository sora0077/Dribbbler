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
    public let users = UserRepository()
}

struct Weak<T: AnyObject> {
    let value: T?
    init(_ value: T) {
        self.value = value
    }
}

public final class UserRepository {
    private var cache: [User.Identifier: Weak<Model.User>] = [:]

    public subscript(id id: User.Identifier) -> Model.User {
        if let user = cache[id]?.value { return user }
        print("create new User(id: \(Int(id)))")
        let user = Model.User(id: id)
        cache[id] = Weak(user)
        return user
    }
}

public final class UserShotsRepository {
    private var cache: [User.Identifier: Weak<Model.UserShots>] = [:]

    public subscript(user user: User) -> Model.UserShots {
        return self[userId: user.id]
    }

    public subscript(userId userId: User.Identifier) -> Model.UserShots {
        if let shots = cache[userId]?.value { return shots }
        print("create new UserShots(userId: \(Int(userId)))")
        let shots = Model.UserShots(userId: userId)
        cache[userId] = Weak(shots)
        return shots
    }
}
