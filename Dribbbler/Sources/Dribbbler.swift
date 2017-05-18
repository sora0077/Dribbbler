//
//  Dribbbler.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/05.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit
import APIKit
import Result

typealias Session = DribbbleKit.Session
typealias GetUser = DribbbleKit.GetUser<_User>
typealias ListUserShots = DribbbleKit.ListUserShots<_Shot, _Team>

func Realm() -> RealmSwift.Realm {
    return try! RealmSwift.Realm()  // swiftlint:disable:this force_try
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

class ASessionAdapter: URLSessionAdapter {
    override func createTask(with URLRequest: URLRequest, handler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionTask {
        return super.createTask(with: URLRequest, handler: { (data, response, error) in
            print(data.flatMap { String(data: $0, encoding: .utf8) } ?? "[]")
            handler(data, response, error)
        })
    }
}

//let session = DribbbleKit.Session(adapter: ASessionAdapter(configuration: .default))
let session: Session = {
    DribbbleKit.setup(.init(perPage: 100))
    return Session.shared
}()

public enum NetworkState {
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
}

protocol NetworkStateHolder: class {
    var networkState: NetworkState { get set }
}

final class RequestController<Request: DribbbleKit.Request> {
    private let request: Request
    private let session: Session
    private let holder: NetworkStateHolder

    init(_ request: Request, session: Session = Dribbbler.session, stateHolder: NetworkStateHolder) {
        self.request = request
        self.session = session
        holder = stateHolder
    }

    func runNext(_ completion: @escaping (Request.Response) -> (NetworkState, (() -> Void)?)) {
        guard holder.networkState.isRunnable else { return }
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

func print(_ items: Any?..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items.map(String.init(describing:)), separator: separator, terminator: terminator)
}
