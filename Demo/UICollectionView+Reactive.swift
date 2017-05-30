//
//  UICollectionView+Reactive.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Dribbbler

extension Reactive where Base: UICollectionView {
    func reloadData() -> UIBindingObserver<Base, Void> {
        return UIBindingObserver(UIElement: base, binding: { (base, _) in
            base.reloadData()
        })
    }

    func reloadData(at section: Int = 0) -> UIBindingObserver<Base, TimelineChanges> {
        return UIBindingObserver(UIElement: base, binding: { (base, changes) in
            base.performBatchUpdates({
                switch changes {
                case .initial:
                    base.reloadData()
                case let .update(deletions, insertions, modifications):
                    func indexPaths(_ values: [Int]) -> [IndexPath] {
                        return values.map { IndexPath(item: $0, section: section) }
                    }
                    base.deleteItems(at: indexPaths(deletions))
                    base.insertItems(at: indexPaths(insertions))
                    base.reloadItems(at: indexPaths(modifications))
                }
            }, completion: nil)
        })
    }
}
