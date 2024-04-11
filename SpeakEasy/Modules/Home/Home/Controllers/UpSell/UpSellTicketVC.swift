//
//  UpsellTicketVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 28/02/24.
//

import UIKit

class UpSellTicketVC: UIViewController {
    
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var upSellTitle: UILabel!
    @IBOutlet weak var upSellDescription: UILabel!
    
    var venueDetails: ClipVenue?
    var doormanId = ""
    private var maxTicket = 20
    var upSellTicket = [UpSellTicket]()
    var selectedCoverTicket: [CoverTicket] {
        venueDetails?.coverTicket?.filter({ $0.selectedQuantity ?? 0 != 0}) ?? []
    }
    var selectedAddOns: [UpSellTicket] {
        upSellTicket.filter({$0.selectedQuantity ?? 0 != 0})
    }
    var hasMany = false
    var isLoading = false
    var bookingType: TicketPriceType = .FREE
    var modifiedUpSellTicket: [UpSellTicket] {
        var ticketData = [UpSellTicket]()
        upSellTicket.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            var taxRate = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                taxRate = (venueDetails?.venueSettings?.addOnsBookingSettings?.salesTax ?? 0) / 100
            }
            
            var totalCustomFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableCustomFee == true {
                if venueDetails?.venueSettings?.addOnsBookingSettings?.customFeeType == "PERCENTAGE" {
                    totalCustomFee = (ticketData[index].price * (venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0) / 100)
                } else {
                    totalCustomFee = (venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0)
                }
            }
            
            var totalProcessingFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isProcessingFeePassToCustomer == true {
                let stripeFee = (0.029 * (1 + taxRate) * (ticket.price + SEFee(ticket.price) + totalCustomFee ) + 0.3) / (1 - (1 + taxRate) * 0.029)
                totalProcessingFee = stripeFee + SEFee(ticket.price)
            }
            
