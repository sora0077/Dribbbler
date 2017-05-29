//
//  ShotsViewController.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/12.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import Dribbbler
import RxSwift
import RxCocoa

extension Reactive where Base: UICollectionView {
    func reloadData() -> UIBindingObserver<Base, Void> {
        return UIBindingObserver(UIElement: base, binding: { (base, _) in
            base.reloadData()
        })
    }
}

extension Reactive where Base: UIView {
    func animate<T>(
        withDuration duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIViewAnimationOptions = [],
        animations: @escaping (Base, T) -> Void,
        completion: ((_ finished: Bool) -> Void)? = nil) -> UIBindingObserver<Base, T> {
        return UIBindingObserver(UIElement: base, binding: { (base, val) in
            UIView.animate(
                withDuration: duration,
                animations: {
                    animations(base, val)
                },
                completion: completion)
        })
    }

    func animate<T>(
        withDuration duration: TimeInterval,
        delay: TimeInterval = 0,
        usingSpringWithDamping damping: CGFloat,
        initialSpringVelocity velocity: CGFloat,
        options: UIViewAnimationOptions = [],
        animations: @escaping (Base, T) -> Void,
        completion: ((_ finished: Bool) -> Void)? = nil) -> UIBindingObserver<Base, T> {
        return UIBindingObserver(UIElement: base, binding: { (base, val) in
            UIView.animate(
                withDuration: duration,
                delay: delay,
                usingSpringWithDamping: damping,
                initialSpringVelocity: velocity,
                options: options,
                animations: {
                    animations(base, val)
                },
                completion: completion)
        })
    }
}

extension Reactive where Base: UIScrollView {
    var reachedBottom: ControlEvent<Void> {
        let observable = contentOffset
            .flatMap { [weak base] contentOffset -> Observable<Void> in
                guard let scrollView = base else { return .empty() }
                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight)

                return y > threshold ? .just() : .empty()
        }

        return ControlEvent(events: observable)
    }
}

final class ShotsViewController<Timeline: Dribbbler.Timeline>: UICollectionViewController, UICollectionViewDelegateFlowLayout
where Timeline.Element == Shot {
    private let timeline: Timeline
    private let disposeBag = DisposeBag()

    init(timeline: Timeline) {
        self.timeline = timeline
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 30)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let collectionView = collectionView else { return }
        collectionView.register(ShotCollectionViewCell.self, forCellWithReuseIdentifier: "ShotCollectionViewCell")

        let refreshControl = UIRefreshControl()
        collectionView.refreshControl = refreshControl
        disposeBag.insert(
            refreshControl.rx.controlEvent(.valueChanged).asDriver()
                .drive(timeline.rx.reload(force: true)),
            collectionView.rx.reachedBottom.asDriver()
                .drive(timeline.rx.fetch()),
            timeline.isLoading
                .drive(refreshControl.rx.isRefreshing),
            timeline.isLoading
                .map { $0 ? 0.5 : 1 }
                .drive(collectionView.rx
                    .animate(withDuration: 0.3, animations: { $0.alpha = $1 })),
            timeline.changes
                .map { _ in }
                .drive(collectionView.rx.reloadData()))

        if timeline.reload() {
            collectionView.alpha = 0.5
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeline.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShotCollectionViewCell", for: indexPath) as! ShotCollectionViewCell
        let item = timeline[indexPath.item]
        cell.apply(item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let item = timeline[indexPath.item]
        return CGSize(width: width, height: width * (item.ratio ?? 1))
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = timeline[indexPath.item]
        print(item)
        let comments = Model.Comments(id: item.id)
        comments.reload()
        store = comments
    }
}

private var store: Any?
