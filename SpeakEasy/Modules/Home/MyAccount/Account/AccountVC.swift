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
        listTableView.setupPadding()
        listTableView.groupStyleSpacing()
    }
    
    @IBAction func onClickShare(_ sender: Any) {
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
}
