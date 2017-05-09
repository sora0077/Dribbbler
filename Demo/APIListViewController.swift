//
//  APIListViewController.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/09.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import DribbbleKit

final class APIListViewController: UITableViewController {

    @IBAction
    private func authorizeAction() {
        guard let clientId = UserDefaults.standard.clientId else { return }
        UIApplication.shared.open(
            OAuth.authorizeURL(clientId: clientId, scopes: [.public]), options: [:], completionHandler: nil)
    }
}
