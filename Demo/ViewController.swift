//
//  ViewController.swift
//  Demo
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet private var clientIdField: UITextField!
    @IBOutlet private var clientSecretField: UITextField!
    @IBOutlet private var accessTokenLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let defaults = UserDefaults.standard
        clientIdField.text = defaults.clientId
        clientSecretField.text = defaults.clientSecret
//        accessTokenLabel.text = defaults.authorization?.accessToken
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction
    private func saveAction() {
        guard
            let clientId = clientIdField.text, !clientId.isEmpty,
            let clientSecret = clientSecretField.text, !clientSecret.isEmpty else { return }

        let defaults = UserDefaults.standard
        defaults.clientId = clientId
        defaults.clientSecret = clientSecret
        defaults.synchronize()

        performSegue(withIdentifier: "Launch", sender: nil)
    }
}
