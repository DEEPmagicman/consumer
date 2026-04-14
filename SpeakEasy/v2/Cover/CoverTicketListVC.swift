//
//  CoverTicketListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit
import SDWebImage

final class CoverTicketListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var venueImage: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var continueToChekoutBtn: UIView!
    @IBOutlet weak var ticketsTitleLbl: UILabel!
    
    var venueDetails: ClipVenue?
    var doormanId = ""
    
    private let maxTicket = 20
    
    private var coverTickets: [CoverTicket] = []
    private var upSellTickets: [UpSellTicket] = []
    
    private var coverTicketCount: [Int: Int] = [:]
    private var upSellTicketCount: [Int: Int] = [:]
    private var expandedIndexSet: Set<String> = []
    private var hasMoreUpSell = false
    private var bookingType: TicketPriceType = .FREE
    
    private enum FlowStep {
        case coverTickets
        case addOns
    }
    
    private var currentStep: FlowStep = .coverTickets
    
    // MARK: - Computed
    
    private var isVenueOpen: Bool {
        venueDetails?.venueSettings?.bookingStatus?.uppercased() == "OPEN"
    }
    
    private var totalSelectedCount: Int {
        coverTicketCount.values.reduce(0, +) + upSellTicketCount.values.reduce(0, +)
    }
    
    private var isMaxTicketReached: Bool {
        totalSelectedCount >= maxTicket
    }
    
    private var selectedCoverTickets: [CoverTicket] {
        coverTickets.enumerated().compactMap { index, ticket in
            let qty = coverTicketCount[index] ?? 0
            guard qty > 0 else { return nil }
            var item = ticket
            item.selectedQuantity = qty
            return item
        }
    }
    
    private var selectedAddOns: [UpSellTicket] {
        upSellTickets.enumerated().compactMap { index, ticket in
            let qty = upSellTicketCount[index] ?? 0
            guard qty > 0 else { return nil }
            var item = ticket
            item.selectedQuantity = qty
            return item
        }
    }
    
    private var hasPaidCoverTicket: Bool {
        selectedCoverTickets.contains { $0.price > 0 }
    }
    
    private var hasAnyCoverSelection: Bool {
        !selectedCoverTickets.isEmpty
    }
    
    private var hasAnyUpsell: Bool {
        !upSellTickets.isEmpty
    }
    
    private var modifiedUpSellTicket: [UpSellTicket] {
        var ticketData = [UpSellTicket]()
        
        upSellTickets.enumerated().forEach { index, ticket in
            ticketData.append(ticket)
            
            var taxRate = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                taxRate = (venueDetails?.venueSettings?.addOnsBookingSettings?.salesTax ?? 0) / 100
            }
            
            var totalCustomFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableCustomFee == true {
                if venueDetails?.venueSettings?.addOnsBookingSettings?.customFeeType == "PERCENTAGE" {
                    totalCustomFee = ticketData[index].price * (venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0) / 100
                } else {
                    totalCustomFee = venueDetails?.venueSettings?.addOnsBookingSettings?.customFee ?? 0
                }
            }
            
            var totalProcessingFee = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isProcessingFeePassToCustomer == true {
                let stripeFee = (0.029 * (1 + taxRate) * (ticket.price + SEFee(ticket.price) + totalCustomFee) + 0.3) / (1 - (1 + taxRate) * 0.029)
                totalProcessingFee = stripeFee + SEFee(ticket.price)
            }
            
            var salesTax = 0.0
            if venueDetails?.venueSettings?.addOnsBookingSettings?.isEnableSalesTax == true {
                salesTax = (ticket.price + totalProcessingFee + totalCustomFee) * taxRate
            }
            
            let amountChargedToConsumer = ticket.price + totalProcessingFee + totalCustomFee + salesTax
            ticketData[index].price = round(amountChargedToConsumer * 100) / 100
        }
        
        return ticketData
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupContinueTap()
        setupScreen()
        setupCoverTickets()
        getUpsellTickets()
        updateCheckoutState()
    }
    
    @IBAction func onClickContinueBtn(_ sender: Any) {
        
        if UserDefault.shared.isGuest == true {
            Navigate.to.loginMandatory(self)
            return
        }
        
        guard !selectedCoverTickets.isEmpty else { return }
        
        switch currentStep {
        case .coverTickets:
            if hasAnyUpsell {
                moveToAddOnStep()
            } else {
                proceedToFinalCheckout()
            }
            
        case .addOns:
            proceedToFinalCheckout()
        }
        
    }
}

