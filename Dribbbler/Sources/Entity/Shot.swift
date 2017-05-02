//
//  Shot.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/02.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

final class _Shot: Object, ShotData {  // swiftlint:disable:this type_name
    private(set) dynamic var id: Int = 0
    private(set) dynamic var title: String = ""
    private(set) dynamic var width: Int = 0
    private(set) dynamic var height: Int = 0
    private(set) dynamic var viewsCount: Int = 0
    private(set) dynamic var likesCount: Int = 0
    private(set) dynamic var commentsCount: Int = 0
    private(set) dynamic var attachmentsCount: Int = 0
    private(set) dynamic var reboundsCount: Int = 0
    private(set) dynamic var bucketsCount: Int = 0
    private(set) dynamic var createdAt: Date = .distantPast
    private(set) dynamic var updatedAt: Date = .distantPast
    private(set) dynamic var animated: Bool = false

    override var description: String { return _description }
    private(set) lazy var htmlURL: URL = URL(string: self._html)!
    private(set) lazy var attachmentsURL: URL = URL(string: self._attachments)!
    private(set) lazy var bucketsURL: URL = URL(string: self._buckets)!
    private(set) lazy var commentsURL: URL = URL(string: self._comments)!
    private(set) lazy var likesURL: URL = URL(string: self._likes)!
    private(set) lazy var projectsURL: URL = URL(string: self._projects)!
    private(set) lazy var reboundsURL: URL = URL(string: self._rebounds)!

    private dynamic var _description: String = ""
    private dynamic var _html: String = ""
    private dynamic var _attachments: String = ""
    private dynamic var _buckets: String = ""
    private dynamic var _comments: String = ""
    private dynamic var _likes: String = ""
    private dynamic var _projects: String = ""
    private dynamic var _rebounds: String = ""

    override class func primaryKey() -> String? { return "id" }

    override class func ignoredProperties() -> [String] {
        return ["htmlURL", "attachmentsURL", "bucketsURL", "commentsURL", "likesURL", "projectsURL", "reboundsURL"]
    }

    convenience init(
        id: Identifier,
        title: String,
        description: String,
        width: Int,
        height: Int,
        images: [String : URL],
        viewsCount: Int,
        likesCount: Int,
        commentsCount: Int,
        attachmentsCount: Int,
        reboundsCount: Int,
        bucketsCount: Int,
        createdAt: Date,
        updatedAt: Date,
        htmlURL: URL,
        attachmentsURL: URL,
        bucketsURL: URL,
        commentsURL: URL,
        likesURL: URL,
        projectsURL: URL,
        reboundsURL: URL,
        animated: Bool,
        tags: [String]
        ) throws {
        self.init()
        self.id = Int(id)
        self.title = title
        self._description = description
        self.width = width
        self.height = height
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.attachmentsCount = attachmentsCount
        self.reboundsCount = reboundsCount
        self.bucketsCount = bucketsCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self._html = htmlURL.absoluteString
        self._attachments = attachmentsURL.absoluteString
        self._buckets = bucketsURL.absoluteString
        self._comments = commentsURL.absoluteString
        self._likes = likesURL.absoluteString
        self._projects = projectsURL.absoluteString
        self._rebounds = reboundsURL.absoluteString
        self.animated = animated
    }
}
