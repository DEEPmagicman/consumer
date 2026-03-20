//
//  CoverTicketListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class CoverTicketListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var ticketCount = [Int: Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CoverTicketTVC.nib, forCellReuseIdentifier: CoverTicketTVC.identifier)
    }
}

extension CoverTicketListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CoverTicketTVC = tableView.dequeue(withIdentifier: CoverTicketTVC.identifier, for: indexPath)
        cell.selectionStyle = .none
        cell.plusBtnView.isHidden = false
        if let count = ticketCount[indexPath.row], count != 0 {
            cell.minusBtnView.isHidden = false
            cell.ticketCountView.isHidden = false
            cell.ticketCount.text = "\(count)"
        } else {
            cell.minusBtnView.isHidden = true
            cell.ticketCountView.isHidden = true
        }
        cell.minusBtn.tag = indexPath.row
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClicked(_:)), for: .touchUpInside)
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClicked(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func plusBtnClicked(_ sender: UIButton) {
        if let count = ticketCount[sender.tag] {
            ticketCount[sender.tag] = count + 1
        } else {
            ticketCount[sender.tag] = 1
        }
        self.tableView.reloadData()
    }
    
    @objc func minusBtnClicked(_ sender: UIButton) {
        if let count = ticketCount[sender.tag], count != 0 {
            ticketCount[sender.tag] = count - 1
        } else {
            ticketCount[sender.tag] = 0
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let count = ticketCount[indexPath.row] {
            ticketCount[indexPath.row] = count + 1
        } else {
            ticketCount[indexPath.row] = 1
        }
        self.tableView.reloadData()
    }
}
