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

protocol EventDetailsDelegate {
    func onClickUserProfile(index: Int)
    func onClickArtistProfile()
}

class EventBookingDetails: UIViewController {
    
    @IBOutlet weak var viewProceed: UIView!
    @IBOutlet weak var btnProceed: UIButtonDeviceClass!
    @IBOutlet weak var strechyTableView: UITableView!
    @IBOutlet weak var lblArtistName: UILabelDeviceClass!
    @IBOutlet weak var lblEventDate: UILabelDeviceClass!
    
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 487.0
    var selectedTabAt = 0
    
    var topEventData: TopEventDataSet?
    var attendeeData: AttendeeProfile?
    var totalTicket = 0
    var eventId = ""
    var eventDetail: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchEventDetail()
        self.setUI()
        self.viewProceed.isHidden = true
    }
    
    private func fetchEventDetail() {
        Loader.show()
        EventPresenter.getEventDetail(eventId: self.eventId) { [weak self] isSuccess, errMsg, eventDetails, _ in
            guard let self = self else { return }
            if isSuccess {
                self.eventDetail = eventDetails
                self.loadHeaderView()
                self.strechyTableView.alpha = 1
                self.setupStreachyHeaderViewFrames()
                self.strechyTableView.layoutIfNeeded()
                self.setUpUI()
                print(self.eventDetail)
                self.strechyTableView.reloadData()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
    
    private func setUpUI() {
        lblArtistName.text = self.eventDetail?.title
        let date = self.eventDetail?.date?.convertDateFormat(from: .YYYYMMDD, to: .EEEEMMMD)
        let dd = self.eventDetail?.date?.toDate(withFormat: .YYYYMMDD)
        lblEventDate.text = date
        print(dd ?? Date())
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
        if selectedTabAt == 0 {
            let viewEventTicketsController = ViewEventTickets()
            viewEventTicketsController.topEventData = self.topEventData
            self.navigationController?.navigationController?.pushViewController(viewEventTicketsController, animated: true)
        } else {
            
        }
        
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
        self.strechyTableView.register(UINib(nibName: "PublikAttendeesTVC", bundle: nil), forCellReuseIdentifier: "PublikAttendeesTVC")
    }
    private func loadHeaderView() {
        if strechyTableView.tableHeaderView == nil {
            let tableHeaderView  = EventTableViewHeader.instanceFromNib() as! EventTableViewHeader
            guard let eventDetail = self.eventDetail else {return}
            tableHeaderView.setDataNew(data: eventDetail)
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
            if selectedTabAt == 0 {
                return self.eventDetail?.eventTicket?.count ?? 0
            } else if selectedTabAt == 1 {
                return 1
            } else {
                return 1
            }
//            return selectedTabAt == 0 ? self.arrEventBooking.count : 1
        }
        else {
            if selectedTabAt == 0 {
               return 1
            } else if selectedTabAt == 1 {
                return 0
            } else {
                return 0
            }
//            return selectedTabAt == 0 ? 1 : 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "EventBookingSelectionTVC", for: indexPath) as? EventBookingSelectionTVC else { return UITableViewCell() }
            cell.selectedTabAt = { index in
                self.selectedTabAt = index
                DispatchQueue.main.async {
                    if self.selectedTabAt == 0 {
                        if self.totalTicket == 0 {
                            self.viewProceed.isHidden = true
                        } else {
                            self.viewProceed.isHidden = false
                        }
                    } else {
                        self.viewProceed.isHidden = true
                    }
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
                guard let data = self.eventDetail?.eventTicket?[indexPath.row] else { return UITableViewCell()}
                cell.setData(data: data)
                return cell
            }else if selectedTabAt == 1 {
                guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "VIPTableBookingTVC", for: indexPath) as? VIPTableBookingTVC else { return UITableViewCell() }
                cell.btnBookVIPTable.addTarget(self, action: #selector(self.onBtnBookVIPTable), for: .touchUpInside)
                return cell
            } else {
                guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "PublikAttendeesTVC", for: indexPath) as? PublikAttendeesTVC else { return UITableViewCell() }
                cell.eventDetailDelegate = self
                cell.collectionView.reloadData()
                cell.delegate = self
//                cell.btnBookVIPTable.addTarget(self, action: #selector(self.onBtnBookVIPTable), for: .touchUpInside)
                return cell
            }
        }
        else {
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            return cell
        }
    }
    @objc func onBtnMinusQuantity(_ sender: UIButton){
        let count = self.eventDetail?.eventTicket?[sender.tag].selectedTicketCount ?? 0
        if count == 1 {
            self.eventDetail?.eventTicket?[sender.tag].selectedTicketCount! -= 1
            self.totalTicket -= 1
            self.viewProceed.isHidden = true
        }
        self.strechyTableView.reloadData()
    }
    @objc func onBtnPlusQuantity(_ sender: UIButton){
        let count = self.eventDetail?.eventTicket?[sender.tag].selectedTicketCount ?? 0
        if count == 0 {
            for index in 0..<(self.eventDetail?.eventTicket?.count ?? 0) {
                self.eventDetail?.eventTicket?[index].selectedTicketCount = 0
            }
            self.eventDetail?.eventTicket?[sender.tag].selectedTicketCount! += 1
            self.totalTicket += 1
            self.viewProceed.isHidden = false
        }
        self.strechyTableView.reloadData()
    }
    @objc func onBtnBookVIPTable(){
        // fixthis
        Utility.main.topViewController()?.navigationController?.navigationController?.pushViewController(TableSelection(), animated: true)
    }
}
//MARK: - UITableViewDataSource
extension EventBookingDetails: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && self.selectedTabAt == 0 {
            if self.viewProceed.isHidden == true {
                return 0
            } else {
                return self.viewProceed.frame.height
            }
        } else if indexPath.section == 2 && self.selectedTabAt == 2 {
            return self.viewProceed.frame.height
        }
        return UITableView.automaticDimension
    }
}

extension EventBookingDetails: EventDetailsDelegate {
    
    func onClickArtistProfile() {
        let vc = ArtistProfilePopUp()
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        self.tabBarController?.present(vc, animated: true, completion: nil)
    }
    
    func onClickUserProfile(index: Int) {
        let vc = UserProfilePopUp()
        vc.attendeeData = Constants.arrayAttendees[index]
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        self.tabBarController?.present(vc, animated: true, completion: nil)
    }
}

extension EventBookingDetails: PublikAttendeesTVCDelegate {
    func refreshTableViewIfNeeded() {
        strechyTableView.layoutIfNeeded()
        DispatchQueue.main.async {
            self.strechyTableView.performBatchUpdates(nil)
        }
    }
}