            var salesTax = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                salesTax = (ticket.price + totalProcessingFee + totalCustomFee) * taxRate
            }
            
            let amountChargedToConsumer = ticket.price + totalProcessingFee + totalCustomFee + salesTax
            ticketData[index].price = round(amountChargedToConsumer * 100) / 100
        })
        return ticketData
    }
    
    func SEFee(_ ticketPrice: Double) -> Double {
        var amountTransferToSE = 0.0
        if venueDetails?.speakEasyCharges == "SAME_PRICE" {
            amountTransferToSE = 1
        }
        if venueDetails?.speakEasyCharges == "FREE" {
            amountTransferToSE = 0
        }
        if venueDetails?.speakEasyCharges == "INCREMENTAL" {
            if ticketPrice <= 10 {
                amountTransferToSE = 0.5
            } else if (ticketPrice <= 20 && ticketPrice > 10) {
                amountTransferToSE = 1
            } else if (ticketPrice <= 100 && ticketPrice > 20) {
                amountTransferToSE = 2
            } else if (ticketPrice > 100) {
                amountTransferToSE = 5
            }
        }
        if venueDetails?.speakEasyCharges == "DIFFRENT_PRICE" {
            amountTransferToSE = 0.5
        }
        if venueDetails?.speakEasyCharges == "TAO_PRICING" {

            amountTransferToSE = 0.5
        }
        return amountTransferToSE
    }
    
    private var isMaxTicketReached: Bool {
        var total = 0
        upSellTicket.forEach {
            if let quantity = $0.selectedQuantity {
                total += quantity
            }
        }
        return total >= maxTicket
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if upSellTicket.count == 0 {
            Loader.show()
            getUpsellTicket()
        }
        
        ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketTypeTableView.register(UINib(nibName: "FooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "FooterView")
        upSellTitle.text = venueDetails?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Upsell Items"
        upSellDescription.text = venueDetails?.venueSettings?.addOnsBookingSettings?.description ?? ""
        updateContinueBtn()
    }
    
    private func updateContinueBtn() {
        if selectedCoverTicket.count == 0 {
            continueBtn.setTitle(Constant.String.continueBtnTitle, for: .normal)
            continueBtn.alpha = selectedAddOns.count == 0 ? 0.5 : 1
            continueBtn.isUserInteractionEnabled = selectedAddOns.count == 0 ? false : true
        } else {
            if selectedAddOns.count == 0 {
                if bookingType == .FREE {
                    continueBtn.setTitle(Constant.String.skipAndGetMyFreeTicket, for: .normal)
                } else {
                    continueBtn.setTitle(Constant.String.skipAndContinueBtnTitle, for: .normal)
                }
            } else {
                continueBtn.setTitle(Constant.String.continueBtnTitle, for: .normal)
            }
        }
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickContinueBtn(_ sender: Any) {
        if selectedAddOns.count != 0 || bookingType != .FREE {
            Navigate.to.checkOutVC(self, venue: venueDetails, selectedCoverTickets: selectedCoverTicket, selectedEventTicket: [], selectedAddOnsItem: selectedAddOns, totalPrice: 0, type: .appClip, bookingType: bookingType)
        } else {
            createFreeBooking()
        }
    }
        private func getUpsellTicket() {
            MVPPresenter.getUpSellItem(skip: upSellTicket.count, doormanId: doormanId, venueId: venueDetails?.id ?? "") {[weak self] isSuccess, errMsg, upSellItem, hasMore, _ in
                guard let self = self else { return }
                Loader.hide()
                if isSuccess {
                    self.isLoading = false
                    for item in upSellItem {
                        self.upSellTicket.append(item)
                    }
                    self.hasMany = hasMore
                    DispatchQueue.main.async {
                        self.ticketTypeTableView.reloadData()
                    }
                } else {
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
            }
        }
        
        private func createFreeBooking() {
            if let selectedTickets = venueDetails?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
                var tickets = [[String: Any]]()
                selectedTickets.forEach {
                    tickets.append(["ticketId": $0.id,
                                    "ticketQuantity": $0.selectedQuantity ?? 0])
                }
                Loader.show()
                PaymentPresenter.createCoverFreeBooking(coverTickets: tickets, venueId: venueDetails?.id ?? "") { [weak self] isSuccess, errMsg, id,message   in
                    Loader.hide()
                    guard let self = self else { return }
                    if isSuccess, let id = id {
                        Navigate.to.scanQR(self, bookingId: id, addOnsBookingId: "")
                    } else {
                        Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                    }
                }
            }
        }
    }

extension UpSellTicketVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return upSellTicket.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        cell.ticketTypeLbl.text = upSellTicket[indexPath.row].addOns?.name ?? ""
        cell.infoLbl.text = upSellTicket[indexPath.row].addOns?.description ?? ""
        if venueDetails?.venueSettings?.addOnsBookingSettings?.isUpFront == true {
            cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((modifiedUpSellTicket[indexPath.row].price).decimalFormat(true))"
        } else {
            cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\((upSellTicket[indexPath.row].price).decimalFormat(true))"
        }
        cell.ticketPlusMinusView.isHidden = !(upSellTicket[indexPath.row].selectedQuantity ?? 0 > 0)
        if let quantity = upSellTicket[indexPath.row].selectedQuantity {
            cell.totalTicketLbl.text = "\(quantity)"
        }
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        cell.plusBtn.isEnabled = isMaxTicketReached ? false : true
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMaxTicketReached {
            Alert.showToast(Constant.String.maxTicketSelectionReached)
            return
        }
        if (tableView.cellForRow(at: indexPath) as? ticketTypeTableViewCell) != nil {
            if  upSellTicket[indexPath.row].selectedQuantity == nil || upSellTicket[indexPath.row].selectedQuantity == 0 {
                var quantity = upSellTicket[indexPath.row].selectedQuantity ?? 0
                quantity = quantity + 1
                self.upSellTicket[indexPath.row].selectedQuantity = quantity
            }
            updateContinueBtn()
            ticketTypeTableView.reloadData()
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = upSellTicket[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                upSellTicket[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                upSellTicket[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast(Constant.String.maxTicketSelectionReached)
            return
        }
        if let totalTicket = upSellTicket[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                upSellTicket[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else {
                Alert.showToast(Constant.String.maxTicketSelectionReached)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = self.ticketTypeTableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterView") as? FooterView
        footer?.loader.startAnimating()
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isLoading {
            return 50
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (upSellTicket.count) - 1 && hasMany && isLoading == false {
            isLoading = true
            DispatchQueue.main.async {
                self.ticketTypeTableView.reloadData()
            }
            getUpsellTicket()
        }
    }
}
