//
//  UIView+Reactive.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

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
