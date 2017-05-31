//
//  Shots.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/23.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import DribbbleKit
import RealmSwift
import RxSwift
import RxCocoa
import PredicateKit

@objc(ShotsCache)
private final class ShotsCache: PaginatorCache, TimelineCache {
    private dynamic var list: String?
    private dynamic var timeframe: String?
    private dynamic var sort: String?
    private let date = RealmOptional<Int>()
    let shots = List<_Shot>()
    override var liftime: TimeInterval { return 30.min }

    var objects: List<_Shot> { return shots }

    convenience init(list: String?, timeframe: String?, sort: String?, date: Int?) {
        self.init()
        self.list = list
        self.timeframe = timeframe
        self.sort = sort
        self.date.value = date
    }
}

extension ShotsCache {
    static let list = Attribute<String>("list")
    static let timeframe = Attribute<String>("timeframe")
    static let sort = Attribute<String>("sort")
    static let date = Attribute<Int>("date")
}

extension Model {
    public final class Shots: Timeline, TimelineDelegate {
        typealias Request = ListShots
        public enum List: String {
            case animated, attachments, debuts, playoffs, rebounds, terms
        }
        public enum Sort {
            case comments(Timeframe?), views(Timeframe?), recent
        }
        public var isLoading: Driver<Bool> { return impl.isLoading }
        public var changes: Driver<Changes> { return impl.changes }
        fileprivate let impl: _TimelineModel<ShotsCache, Model.Shots>

        public init(list: List? = nil, date: Date? = nil, sort: Sort? = nil) {
            let date = date?.dateWithoutTime
            let dateInt = date.flatMap { Int($0.timeIntervalSince1970) }
            impl = stateRepository(forKey: Hash(list: list, date: date, sort: sort), default: .init(
                request: ListShots(list: list?.actual, date: date, sort: sort?.actual),
                cache: ShotsCache(list: list?.rawValue,
                                  timeframe: sort?.timeframe?.rawValue,
                                  sort: sort?.rawValue,
                                  date: dateInt),
                predicate: ShotsCache.list == list?.rawValue &&
                    ShotsCache.timeframe == sort?.timeframe?.rawValue &&
                    ShotsCache.sort == sort?.rawValue &&
                    ShotsCache.date == dateInt))
            impl.delegate = self
        }

        deinit {
            print("deinit", self)
        }

        public func reload(force: Bool = false) -> Bool {
            return impl.reload(force: force)
        }

        public func fetch() {
            impl.fetch()
        }

        func timelineProcessResponse(_ response: Request.Response, refreshing: Bool, realm: Realm) throws -> [_Shot] {
            return response.data.elements.map { shot, userOrTeam, team in
                shot._user = userOrTeam.user
                shot._team = team
                return shot
            }
        }
    }
}

private extension Model.Shots {
    struct Hash: Hashable {
        var list: List?
        var date: Date?
        var sort: Sort?

        var hashValue: Int {
            return "\(String(describing: list))\(String(describing: date))\(String(describing: sort))".hashValue
        }

        static func == (lhs: Hash, rhs: Hash) -> Bool {
            return lhs.list == rhs.list
                && lhs.sort?.rawValue == rhs.sort?.rawValue
                && lhs.sort?.timeframe?.rawValue == rhs.sort?.timeframe?.rawValue
                && lhs.date == rhs.date
        }
    }
}

extension Model.Shots {
    public var count: Int { return impl.cache.objects.count }
    public var startIndex: Int { return impl.cache.objects.startIndex }
    public var endIndex: Int { return impl.cache.objects.endIndex }
    public subscript(idx: Int) -> Shot { return impl.cache.objects[idx] }

    public func index(after i: Int) -> Int { return impl.cache.objects.index(after: i) }
}

// MARK: - 
extension Model.Shots.List {
    fileprivate var actual: ListShots.List {
        switch self {
        case .animated: return .animated
        case .attachments: return .attachments
        case .debuts: return .debuts
        case .playoffs: return .playoffs
        case .rebounds: return .rebounds
        case .terms: return .terms
        }
    }
}

extension Model.Shots.Sort {
    public enum Timeframe: String {
        case week, month, year, ever
    }
    fileprivate var rawValue: String {
        switch self {
        case .comments: return "comments"
        case .recent: return "recent"
        case .views: return "views"
        }
    }
    fileprivate var timeframe: Model.Shots.Sort.Timeframe? {
        switch self {
        case .comments(let timeframe), .views(let timeframe): return timeframe
        case .recent: return nil
        }
    }
    fileprivate var actual: ListShots.Sort {
        switch self {
        case .comments(let timeframe): return .comments(timeframe?.actual)
        case .views(let timeframe): return .views(timeframe?.actual)
        case .recent: return .recent
        }
    }
}

extension Model.Shots.Sort.Timeframe {
    fileprivate var actual: ListShots.Sort.Timeframe {
        switch self {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        case .ever: return .ever
        }
    }
}
