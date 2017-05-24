//
//  Model.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/20.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import DribbbleKit

protocol TimelineCache {
    associatedtype Element: Object
    var objects: List<Element> { get }
    var next: RequestCache { get }
    var isOutdated: Bool { get }
}

private extension Results {
    func filterIf(_ predicate: NSPredicate?) -> Results<T> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }
}

protocol TimelineDelegate: class {
    associatedtype Request: PaginatorRequest
    func timelinePrepareFetch() -> Bool
    func timelineFetcher(from request: Request) -> Single<Request.Response>?
    func timelineProcessResponse(_ response: Request.Response, refreshing: Bool) -> Request?
}

extension TimelineDelegate {
    func timelinePrepareFetch() -> Bool { return true }
    func timelineFetcher(from request: Request) -> Single<Request.Response>? { return nil }
}

public struct Model {
    class _EntityModel<Element: Object> {  // swiftlint:disable:this type_name

    }

    // swiftlint:disable:next type_name
    class _TimelineModel<Cache: TimelineCache, Delegate: TimelineDelegate> where Cache: Object {
        typealias Request = Delegate.Request
        private(set) lazy var isLoading: Driver<Bool> = self._isLoading.asDriver(onErrorJustReturn: false)
        private(set) lazy var changes: Driver<TimelineChanges> = self._changes.asDriver(onErrorDriveWith: .empty())
        private let _changes = PublishSubject<TimelineChanges>()
        private let _isLoading = PublishSubject<Bool>()

        weak var delegate: Delegate?
        let cache: Cache
        private let initRequest: () -> Request
        private let predicate: () -> NSPredicate?
        private var token: NotificationToken!
        private var next: Request?
        private var networkState: NetworkState = .waiting {
            didSet { _isLoading.onNext(networkState == .loading)
                print("\(Delegate.self) \(networkState)")
            }
        }
        private let disposeBag = DisposeBag()

        init(request initRequest: @escaping () -> Request,
             cache initCache: () -> Cache,
             predicate: @escaping () -> NSPredicate?) {
            self.initRequest = initRequest
            self.predicate = predicate

            let realm = Realm()
            cache = realm.objects(Cache.self).filterIf(predicate()).first ?? realm.write(initCache)
            if !cache.next.isDone {
                next = cache.next.request() ?? initRequest()
            }
            token = cache.objects.addNotificationBlock { [weak self] ch in
                self?._changes.onNext(.init(ch))
            }
        }

        func cache(from realm: Realm) -> Cache? {
            return realm.objects(Cache.self).filterIf(self.predicate()).first
        }

        func prepareFetch() -> Bool { return true }

        func reload(force: Bool) {
            _fetch(refreshing: force || cache.isOutdated)
        }

        func fetch() {
            _fetch(refreshing: cache.isOutdated)
        }

        func fetcher() -> Single<Request.Response?> {
            guard let next = next else { return .just(nil) }
            let fetcher = delegate?.timelineFetcher(from: next) ?? session.send(next)
            return fetcher.map { $0 }
        }

        func _fetch(refreshing: Bool) {
            guard networkState.isRunnable else { return }
            guard delegate?.timelinePrepareFetch() ?? false else { return }
            if refreshing && networkState != .loading { networkState = .waiting }
            if refreshing { next = initRequest() }
            disposeBag.insert(
                fetcher()
                    .do(
                        onSubscribe: { [weak self] _ in
                            self?.networkState = .loading
                        })
                    .subscribe(
                        onSuccess: { [weak self] response in
                            guard let response = response else {
                                self?.networkState = .done
                                return
                            }
                            let next = self?.delegate?.timelineProcessResponse(response, refreshing: refreshing)
                            self?.networkState = next == nil ? .done : .waiting
                            print(next)
                        },
                        onError: { [weak self] error in
                            self?.networkState = .error(error)
                        })
            )
        }
    }
}
