//
//  EntityTeam.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/02.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import DribbbleKit

final class _Team: Object, TeamData {  // swiftlint:disable:this type_name
    private(set) dynamic var id: Int = 0
    private(set) dynamic var name: String = ""
    private(set) dynamic var username: String = ""
    private(set) dynamic var bio: String = ""
    private(set) dynamic var location: String = ""
    private(set) dynamic var bucketsCount: Int = 0
    private(set) dynamic var commentsReceivedCount: Int = 0
    private(set) dynamic var followersCount: Int = 0
    private(set) dynamic var followingsCount: Int = 0
    private(set) dynamic var likesCount: Int = 0
    private(set) dynamic var likesReceivedCount: Int = 0
    private(set) dynamic var projectsCount: Int = 0
    private(set) dynamic var reboundsReceivedCount: Int = 0
    private(set) dynamic var shotsCount: Int = 0
    private(set) dynamic var canUploadShot: Bool = false
    private(set) dynamic var type: String = ""
    private(set) dynamic var pro: Bool = false
    private(set) dynamic var createdAt: Date = .distantPast
    private(set) dynamic var updatedAt: Date = .distantPast
    let _shots = LinkingObjects(fromType: _Shot.self, property: "_team")

    private(set) lazy var htmlURL: URL = URL(string: self._htmlUrl)!
    private(set) lazy var avatarURL: URL = URL(string: self._avatarUrl)!
    private(set) lazy var bucketsURL: URL = URL(string: self._bucketsUrl)!
    private(set) lazy var followersURL: URL = URL(string: self._followersUrl)!
    private(set) lazy var followingURL: URL = URL(string: self._followingUrl)!
    private(set) lazy var likesURL: URL = URL(string: self._likesUrl)!
    private(set) lazy var membersURL: URL = URL(string: self._membersUrl)!
    private(set) lazy var shotsURL: URL = URL(string: self._shotsUrl)!
    private(set) lazy var teamShotsURL: URL = URL(string: self._teamShotsUrl)!

    private dynamic var _htmlUrl: String = ""
    private dynamic var _avatarUrl: String = ""
    private dynamic var _bucketsUrl: String = ""
    private dynamic var _followersUrl: String = ""
    private dynamic var _followingUrl: String = ""
    private dynamic var _likesUrl: String = ""
    private dynamic var _membersUrl: String = ""
    private dynamic var _shotsUrl: String = ""
    private dynamic var _teamShotsUrl: String = ""

    override class func primaryKey() -> String? { return "id" }

    override class func ignoredProperties() -> [String] {
        return ["htmlURL", "avatarURL", "bucketsURL", "followersURL", "followingURL", "likesURL", "membersURL", "shotsURL", "teamShotsURL"]
    }

    convenience init(
        id: Identifier,
        name: String,
        username: String,
        htmlURL: URL,
        avatarURL: URL,
        bio: String,
        location: String,
        links: [String : URL],
        bucketsCount: Int,
        commentsReceivedCount: Int,
        followersCount: Int,
        followingsCount: Int,
        likesCount: Int,
        likesReceivedCount: Int,
        membersCount: Int,
        projectsCount: Int,
        reboundsReceivedCount: Int,
        shotsCount: Int,
        canUploadShot: Bool,
        type: String,
        pro: Bool,
        bucketsURL: URL,
        followersURL: URL,
        followingURL: URL,
        likesURL: URL,
        membersURL: URL,
        shotsURL: URL,
        teamShotsURL: URL,
        createdAt: Date,
        updatedAt: Date
        ) throws {
        self.init()
        self.id = Int(id)
        self.name = name
        self.username = username
        self._htmlUrl = htmlURL.absoluteString
        self._avatarUrl = avatarURL.absoluteString
        self.bio = bio
        self.location = location
        self.bucketsCount = bucketsCount
        self.commentsReceivedCount = commentsReceivedCount
        self.followersCount = followersCount
        self.followingsCount = followingsCount
        self.likesCount = likesCount
        self.likesReceivedCount = likesReceivedCount
        self.projectsCount = projectsCount
        self.reboundsReceivedCount = reboundsReceivedCount
        self.shotsCount = shotsCount
        self.canUploadShot = canUploadShot
        self.type = type
        self.pro = pro
        self._bucketsUrl = bucketsURL.absoluteString
        self._followersUrl = followersURL.absoluteString
        self._followingUrl = followingURL.absoluteString
        self._likesUrl = likesURL.absoluteString
        self._shotsUrl = shotsURL.absoluteString
        self._teamShotsUrl = teamShotsURL.absoluteString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
