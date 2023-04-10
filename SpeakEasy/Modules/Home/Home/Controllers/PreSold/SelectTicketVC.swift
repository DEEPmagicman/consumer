//
//  SelectTicketVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/04/23.
//

import UIKit

final class SelectTicketVC: UIViewController {
    
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var continueBtn: UIButton!
    
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var maxTicket = 10
    private var totalPrice: Int {
        var total = 0
        venueDetails?.appClipTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += ($0.price * quantity)
            }
        }
        return total
    }
    var venueId = ""
    var venueDetails: ClipVenue?

    override func viewDidLoad() {
        super.viewDidLoad()
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
        if let selectedTickets = venueDetails?.appClipTicket?.filter({ $0.selectedQuantity != nil }) {
            Navigate.to.checkOutVC(self, venueName: venueDetails?.name ?? "", venueId: venueId, venueAttachment: venueDetails?.venueAttachment.first?.key ?? "", venueLogo: venueDetails?.logo?.key ?? "", selectedTickets: selectedTickets, totalPrice: totalPrice)
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
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
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if let totalTicket = venueDetails?.appClipTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetails?.appClipTicket?[sender.tag].selectedQuantity = totalTicket + 1
                ticketListTableView.reloadData()
                updateContinueBtn()
            } else {
                Alert.showToast("Max ticket selection reached")
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
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  $\(self.totalPrice)", for: .normal)
        }
    }
}

extension SelectTicketVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetails?.appClipTicket?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if venueDetails?.appClipTicket?[indexPath.row].status == "DISABLED" {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        cell.ticketTypeLbl.text = venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
        cell.infoLbl.text = venueDetails?.appClipTicket?[indexPath.row].description
        if venueDetails?.appClipTicket?[indexPath.row].price ?? 0 >= 5 {
            cell.ticketPriceLbl.text = "$\(venueDetails?.appClipTicket?[indexPath.row].price ?? 0)"
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
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.totalTicketLbl.text = "\(venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0)"
        cell.plusBtn.alpha = venueDetails?.appClipTicket?[indexPath.row].selectedQuantity ?? 0 == maxTicket ? 0.5 : 1
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if venueDetails?.bookingStatus != "OPEN" || venueDetails?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
        if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        if venueDetails?.appClipTicket?[indexPath.row].selectedQuantity != nil { return }
        continueBtn.isHidden = false
        scrollViewBottomConstraint.constant = 90
        venueDetails?.appClipTicket?[indexPath.row].selectedQuantity = 1
        ticketListTableView.reloadData()
        updateContinueBtn()
    }
}
