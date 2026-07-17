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
    
    var guestUserLastNavigation: (NavigationDestination, String) = (.appLaunch, "")
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guestUserLastNavigation = (.appLaunch, "")
    }

    @IBAction func onClickBtn(_ sender: Any) {
        AppDelegate.shared.guestUserLastNavigation = guestUserLastNavigation
        UserDefault.shared.emptyData()
        AppDelegate.shared.changeRootViewController()
    }
}
