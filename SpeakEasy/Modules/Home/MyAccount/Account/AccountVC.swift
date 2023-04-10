//
//  AccountVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 07/04/23.
//

import UIKit

final class AccountVC: UIViewController {

    @IBOutlet private weak var listTableView: UITableView!
    @IBOutlet private weak var listHeight: NSLayoutConstraint!
    @IBOutlet private weak var confirmEmailLbl: UILabel!

    private var listHeightObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        listTableView.register(UINib(nibName: "TitleHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleHeader")
        listTableView.register(UINib(nibName: "UpcomingTVC", bundle: nil), forCellReuseIdentifier: "UpcomingTVC")
        listHeightObservation = listTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.listHeight.constant = self.listTableView.contentSize.height
            self.listTableView.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickConfirmEmail))
        confirmEmailLbl.isUserInteractionEnabled = true
        confirmEmailLbl.addGestureRecognizer(tap)
        listTableView.setupPadding()
        listTableView.groupStyleSpacing()
    }
    
    @objc private func onClickConfirmEmail() {
        Navigate.to.presentCommentDoneBottomSheet(self)
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = """
 Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues.

 Link to App: https://apps.apple.com/us/app/speakeasy-go/id1642351956
 """
         Utility.main.shareSocialWith(text: msgText)
    }

    @IBAction func onBtnSetting(_ sender: UIButton) {
        Navigate.to.settingsVc(self)
    }
}

extension AccountVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
            
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingTVC", for: indexPath) as! UpcomingTVC
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        72
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TitleHeader") as? TitleHeader
        if section == 0 {
            header?.titleLbl.text = "Your Tickets"
        } else {
            header?.titleLbl.text = "Recommended"
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            // TODO: navigate with actual data
            Navigate.to.qrCodeMvpVC(self, venueName: "hello", bookingId: "hello", venueAttachment: "hee", venueLogo: "aas", selectedTickets: [])
        case 1:
            // TODO: navigate to recommended event
            break
        default:
            break
        }
    }
}
