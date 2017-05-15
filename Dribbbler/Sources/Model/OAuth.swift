//
//  OAuth.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/10.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

private typealias _OAuth = DribbbleKit.OAuth  // swiftlint:disable:this type_name

public final class OAuth: NetworkStateHolder {
    public typealias Scope = DribbbleKit.OAuth.Scope
    public enum Error: Swift.Error {
        case parametricError
        case mismatchedState(String?, String?)
    }
    var networkState: NetworkState = .waiting

    public init() {

    }

    public func client() -> (id: String, secret: String, accessToken: String?)? {  // swiftlint:disable:this large_tuple
        guard let client = latestClient(Realm()) else { return nil }
        return (client.id, client.secret, client.authorization?.accessToken)
    }

    public func saveClient(id: String, secret: String) {
        write { realm in
            let client = _Client()
            client.id = id
            client.secret = secret
            realm.add(client, update: true)
        }
    }

    @discardableResult
    public func activate() -> Bool {
        guard let auth = latestClient(Realm())?.authorization else {
            return false
        }
        session.authorization = .init(accessToken: auth.accessToken, tokenType: auth.tokenType, scopes: auth.scopes)
        return true
    }

    public func authorizeURL(with scopes: [Scope], redirectURL: URL? = nil, state: String? = nil) throws -> URL {
        let realm = Realm()
        guard let client = latestClient(realm) else {
            throw Error.parametricError
        }
        try realm.write {
            client.state = state
            client.redirectURL = redirectURL
        }
        return _OAuth.authorizeURL(clientId: client.id, redirectURL: redirectURL, scopes: scopes, state: state)
    }

    public func fetchToken(from url: URL) throws {
        guard let client = latestClient(Realm()) else {
            throw Error.parametricError
        }
        if let redirect = client.redirectURL, url != redirect {
            throw Error.parametricError
        }
        let (code, state) = try _OAuth.parse(from: url)
        guard client.state == state else {
            throw Error.mismatchedState(client.state, state)
        }
        let request = _OAuth.GetToken(clientId: client.id, clientSecret: client.secret, code: code, redirectURL: client.redirectURL)
        RequestController(request, stateHolder: self).run { response in
            write { realm in
                let auth = _Authorization()
                auth.accessToken = response.data.accessToken
                auth.tokenType = response.data.tokenType
                auth.scopes = response.data.scopes
                realm.add(auth, update: true)

                if let client = latestClient(realm) {
                    client.authorization = auth
                    realm.add(client, update: true)
                    session.authorization = response.data
                } else {
                    throw Error.parametricError
                }
            }
            return .done
        }
    }
}

private func latestClient(_ realm: Realm) -> _Client? {
    return realm.objects(_Client.self).sorted(byKeyPath: _Client.createAt.key, ascending: false).first
}
