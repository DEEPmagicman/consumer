//
//  CardDetailsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

protocol CardDetailChangeDelegate: AnyObject {
    func didDeleteCard(id: String)
}

final class CardDetailsViewController: UIViewController {

    @IBOutlet weak var defaultBtn: UIButton!
    @IBOutlet weak var expLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var deleteView: UIView!

    var paymentMethod: PaymentMethod?
    var customerId: String?
    var isDefault = false
    weak var delegate: CardDetailChangeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let paymentMethod = paymentMethod {
            titleLbl.text = "\(paymentMethod.brand.capitalized) \(paymentMethod.last4)"
            expLbl.text = "\(paymentMethod.expMonth.displayMonth)/\(paymentMethod.expYear.displayYear)"
            deleteBtn.isHidden = false
            deleteView.isHidden = false
        } else {
            titleLbl.text = Constant.String.defaultSelectedPM
            expLbl.text = ""
            deleteBtn.isHidden = true
            deleteView.isHidden = true
        }
        defaultBtn.setImage(Constant.Icon.defaultIcon, for: .normal)
        defaultBtn.setImage(Constant.Icon.check, for: .selected)
        defaultBtn.isSelected = isDefault
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
                self.delegate?.didDeleteCard(id: self.paymentMethod?.id ?? "")
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
