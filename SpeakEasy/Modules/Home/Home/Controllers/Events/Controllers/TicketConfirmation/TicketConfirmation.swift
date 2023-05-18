//
//  TicketConfirmation.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/7/22.
//

import UIKit

class TicketConfirmation: UIViewController {
    
    @IBOutlet weak var strechyTableView: UITableView!
//    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnViewInBookings: UIButtonDeviceClass!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var topTitleLbl: UILabelDeviceClass!
    @IBOutlet weak var shareBtn: UIButton!
    
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 487.0
    var selectedTabAt = 0
    var screenType: TicketConfirmationType = .FromHome
    var topEventData: TopEventDataSet?
    var isFromSettings = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.loadHeaderView()
        self.strechyTableView.alpha = 0
        self.setupStreachyHeaderViewFrames()
        self.strechyTableView.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFromSettings {
            shareBtn.isHidden = true
            backBtn.setImage(UIImage(named: "ic-close"), for: .normal)
            topTitleLbl.text = "Ticket Details"
        } else {
            backBtn.setImage(UIImage(named: "BackArrow"), for: .normal)
            topTitleLbl.text = "Confirmation"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateHeaderView()
        
        UIView.animate(withDuration: 0.02, delay: 0, options: .curveEaseOut) {
            self.strechyTableView.alpha = 1.0
        } completion: { _ in
            
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    @IBAction func onBtnViewInBookings(_ sender: UIButtonDeviceClass) {
//        AppDelegate.shared.showHome(selectedIndex: 1)
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnShare(_ sender: UIButton) {
        if self.screenType == .FromHome {
//            AppDelegate.shared.showHome(selectedIndex: 0)
        } else {
            Utility.main.shareSocialWith(text: "www.SpeakEasy.com")
        }
    }
}
//MARK: - HELPER METHODS
extension TicketConfirmation {
    private func setUI(){
        self.registerCell()
        
        switch self.screenType  {
        case .FromHome:
            self.backBtn.isHidden = true
            shareBtn.setImage(UIImage(named: "ic-close"), for: .normal)
            self.btnViewInBookings.isHidden = false
        case .FromBooking:
//            self.btnBack.isHidden = false
            self.btnViewInBookings.isHidden = true
        }
    }
    private func registerCell() {
        self.strechyTableView.register(UINib(nibName: "SelectedTicketAndRecipientTVC", bundle: nil), forCellReuseIdentifier: "SelectedTicketAndRecipientTVC")
        self.strechyTableView.register(UINib(nibName: "ViewEventTicketConfirmTVC", bundle: nil), forCellReuseIdentifier: "ViewEventTicketConfirmTVC")
        self.strechyTableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
        self.strechyTableView.register(UINib(nibName: "TransactionSummaryTVC", bundle: nil), forCellReuseIdentifier: "TransactionSummaryTVC")
    }
    private func loadHeaderView() {
        if strechyTableView.tableHeaderView == nil {
            //let tableHeaderView  = ViewEventHeader.instanceFromNib()
            let tableHeaderView  = ViewEventHeader.instanceFromNib() as! ViewEventHeader
            guard let data = self.topEventData else {return}
            tableHeaderView.setData(data: data)
            strechyTableView.tableHeaderView = tableHeaderView
        }
    }
    private func setupStreachyHeaderViewFrames() {
        strechyTableView.rowHeight = UITableView.automaticDimension
        headerView = strechyTableView.tableHeaderView
        strechyTableView.tableHeaderView = nil
        if headerView != nil {
            strechyTableView.addSubview(headerView)
        }
        strechyTableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        strechyTableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    private func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: strechyTableView.bounds.width, height: kTableHeaderHeight)
        if strechyTableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = strechyTableView.contentOffset.y
            headerRect.size.height = -strechyTableView.contentOffset.y
        }
        debugPrint(headerRect)
        if headerView != nil {
            headerView.frame = headerRect
        }
    }
}
//MARK: - UITableViewDataSource
extension TicketConfirmation: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0,2,3:
            return 1
        case 1:
            return 1
        default:
            return self.screenType == .FromHome ? 1 : 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "SelectedTicketAndRecipientTVC", for: indexPath) as? SelectedTicketAndRecipientTVC else { return UITableViewCell() }
            if isFromSettings { cell.ticketInfo.text = "" }
            return cell
        case 1:
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "ViewEventTicketConfirmTVC", for: indexPath) as? ViewEventTicketConfirmTVC else { return UITableViewCell() }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell") as! PaymentTableViewCell
            cell.setUi(isSetting: isFromSettings)
            return cell
        case 3:
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "TransactionSummaryTVC", for: indexPath) as? TransactionSummaryTVC else { return UITableViewCell() }
            return cell
        default:
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
    }
}
//MARK: - UITableViewDelegate
extension TicketConfirmation: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 4{
            return self.btnViewInBookings.frame.height + 20.0
        }
        return UITableView.automaticDimension
    }
}
