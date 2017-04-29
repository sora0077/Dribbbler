//
//  User.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import DribbbleKit
import RealmSwift

final class _User: Object, UserData {  // swiftlint:disable:this type_name
    private(set) dynamic var id: Int = 0
    private(set) dynamic var name: String = ""
    private(set) dynamic var username: String = ""
    private(set) dynamic var  bio: String = ""
    private(set) dynamic var location: String = ""
    private(set) dynamic var bucketsCount: Int = 0
    private(set) dynamic var commentsRecievedCount: Int = 0
    private(set) dynamic var followersCount: Int = 0
    private(set) dynamic var followingsCount: Int = 0
    private(set) dynamic var likesCount: Int = 0
    private(set) dynamic var likesReceivedCount: Int = 0
    private(set) dynamic var projectsCount: Int = 0
    private(set) dynamic var reboundsReceivedCount: Int = 0
    private(set) dynamic var shotsCount: Int = 0
    private(set) dynamic var teamsCount: Int = 0
    private(set) dynamic var canUploadShot: Bool = false
    private(set) dynamic var type: String = ""
    private(set) dynamic var pro: Bool = false
    private(set) dynamic var createdAt: Date = .distantPast
    private(set) dynamic var updatedAt: Date = .distantPast

    private(set) lazy var htmlURL: URL = URL(string: self._html)!
    private(set) lazy var avatarURL: URL = URL(string: self._avatar)!
    private(set) lazy var bucketsURL: URL = URL(string: self._buckets)!
    private(set) lazy var followersURL: URL = URL(string: self._followers)!
    private(set) lazy var followingURL: URL = URL(string: self._following)!
    private(set) lazy var likesURL: URL = URL(string: self._likes)!
    private(set) lazy var shotsURL: URL = URL(string: self._shots)!
    private(set) lazy var teamsURL: URL = URL(string: self._teams)!

    private dynamic var _html: String = ""
    private dynamic var _avatar: String = ""
    private dynamic var _buckets: String = ""
    private dynamic var _followers: String = ""
    private dynamic var _following: String = ""
    private dynamic var _likes: String = ""
    private dynamic var _shots: String = ""
    private dynamic var _teams: String = ""

    override class func primaryKey() -> String? { return "id" }

    override class func ignoredProperties() -> [String] {
        return ["htmlURL", "avatarURL", "bucketsURL", "followersURL", "followingURL", "likesURL", "shotsURL", "teamsURL"]
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
        commentsRecievedCount: Int,
        followersCount: Int,
        followingsCount: Int,
        likesCount: Int,
        likesReceivedCount: Int,
        projectsCount: Int,
        reboundsReceivedCount: Int,
        shotsCount: Int,
        teamsCount: Int,
        canUploadShot: Bool,
        type: String,
        pro: Bool,
        bucketsURL: URL,
        followersURL: URL,
        followingURL: URL,
        likesURL: URL,
        shotsURL: URL,
        teamsURL: URL,
        createdAt: Date,
        updatedAt: Date
        ) throws {
        self.init()
        self.id = Int(id)
        self.name = name
        self.username = username
        self._html = htmlURL.absoluteString
        self._avatar = avatarURL.absoluteString
        self.bio = bio
        self.location = location
        self.bucketsCount = bucketsCount
        self.commentsRecievedCount = commentsRecievedCount
        self.followersCount = followersCount
        self.followingsCount = followingsCount
        self.likesCount = likesCount
        self.likesReceivedCount = likesReceivedCount
        self.projectsCount = projectsCount
        self.reboundsReceivedCount = reboundsReceivedCount
        self.shotsCount = shotsCount
        self.teamsCount = teamsCount
        self.canUploadShot = canUploadShot
        self.type = type
        self.pro = pro
        self._buckets = bucketsURL.absoluteString
        self._followers = followersURL.absoluteString
        self._following = followingURL.absoluteString
        self._likes = likesURL.absoluteString
        self._shots = shotsURL.absoluteString
        self._teams = teamsURL.absoluteString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
