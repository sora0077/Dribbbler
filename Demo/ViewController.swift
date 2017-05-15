//
//  ViewController.swift
//  Demo
//
//  Created by 林達也 on 2017/04/29.
//  Copyright © 2017年 jp.sora0077. All rights reserved.
//

import UIKit
import Dribbbler

class ViewController: UIViewController {
    @IBOutlet private var clientIdField: UITextField!
    @IBOutlet private var clientSecretField: UITextField!
    @IBOutlet private var accessTokenLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let client = OAuth().client()
        clientIdField.text = client?.id
        clientSecretField.text = client?.secret
        accessTokenLabel.text = client?.accessToken
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

        let client = OAuth().client()
        if client?.id != clientId && client?.secret != clientSecret {
            OAuth().saveClient(id: clientId, secret: clientSecret)
        }
        performSegue(withIdentifier: "Launch", sender: nil)
    }
}
