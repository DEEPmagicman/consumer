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
    
    private var tickets: [TicketModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        ticketTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        loadMockData()
        
    }
    
    private func loadMockData() {
        tickets = [
            TicketModel(title: "General Admission", price: 499, quantity: 0),
            TicketModel(title: "VIP Entry", price: 999, quantity: 0),
            TicketModel(title: "Couple Pass", price: 1499, quantity: 0)
        ]
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

        cell.configure(ticket: ticket)

        cell.onIncrease = { [weak self] in
            guard let self = self else { return }
            self.tickets[indexPath.row].quantity += 1
            cell.showMinusView(ticket: self.tickets[indexPath.row])
            tableView.reloadRows(at: [indexPath], with: .none)
        }

        cell.onDecrease = { [weak self] in
            guard let self = self else { return }
            if self.tickets[indexPath.row].quantity <= 0 {
                cell.hideMinusView()
            }

            guard self.tickets[indexPath.row].quantity > 0 else { return }

            tickets[indexPath.row].quantity -= 1

          
            tableView.reloadRows(at: [indexPath], with: .none)
        }


        return cell
    }
}

