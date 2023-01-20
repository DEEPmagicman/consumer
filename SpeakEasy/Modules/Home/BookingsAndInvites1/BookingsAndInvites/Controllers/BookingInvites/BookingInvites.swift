//
//  BookingInvites.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 27/09/2022.
//

import UIKit

class BookingInvites: UIViewController {

    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    @IBOutlet weak var btnCross: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewPendingPayment: UIView!
    @IBOutlet weak var viewBookingRequestSent: UIView!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var topTitleLbl: UILabelDeviceClass!
    @IBOutlet weak var statusLbl: UILabelDeviceClass!
    
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 414.0
    
    var booking: BookingsDataSet?
    var isFromSettings = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        self.setupStretchyTableView()
        self.setUI()
        self.tableView.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFromSettings {
            viewPendingPayment.isHidden = isFromSettings
            backBtn.setImage(UIImage(named: "ic-close"), for: .normal)
            topTitleLbl.text = "Visit Details"
//        } else {
//            backBtn.setImage(UIImage(named: "BackArrow"), for: .normal)
//            topTitleLbl.text = "Pending Booking"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateHeaderView()
        
        UIView.animate(withDuration: 0.02) {
            self.tableView.alpha = 1.0
        } completion: { _ in
            
        }
    }

    @IBAction func onBtnBack(_ sender: UIButton) {
        Utility.main.topViewController()?.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnCross(_ sender: UIButton) {
        AppDelegate.shared.showHome(selectedIndex: 1)
    }
}

//MARK: - Helper Methods
extension BookingInvites {
    
    private func registerCells() {
        self.tableView.register(UINib(nibName: "BookingAddressTVC", bundle: nil), forCellReuseIdentifier: "BookingAddressTVC")
        self.tableView.register(UINib(nibName: "BookingDetailTVC", bundle: nil), forCellReuseIdentifier: "BookingDetailTVC")
        self.tableView.register(UINib(nibName: "InviteFriendsCostSplitTVC", bundle: nil), forCellReuseIdentifier: "InviteFriendsCostSplitTVC")
        self.tableView.register(UINib(nibName: "PaymentsTVC", bundle: nil), forCellReuseIdentifier: "PaymentsTVC")
        self.tableView.register(UINib(nibName: "SubmitRequestTVC", bundle: nil), forCellReuseIdentifier: "SubmitRequestTVC")
        self.tableView.register(UINib(nibName: "TransactionSummaryTVC", bundle: nil), forCellReuseIdentifier: "TransactionSummaryTVC")
        self.tableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
    }
    
    private func setupStretchyTableView(){
        self.loadHeaderView()
//        self.tableView.alpha = 0
        self.setupStreachyHeaderViewFrames()
//        self.tableView.layoutIfNeeded()
    }
    
    func setUI(){
        guard let status = self.booking?.status else {return}
        
        switch status {
        case .PurchaseConfirmed,.TicketPurchasedConfirmed:
            break
        case .AwaitingApproval:
            self.lblTitle.text = "Pending Booking"
            
            self.viewPendingPayment.isHidden = false
            self.viewBookingRequestSent.isHidden = true

            
             self.btnBack.isHidden = false
             self.btnCross.isHidden = true

            
        case .AwaitingVenueApproval:
//            self.lblTitle.text = "Booking Invite"
            self.lblTitle.text = "Pending Booking"
            self.viewPendingPayment.isHidden = false
            self.viewBookingRequestSent.isHidden = true

            self.statusLbl.text = "Booking Status: Awaiting Venue Approval"
            self.btnBack.isHidden = true
            self.btnCross.isHidden = false

        case .SubmitRequest:
             self.lblTitle.text = "Submit Request"

            self.viewPendingPayment.isHidden = true
            self.viewBookingRequestSent.isHidden = true

            self.btnBack.isHidden = false
            self.btnCross.isHidden = true
        case .BookingConfirmation:
//            self.lblTitle.text = "Confirmation"
            self.lblTitle.text = "Pending Booking"
            
            self.viewPendingPayment.isHidden = false
            self.viewBookingRequestSent.isHidden = true
            
            self.btnBack.isHidden = true
            self.btnCross.isHidden = false

        }
        
        
        //        if status == BookingStatusType.AwaitingApproval {
        //            self.lblTitle.text = "Pending Booking"
        //
        //            self.viewPendingPayment.isHidden = false
        //            self.viewCancelReques.isHidden = false
        //            self.btnCancelRequest.isHidden = false
        //            self.viewSubmitRequest.isHidden = true
        //            self.btnSubmitRequest.isHidden = true
        //        }
        //        else {
        //            self.lblTitle.text = "Booking Invite"
        //
        //            self.viewPendingPayment.isHidden = true
        //            self.viewCancelReques.isHidden = true
        //            self.btnCancelRequest.isHidden = true
        //            self.viewSubmitRequest.isHidden = false
        //            self.btnSubmitRequest.isHidden = false
        //        }

    }
}
//MARK: - Stretchy TableView
extension BookingInvites {
    
