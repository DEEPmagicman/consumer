//
//  TicketCheckoutVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 06/02/26.
//

import UIKit

class TicketCheckoutVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var feesAndTaxTableView: UITableView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var totalAmountLbl: UILabel!
    @IBOutlet weak var feesAndTxtTotalAmountLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feesAndTaxesTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var feedAndTaxesTableView: UITableView!
    @IBOutlet weak var purchaseTicketBtn: UIButton!
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var promoCodeTextFeild: UITextField!
    @IBOutlet weak var submitPromoBtn: UIButton!
    @IBOutlet weak var promoCodeView: UIView!
    
    var selectedTickets: [EventTicket] = []
    var venueDetails: ClipVenue?
    var event: Event?
    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 5 * 60


    private var currency: String {
        return venueDetails?.venueSettings?.currencySymbol ?? "$"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TicketItemTableViewCell.nib,
                           forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        feesAndTaxTableView.delegate = self
        feesAndTaxTableView.dataSource = self
        feesAndTaxTableView.register(TicketItemTableViewCell.nib,
                                     forCellReuseIdentifier: TicketItemTableViewCell.identifier)

        setupHeaderData()
        startCountdown()
        calculateTotal()
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        feesAndTaxTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

    }
    
    deinit {
        countdownTimer?.invalidate()
        tableView.removeObserver(self, forKeyPath: "contentSize")
        feesAndTaxTableView.removeObserver(self, forKeyPath: "contentSize")
    }

    
    private func setupHeaderData() {

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name
        venueName2.text = venueDetails?.name
        eventTitleLbl.text = event?.title
    }
    
    private func calculateTotal() {

        let subtotal = selectedTickets.reduce(0.0) { result, ticket in
            let quantity = ticket.selectedTicketCount ?? 0
            let price = ticket.price ?? 0
            return result + (Double(quantity) * price)
        }

//        let fees = getFeesAndTaxes().reduce(0.0) { $0 + $1.amount }

//        let grandTotal = subtotal + fees

        totalAmountLbl.text = "\(currency)\(subtotal.decimalFormat(true))"
        if let hex = self.event?.whiteLabelColor {
              let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
            purchaseTicketBtn.backgroundColor = color
        }
//        feesAndTxtTotalAmountLbl.text = "\(currency)\(grandTotal.decimalFormat(true))"
    }
    
    
    private func startCountdown() {
        updateTimerLabel()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateTimerLabel()
            } else {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.timerExpired()
            }
        }
    }

    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        timerLbl.text = "\(minutes) mins \(seconds) secs"
    }

    private func timerExpired() {
        timerLbl.text = "Ticket hold expired"
        Alert.showToast("Your ticket hold has expired")
        navigationController?.popToRootViewController(animated: true)
    }


    
    @IBAction func onClickAddPromoCode(_ sender: Any) {
        let shouldShow = promoCodeView.isHidden
        
        if shouldShow {
            promoCodeView.alpha = 0
            promoCodeView.isHidden = false
        }

        UIView.animate(withDuration: 0.25) {
            self.promoCodeView.alpha = shouldShow ? 1 : 0
        } completion: { _ in
            self.promoCodeView.isHidden = !shouldShow
        }
    }

    @IBAction func onClickFeesAndTaxs(_ sender: Any) {
        
    }
    
    @IBAction func onClickAcceptCheckBox(_ sender: Any) {
        
    }

    @IBAction func onClickSubmitPromoBtn(_ sender: Any) {
        
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        if keyPath == "contentSize" {

            if let table = object as? UITableView {

                if table == self.tableView {
                    tableViewHeight.constant = table.contentSize.height
                } else if table == self.feesAndTaxTableView {
                    feesAndTaxesTableViewHeight.constant = table.contentSize.height
                }
            }
        }
    }

}



extension TicketCheckoutVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {

        if tableView == self.tableView {
            return selectedTickets.count
        } else {
            return   5
//            getFeesAndTaxes().count
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketItemTableViewCell.identifier,
            for: indexPath
        ) as? TicketItemTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        if tableView == self.tableView {

            let ticket = selectedTickets[indexPath.row]
            let quantity = ticket.selectedTicketCount ?? 0
            let price = ticket.price ?? 0

            let total = Double(quantity) * price

            cell.titleLbl.text = "\(quantity)x \(ticket.tierName)"
            cell.amountLbl.text = total <= 0
                ? "Free"
                : "\(currency)\(total.decimalFormat(true))"

        } else {

//            let feeItem = getFeesAndTaxes()[indexPath.row]
//
//            cell.titleLbl.text = feeItem.title
//            cell.amountLbl.text = "\(currency)\(feeItem.amount.decimalFormat(true))"
        }

        return cell
    }
}
