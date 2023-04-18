//
//  PaymentMethodsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

protocol PaymentMethodVCDelegate: AnyObject {
    func didSelectMethod(_ id: String)
}

final class PaymentMethodsViewController: UIViewController {

    @IBOutlet weak var paymentTableView: UITableView!

    private var paymentMethods = [PaymentMethod]()
    private var selectedId = "Apple Pay"
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
        PaymentPresenter.getUserSavedMethods(customerId: "cus_NjIf65HxFjE65P") { [weak self] isSuccess, errMsg, paymentMethods in
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
    
    @objc func buttonAction(sender: UIButton) {
//        if demoPaymentArray[sender.tag] == "Mastercard 1234" {
//            Navigate.to.cardDetailsVc(self) }
    }
}

extension PaymentMethodsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        paymentMethods.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell", for: indexPath) as! PaymentTableViewCell
        cell.selectionStyle = .none
        cell.setUi(isSetting: true)
        if indexPath.row == 0 {
            cell.paymentIcon.image = Constant.Icon.applePay
            cell.paymentType.text = "Apple Pay"
            cell.defaultLbl.isHidden = selectedId == "Apple Pay" ? false : true
        } else {
            let paymentMethod = paymentMethods[indexPath.row - 1]
            cell.paymentIcon.image = Constant.Icon.masterCard
            cell.paymentType.text = "\(paymentMethod.brand) \(paymentMethod.last4)"
            cell.defaultLbl.isHidden = selectedId == paymentMethod.id ? false : true
        }
        cell.navigateBtn.isHidden = true
        cell.navigateBtn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        cell.navigateBtn.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            selectedId = "Apple Pay"
        } else {
            selectedId = paymentMethods[indexPath.row - 1].id
            Navigate.to.cardDetailsVc(self, customerId: "cus_NjIf65HxFjE65P", paymentMethod: paymentMethods[indexPath.row - 1])
        }
        paymentTableView.reloadData()
        delegate?.didSelectMethod(selectedId)
    }
}
