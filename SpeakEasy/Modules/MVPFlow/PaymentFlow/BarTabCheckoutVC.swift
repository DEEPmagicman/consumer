//
//  BarTabCheckoutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/06/25.
//

import UIKit
import PassKit
import StripeApplePay
import StripePaymentSheet

final class BarTabCheckoutVC: UIViewController {
    
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dateLbl: UILabel!
    @IBOutlet private weak var venueNameLbl: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var paymentMethodImg: UIImageView!
    @IBOutlet private weak var buyNowBtn: UIButton!
    @IBOutlet private weak var subTotalView: UIView!
    @IBOutlet private weak var processingFeesView: UIView!
    @IBOutlet private weak var customFeesView: UIView!
    @IBOutlet weak var salesTaxView: UIView!
    @IBOutlet private weak var subTotalAmount: UILabel!
    @IBOutlet private weak var processingFeeAmount: UILabel!
    @IBOutlet weak var salesTaxAmount: UILabel!
    @IBOutlet weak var salesTaxPr: UILabel!
    @IBOutlet weak var salesTaxName: UILabel!
    @IBOutlet weak var customFeesTableView: UITableView!
    @IBOutlet weak var customFeesTableViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var totalAmountLbl: UILabel!
    
    var venueDetails: ClipVenue?
    var selectedTicket = [CoverTicket]()
    private var ticketListHeightObservation: NSKeyValueObservation?
    var barTabData: BarTabData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLbl.text = "Bar Tab"
        dateLbl.text = Date().toString(dateFormat: .EEEMMMD, timeZone: TimeZone(identifier: venueDetails?.timezone ?? "") ?? TimeZone(identifier: "UTC"))
        venueNameLbl.text = "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        venueLogo.sd_setImage(with: URL(string: (venueDetails?.logo?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        ticketListTableView.delegate = self
        ticketListTableView.dataSource = self
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        getPaymentDetails()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    private func getPaymentDetails() {
        Loader.show()
        var param = [String: Any]()
        param["phone"] = UserDefault.shared.user?.phone
        param["code"] = UserDefault.shared.user?.code
        param["firstName"] = UserDefault.shared.user?.firstName
        param["lastName"] = UserDefault.shared.user?.lastName
        param["email"] = UserDefault.shared.user?.email
        param["ticketId"] = selectedTicket.first?.id
        param["venueId"] = selectedTicket.first?.venueId
        
        BarTabPresenter.getPaymentDetails(param: param) { [weak self] isSuccess, errMsg, barTabDetails in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.setUpData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func setUpData() {
        let feeData = barTabData?.barTab.barTabPayments?.first?.bookingFees
        subTotalView.isHidden = feeData?.subTotal == feeData?.total
        salesTaxView.isHidden = feeData?.salesTax ?? 0 == 0
        customFeesView.isHidden = feeData?.customFees?.count == 0
        processingFeesView.isHidden = feeData?.processingFee ?? 0 == 0
        
        totalAmountLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.total ?? 0).decimalFormat(true))"
    }
}

extension BarTabCheckoutVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == ticketListTableView ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == ticketListTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
            cell.selectionStyle = .none
            cell.titleLbl.text = selectedTicket[indexPath.row].customName ?? "" == "" ? selectedTicket[indexPath.row].name : selectedTicket[indexPath.row].customName
            cell.subTitleLbl.text = selectedTicket[indexPath.row].description
            cell.quantityLbl.text = "1x"
            return cell
        }
        return UITableViewCell()
    }
}
