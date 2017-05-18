//
//  Cache.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/09.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

class Cache: Object {
    private(set) dynamic var createAt: Date = Date()
    private(set) dynamic var updateAt: Date = .distantPast
    var liftime: TimeInterval { fatalError() }
    var isOutdated: Bool { return Date().timeIntervalSince(updateAt) > liftime }

    func update(_ block: () -> Void) {
        block()
        updateAt = Date()
    }
}

class RequestCache: Object {
    private dynamic var path: String = ""
    private dynamic var parametersJson: Data?
    var parameters: Any? {
        get {
            guard let data = parametersJson else { return nil }
            return try? JSONSerialization.jsonObject(with: data, options: [])
        }
        set {
            if let object = newValue {
                parametersJson = try? JSONSerialization.data(withJSONObject: object, options: [])
            } else {
                parametersJson = nil
            }
        }
    }
    private(set) dynamic var isDone: Bool = false

    override class func ignoredProperties() -> [String] {
        return ["parameters"]
    }

    func request<Request: PaginatorRequest>() -> Request? {
        guard let parameters = parameters as? [String: Any], !path.isEmpty else { return nil }
        return try? Request(path: path, parameters: parameters)
    }

    func setRequest<Request: PaginatorRequest>(_ request: Request?) {
        path = request?.path ?? ""
        parameters = request?.parameters
        isDone = request == nil
    }
}

class PaginatorCache: Cache {
    private dynamic var _next: RequestCache? = RequestCache()
    var next: RequestCache { return _next! }
}
