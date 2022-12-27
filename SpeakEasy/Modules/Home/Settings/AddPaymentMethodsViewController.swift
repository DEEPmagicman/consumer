//
//  AddPaymentMethodsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

class AddPaymentMethodsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickCard(_ sender: Any) {
        Navigate.to.addCardInfoVc(self)
    }
    
    @IBAction func onClickPaypal(_ sender: Any) {
        Navigate.to.cardDetailsVc(self)
    }
    
}
