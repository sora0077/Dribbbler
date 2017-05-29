//
//  CommentsViewController.swift
//  Dribbbler
//
//  Created by 林達也 on 2017/05/30.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Dribbbler

final class CommentsViewController<Timeline: Dribbbler.Timeline>: UITableViewController where Timeline.Element == Comment {
    private let timeline: Timeline
    private let disposeBag = DisposeBag()

    init(timeline: Timeline) {
        self.timeline = timeline
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return timeline.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = timeline[indexPath.row]
        cell.textLabel?.text = item.body
        return cell
    }
}