// MARK: - Setup
private extension CoverTicketListVC {
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CoverTicketTVC.nib, forCellReuseIdentifier: CoverTicketTVC.identifier)
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func setupContinueTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickContinue))
        continueToChekoutBtn.addGestureRecognizer(tap)
    }
    
    func setupScreen() {
        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueImage.sd_setImage(with: URL(string: logoUrl), completed: nil)
        
        let imageUrlString = "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            bgImage.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy")
            )
        } else {
            bgImage.image = UIImage(named: "newSpeakeasy")
        }
        venueName.text = venueDetails?.name ?? ""
        timeLbl.text = venueDetails?.timezone
        
        if let hexColor = venueDetails?.venueSettings?.whiteLabelColor {
            let color = UIColor(hex: hexColor)
            continueToChekoutBtn.backgroundColor = color
            continueToChekoutBtn.layer.borderColor = color.cgColor
            continueToChekoutBtn.layer.borderWidth = 1
            timeLbl.textColor = color
        }
        
        continueToChekoutBtn.isHidden = true
        continueToChekoutBtn.alpha = 0
    }
    
    func setupCoverTickets() {
        guard let list = venueDetails?.coverTicket else {
            coverTickets = []
            tableView.reloadData()
            updateCheckoutState()
            return
        }
        
        coverTickets = list.filter {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }
        
        tableView.reloadData()
        updateCheckoutState()
    }
    
    func setContinueButtonTitle(_ title: String) {
        if let button = continueToChekoutBtn as? UIButton {
            button.setTitle(title, for: .normal)
            return
        }
        
        if let button = continueToChekoutBtn.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.setTitle(title, for: .normal)
            return
        }
        
        if let label = continueToChekoutBtn.subviews.first(where: { $0 is UILabel }) as? UILabel {
            label.text = title
            return
        }
    }
}

// MARK: - API
private extension CoverTicketListVC {
    
    func getUpsellTickets() {
        guard let venueId = venueDetails?.id, !venueId.isEmpty else {
            upSellTickets = []
            tableView.reloadData()
            return
        }
        
        MVPPresenter.getUpSellItem(skip: 0, doormanId: doormanId, venueId: venueId) { [weak self] isSuccess, errMsg, upSellItem, hasMore, _ in
            guard let self = self else { return }
            
            if isSuccess {
                self.upSellTickets = upSellItem
                self.hasMoreUpSell = hasMore
                self.tableView.reloadData()
                self.updateCheckoutState()
            } else {
                self.upSellTickets = []
                self.hasMoreUpSell = false
                self.tableView.reloadData()
                
                if let errMsg, !errMsg.isEmpty {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                }
            }
        }
    }
}

// MARK: - Pricing
private extension CoverTicketListVC {
    
    func displayPrice(for ticket: CoverTicket) -> String {
        if ticket.price == 0 {
            return "FREE"
        }
        
        let symbol = venueDetails?.venueSettings?.currencySymbol ?? "$"
        let total = ticket.price + (ticket.extraFees ?? 0)
        return "\(symbol)\(total.decimalFormat(true))"
    }
    
    func displayPrice(for ticket: UpSellTicket, at index: Int) -> String {
        let symbol = venueDetails?.venueSettings?.currencySymbol ?? "$"
        
        if venueDetails?.venueSettings?.addOnsBookingSettings?.isUpFront == true {
            let total = modifiedUpSellTicket[index].price
            return "\(symbol)\(total.decimalFormat(true))"
        } else {
            let total = ticket.price
//            + (ticket.extraFees ?? 0)
            return "\(symbol)\(total.decimalFormat(true))"
        }
    }
    
    func displayExtraFeesText(extraFees: Double?) -> String? {
        let fee = extraFees ?? 0
        guard fee > 0 else { return nil }
        let symbol = venueDetails?.venueSettings?.currencySymbol ?? "$"
        return "Incl. \(symbol)\(fee.decimalFormat(true)) in fees"
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
            } else if ticketPrice <= 20 {
                amountTransferToSE = 1
            } else if ticketPrice <= 100 {
                amountTransferToSE = 2
            } else if ticketPrice > 100 {
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
}

// MARK: - UI State
private extension CoverTicketListVC {
    
