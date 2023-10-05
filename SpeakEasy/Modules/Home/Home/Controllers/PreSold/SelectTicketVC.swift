//
//  SelectTicketVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/04/23.
//

import UIKit

enum TicketType {
    case appClip
    case event
}

final class SelectTicketVC: UIViewController {
    
    @IBOutlet private weak var mainImg: UIImageView!
    @IBOutlet private weak var titleLbl: UILabel!
    @IBOutlet private weak var dateLbl: UILabel!
    @IBOutlet private weak var subtitleLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var continueBtn: UIButton!
    
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var maxTicket = 20
    private var totalPrice: Int {
        var total = 0
        switch type {
        case .appClip:
            venueDetails?.appClipTicket?.forEach {
                if let quantity = $0.selectedQuantity {
                    total += ($0.price * quantity)
                }
            }
        case .event:
            event?.eventTicket?.forEach {
                if let quantity = $0.selectedTicketCount {
                    total += (($0.price ?? 0) * quantity)
                }
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        totalSelectedTickets >= maxTicket
    }
    private var totalSelectedTickets: Int {
        var total = 0
        switch type {
        case .appClip:
            venueDetails?.appClipTicket?.forEach {
                if let quantity = $0.selectedQuantity {
                    total += quantity
                }
            }
        case .event:
            event?.eventTicket?.forEach {
                if let quantity = $0.selectedTicketCount {
                    total += quantity
                }
            }
        }
        return total
    }
    var venueDetails: ClipVenue?
    var event: Event?
    var type: TicketType = .appClip

    override func viewDidLoad() {
        super.viewDidLoad()
        switch type {
        case .appClip:
            break
        case .event:
            mainImg.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            titleLbl.text = event?.title ?? "Untitle Event"
            dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")
            subtitleLbl.text = "\(venueDetails?.name ?? ""), \(venueDetails?.city ?? "")"
        }
        ticketListTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
        updateContinueBtn(forceRemove: true)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickContinue(_ sender: Any) {
        if let selectedTickets = event?.eventTicket?.filter({ $0.selectedTicketCount != nil }) {
            Navigate.to.checkOutVC(self, venue: venueDetails, selectedAppClipTickets: [], selectedEventTicket: selectedTickets, event: event, totalPrice: Double(totalPrice), type: .singleTickedEvent)
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        switch type {
        case .appClip:
            if let totalTicket = venueDetails?.appClipTicket?[sender.tag].selectedQuantity {
                if totalTicket > 1 {
                    venueDetails?.appClipTicket?[sender.tag].selectedQuantity = totalTicket - 1
                    ticketListTableView.reloadData()
                    updateContinueBtn()
                } else if totalTicket == 1 {
                    venueDetails?.appClipTicket?[sender.tag].selectedQuantity = nil
                    ticketListTableView.reloadData()
                    updateContinueBtn(forceRemove: (venueDetails?.appClipTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
                }
            }
        case .event:
            if let totalTicket = event?.eventTicket?[sender.tag].selectedTicketCount {
                if totalTicket > 1 {
                    event?.eventTicket?[sender.tag].selectedTicketCount = totalTicket - 1
                    ticketListTableView.reloadData()
                    updateContinueBtn()
                } else if totalTicket == 1 {
                    event?.eventTicket?[sender.tag].selectedTicketCount = nil
                    ticketListTableView.reloadData()
                    updateContinueBtn(forceRemove: (event?.eventTicket?.firstIndex(where: { $0.selectedTicketCount != nil })) == nil)
                }
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        switch type {
        case .appClip:
            if let totalTicket = venueDetails?.appClipTicket?[sender.tag].selectedQuantity {
                if totalTicket < maxTicket {
                    venueDetails?.appClipTicket?[sender.tag].selectedQuantity = totalTicket + 1
                    ticketListTableView.reloadData()
                    updateContinueBtn()
                } else {
                    Alert.showToast("Max ticket selection reached")
                }
            }
        case .event:
            if let totalTicket = event?.eventTicket?[sender.tag].selectedTicketCount {
                if totalTicket < maxTicket {
                    if let remaining = event?.eventTicket?[sender.tag].remainingQuantity, remaining > totalTicket {
                        event?.eventTicket?[sender.tag].selectedTicketCount = totalTicket + 1
                        ticketListTableView.reloadData()
                        updateContinueBtn()
                    }
                } else {
                    Alert.showToast("Max ticket selection reached")
                }
            }
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 30
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                self.ticketListTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  \(self.venueDetails?.venueSettings?.currencySymbol ?? "$")\(Double(self.totalPrice).decimalFormat(true))", for: .normal)
        }
    }
}

extension SelectTicketVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch type {
        case .appClip:
            return venueDetails?.appClipTicket?.count ?? 0
        case .event:
            return event?.eventTicket?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch type {
        case .appClip:
            if venueDetails?.appClipTicket?[indexPath.row].status == "DISABLED" {
                return 0
            }
        case .event:
            if event?.eventTicket?[indexPath.row].sellingPaused == true {
                return 0
            }
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        switch type {
        case .appClip:
            cell.ticketTypeLbl.text = venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
            cell.infoLbl.text = venueDetails?.appClipTicket?[indexPath.row].description
            if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 >= 2 {
                cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\(Double(venueDetails?.appClipTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
            } else {
                cell.ticketPriceLbl.text = "FREE"
            }
            if venueDetails?.bookingStatus == "OPEN" && venueDetails?.appClipTicket?[indexPath.row].status == "ENABLED" {
                cell.ticketPriceLbl.textColor = .white
                cell.ticketTypeLbl.textColor = .white
            } else {
                cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
                cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            }
            if venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0 >= 1 {
                cell.ticketPlusMinusView.isHidden = false
            } else {
                cell.ticketPlusMinusView.isHidden = true
            }
            if venueDetails?.checkInUser ?? 0 > 100 {
                cell.hotVenueLbl.isHidden = false
            } else {
                cell.hotVenueLbl.isHidden = true
            }
            cell.totalTicketLbl.text = "\(venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0)"
        case .event:
             cell.ticketTypeLbl.text = event?.eventTicket?[indexPath.row].tierName
             cell.infoLbl.text = event?.eventTicket?[indexPath.row].tierDescription
             cell.ticketPriceLbl.text = "\(venueDetails?.venueSettings?.currencySymbol ?? "$")\(Double(event?.eventTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
             cell.ticketPriceLbl.textColor = .white
             cell.ticketTypeLbl.textColor = .white
             if event?.eventTicket?[indexPath.row].selectedTicketCount ?? 0 >= 1 {
                 cell.ticketPlusMinusView.isHidden = false
             } else {
                 cell.ticketPlusMinusView.isHidden = true
             }
             if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, remaining <= 20 {
                 cell.hotVenueLbl.isHidden = false
                 if remaining == 0 {
                     cell.hotVenueLbl.text = "Sold out"
                 } else {
                     cell.hotVenueLbl.text = "Only \(remaining) left"
                 }
             } else {
                 cell.hotVenueLbl.isHidden = true
             }
             cell.totalTicketLbl.text = "\(event?.eventTicket?[indexPath.row].selectedTicketCount ?? 0)"
        }
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, let selectedTicket = event?.eventTicket?[indexPath.row].selectedTicketCount, remaining <= selectedTicket {
            cell.plusBtn.alpha = 0.5
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch type {
        case .appClip:
            if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
            if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
            if venueDetails?.appClipTicket?[indexPath.row].selectedQuantity != nil { return }
        case .event:
            if event?.eventTicket?[indexPath.row].selectedTicketCount != nil { return }
        }
        
        if isMaxTicketReached {
            Alert.showToast("Max ticket selection reached")
            return
        }
        
        switch type {
        case .appClip:
            venueDetails?.appClipTicket?[indexPath.row].selectedQuantity = 1
        case .event:
            if let startDate = event?.eventTicket?[indexPath.row].beginSale, (startDate.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date() {
                Alert.showAlertSheet(style: .alert, title: nil, message: String(format: Constant.String.ticketSellingWillStartAt, startDate.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMMMddHHmm, useDayLightSavingTime: true, customTimeZone: venueDetails?.useTimezone ?? "")))
                return
            }
            
            if let remaining = event?.eventTicket?[indexPath.row].remainingQuantity, remaining >= 1 {
                event?.eventTicket?[indexPath.row].selectedTicketCount = 1
            } else {
                Alert.showToast("Sold out")
                return
            }
        }
        
        continueBtn.isHidden = false
        scrollViewBottomConstraint.constant = 90
        ticketListTableView.reloadData()
        if totalSelectedTickets == 0 {
            updateContinueBtn(forceRemove: true)
        } else {
            updateContinueBtn()
        }
    }
}
