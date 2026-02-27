//
//  TicketSelectionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

import UIKit
import MHLoadingButton

class TicketSelectionViewController: UIViewController {

    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var hiddenTicketField: UITextField!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var continueToCheckOutBtn: LoadingButton!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var protectedTicketView: UIView!
    @IBOutlet weak var unLockTF: UITextField!
    @IBOutlet weak var unLockBtn: UIView!
    @IBOutlet weak var addOnTicketTitleView: UIView!
    @IBOutlet weak var addOnTicketTitleLbl: UILabel!

    private enum TicketMode {
        case normal
        case addOn
    }

    private var mode: TicketMode = .normal

    private var tickets: [EventTicket] = []
    private var normalTickets: [EventTicket] = []
    private var addOnTickets: [EventTicket] = []

    private var selectedNormalTickets: [EventTicket] = []
    
    var event: Event?
    var venueDetails: ClipVenue?

    private var eventTicketId = [String]()

    private var totalSelectedTickets: Int {
        var total = 0
        tickets.forEach {
            if let quantity = $0.selectedTicketCount {
                total += quantity
            }
        }
        return total
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let venue = event?.venue {
            self.venueDetails = venue
        }

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        
        continueToCheckOutBtn.indicator = MaterialLoadingIndicator(color: .white)
        continueToCheckOutBtn.bgColor = continueToCheckOutBtn.backgroundColor ?? .orange

        setupData()
    }

