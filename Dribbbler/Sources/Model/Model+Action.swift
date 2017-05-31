//
//  Model+Action.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/31.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol ActionDelegate: class {
    func actionGeberator() -> Observable<Void>

}

extension Model {
    final class _ActionModel<Delegate: ActionDelegate> {  // swiftlint:disable:this type_name
        private(set) lazy var isLoading: Driver<Bool> = self._isLoading.asDriver(onErrorJustReturn: false)
        private let _isLoading = PublishSubject<Bool>()
        private let disposeBag = DisposeBag()
        private var networkState: NetworkState = .waiting {
            didSet { _isLoading.onNext(networkState == .loading) }
        }
        weak var delegate: Delegate?

        deinit {
            print("deinit", self)
        }

        func action() {
            if networkState != .loading { networkState = .waiting }
            guard networkState.isRunnable else { return }
            guard let delegate = delegate else { fatalError() }
            var strongDelegate: Delegate? = delegate
            disposeBag.insert((strongDelegate ?? delegate).actionGeberator()
                .do(
                    onSubscribe: { [weak self] _ in
                        self?.networkState = .loading
                })
                .subscribe(
                    onNext: { [weak self] _ in
                        self?.networkState = .waiting
                        strongDelegate = nil
                    },
                    onError: { [weak self] error in
                        self?.networkState = .error(error)
                        strongDelegate = nil
                }))
        }
    }
}
