//
//  CardDetailsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

final class CardDetailsViewController: UIViewController {

    @IBOutlet weak var defaultBtn: UIButton!
    @IBOutlet weak var expLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!

    var paymentMethod: PaymentMethod?
    var customerId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLbl.text = "\(paymentMethod?.brand ?? "") \(paymentMethod?.last4 ?? "")"
        expLbl.text = "\(paymentMethod?.expMonth ?? 0)/\(paymentMethod?.expYear ?? 0)"
        defaultBtn.setImage(Constant.Icon.defaultIcon, for: .normal)
        defaultBtn.setImage(Constant.Icon.check, for: .selected)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickDelete(_ sender: Any) {
        Loader.show()
        PaymentPresenter.deleteMethod(customerId: customerId ?? "", methodId: paymentMethod?.id ?? "") { [weak self] isSuccess, errMsg in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                Navigate.to.back(self)
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    @IBAction func onClickDefault(_ sender: UIButton) {
        defaultBtn.isSelected.toggle()
    }
}
