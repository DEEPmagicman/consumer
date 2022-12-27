//
//  AddCardInfoViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

class AddCardInfoViewController: UIViewController {

    @IBOutlet weak var defaultNameBtn: UIButton!
    @IBOutlet weak var defaultCardBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultNameBtn.setImage(Constant.Icon.defaultIcon, for: .normal)
        defaultNameBtn.setImage(Constant.Icon.check, for: .selected)
        defaultCardBtn.setImage(Constant.Icon.defaultIcon, for: .normal)
        defaultCardBtn.setImage(Constant.Icon.check, for: .selected)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickDefaultCard(_ sender: Any) {
        defaultCardBtn.isSelected.toggle()
    }
    
    @IBAction func onClickUserName(_ sender: Any) {
        defaultNameBtn.isSelected.toggle()
    }
    
    @IBAction func onClickAddCard(_ sender: Any) {
        if let paymentVC = navigationController?.viewControllers.first(where: { ($0 as? PaymentMethodsViewController) != nil}) {
              self.navigationController?.popToViewController(paymentVC, animated: false)
            }
    }
}
