//
//  SelectTicketClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class SelectTicketClipVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "EnterPhoneNumberClipVC"))
        navigationController?.pushViewController(vc, animated: true)
    }
}
