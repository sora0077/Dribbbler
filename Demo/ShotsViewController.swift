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

final class ShotsViewController<Timeline: Dribbbler.Timeline>: UICollectionViewController where Timeline.Element == Shot {
    private let timeline: Timeline

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
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        let refreshControl = UIRefreshControl()
        collectionView?.refreshControl = refreshControl
        _ = refreshControl.rx.controlEvent(.valueChanged)
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.timeline.reload(force: true)
            })
        _ = timeline.isLoading.debug().drive(refreshControl.rx.isRefreshing)
        _ = timeline.changes
            .drive(onNext: { [weak self] _ in
                self?.collectionView?.reloadData()
            })
        timeline.reload()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeline.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .white
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview({
            let label = UILabel()
            label.text = "\(indexPath.item)"
            label.frame = cell.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return label
        }())
        return cell
    }
}
