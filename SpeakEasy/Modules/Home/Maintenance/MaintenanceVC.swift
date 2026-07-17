//
//  MaintenanceVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mac on 13/05/24.
//

import UIKit

final class MaintenanceVC: UIViewController {
    
    @IBAction func onClickRefresh(_ sender: Any) {
        RemoteConfigHelper.shared.updateConfigValue {
            if RemoteConfigHelper.shared.isMaintenanceiOSConsumer == false {
                DispatchQueue.main.async {
                    AppDelegate.shared.changeRootViewController()
                }
            }
        }
    }
}
