//
//  APIListViewController.swift
//  Dribbbler
//
//  Created by 林 達也 on 2017/05/09.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import Dribbbler

private enum Row: String {
    case userShots, shots

    var title: String { return rawValue }
}

final class APIListViewController: UITableViewController {
    fileprivate let rows: [Row] = [
        .userShots,
        .shots
    ]

    @IBAction
    private func authorizeAction() {
        do {
            try UIApplication.shared.open(
                OAuth().authorizeURL(with: [.public, .write]), options: [:], completionHandler: nil)
        } catch _ as OAuth.Error {

        } catch {

        }
    }
}

extension APIListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = rows[indexPath.row].title
        return cell
    }
}

extension APIListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .userShots:
            let userShots = Model.UserShots(userId: 1)
            let vc = ShotsViewController(timeline: userShots)
            navigationController?.pushViewController(vc, animated: true)
        case .shots:
            let shots = Model.Shots(list: .animated, sort: .recent)
            let vc = ShotsViewController(timeline: shots)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