    private func setupData() {
        guard let event = event else { return }

        let hasProtectedTicket = !(event.protectedEventTicket?.isEmpty ?? true)
        protectedTicketView.isHidden = !hasProtectedTicket

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )

        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title
        
        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            dateandtimeLbl.text = customText
            
        } else {
            
            let timezone = venueDetails?.useTimezone ?? ""
            
            let dateText = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )
            
            let startTime = event.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            )
            
            let endTime = event.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"
            
            dateandtimeLbl.text = "\(dateText) at \(startTime) - \(endTime)"
        }

        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
            continueToCheckOutBtn.backgroundColor = color
            continueToCheckOutBtn.bgColor = color
        }

        func filterAvailable(_ list: [EventTicket]) -> [EventTicket] {
            return list.filter { ticket in
                let remaining = ticket.remainingQuantity ?? 0
                let isNotDeleted = ticket.isDeleted == false
                let isNotPaused = ticket.sellingPaused == false
                return remaining > 0 && isNotDeleted && isNotPaused
            }
        }

        normalTickets = filterAvailable(event.eventTicket ?? [])
        addOnTickets  = filterAvailable(event.eventAddOnTicket ?? [])

        // default mode
        switchToNormalMode()
    }

    private func switchToNormalMode() {
        mode = .normal
        tickets = normalTickets

        addOnTicketTitleView.isHidden = true
        updateContinueButtonForMode()
        updateContinueBtnState()
        ticketTableView.reloadData()
    }

    private func switchToAddOnMode() {
        mode = .addOn
        tickets = addOnTickets

        addOnTicketTitleView.isHidden = false
        updateContinueButtonForMode()
        updateContinueBtnState()
        ticketTableView.reloadData()
    }
    
    private func refreshContinueButtonTitle() {
        updateContinueButtonForMode()
    }

    private func updateContinueButtonForMode() {
        switch mode {
        case .normal:
            continueToCheckOutBtn.setTitle("Continue to Checkout", for: .normal)
            

        case .addOn:
            let anyAddOnSelected = addOnTickets.contains(where: { ($0.selectedTicketCount ?? 0) > 0 })
                   continueToCheckOutBtn.setTitle(anyAddOnSelected ? "Continue to Checkout" : "NO THANKS", for: .normal)
        }
    }
    
    private func buildTicketsPayload(from selected: [EventTicket]) -> [[String: Any]] {
        var payload = [[String: Any]]()

        selected.forEach {
            payload.append([
                "ticketId": $0.id ?? "",
                "ticketQuantity": $0.selectedTicketCount ?? 0,
                "ticketPrice": $0.price ?? 0
            ])
        }

        return payload
    }

    private func getTicketByPassWord() {

        EventPresenter.getEventTicketByPassWord(
            eventId: self.event?.uniqueId ?? "",
            venueTimeZone: venueDetails?.useTimezone,
            password: unLockTF.text ?? ""
        ) { isSuccess, errMsg, ticket in

            if isSuccess {
                let tickets = ticket ?? []

                for tics in tickets {
                    if self.eventTicketId.contains(where: { $0 == tics.id }) == false {
                        self.eventTicketId.append(tics.id ?? "")
                    }
                }

                self.protectedTicketView.isHidden = self.event?.totalTickets == self.eventTicketId.count

                for data in tickets {
                    if self.event?.protectedEventTicket?.contains(where: { $0.id == data.id }) ?? false == false {
                        if self.event?.protectedEventTicket == nil {
                            self.event?.protectedEventTicket = [data]
                        } else {
                            self.event?.protectedEventTicket?.append(data)
                        }
                    }
                }
                self.unLockTF.text = ""
                self.unLockPassword()
                self.setupData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }

    @objc func unLockPassword() {
        unLockBtn.alpha = (unLockTF.text ?? "").isEmpty ? 0.5 : 1
        unLockBtn.isUserInteractionEnabled = !(unLockTF.text ?? "").isEmpty
    }

    @IBAction func onClickUnLockBtn(_ sender: Any) {

        let code = (unLockTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        guard var event = event else { return }

        let protectedList = event.protectedEventTicket ?? []
        guard !protectedList.isEmpty else {
            protectedTicketView.isHidden = true
            return
        }

        let matchedTickets = protectedList.filter { t in
            let pass = t.eventTicketHasPassword?.password ?? ""
            return pass.caseInsensitiveCompare(code) == .orderedSame
        }

        guard !matchedTickets.isEmpty else { return }

        for ticket in matchedTickets {
            if !normalTickets.contains(where: { $0.id == ticket.id }) {
                normalTickets.append(ticket)
            }
        }

        let unlockedIds = Set(matchedTickets.compactMap { $0.id })
        event.protectedEventTicket = protectedList.filter { t in
            guard let id = t.id else { return true }
            return !unlockedIds.contains(id)
        }

        unLockTF.text = ""
        unLockPassword()

        protectedTicketView.isHidden = (event.protectedEventTicket ?? []).isEmpty

        if mode == .normal {
            tickets = normalTickets
            ticketTableView.reloadData()
        }
    }


    @IBAction func onClickCloseBtn(_ sender: Any) {
        
        Navigate.to.back(self)
        
//        if mode == .addOn {
//            switchToNormalMode()
//        } else {
//            Navigate.to.back(self)
//        }
    }

    @IBAction func onClickLockBtn(_ sender: Any) {
  
    }

    @IBAction func onClickContinueBtn(_ sender: Any) {

        guard let event = event else { return }

        switch mode {

        case .normal:
            let selected = normalTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            guard !selected.isEmpty else { return }

            selectedNormalTickets = selected
           

            if addOnTickets.isEmpty {
                let ticketsPayload = buildTicketsPayload(from: selectedNormalTickets)
                continueToCheckOutBtn.showLoader(userInteraction: false)
                PaymentPresenter.createEventBookingV2(
                    eventId: event.id,
                    code: UserDefault.shared.user?.code ?? "+1",
                    phone: UserDefault.shared.user?.phone ?? "8286902566",
                    gender: "UNASSIGNED",
                    userId: UserDefault.shared.user?.id ?? "68d3e52d-14de-43f1-a49d-37d9b5764f2d",
                    tickets: ticketsPayload
                ) { [weak self] isSuccess, errMsg, id, message in
                    guard let self = self else { return }
                    continueToCheckOutBtn.hideLoader()
                    if isSuccess {
                        Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: self.selectedNormalTickets, bookingId: id)
                    } else {
                        Alert.showToast(errMsg ?? "Somthing went wrong")
                    }
                }
                return
            }

            switchToAddOnMode()

        case .addOn:
            let selectedAddOns = addOnTickets.filter { ($0.selectedTicketCount ?? 0) > 0 }
            let finalSelectedTickets = selectedNormalTickets + selectedAddOns
            let ticketsPayload = buildTicketsPayload(from: finalSelectedTickets)
            continueToCheckOutBtn.showLoader(userInteraction: true)
            PaymentPresenter.createEventBookingV2(
                eventId: event.id,
                code: UserDefault.shared.user?.code ?? "+1",
                phone: UserDefault.shared.user?.phone ?? "8286902566",
                gender: "UNASSIGNED",
                userId: UserDefault.shared.user?.id ?? "68d3e52d-14de-43f1-a49d-37d9b5764f2d",
                tickets: ticketsPayload
            ) { [weak self] isSuccess, errMsg, id, message in
                guard let self = self else { return }
                continueToCheckOutBtn.hideLoader()
                if isSuccess {
                    Navigate.to.ticketCheckoutVC(self, event: event, selectedTickets: finalSelectedTickets, bookingId: id)
                } else {
                    Alert.showToast(errMsg ?? "Somthing went wrong")
                }
            }
        }
    }

    private func indexForTicket(_ ticket: EventTicket) -> Int? {
        guard let id = ticket.id else { return nil }
        return tickets.firstIndex(where: { $0.id == id })
    }

    private func replaceTicketInCurrentMode(_ updated: EventTicket) {
        guard let id = updated.id else { return }

        switch mode {
        case .normal:
            if let idx = normalTickets.firstIndex(where: { $0.id == id }) {
                normalTickets[idx] = updated
            }
            tickets = normalTickets

        case .addOn:
            if let idx = addOnTickets.firstIndex(where: { $0.id == id }) {
                addOnTickets[idx] = updated
            }
            tickets = addOnTickets
        }
    }

    private func handlePlus(ticket: EventTicket) {
        guard let index = indexForTicket(ticket) else { return }

        let totalTicket = tickets[index].selectedTicketCount ?? 0
        let issuedUnits = tickets[index].issuedUnits ?? 0

        if totalTicket < issuedUnits,
           let remaining = tickets[index].remainingQuantity,
           remaining > totalTicket {

            tickets[index].selectedTicketCount = totalTicket + 1
            replaceTicketInCurrentMode(tickets[index])

            ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            updateContinueBtnState()
            updateContinueButtonForMode()
        } else {
            Alert.showToast("Max Tickets Selected: create a separate order to purchase more")
        }
    }

    private func handleMinus(ticket: EventTicket) {
        guard let index = indexForTicket(ticket) else { return }
        guard let totalTicket = tickets[index].selectedTicketCount else { return }

        if totalTicket > 1 {
            tickets[index].selectedTicketCount = totalTicket - 1
        } else {
            tickets[index].selectedTicketCount = nil
        }

        replaceTicketInCurrentMode(tickets[index])

        ticketTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        updateContinueBtnState()
        updateContinueButtonForMode()
    }

    private func handleRSVP(ticket: EventTicket) {
        guard let event = event else { return }

        switch mode {

        case .normal:
            selectedNormalTickets = [ticket]

            if addOnTickets.isEmpty {
                Navigate.to.ticketCheckoutVC(
                    self,
                    event: event,
                    selectedTickets: selectedNormalTickets, bookingId: nil
                )
            } else {
                switchToAddOnMode()
            }

        case .addOn:
            let finalTickets = selectedNormalTickets + [ticket]

            Navigate.to.ticketCheckoutVC(
                self,
                event: event,
                selectedTickets: finalTickets, bookingId: nil
            )
        }
    }


    private func updateContinueBtnState() {
        switch mode {
        case .normal:
            let isHidden = totalSelectedTickets <= 0
            continueToCheckOutBtn.isHidden = isHidden
            continueButtonBottomConstraint.constant = isHidden ? 0 : 32

        case .addOn:
            continueToCheckOutBtn.isHidden = false
            continueButtonBottomConstraint.constant = 32
        }

        view.layoutIfNeeded()
    }
}

extension TicketSelectionViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketsTVC.identifier,
            for: indexPath
        ) as? TicketsTVC else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        let ticket = tickets[indexPath.row]
        let currency = venueDetails?.venueSettings?.currencySymbol ?? "$"

        cell.configure(ticket: ticket, currency: currency, whiteLabelColor: event?.whiteLabelColor)

        cell.onPlusTap = { [weak self] ticket in
            self?.handlePlus(ticket: ticket)
        }

        cell.onMinusTap = { [weak self] ticket in
            self?.handleMinus(ticket: ticket)
        }

        cell.onRSVPTap = { [weak self] ticket in
            self?.handleRSVP(ticket: ticket)
        }

        return cell
    }
}
