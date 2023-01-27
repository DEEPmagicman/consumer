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
    @IBOutlet private weak var ticketTypeTableView: UITableView!
    @IBOutlet private weak var tableViewHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
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
            cell.infoLbl.text = "Provides general admission to the venue. Admission subject to doorman discretion."
            cell.ticketPriceLbl.text = "$50"
            cell.lineView.isHidden = false
        } else {
            cell.ticketTypeLbl.text = "VIP Skip the Line"
            cell.infoLbl.text = "Don’t wait - go to the front and enter immediately. Admission subject to doorman discretion."
            cell.ticketPriceLbl.text = "$90"
            cell.lineView.isHidden = true
        }
        cell.selectionStyle = .none
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
