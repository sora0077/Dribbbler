//
//  ShotCollectionViewCell.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/27.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import SnapKit
import PINRemoteImage
import FLAnimatedImage
import Dribbbler

final class ShotCollectionViewCell: UICollectionViewCell {
    private let imageView = FLAnimatedImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(0)
        }

        contentView.backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.pin_cancelImageDownload()
        imageView.animatedImage = nil
    }

    func apply(_ data: Shot) {
        let url = data.images.hidpi ?? data.images.normal
        print(url)
        imageView.pin_setImage(from: url)
    }
}
