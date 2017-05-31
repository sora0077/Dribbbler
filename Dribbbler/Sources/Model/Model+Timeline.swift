//
//  Model+Timeline.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/31.
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

    func update(_ block: () throws -> Void) rethrows
}

protocol TimelineDelegate: class {
    associatedtype Request: PaginatorRequest
    associatedtype Element: Object
    func timelineFetcher(from request: Request) -> Single<Request.Response>?
    func timelineProcessResponse(_ response: Request.Response, refreshing: Bool, realm: Realm) throws -> [Element]
}

extension TimelineDelegate {
    func timelineFetcher(from request: Request) -> Single<Request.Response>? { return nil }
}

private extension Results {
    func filterIf(_ predicate: NSPredicate?) -> Results<T> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }
}

extension Model {
    // swiftlint:disable:next type_name
    final class _TimelineModel<Cache: TimelineCache, Delegate: TimelineDelegate>
        where
        Cache: Object,
        Cache.Element == Delegate.Element,
        Delegate.Request.Response == DribbbleKit.Response<Page<Delegate.Request>> {
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

        init(request initRequest: @autoclosure @escaping () -> Request,
             cache initCache: @autoclosure () -> Cache,
             predicate: @autoclosure @escaping () -> NSPredicate?) {
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

        deinit {
            print("deinit", self)
        }

        func cache(from realm: Realm) -> Cache? {
            return realm.objects(Cache.self).filterIf(self.predicate()).first
        }

        func reload(force: Bool) -> Bool {
            guard force || cache.isOutdated else { return false }
            _fetch(refreshing: true)
            return true
        }

        func fetch() {
            _fetch(refreshing: cache.isOutdated)
        }

        private func fetcher(refreshing: Bool) -> Single<Request.Response?> {
            if refreshing { next = initRequest() }
            guard let next = next else { return .just(nil) }
            print("fetch: ", next)
            let fetcher = delegate?.timelineFetcher(from: next) ?? session.send(next)
            return fetcher.map { $0 }
        }

        private func _fetch(refreshing: Bool) {
            print(networkState)
            if refreshing && networkState != .loading { networkState = .waiting }
            guard networkState.isRunnable else { return }
            var strongDelegate = delegate
            disposeBag.insert(
                fetcher(refreshing: refreshing)
                    .do(
                        onSubscribe: { [weak self] _ in
                            self?.networkState = .loading
                    })
                    .subscribe(
                        onSuccess: { [weak self] response in
                            guard let response = response else {
                                self?.next = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                                    self?.networkState = .done
                                    strongDelegate = nil
                                })
                                return
                            }
                            write { realm in
                                guard let cache = self?.cache(from: realm) else { return }
                                try cache.update {
                                    if refreshing {
                                        cache.objects.removeAll()
                                    }
                                    let objects = try strongDelegate?.timelineProcessResponse(
                                        response, refreshing: refreshing, realm: realm) ?? []
                                    realm.add(objects, update: true)
                                    cache.objects.distinctAppend(contentsOf: objects)
                                    cache.next.setRequest(response.data.next)
                                    self?.next = response.data.next
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                                self?.networkState = self?.next == nil ? .done : .waiting
                                strongDelegate = nil
                            })
                            print(self?.next)
                        },
                        onError: { [weak self] error in
                            self?.networkState = .error(error)
                            strongDelegate = nil
                    })
            )
        }
    }
}
