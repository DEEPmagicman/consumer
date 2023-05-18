//
//  ConfirmEmailBottomSheet.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 04/04/23.
//

import UIKit

final class ConfirmEmailBottomSheet: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onClickConfirmEmail(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onClickLater(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
