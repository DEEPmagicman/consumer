//
//  PaymentMethodsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 27/12/22.
//

import UIKit

class PaymentMethodsViewController: UIViewController {

    @IBOutlet weak var paymentTableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var paymentArray = ["Apple Pay", "Mastercard 1234"]
    var defaultType = "Apple Pay"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        paymentTableView.delegate = self
        paymentTableView.dataSource = self
        paymentTableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewHeightConstraint.constant = CGFloat((paymentArray.count) * 90)
        paymentTableView.reloadData()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        if paymentArray[sender.tag] == "Mastercard 1234" {
            Navigate.to.cardDetailsVc(self) }
    }
    
    @IBAction func onClickAddPaymentMethods(_ sender: Any) {
        Navigate.to.addPaymentMethodsVc(self)
    }
}

extension PaymentMethodsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell", for: indexPath) as! PaymentTableViewCell
        cell.selectionStyle = .none
        cell.setUi(isSetting: true)
        if paymentArray[indexPath.row] == "Apple Pay" {
            cell.paymentIcon.image = Constant.Icon.applePay
        } else {
            cell.paymentIcon.image = Constant.Icon.masterCard
        }
        cell.paymentType.text = paymentArray[indexPath.row]
        cell.defaultLbl.isHidden = defaultType == paymentArray[indexPath.row] ? false : true
        cell.navigateBtn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        cell.navigateBtn.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if paymentArray[indexPath.row] == "Mastercard 1234" {
            Navigate.to.cardDetailsVc(self) }
    }
}


