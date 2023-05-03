//
//  DeleteAccountViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class DeleteAccountViewController: UIViewController {

    @IBOutlet weak var emailLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLbl.text = UserDefault.shared.user?.email ?? UserDefault.shared.user?.additionalEmail ?? "No email found"
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSendEmail(_ sender: Any) {
        // TODO: delete email API flow?
        Alert.showToast("Email sent")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UserDefault.shared.emptyData()
            AppDelegate.shared.changeRootViewController()
        }
    }
}