    func updateCheckoutState() {
        switch currentStep {
        case .coverTickets:
            let shouldShow = hasAnyCoverSelection
            
            if shouldShow {
                continueToChekoutBtn.isHidden = false
//                setContinueButtonTitle("CHECKOUT")
            }
            
            updateCheckoutButton(shouldShow: shouldShow)
            
        case .addOns:
            let shouldShow = hasAnyCoverSelection
            
            if shouldShow {
                continueToChekoutBtn.isHidden = false
//                let title = selectedAddOns.isEmpty ? "SKIP THIS AND CHECKOUT" : "CONTINUE TO CHECKOUT"
//                setContinueButtonTitle(title)
            }
            
            updateCheckoutButton(shouldShow: shouldShow)
        }
        
        bookingType = hasPaidCoverTicket ? .PAID : .FREE
    }
    
    func updateCheckoutButton(shouldShow: Bool) {
        
        if shouldShow {
            continueToChekoutBtn.isHidden = false
            continueToChekoutBtn.alpha = 0
            continueToChekoutBtn.transform = CGAffineTransform(translationX: 0, y: 80)

            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.6,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                self.continueToChekoutBtn.alpha = 1
                self.continueToChekoutBtn.transform = .identity
            }

        } else {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                self.continueToChekoutBtn.alpha = 0
                self.continueToChekoutBtn.transform = CGAffineTransform(translationX: 0, y: 80)
            } completion: { _ in
                self.continueToChekoutBtn.isHidden = true
            }
        }
    }
    
    func animateRowReload(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func canSelectMoreTickets() -> Bool {
        if isMaxTicketReached {
            Alert.showToast(Constant.String.maxTicketSelectionReached)
            return false
        }
        return true
    }
    
    func moveToAddOnStep() {
        currentStep = .addOns
        expandedIndexSet.removeAll()
        tableView.reloadData()
        updateCheckoutState()
    }
    
    func proceedToFinalCheckout() {
        guard !selectedCoverTickets.isEmpty else { return }

        if !selectedAddOns.isEmpty || hasPaidCoverTicket {
            Navigate.to.coverCheckOutVC(
                self,
                venue: venueDetails,
                selectedCoverTickets: selectedCoverTickets,
                selectedAddOnsItem: selectedAddOns,
                totalPrice: 0,
                bookingType: bookingType
            )
        } else {
            createFreeBooking()
        }
    }
}

// MARK: - Actions
extension CoverTicketListVC {
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        if currentStep == .addOns {
            currentStep = .coverTickets
            expandedIndexSet.removeAll()
            tableView.reloadData()
            updateCheckoutState()
            return
        }
        
