//
//  VipBookingInviteNew.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 13/01/23.
//

import UIKit

class VipBookingInviteNew: UIViewController {

    @IBOutlet weak var inviteTableView: UITableView!
    @IBOutlet weak var titleLbl: UILabelDeviceClass!
    
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 414.0
    var itsFree = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        self.setupStretchyTableView()
        self.inviteTableView.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateHeaderView()
        UIView.animate(withDuration: 0.02) {
            self.inviteTableView.alpha = 1.0
        } completion: { _ in
            
        }
    }

    @IBAction func onClickback(_ sender: Any) {
        Utility.main.topViewController()?.navigationController?.popViewController(animated: true)
    }
}
//MARK: - Helper Methods
extension VipBookingInviteNew {
    private func registerCells() {
        self.inviteTableView.register(UINib(nibName: "BookingDetailTVC", bundle: nil), forCellReuseIdentifier: "BookingDetailTVC")
        self.inviteTableView.register(UINib(nibName: "InviteFriendsCostSplitTVC", bundle: nil), forCellReuseIdentifier: "InviteFriendsCostSplitTVC")
        self.inviteTableView.register(UINib(nibName: "SubmitInviteTVC", bundle: nil), forCellReuseIdentifier: "SubmitInviteTVC")
        self.inviteTableView.register(UINib(nibName: "TransactionSummaryTVC", bundle: nil), forCellReuseIdentifier: "TransactionSummaryTVC")
        self.inviteTableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
    }
    private func setupStretchyTableView(){
        self.loadHeaderView()
        self.setupStreachyHeaderViewFrames()
    }
}
//MARK: - Stretchy TableView
extension VipBookingInviteNew {
    
    private func loadHeaderView() {
        if inviteTableView.tableHeaderView == nil {
            let tableHeaderView  = BookingInvitesHeaderView.instanceFromNib()
            inviteTableView.tableHeaderView = tableHeaderView
        }
    }
    private func setupStreachyHeaderViewFrames() {
        inviteTableView.rowHeight = UITableView.automaticDimension
        headerView = inviteTableView.tableHeaderView
        inviteTableView.tableHeaderView = nil
        if headerView != nil {
            inviteTableView.addSubview(headerView)
        }
        inviteTableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        inviteTableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    private func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: inviteTableView.bounds.width, height: kTableHeaderHeight)
        if inviteTableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = inviteTableView.contentOffset.y
            headerRect.size.height = -inviteTableView.contentOffset.y
        }
        debugPrint(headerRect)
        if headerView != nil {
            headerView.frame = headerRect
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
}

//MARK: - UITableViewDelegate
extension VipBookingInviteNew: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if itsFree == true {
            return 4
        } else {
            return 5
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingDetailTVC") as! BookingDetailTVC
                cell.userNoteLbl.text = "Additional requests"
                cell.have6BottelNote.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InviteFriendsCostSplitTVC") as! InviteFriendsCostSplitTVC
                cell.isFromInvite = true
                cell.costSpliteView.isHidden = true
                cell.headerLbl.text = "Guests & Cost Split (5)"
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionSummaryTVC", for: indexPath) as! TransactionSummaryTVC
            cell.setDataForInvite(itsFree: self.itsFree)
            return cell
        case 3:
            if itsFree == true {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubmitInviteTVC") as! SubmitInviteTVC
                cell.acceptBtn.addTarget(nil, action: #selector(self.onBtnAcceptInvite(_:)), for: .touchUpInside)
                cell.rejectBtn.addTarget(nil, action: #selector(self.onBtnRejectInvite(_:)), for: .touchUpInside)
                cell.setData(itsFree: self.itsFree)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell") as! PaymentTableViewCell
                cell.setUi(isSetting: false)
                return cell
            }
        default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubmitInviteTVC") as! SubmitInviteTVC
                cell.acceptBtn.addTarget(nil, action: #selector(self.onBtnAcceptInvite(_:)), for: .touchUpInside)
                cell.rejectBtn.addTarget(nil, action: #selector(self.onBtnRejectInvite(_:)), for: .touchUpInside)
            cell.setData(itsFree: self.itsFree)
                return cell
        }
    }
    @objc func onBtnAcceptInvite(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onBtnRejectInvite(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

