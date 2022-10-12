//
//  EventBookingDetails.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit

struct EventBooking {
    
    var ticketCount: Int
}

class EventBookingDetails: UIViewController {
    
    @IBOutlet weak var viewProceed: UIView!
    @IBOutlet weak var btnProceed: UIButtonDeviceClass!
    @IBOutlet weak var strechyTableView: UITableView!
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 487.0
    var selectedTabAt = 0
    
    var arrEventBooking = [EventBooking(ticketCount: 0),
                           EventBooking(ticketCount: 0),
                           EventBooking(ticketCount: 0)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.loadHeaderView()
        self.strechyTableView.alpha = 0
        self.setupStreachyHeaderViewFrames()
        self.strechyTableView.layoutIfNeeded()
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
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnShare(_ sender: UIButton) {
        Utility.main.shareSocialWith(text: "www.SpeakEasy.com")
    }
    @IBAction func onBtnProceed(_ sender: UIButtonDeviceClass) {
        //        self.navigationController?.pushViewController(TicketRecipients(), animated: true)
        self.navigationController?.pushViewController(ViewEventTickets(), animated: true)
        
    }
}
//MARK: - HELPER METHODS
extension EventBookingDetails {
    private func setUI(){
        self.registerCell()
    }
    private func registerCell() {
        self.strechyTableView.register(UINib(nibName: "ViewEventTicketTVC", bundle: nil), forCellReuseIdentifier: "ViewEventTicketTVC")
        self.strechyTableView.register(UINib(nibName: "EventBookingSelectionTVC", bundle: nil), forCellReuseIdentifier: "EventBookingSelectionTVC")
        self.strechyTableView.register(UINib(nibName: "VIPTableBookingTVC", bundle: nil), forCellReuseIdentifier: "VIPTableBookingTVC")
    }
    private func loadHeaderView() {
        if strechyTableView.tableHeaderView == nil {
            let tableHeaderView  = EventTableViewHeader.instanceFromNib()
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
    private func resetTabaleViewScroll(){
        
    }
}
//MARK: - UITableViewDataSource
extension EventBookingDetails: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return selectedTabAt == 0 ? self.arrEventBooking.count : 1
        }
        else {
            return selectedTabAt == 0 ? 1 : 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "EventBookingSelectionTVC", for: indexPath) as? EventBookingSelectionTVC else { return UITableViewCell() }
            cell.selectedTabAt = { index in
                self.selectedTabAt = index
                DispatchQueue.main.async {
                    self.viewProceed.isHidden = self.selectedTabAt == 0 ? false : true
                    self.strechyTableView.reloadData()
                    
                    self.updateHeaderView()
                }
            }
            return cell
        }
        else if indexPath.section == 1 {
            if selectedTabAt == 0 {
                let cell = strechyTableView.dequeueReusableCell(withIdentifier: "ViewEventTicketTVC", for: indexPath) as! ViewEventTicketTVC
                
                cell.btnPlusQuantity.tag = indexPath.row
                cell.btnMinusQuantity.tag = indexPath.row
                
                cell.btnMinusQuantity.addTarget(self, action: #selector(self.onBtnMinusQuantity(_:)), for: .touchUpInside)
                cell.btnPlusQuantity.addTarget(self, action: #selector(self.onBtnPlusQuantity(_:)), for: .touchUpInside)
                
                let data = self.arrEventBooking[indexPath.row]
                cell.setData(data: data)
                return cell
            }else {
                guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "VIPTableBookingTVC", for: indexPath) as? VIPTableBookingTVC else { return UITableViewCell() }
                cell.btnBookVIPTable.addTarget(self, action: #selector(self.onBtnBookVIPTable), for: .touchUpInside)
                return cell
            }
        }
        else {
            return UITableViewCell()
        }
    }
    @objc func onBtnMinusQuantity(_ sender: UIButton){
        let count = self.arrEventBooking[sender.tag].ticketCount
        if count == 1 {
            self.arrEventBooking[sender.tag].ticketCount -= 1
        }
        self.strechyTableView.reloadData()
    }
    @objc func onBtnPlusQuantity(_ sender: UIButton){
        let count = self.arrEventBooking[sender.tag].ticketCount
        if count == 0 {
            for index in 0..<self.arrEventBooking.count {
                self.arrEventBooking[index].ticketCount = 0
            }
            self.arrEventBooking[sender.tag].ticketCount += 1
        }
        self.strechyTableView.reloadData()
    }
    @objc func onBtnBookVIPTable(){
        Utility.main.topViewController()?.navigationController?.pushViewController(TableSelection(), animated: true)
    }
}
//MARK: - UITableViewDataSource
extension EventBookingDetails: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && self.selectedTabAt == 0 {
            return self.viewProceed.frame.height
        }
        return UITableView.automaticDimension
    }
}
