//
//  MVPStartScreenVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/02/23.
//

import UIKit
import AVFoundation

final class MVPStartScreenVC: UIViewController {
    
    @IBOutlet weak var bgImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onClickBtn(_ sender: Any) {
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController()
    }
}
