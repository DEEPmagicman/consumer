//
//  PaymentMethodsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

protocol PaymentMethodVCDelegate: AnyObject {
    func didSelectMethod(_ id: String, image: UIImage?, brand: String)
    func addCard()
}

final class PaymentMethodsViewController: UIViewController {

    @IBOutlet weak var paymentTableView: UITableView!

    var selectedId = Constant.String.defaultSelectedPM
    var isEditable = false
    private var paymentMethods = [PaymentMethod]()
    private var selectedImage = Constant.Card.cardIc
    private var selectedBrand = Constant.String.defaultSelectedPM
    private var isNoPaymentMethodFound: Bool {
        paymentMethods.count == 0
    }
    weak var delegate: PaymentMethodVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getSavedMethods()
        paymentTableView.delegate = self
        paymentTableView.dataSource = self
        paymentTableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
    }
    
    private func getSavedMethods() {
        Loader.show()
        PaymentPresenter.getUserSavedMethods(customerId: UserDefault.shared.user?.stripeCusId ?? "") { [weak self] isSuccess, errMsg, paymentMethods in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.paymentMethods = paymentMethods
                self.paymentTableView.reloadData()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension PaymentMethodsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isNoPaymentMethodFound {
            return isEditable ? 1 : 2
        }
        return paymentMethods.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell", for: indexPath) as! PaymentTableViewCell
        cell.selectionStyle = .none
        cell.setUi(isSetting: true)
        if indexPath.row == 0 {
            cell.paymentIcon.image = Constant.Card.applePay
            cell.paymentType.text = Constant.String.defaultSelectedPM
            cell.defaultLbl.isHidden = selectedId == Constant.String.defaultSelectedPM ? false : true
            cell.navigateBtn.isHidden = true
        } else {
            if isNoPaymentMethodFound {
                cell.paymentIcon.image = Constant.Card.cardIc
                cell.paymentType.text = "Add card"
                cell.defaultLbl.isHidden = true
            } else {
                let paymentMethod = paymentMethods[indexPath.row - 1]
                cell.paymentIcon.image = paymentMethods[indexPath.row - 1].brand.paymentImg
                cell.paymentType.text = "\(paymentMethod.brand) \(paymentMethod.last4)"
                cell.defaultLbl.isHidden = selectedId == paymentMethod.id ? false : true
            }
            cell.navigateBtn.isHidden = !isEditable
        }
        if isEditable {
            cell.defaultLbl.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            selectedId = Constant.String.defaultSelectedPM
            selectedImage = Constant.Card.applePay
            selectedBrand = Constant.String.defaultSelectedPM
        } else {
            if isEditable {
                Navigate.to.cardDetailsVc(self, customerId: UserDefault.shared.user?.stripeCusId ?? "", paymentMethod: paymentMethods[indexPath.row - 1])
                return
            }
            if isNoPaymentMethodFound {
                delegate?.addCard()
                Navigate.to.back(self)
                return
            } else {
                selectedId = paymentMethods[indexPath.row - 1].id
                selectedImage = paymentMethods[indexPath.row - 1].brand.paymentImg
                selectedBrand = paymentMethods[indexPath.row - 1].brand
            }
        }
        paymentTableView.reloadData()
        delegate?.didSelectMethod(selectedId, image: selectedImage, brand: selectedBrand)
    }
}

extension PaymentMethodsViewController: CardDetailChangeDelegate {
    func didDeleteCard(id: String) {
        paymentMethods.removeAll { $0.id == id }
        paymentTableView.reloadData()
    }
}
