//
//  EntityShot.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/02.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

public protocol Shot {

}

final class _Shot: Entity, Shot, ShotData {  // swiftlint:disable:this type_name
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
    dynamic var _user: _User?
    dynamic var _team: _Team?

    override var description: String { return _description }
    private(set) lazy var htmlURL: URL = URL(string: self._htmlUrl)!
    private(set) lazy var attachmentsURL: URL = URL(string: self._attachmentsUrl)!
    private(set) lazy var bucketsURL: URL = URL(string: self._bucketsUrl)!
    private(set) lazy var commentsURL: URL = URL(string: self._commentsUrl)!
    private(set) lazy var likesURL: URL = URL(string: self._likesUrl)!
    private(set) lazy var projectsURL: URL = URL(string: self._projectsUrl)!
    private(set) lazy var reboundsURL: URL = URL(string: self._reboundsUrl)!

    private dynamic var _description: String = ""
    private dynamic var _htmlUrl: String = ""
    private dynamic var _attachmentsUrl: String = ""
    private dynamic var _bucketsUrl: String = ""
    private dynamic var _commentsUrl: String = ""
    private dynamic var _likesUrl: String = ""
    private dynamic var _projectsUrl: String = ""
    private dynamic var _reboundsUrl: String = ""

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
        self._htmlUrl = htmlURL.absoluteString
        self._attachmentsUrl = attachmentsURL.absoluteString
        self._bucketsUrl = bucketsURL.absoluteString
        self._commentsUrl = commentsURL.absoluteString
        self._likesUrl = likesURL.absoluteString
        self._projectsUrl = projectsURL.absoluteString
        self._reboundsUrl = reboundsURL.absoluteString
        self.animated = animated
    }
}
