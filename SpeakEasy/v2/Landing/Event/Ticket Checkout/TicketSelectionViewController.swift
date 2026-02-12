//
//  TicketSelectionViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

import UIKit

class TicketSelectionViewController: UIViewController {

    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var hiddenTicketField: UITextField!
    @IBOutlet weak var eventTitleLbl: UILabel!
    
    private var tickets: [EventTicket] = []
    var event: Event?
    var venueDetails: ClipVenue?
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
        setupData()
    }
    
    private func setupData() {

        guard let event = event else { return }

        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        venueName.text = venueDetails?.name ?? ""
        venueName2.text = venueDetails?.name ?? ""
        eventTitleLbl.text = event.title

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
        if let hex = self.event?.whiteLabelColor {
              let color = UIColor(hex: hex)
            dateandtimeLbl.textColor = color
        }
       

        // Convert EventTicket → TicketModel
     

//        tickets = event.eventTicket?.compactMap { ticket in
//            guard ticket.isDeleted == false,
//                  ticket.sellingPaused == false else { return  }
//
//            return TicketModel(
//                title: ticket.tierName ?? "",
//                price: ticket.price ?? 0,
//                quantity: 0,
//                currency: currency
//            )
//        } ?? []
        self.tickets = event.eventTicket ?? []
 
        ticketTableView.reloadData()
    }

    
    @IBAction func onClickCloseBtn(_ sender: Any) {
    }
    
    @IBAction func onClickLockBtn(_ sender: Any) {
    }
    
    @IBAction func onClickContinueBtn(_ sender: Any) {
        Navigate.to.ticketCheckoutVC(self)
    }
    
}

extension TicketSelectionViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

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
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        
        if let remaining = tickets[indexPath.row].remainingQuantity, let selectedTicket = tickets[indexPath.row].selectedTicketCount, remaining <= selectedTicket {
            cell.plusBtn.isHidden = false
        }
        if let count  = tickets[indexPath.row].selectedTicketCount, count != 0 {
            cell.quantityLbl.isHidden = false
            cell.quantityLbl.text = "\(count)"
            cell.minusView.isHidden = false
        }
      

        cell.onIncrease = { [weak self] in
            guard let self = self else { return }
//            cell.showMinusView(ticket: self.tickets[indexPath.row])
            tableView.reloadRows(at: [indexPath], with: .none)
        }

        cell.onDecrease = { [weak self] in
            guard let self = self else { return }
//            if self.tickets[indexPath.row].quantity <= 0 {
//                cell.hideMinusView()
//            }

//            guard self.tickets[indexPath.row].quantity > 0 else { return }

       

          
            tableView.reloadRows(at: [indexPath], with: .none)
        }


        return cell
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = tickets[sender.tag].selectedTicketCount {
            if totalTicket > 1 {
                tickets[sender.tag].selectedTicketCount = totalTicket - 1
                ticketTableView.reloadData()
//                updateContinueBtn()
            } else if totalTicket == 1 {
                tickets[sender.tag].selectedTicketCount = nil
                ticketTableView.reloadData()
//                updateContinueBtn(forceRemove: (activeTickets?.firstIndex(where: { $0.selectedTicketCount != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
         let totalTicket = tickets[sender.tag].selectedTicketCount ?? 0
            if totalTicket < tickets[sender.tag].issuedUnits ?? 0 {
                
                if let remaining = tickets[sender.tag].remainingQuantity, remaining > totalTicket {
                    tickets[sender.tag].selectedTicketCount = totalTicket + 1
                    ticketTableView.reloadData()
//                    updateContinueBtn()
                }
            }
            else {
                Alert.showToast("Max ticket selection reached")
            }
        
    }
}
