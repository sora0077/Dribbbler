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

    func update(_ block: () throws -> Void) rethrows
}

private extension Results {
    func filterIf(_ predicate: NSPredicate?) -> Results<T> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }
}

protocol EntityDelegate: class {
    associatedtype Request: DribbbleKit.Request
    associatedtype Element: Object
    func entityFetcher() -> Single<Request.Response>?
    func entityProcessResponse(_ response: Request.Response, realm: Realm) throws
}

extension EntityDelegate {
    func entityFetcher() -> Single<Request.Response>? { return nil }
}

extension EntityDelegate where Request.Response == DribbbleKit.Response<Element> {
    func entityProcessResponse(_ response: Request.Response, realm: Realm) throws {
        realm.add(response.data, update: true)
    }
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

public struct Model {
    class _EntityModel<Element: Entity, Delegate: EntityDelegate> {  // swiftlint:disable:this type_name
        typealias Request = Delegate.Request
        var data: Element? { return cache.first }
        private(set) lazy var isLoading: Driver<Bool> = self._isLoading.asDriver(onErrorJustReturn: false)
        private(set) lazy var change: Driver<Void> = self._change.asDriver(onErrorDriveWith: .empty())
        private let _isLoading = PublishSubject<Bool>()
        private let _change = PublishSubject<Void>()
        private let disposeBag = DisposeBag()
        private let initRequest: () -> Request
        private let predicate: () -> NSPredicate?
        private let cache: Results<Element>
        private var token: NotificationToken!
        private var networkState: NetworkState = .waiting {
            didSet { _isLoading.onNext(networkState == .loading) }
        }
        weak var delegate: Delegate?

        init(request initRequest: @autoclosure @escaping () -> Request,
             predicate: @autoclosure @escaping () -> NSPredicate?) {
            self.initRequest = initRequest
            self.predicate = predicate
            cache = Realm().objects(Element.self).filterIf(predicate())
            token = cache.addNotificationBlock { [weak self] _ in
                self?._change.onNext()
            }
            networkState = data == nil ? .waiting : .done
        }

        func cache(from realm: Realm) -> Element? {
            return realm.objects(Element.self).filterIf(predicate()).first
        }

        func reload(force: Bool) {
            _fetch(refreshing: force || data?.isOutdated ?? false)
        }

        func fetch() {
            _fetch(refreshing: data?.isOutdated ?? false)
        }

        private func fetcher() -> Single<Request.Response?> {
            let fetcher = delegate?.entityFetcher() ?? session.send(initRequest())
            return fetcher.map { $0 }
        }

        private func _fetch(refreshing: Bool) {
            guard networkState.isRunnable else { return }
            if refreshing && networkState != .loading { networkState = .waiting }
            if !refreshing && cache(from: Realm()) != nil {
                networkState = .done
                return
            }
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
                            write { realm in
                                try self?.delegate?.entityProcessResponse(response, realm: realm)
                                self?.networkState = .done
                            }
                        },
                        onError: { [weak self] error in
                            self?.networkState = .error(error)
                        })
            )
        }
    }

    // swiftlint:disable:next type_name
    class _TimelineModel<Cache: TimelineCache, Delegate: TimelineDelegate>
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
            guard networkState.isRunnable else { return }
            if refreshing && networkState != .loading { networkState = .waiting }
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
                                })
                                return
                            }
                            write { realm in
                                guard let cache = self?.cache(from: realm) else { return }
                                try cache.update {
                                    if refreshing {
                                        cache.objects.removeAll()
                                    }
                                    let objects = try self?.delegate?.timelineProcessResponse(
                                        response, refreshing: refreshing, realm: realm) ?? []
                                    realm.add(objects, update: true)
                                    cache.objects.distinctAppend(contentsOf: objects)
                                    cache.next.setRequest(response.data.next)
                                    self?.next = response.data.next
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                                self?.networkState = self?.next == nil ? .done : .waiting
                            })
                            print(self?.next)
                        },
                        onError: { [weak self] error in
                            self?.networkState = .error(error)
                        })
            )
        }
    }
}
