//
//  PaymentDetailVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/04/23.
//

import UIKit

final class PaymentDetailVC: UIViewController {
    
    @IBOutlet private weak var totalPriceLbl: UILabel!
    @IBOutlet private weak var ticketListTableView: UITableView!
    @IBOutlet private weak var ticketListHeight: NSLayoutConstraint!
    
    var selectedTickets = [AppClipTicket]()
    var totalPrice = 0
    private var ticketListHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        totalPriceLbl.text = "$\(totalPrice)"
        ticketListTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketListTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketListHeight.constant = self.ticketListTableView.contentSize.height
            self.ticketListTableView.layoutIfNeeded()
        }
    }

    @IBAction func onClickBack(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension PaymentDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
        cell.titleLbl.text = selectedTickets[indexPath.row].name
        cell.subTitleLbl.text = selectedTickets[indexPath.row].description
        cell.quantityLbl.text = "\(selectedTickets[indexPath.row].selectedQuantity ?? 0)x"
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}
