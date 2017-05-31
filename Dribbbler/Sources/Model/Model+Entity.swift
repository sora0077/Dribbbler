//
//  Model+Entity.swift
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

protocol ModelOperation: class {
    associatedtype Data
    var data: Data? { get }
    var change: Driver<EntityChange> { get }

    @discardableResult
    func reload(force: Bool) -> Bool
    func fetch()
}

protocol EntityDelegate: class {
    associatedtype Request: DribbbleKit.Request
    associatedtype Element: Object
    func entityFetcher() -> Single<Request.Response>?
    func entityProcessResponse(_ response: Request.Response, realm: Realm) throws
}

public enum EntityChange {
    case initial
    case update

    init<T>(_ changes: RealmCollectionChange<T>) {
        switch changes {
        case .initial: self = .initial
        case .update: self = .update
        case .error(let error):
            fatalError("\(error)")
        }
    }
}

extension EntityDelegate {
    func entityFetcher() -> Single<Request.Response>? { return nil }
}

extension EntityDelegate where Request.Response == DribbbleKit.Response<Element> {
    func entityProcessResponse(_ response: Request.Response, realm: Realm) throws {
        realm.add(response.data, update: true)
    }
}

private extension Results {
    func filterIf(_ predicate: NSPredicate?) -> Results<T> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }
}

extension Model {
    final class _EntityModel<Element: Entity, Delegate: EntityDelegate> {  // swiftlint:disable:this type_name
        typealias Request = Delegate.Request
        var data: Element? { return Thread.isMainThread ? cache.first : cache(from: Realm()) }
        private(set) lazy var isLoading: Driver<Bool> = self._isLoading.asDriver(onErrorJustReturn: false)
        private(set) lazy var change: Driver<EntityChange> = self._change.asDriver(onErrorDriveWith: .empty())
        private let _isLoading = PublishSubject<Bool>()
        private let _change = PublishSubject<EntityChange>()
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
            token = cache.addNotificationBlock { [weak self] changes in
                self?._change.onNext(EntityChange(changes))
            }
            networkState = data == nil ? .waiting : .done
        }

        deinit {
            print("deinit", self)
        }

        func cache(from realm: Realm) -> Element? {
            return realm.objects(Element.self).filterIf(predicate()).first
        }

        func reload(force: Bool) -> Bool {
            guard force || data?.isOutdated ?? true else { return false }
            _fetch(refreshing: true)
            return true
        }

        func fetch() {
            _fetch(refreshing: data?.isOutdated ?? false)
        }

        private func fetcher() -> Single<Request.Response?> {
            let fetcher = delegate?.entityFetcher() ?? session.send(initRequest())
            return fetcher.map { $0 }
        }

        private func _fetch(refreshing: Bool) {
            if refreshing && networkState != .loading { networkState = .waiting }
            guard networkState.isRunnable else { return }
            if !refreshing && cache(from: Realm()) != nil {
                networkState = .done
                return
            }
            var strongDelegate = delegate
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
                                strongDelegate = nil
                                return
                            }
                            write { realm in
                                try strongDelegate?.entityProcessResponse(response, realm: realm)
                                self?.networkState = .done
                            }
                            strongDelegate = nil
                        },
                        onError: { [weak self] error in
                            self?.networkState = .error(error)
                            strongDelegate = nil
                    })
            )
        }
    }
}
