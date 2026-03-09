//
//  TablePurchaseVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 24/02/26.
//

import UIKit
import MHLoadingButton

class TablePurchaseVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var feesAndTxtTotalAmountLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableView: UITableView!
    @IBOutlet weak var purchaseTicketBtn: UIButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeild: UITextField!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var feesAndTaxesTitleView: UIView!
    @IBOutlet weak var feesAndTaxesContainerView: UIView!
    @IBOutlet weak var discountToalLbl: UILabel!
    @IBOutlet weak var shimmerView: UIView!
    @IBOutlet weak var feesDropDowenIc: UIImageView!
    @IBOutlet weak var submitPromoCodeBtn: LoadingButton!
    @IBOutlet weak var addPromoCodeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
}
