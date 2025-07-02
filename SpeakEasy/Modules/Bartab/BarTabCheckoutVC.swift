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

final class BarTabCheckoutVC: UIViewController, ApplePayContextDelegate {
    
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
    @IBOutlet private weak var paymentMethodView: UIView!
    
    var venueDetails: ClipVenue?
    var selectedTicket = [CoverTicket]()
    private var ticketListHeightObservation: NSKeyValueObservation?
    var barTabData: BarTabData?
    private var selectedId = Constant.String.defaultSelectedPM
    private var isFromApplePay = false
    private var isApplePayNotSupported: Bool {
        !PKPaymentAuthorizationViewController.canMakePayments()
    }
    private var isPaymentInitiated = false
    private var paymentSheet: PaymentSheet?
    
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickPaymentMethod))
        paymentMethodView.addGestureRecognizer(tap)
        customFeesTableView.delegate = self
        customFeesTableView.dataSource = self
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
        param["venueId"] = venueDetails?.id
        var tickets = [[String: Any]]()
        selectedTicket.forEach {
            tickets.append(["ticketId": $0.id,
                            "ticketQuantity": $0.selectedQuantity ?? 0])
        }
        param["tickets"] = tickets
        
        BarTabPresenter.getPaymentDetails(param: param) { [weak self] isSuccess, errMsg, barTabDetails in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.barTabData = barTabDetails
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
        customFeesView.isHidden = feeData?.additionalFees?.count == 0
        processingFeesView.isHidden = !setProcessingFeeView
        
        processingFeeAmount.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.processingFee ?? 0).decimalFormat(true))"
        totalAmountLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.total ?? 0).decimalFormat(true))"
        subTotalAmount.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.subTotal ?? 0).decimalFormat(true))"
        salesTaxAmount.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.salesTax ?? 0).decimalFormat(true))"
        salesTaxName.text = feeData?.salesTaxName ?? "Sales Tax"
        totalAmountLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((feeData?.total ?? 0).decimalFormat(true))"
        
        self.customFeesTableViewHeight.constant = CGFloat((feeData?.additionalFees?.count ?? 0) * 30)
        self.customFeesTableView.setNeedsLayout()
        self.customFeesTableView.reloadData()
        self.customFeesView.isHidden = false
        
        self.setUpPaymentBottomSheet()
    }
    
    var setProcessingFeeView: Bool {
        let feeData = barTabData?.barTab.barTabPayments?.first?.bookingFees
        let totalCustomFee = feeData?.additionalFees?.reduce(0.0) { $0 + ($1.amount ?? 0) } ?? 0
        let processingFee = feeData?.processingFee ?? 0
        let subTotal = feeData?.subTotal ?? 0
        let salesTax = feeData?.salesTax ?? 0
        let total = feeData?.total ?? 0

        return (processingFee != 0) && (total != subTotal) && ((subTotal + salesTax + totalCustomFee) != total)
    }
    
    @objc private func onClickPaymentMethod() {
        Navigate.to.paymentMethodsVc(self, selectedId: selectedId)
    }
    
    private func onClickCreditCardPay() {
        // MARK: Start the checkout process
        isPaymentInitiated = true
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.paymentStatus() { posCheckId in
                    Navigate.to.barTabQRCodeVC(self, posCheckId: posCheckId, venue: self.venueDetails, barTabId: self.barTabData?.barTab.id ?? "")
                }
            case .canceled:
                self.isPaymentInitiated = false
            case .failed:
                self.isPaymentInitiated = false
                let alert = UIAlertController(title: "Alert", message: "Payment failed", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func applePayButtonTapped() {
        isFromApplePay = true
        if StripeAPI.deviceSupportsApplePay() == false {
            alertForWallet()
            return
        }
        isPaymentInitiated = true
        let merchantIdentifier = "merchant.com.speakeasy"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: venueDetails?.venueSettings?.currencyCode?.uppercased() ?? "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            // The final line should represent your company;
            // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
            PKPaymentSummaryItem(label: "Speakeasy Bookings Inc. (VIA Speakeasy Go!)", amount: NSDecimalNumber(value: barTabData?.barTab.barTabPayments?.first?.bookingFees?.total ?? 0)),
        ]
        paymentRequest.requiredBillingContactFields = []
        // Initialize an STPApplePayContext instance
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            // Present Apple Pay payment sheet
            applePayContext.presentApplePay()
        } else {
            Alert.showToast("Problem with your Apple Pay")
            // There is a problem with your Apple Pay configuration
        }
    }
    
    private func alertForWallet() {
        let title = isApplePayNotSupported ? Constant.String.notSupported : Constant.String.addCardToApplePay
        let message = isApplePayNotSupported ? Constant.String.applePayNotSupported : Constant.String.addCardToYourApplePayWallet
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.isFromApplePay = true
        }
        let setUpAction = UIAlertAction(title: "Add Card", style: .default) { (_) in
            if let url = URL(string: "wallet://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(okAction)
        alertController.addAction(setUpAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func setUpPaymentBottomSheet() {
        STPAPIClient.shared.publishableKey = Stripe.publishableKey
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Speakeasy Bookings Inc. (VIA Speakeasy Go!)"
        configuration.customer = .init(id: UserDefault.shared.user?.stripeCusId ?? "", ephemeralKeySecret: barTabData?.ephemeralKey ?? "")
        configuration.savePaymentMethodOptInBehavior = .automatic
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment
        // methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        paymentSheet = PaymentSheet(paymentIntentClientSecret: barTabData?.clientSecret ?? "", configuration: configuration)
        DispatchQueue.main.async {
            self.buyNowBtn.alpha = 1
            self.buyNowBtn.isUserInteractionEnabled = true
//            self.displayPayment()
        }
    }
    
    private func paymentStatus(completion: @escaping ((_ posCheckId: String)-> Void)) {
        Loader.show()
        BarTabPresenter.barTabPaymentCompleteAPI(barId: barTabData?.barTab.id ?? "", paymentId: barTabData?.barTab.barTabPayments?.first?.id ?? "") { isSuccess, errMsg, barTab in
            Loader.hide()
            if isSuccess {
                completion(barTab?.posChecksId ?? "")
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    @IBAction private func onClickBuy(_ sender: Any) {
        if selectedId == Constant.String.defaultSelectedPM {
            applePayButtonTapped()
        } else {
            onClickCreditCardPay()
        }
    }
}

extension BarTabCheckoutVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == ticketListTableView ? selectedTicket.count : barTabData?.barTab.barTabPayments?.first?.bookingFees?.additionalFees?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == ticketListTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
            cell.selectionStyle = .none
            cell.titleLbl.text = selectedTicket[indexPath.row].customName ?? "" == "" ? selectedTicket[indexPath.row].name : selectedTicket[indexPath.row].customName
            cell.subTitleLbl.text = selectedTicket[indexPath.row].description
            cell.quantityLbl.text = "\(selectedTicket[indexPath.row].selectedQuantity ?? 0)x"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomFeeTVC", for: indexPath) as! CustomFeeTVC
            let customFee = self.barTabData?.barTab.barTabPayments?.first?.bookingFees?.additionalFees?[indexPath.row]
            cell.lblFeeName.text = customFee?.name ?? "Custom fee"
            cell.lblFeeValue.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((customFee?.amount ?? 0).decimalFormat(true))"
            return cell
        }
    }
}

extension BarTabCheckoutVC: PaymentMethodVCDelegate {
    func didSelectMethod(_ id: String, image: UIImage?) {
        selectedId = id
        paymentMethodImg.image = image
    }
    
    func addCard() {
        selectedId = Constant.String.addNewCard
        paymentMethodImg.image = Constant.Card.cardIc
        DispatchQueue.main.async {
            self.onClickCreditCardPay()
        }
    }
}

extension BarTabCheckoutVC {
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        let clientSecret = self.barTabData?.clientSecret ?? ""
        // Call the completion block with the client secret or an error
        completion(clientSecret, nil)
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        switch status {
        case .success:
            self.paymentStatus() { posCheckId in
                Navigate.to.barTabQRCodeVC(self, posCheckId: posCheckId, venue: self.venueDetails, barTabId: self.barTabData?.barTab.id ?? "")
            }
        case .error:
            isFromApplePay = true
            self.isPaymentInitiated = false
            let alert = UIAlertController(title: "Alert", message: "Payment field", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .userCancellation:
            isFromApplePay = true
            self.isPaymentInitiated = false
        }
    }
}
