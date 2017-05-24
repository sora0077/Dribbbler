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
private final class ShotsCache: PaginatorCache {
    private dynamic var list: String?
    private dynamic var timeframe: String?
    private dynamic var sort: String?
    private let date = RealmOptional<Int>()
    let shots = List<_Shot>()
    override var liftime: TimeInterval { return 30.min }

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
    public final class Shots: Timeline, NetworkStateHolder {
        public enum List: String {
            case animated, attachments, debuts, playoffs, rebounds, terms
        }
        public enum Sort {
            case comments(Timeframe?), views(Timeframe?), recent
        }
        public private(set) lazy var isLoading: Driver<Bool> = self._isLoading.asDriver(onErrorJustReturn: false)
        public private(set) lazy var changes: Driver<Changes> = self._changes.asDriver(onErrorDriveWith: .empty())
        private let _changes = PublishSubject<Changes>()
        private let _isLoading = PublishSubject<Bool>()
        fileprivate var token: NotificationToken!
        fileprivate var next: ListShots?
        fileprivate let cache: ShotsCache
        fileprivate let initRequest: () -> ListShots
        fileprivate let filtered: (Realm) -> ShotsCache?
        var networkState: NetworkState = .waiting {
            didSet {
                _isLoading.onNext(networkState == .loading)
            }
        }

        public init(list: List? = nil, date: Date? = nil, sort: Sort? = nil) {
            let date = date?.dateWithoutTime
            let dateInt = date.flatMap { Int($0.timeIntervalSince1970) }
            initRequest = { ListShots(list: list?.actual, date: date, sort: sort?.actual) }
            filtered = {
                $0.objects(ShotsCache.self).filter(
                    ShotsCache.list == list?.rawValue &&
                    ShotsCache.timeframe == sort?.timeframe?.rawValue &&
                    ShotsCache.sort == sort?.rawValue &&
                    ShotsCache.date == dateInt).first }
            let realm = Realm()
            cache = filtered(realm) ?? realm.write {
                ShotsCache(list: list?.rawValue,
                           timeframe: sort?.timeframe?.rawValue,
                           sort: sort?.rawValue,
                           date: dateInt)
            }
            if !cache.next.isDone {
                next = cache.next.request() ?? ListShots()
            }
            token = cache.shots.addNotificationBlock { [weak self] ch in
                self?._changes.onNext(TimelineChanges(ch))
            }
        }
    }
}

extension Model.Shots {
    public func reload(force: Bool = false) {
        _fetch(refreshing: force || cache.isOutdated)
    }

    public func fetch() {
        _fetch(refreshing: cache.isOutdated)
    }

    private func _fetch(refreshing: Bool) {
        if refreshing && networkState != .loading { networkState = .waiting }
        if refreshing { next = initRequest() }
        RequestController(next, stateHolder: self).run { paginator in
            write { realm in
                let shots = paginator.data.elements.map { shot, userOrTeam, team -> _Shot in
                    shot._user = userOrTeam.user
                    shot._team = team
                    return shot
                }
                realm.add(shots, update: true)

                if let cache = self.filtered(realm) {
                    cache.update {
                        if refreshing {
                            cache.shots.removeAll()
                        }
                        cache.shots.distinctAppend(contentsOf: shots)
                        cache.next.setRequest(paginator.data.next)
                    }
                }
            }
            self.next = paginator.data.next
            print(self.next)
            return self.next == nil ? .done : .waiting
        }
    }
}

extension Model.Shots {
    public var count: Int { return cache.shots.count }
    public var startIndex: Int { return cache.shots.startIndex }
    public var endIndex: Int { return cache.shots.endIndex }
    public subscript(idx: Int) -> Shot { return cache.shots[idx] }

    public func index(after i: Int) -> Int { return cache.shots.index(after: i) }
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