    private func loadHeaderView() {
        if tableView.tableHeaderView == nil {
            // fixthis
            let tableHeaderView  = BookingInvitesHeaderView.instanceFromNib()
//            let tableHeaderView  = BookingInvitesHeaderView.instanceFromNib() as! BookingInvitesHeaderView
//            guard let data = VenueDetails.hotVenuesData else {return}
//            tableHeaderView.setData(data: data)
            tableView.tableHeaderView = tableHeaderView
        }
    }
    private func setupStreachyHeaderViewFrames() {
        tableView.rowHeight = UITableView.automaticDimension
        headerView = tableView.tableHeaderView
        tableView.tableHeaderView = nil
        if headerView != nil {
            tableView.addSubview(headerView)
        }
        tableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    private func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: tableView.bounds.width, height: kTableHeaderHeight)
        if tableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
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
extension BookingInvites: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.booking?.status == .SubmitRequest || self.booking?.status == .BookingConfirmation || self.booking?.status == .AwaitingVenueApproval{
            return 5
        } else {
            return 4
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingDetailTVC") as! BookingDetailTVC
            if self.booking?.status == .SubmitRequest || self.booking?.status == .BookingConfirmation || self.booking?.status == .AwaitingVenueApproval {
                cell.userNoteLbl.text = "Additional requests"
                cell.have6BottelNote.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InviteFriendsCostSplitTVC") as! InviteFriendsCostSplitTVC
            if self.booking?.status == .SubmitRequest || self.booking?.status == .BookingConfirmation || self.booking?.status == .AwaitingVenueApproval {
                cell.status = self.booking?.status
                cell.costSpliteView.isHidden = true
                cell.headerLbl.text = "Guests & Cost Split (5)"
            }
            return cell
        case 2:
            if self.booking?.status == .SubmitRequest || self.booking?.status == .BookingConfirmation || self.booking?.status == .AwaitingVenueApproval {
                 let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionSummaryTVC", for: indexPath) as! TransactionSummaryTVC
                cell.stack2View.isHidden = false
                cell.text1Lbl.text = "Commited spend ($2,000 x 50%)"
                cell.text2Lbl.text = "Sales tax (5%)"
                cell.text3Lbl.text = "Transaction fee (3%)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentsTVC") as! PaymentsTVC
                return cell
            }
        case 3:
            if self.booking?.status == .SubmitRequest || self.booking?.status == .BookingConfirmation || self.booking?.status == .AwaitingVenueApproval {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell") as! PaymentTableViewCell
                cell.setUi(isSetting: false)
                return cell
            } else {
                if !isFromSettings {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "SubmitRequestTVC") as! SubmitRequestTVC
                    cell.btnSubmitRequest.addTarget(nil, action: #selector(self.onBtnSubmitRequest(_:)), for: .touchUpInside)
                    cell.btnCancelRequest.addTarget(nil, action: #selector(self.onBtnSubmitRequest(_:)), for: .touchUpInside)
                    cell.setData(data: self.booking ?? BookingsDataSet())
                    return cell
                }
                else {
                    return UITableViewCell()
                }
            }
        default:
            if !isFromSettings {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubmitRequestTVC") as! SubmitRequestTVC
                cell.btnSubmitRequest.addTarget(nil, action: #selector(self.onBtnSubmitRequest(_:)), for: .touchUpInside)
                cell.btnCancelRequest.addTarget(nil, action: #selector(self.onBtnSubmitRequest(_:)), for: .touchUpInside)
                cell.setData(data: self.booking ?? BookingsDataSet())
                return cell
            }
            else {
                return UITableViewCell()
            }
        }
    }
    @objc func onBtnSubmitRequest(_ sender: UIButton) {
        
        guard let status = self.booking?.status else {return}
        
        switch status {
        case .PurchaseConfirmed:
            self.navigationController?.popToRootViewController(animated: true)
        case .AwaitingApproval:
            self.navigationController?.popToRootViewController(animated: true)
        case .TicketPurchasedConfirmed:
            self.navigationController?.popToRootViewController(animated: true)
        case .AwaitingVenueApproval:
//            self.navigationController?.popToRootViewController(animated: true)
            print("AwaitingVenueApproval")
        case .SubmitRequest:
            let bookingInvites = PendingBookingAwait()
            let booking = BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .BookingConfirmation)
            bookingInvites.booking = booking
            
            self.navigationController?.pushViewController(bookingInvites, animated: true)
        case .BookingConfirmation:
            AppDelegate.shared.showHome(selectedIndex: 1)
        }
    }
    @objc func onBtnCancelRequest(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
