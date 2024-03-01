//
//  CustomPagerViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView

class CustomPagerViewCell: FSPagerViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var ticketsTableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!
    
    var appClipTickets : [AppClipTicket] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(UINib(nibName: "TicketCountTVC", bundle: nil), forCellReuseIdentifier: "TicketCountTVC")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tapGesture)
        
    }
    
    
    @objc func qrImageTapped() {
        containerView.isUserInteractionEnabled = false
        flipView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
    }
    
    private func flipView() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight, animations: {[weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.qrImage.isHidden = !self.qrImage.isHidden
        })
    }
    
}

extension CustomPagerViewCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appClipTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketCountTVC", for: indexPath) as! TicketCountTVC
        cell.ticketNameLbl.text = appClipTickets[indexPath.row].name
        cell.infoLbl.text = appClipTickets[indexPath.row].description
        if let quantity = appClipTickets[indexPath.row].selectedQuantity {
            cell.ticketCountLbl.text = "\(quantity)x"
        }
        cell.selectionStyle = .none
        
        if indexPath.row == appClipTickets.count - 1 {
            cell.separatorView.isHidden = true
        }
        
        return cell
    }
}