        Navigate.to.back(self)
    }
    
    @objc func onClickContinue() {
        if UserDefault.shared.isGuest == true {
            Navigate.to.loginMandatory(self)
            return
        }
        
        guard !selectedCoverTickets.isEmpty else { return }
        
        switch currentStep {
        case .coverTickets:
            if hasAnyUpsell {
                moveToAddOnStep()
            } else {
                proceedToFinalCheckout()
            }
            
        case .addOns:
            proceedToFinalCheckout()
        }
    }
    
    private func createFreeBooking() {
        guard !selectedCoverTickets.isEmpty else { return }
        
        var tickets = [[String: Any]]()
        selectedCoverTickets.forEach {
            tickets.append([
                "ticketId": $0.id,
                "ticketQuantity": $0.selectedQuantity ?? 0
            ])
        }
        
        self.view.isUserInteractionEnabled = false
        
        PaymentPresenter.createCoverFreeBooking(
            coverTickets: tickets,
            venueId: venueDetails?.id ?? ""
        ) { [weak self] isSuccess, errMsg, id, _ in
            guard let self = self else { return }
            
            self.view.isUserInteractionEnabled = true
            
            if isSuccess, let id = id {
                Navigate.to.scanQR(self, bookingId: id, addOnsBookingId: "")
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    @objc func plusBtnClicked(_ sender: UIButton) {
        guard isVenueOpen else { return }
        guard canSelectMoreTickets() else { return }
        
        let indexPath = IndexPath(row: sender.tag, section: 0)
        
        switch currentStep {
        case .coverTickets:
            guard sender.tag < coverTickets.count else { return }
            let ticket = coverTickets[sender.tag]
            guard ticket.status == "ENABLED" else { return }
            
            coverTicketCount[sender.tag] = (coverTicketCount[sender.tag] ?? 0) + 1
            
        case .addOns:
            guard sender.tag < upSellTickets.count else { return }
            upSellTicketCount[sender.tag] = (upSellTicketCount[sender.tag] ?? 0) + 1
        }
        
        animateRowReload(at: indexPath)
        updateCheckoutState()
    }
    
    @objc func minusBtnClicked(_ sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        
        switch currentStep {
        case .coverTickets:
            let current = coverTicketCount[sender.tag] ?? 0
            coverTicketCount[sender.tag] = max(0, current - 1)
            
        case .addOns:
            let current = upSellTicketCount[sender.tag] ?? 0
            upSellTicketCount[sender.tag] = max(0, current - 1)
        }
        
        animateRowReload(at: indexPath)
        updateCheckoutState()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CoverTicketListVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentStep {
        case .coverTickets:
            return coverTickets.count
        case .addOns:
            return upSellTickets.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CoverTicketTVC = tableView.dequeue(withIdentifier: CoverTicketTVC.identifier, for: indexPath)
        cell.selectionStyle = .none
        
        switch currentStep {
        case .coverTickets:
            let ticket = coverTickets[indexPath.row]
            
            if let customName = ticket.customName, !customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cell.titleLbl.text = customName
            } else {
                cell.titleLbl.text = ticket.name
            }
            
            cell.configure(
                description: ticket.description,
                isExpanded: expandedIndexSet.contains(ticket.id),
                id: ticket.id
            )
            
            cell.priceLbl.text = displayPrice(for: ticket)
            
            if let extraFeesText = displayExtraFeesText(extraFees: ticket.extraFees) {
                cell.extraFeesLbl.isHidden = false
                cell.extraFeesLbl.text = extraFeesText
            } else {
                cell.extraFeesLbl.isHidden = true
            }
            
            let count = coverTicketCount[indexPath.row] ?? 0
            cell.ticketCount.text = "\(count)"
            
            let shouldShow = count > 0
            cell.minusBtnView.isHidden = !shouldShow
            cell.ticketCountView.isHidden = !shouldShow
            cell.updateSelectionUI(isSelected: shouldShow)
            
            
        case .addOns:
            let ticket = upSellTickets[indexPath.row]
            
            cell.titleLbl.text = ticket.addOns?.name ?? ""
            cell.configure(
                description: ticket.addOns?.description,
                isExpanded: expandedIndexSet.contains(ticket.id ?? ""),
                id: ticket.id
            )
            
            cell.priceLbl.text = displayPrice(for: ticket, at: indexPath.row)
            
            if let extraFeesText = displayExtraFeesText(extraFees: ticket.extraFees) {
                cell.extraFeesLbl.isHidden = false
                cell.extraFeesLbl.text = extraFeesText
            } else {
                cell.extraFeesLbl.isHidden = true
            }
            
            let count = upSellTicketCount[indexPath.row] ?? 0
            cell.ticketCount.text = "\(count)"
            
            let shouldShow = count > 0
            cell.minusBtnView.isHidden = !shouldShow
            cell.ticketCountView.isHidden = !shouldShow
            cell.updateSelectionUI(isSelected: shouldShow)
        }
        
        cell.onDescriptionToggle = { [weak self] ticketId in
            guard let self = self,
                  let ticketId = ticketId else { return }

            if self.expandedIndexSet.contains(ticketId) {
                self.expandedIndexSet.remove(ticketId)
            } else {
                self.expandedIndexSet.insert(ticketId)
            }

            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
        cell.plusBtn.tag = indexPath.row
        cell.minusBtn.tag = indexPath.row
        
        cell.plusBtn.removeTarget(nil, action: nil, for: .allEvents)
        cell.minusBtn.removeTarget(nil, action: nil, for: .allEvents)
        
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClicked(_:)), for: .touchUpInside)
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClicked(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isVenueOpen else { return }
        guard canSelectMoreTickets() else { return }
        
        switch currentStep {
        case .coverTickets:
            guard indexPath.row < coverTickets.count else { return }
            let ticket = coverTickets[indexPath.row]
            guard ticket.status == "ENABLED" else { return }
            
            coverTicketCount[indexPath.row] = (coverTicketCount[indexPath.row] ?? 0) + 1
            
        case .addOns:
            guard indexPath.row < upSellTickets.count else { return }
            upSellTicketCount[indexPath.row] = (upSellTicketCount[indexPath.row] ?? 0) + 1
        }
        
        animateRowReload(at: indexPath)
        updateCheckoutState()
    }
}
