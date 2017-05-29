//
//  EntityComment.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

public protocol Comment {
    typealias Identifier = CommentData.Identifier
    var body: String { get }
}

final class _Comment: Entity, Comment, CommentData {  // swiftlint:disable:this type_name
    private(set) dynamic var _id: Int = 0
    private(set) dynamic var body: String = ""
    private(set) dynamic var likesCount: Int = 0
    private(set) dynamic var createdAt: Date = .distantPast
    private(set) dynamic var updatedAt: Date = .distantPast

    private(set) lazy var likesURL: URL = URL(string: self._likesUrl)!
    private dynamic var _likesUrl: String = ""

    dynamic var _user: _User?

    override class func primaryKey() -> String? { return "_id" }

    override class func ignoredProperties() -> [String] {
        return ["likesURL"]
    }

    convenience init(
        id: Identifier,
        body: String,
        likesCount: Int,
        likesURL: URL,
        createdAt: Date,
        updatedAt: Date) throws {
        self.init()
        self._id = Int(id)
        self.body = body
        self.likesCount = likesCount
        self._likesUrl = likesURL.absoluteString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
