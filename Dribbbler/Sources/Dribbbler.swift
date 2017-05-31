//
//  Dribbbler.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import DribbbleKit
import APIKit
import Result

typealias Session = DribbbleKit.Session
typealias GetUser = DribbbleKit.GetUser<_User>
typealias GetAuthenticatedUser = DribbbleKit.GetAuthenticatedUser<_User>
typealias GetShot = DribbbleKit.GetShot<_Shot, _User, _Team>
typealias ListShots = DribbbleKit.ListShots<_Shot, _User, _Team>
typealias ListUserShots = DribbbleKit.ListUserShots<_Shot, _Team>
typealias ListShotComments = DribbbleKit.ListShotComments<_Comment, _User>
typealias ListShotLikes = DribbbleKit.ListShotLikes<_Like, _User>
typealias GetLike = DribbbleKit.GetLike<_Like>
typealias LikeShot = DribbbleKit.LikeShot<_Like>
typealias UnlikeShot = DribbbleKit.UnlikeShot

func Realm() -> RealmSwift.Realm {
    let config = RealmSwift.Realm.Configuration.defaultConfiguration
//    config.inMemoryIdentifier = "jp.sora0077.realm"
    return try! RealmSwift.Realm(configuration: config)  // swiftlint:disable:this force_try
}

func write(_ block: (Realm) throws -> Void) {
    do {
        let realm = try RealmSwift.Realm()
        try realm.write {
            try block(realm)
        }
    } catch {
        print(error)
    }
}

func write<C: ThreadConfined>(_ ref1: ThreadSafeReference<C>?, _ block: (Realm, C?) throws -> Void) {
    do {
        let realm = try RealmSwift.Realm()
        let ref1 = ref1.flatMap(realm.resolve)
        try realm.write {
            try block(realm, ref1)
        }
    } catch {
        print(error)
    }
}

class ASessionAdapter: URLSessionAdapter {
    override func createTask(with URLRequest: URLRequest, handler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionTask {
        return super.createTask(with: URLRequest, handler: { (data, response, error) in
            print(data.flatMap { String(data: $0, encoding: .utf8) } ?? "[]")
            handler(data, response, error)
        })
    }
}

let session: Session = {
    DribbbleKit.setup(.init(perPage: 40))
    return Session.shared
//    return DribbbleKit.Session(adapter: ASessionAdapter(configuration: .default))
}()

public enum NetworkState: Equatable {
    case waiting
    case loading
    case error(Error)
    case done

    var isRunnable: Bool {
        switch self {
        case .waiting: return true
        default: return false
        }
    }

    public static func == (lhs: NetworkState, rhs: NetworkState) -> Bool {
        switch (lhs, rhs) {
        case (.waiting, .waiting): return true
        case (.loading, .loading): return true
        case (.error, .error): return true
        case (.done, .done): return true
        default: return false
        }
    }
}

protocol NetworkStateHolder: class {
    var networkState: NetworkState { get set }
}

final class RequestController<Request: DribbbleKit.Request> {
    private let request: Request?
    private let session: Session
    private let holder: NetworkStateHolder

    init(_ request: Request?, session: Session = Dribbbler.session, stateHolder: NetworkStateHolder) {
        self.request = request
        self.session = session
        holder = stateHolder
    }

    func runNext(_ completion: @escaping (Request.Response) -> (NetworkState, (() -> Void)?)) {
        guard holder.networkState.isRunnable else { return }
        guard let request = request else {
            holder.networkState = .done
            return
        }
        holder.networkState = .loading
        session.send(request) { result in
            switch result {
            case .success(let response):
                let (state, next) = completion(response)
                self.holder.networkState = state
                next?()
            case .failure(let error):
                print(error)
                self.holder.networkState = .error(error)
            }
        }
    }

    func run(_ completion: @escaping (Request.Response) -> NetworkState) {
        runNext { response in
            return (completion(response), nil)
        }
    }
}

extension UserOrTeam {
    var user: User? {
        switch self {
        case .user(let user): return user
        case .team: return nil
        }
    }
}

extension Session {
    func send<Request: DribbbleKit.Request>(_ request: Request) -> Single<Request.Response> {
        return Single.create { observer in
            let task = self.send(request) { result in
                switch result {
                case .success(let response):
                    observer(.success(response))
                case .failure(let error):
                    observer(.error(error))
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }
    }
}

func print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items.map(String.init(describing:)), separator: separator, terminator: terminator)
}
