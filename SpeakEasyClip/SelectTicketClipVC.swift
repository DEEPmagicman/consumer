//
//  SelectTicketClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class SelectTicketClipVC: UIViewController {
    
    @IBOutlet private weak var venueBgImg: UIImageView!
    @IBOutlet private weak var venueTitleNameLbl: UILabel!
    @IBOutlet private weak var logoImg: UIImageView!
    @IBOutlet private weak var liveCloseLbl: UILabel!
    @IBOutlet private weak var ticketTypeTableView: UITableView!
    @IBOutlet private weak var tableViewHeight: NSLayoutConstraint!
    
    var isLive = true

    override func viewDidLoad() {
        super.viewDidLoad()
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        if isLive {
            liveCloseLbl.text = "LIVE"
            liveCloseLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
        } else {
            liveCloseLbl.text = "CLOSED"
            liveCloseLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
}

extension SelectTicketClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC
        if indexPath.row == 0 {
            cell.ticketTypeLbl.text = "General Admission"
            cell.infoLbl.text = "General Admission ticket. Entry subject to doorman discretion."
            cell.ticketPriceLbl.text = "$50"
            cell.lineView.isHidden = false
        } else {
            cell.ticketTypeLbl.text = "VIP Skip the Line"
            cell.infoLbl.text = "Don’t wait - enter immediately with a Skip Line ticket. Entry subject to doorman discretion"
            cell.ticketPriceLbl.text = "$90"
            cell.lineView.isHidden = true
        }
        if isLive {
            cell.ticketPriceLbl.textColor = .white
        } else {
            cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "EnterPhoneNumberClipVC")) as? EnterPhoneNumberClipVC {
            vc.ticketPrice = indexPath.row == 0 ? 50 : 90
            vc.isGeneralAdmission = indexPath.row == 0
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
