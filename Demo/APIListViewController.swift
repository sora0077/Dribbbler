//
//  APIListViewController.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/09.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import Dribbbler

final class APIListViewController: UITableViewController {

    @IBAction
    private func authorizeAction() {
        do {
            try UIApplication.shared.open(
                OAuth().authorizeURL(with: [.public]), options: [:], completionHandler: nil)
        } catch let error as OAuth.Error {

        } catch {

        }
    }
}
