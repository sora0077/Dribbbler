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
    let shots = List<_Shot>()
    override var liftime: TimeInterval { return 30.min }
}

extension Model {
    public final class Shots: Timeline, NetworkStateHolder {
        public enum List {
            case animated, attachments, debuts, playoffs, rebounds, terms
        }
        public enum Sort {
            public enum Timeframe {
                case week, month, year, ever
            }
            case comments(Timeframe?), views(Timeframe?), recent
        }
        public private(set) lazy var changes: Driver<Changes> = self._changes.asDriver(onErrorDriveWith: .empty())
        fileprivate let _changes = PublishSubject<Changes>()
        fileprivate var token: NotificationToken!
        fileprivate var next: ListShots?
        fileprivate let cache: ShotsCache
        fileprivate let initRequest: () -> ListShots
        var networkState: NetworkState = .waiting

        public init(list: List? = nil, date: Date? = nil, sort: Sort? = nil) {
            initRequest = { ListShots(list: list?.actual, date: date, sort: sort?.actual) }
            let realm = Realm()
            cache = realm.objects(ShotsCache.self).first ?? realm.write {
                ShotsCache()
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
        if refreshing { next = initRequest() }
        guard let next = next else { return }
        RequestController(next, stateHolder: self).run { paginator in
            write { realm in
                let shots = paginator.data.elements.map { shot, user, team -> _Shot in
                    shot._user = user
                    shot._team = team
                    return shot
                }
                realm.add(shots, update: true)

                if let cache = realm.objects(ShotsCache.self).first {
                    cache.update {
                        if refreshing {
                            cache.shots.removeAll()
                        }
                        cache.shots.append(objectsIn: shots)
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
    fileprivate var actual: ListShots.Sort {
        switch self {
        case .comments(let timeframe): return .comments(timeframe?.actual)
        case .views(let timeframe): return .views(timeframe?.actual)
        case .recent: return .recent
        }
    }
}

extension Model.Shots.Sort.Timeframe {
    fileprivate var actual: ListShots.Timeframe {
        switch self {
        case .week: return .week
        case .month: return .month
        case .year: return .year
        case .ever: return .ever
        }
    }
}
