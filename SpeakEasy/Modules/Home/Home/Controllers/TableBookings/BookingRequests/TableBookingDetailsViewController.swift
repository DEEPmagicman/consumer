//
//  TableBookingDetailsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 09/01/23.
//

import UIKit

enum costSpliteType {
    case itsMe
    case EqualSplite
    case customSplite
}

final class TableBookingDetailsViewController: BaseController {

    @IBOutlet weak var bookingTableView: UITableView!
    
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 414.0
    
    var maxNoOfPeople = 5
    var noOfMale = 0
    var noOfFemale = 0
    var selectedCostSplitType = costSpliteType.itsMe
    var frdList = [InviteFriendsModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        self.setupStretchyTableView()
        self.bookingTableView.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateHeaderView()
        
        UIView.animate(withDuration: 0.02) {
            self.bookingTableView.alpha = 1.0
        } completion: { _ in
            
        }
    }

    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func onBtnProcess(_ sender: Any) {
        let bookingInvites = BookingInvites()
        let booking = BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .SubmitRequest)
        bookingInvites.booking = booking

        Utility.main.topViewController()?.navigationController?.pushViewController(bookingInvites, animated: true)

    }
}

//MARK: - Helper Methods
extension TableBookingDetailsViewController {
    
    private func registerCells() {
        self.bookingTableView.register(UINib(nibName: "TableBookingDetailsCell", bundle: nil), forCellReuseIdentifier: "TableBookingDetailsCell")
        self.bookingTableView.register(UINib(nibName: "BookingDetailTVC", bundle: nil), forCellReuseIdentifier: "BookingDetailTVC")
        self.bookingTableView.register(UINib(nibName: "CostSplitTVC", bundle: nil), forCellReuseIdentifier: "CostSplitTVC")
    }
    
    private func setupStretchyTableView(){
        self.loadHeaderView()
        self.setupStreachyHeaderViewFrames()
    }
    
}
//MARK: - Stretchy TableView
extension TableBookingDetailsViewController {
    
    private func loadHeaderView() {
        if bookingTableView.tableHeaderView == nil {
            let tableHeaderView  = BookingInvitesHeaderView.instanceFromNib()
            bookingTableView.tableHeaderView = tableHeaderView
        }
    }
    private func setupStreachyHeaderViewFrames() {
        bookingTableView.rowHeight = UITableView.automaticDimension
        headerView = bookingTableView.tableHeaderView
        bookingTableView.tableHeaderView = nil
        if headerView != nil {
            bookingTableView.addSubview(headerView)
        }
        bookingTableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        bookingTableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    private func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: bookingTableView.bounds.width, height: kTableHeaderHeight)
        if bookingTableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = bookingTableView.contentOffset.y
            headerRect.size.height = -bookingTableView.contentOffset.y
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
extension TableBookingDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            if self.selectedCostSplitType == .itsMe {
                return 1
            } else {
                return self.noOfMale + self.noOfFemale + self.frdList.count + 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingDetailTVC") as! BookingDetailTVC
            cell.userNoteAndrequestHide()
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableBookingDetailsCell") as! TableBookingDetailsCell
            cell.femaleGuestPlusBtn.addTarget(self, action: #selector(addFemale(_:)), for: .touchUpInside)
            cell.femaleGuestMinusBtn.addTarget(self, action: #selector(minusFemale(_:)), for: .touchUpInside)
            cell.malePlusBtn.addTarget(self, action: #selector(addMale(_:)), for: .touchUpInside)
            cell.maleMinusBtn.addTarget(self, action: #selector(minusMale(_:)), for: .touchUpInside)
            cell.invitedFrd = frdList
            cell.guest = noOfMale + noOfFemale
            cell.setGuestdata(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
            cell.setCostSpliteView(costType: self.selectedCostSplitType)
            cell.inviteFrdCollectionView.reloadData()
            let tap1 = UITapGestureRecognizer(target: self, action: #selector(onClickItsMe(_:)))
            cell.itsOnMeView.addGestureRecognizer(tap1)
            
            let tap2 = UITapGestureRecognizer(target: self, action: #selector(onClickEqualSplite(_:)))
            cell.equalSplitView.addGestureRecognizer(tap2)
            
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(onClickCustomSplite(_:)))
            cell.customSplitView.addGestureRecognizer(tap3)
            
            cell.editFriendListBtn.addTarget(self, action: #selector(onClickEditFriendList(_:)), for: .touchUpInside)
            cell.searcFrdBtn.addTarget(self, action: #selector(onClickEditFriendList(_:)), for: .touchUpInside)
            
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CostSplitTVC") as! CostSplitTVC
            if indexPath.row == 0 {
                cell.lblName.text = "Me"
                cell.imgUser.image = UIImage(named: "Friend")
            } else if indexPath.row <= frdList.count {
                cell.lblName.text = frdList[indexPath.row-1].name
                cell.imgUser.image = UIImage(named: frdList[indexPath.row-1].img)
            } else {
                cell.lblName.text = "Guest"
                cell.imgUser.image = Constant.Icon.maleIdentify
            }
            
            return cell
        default:
                return UITableViewCell()
        }
    }
    
    @objc func addFemale(_ sender: UIButton) {
        if (self.noOfFemale + self.noOfMale + self.frdList.count) < self.maxNoOfPeople {
            self.noOfFemale += 1
            
            guard let cell = self.bookingTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? TableBookingDetailsCell else {return}
            cell.setGuestdata(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
                self.bookingTableView.reloadData()
        }
    }
    @objc func minusFemale(_ sender: UIButton) {
        if self.noOfFemale > 0 {
            self.noOfFemale -= 1
            
            guard let cell = self.bookingTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? TableBookingDetailsCell else {return}
            cell.setGuestdata(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
                self.bookingTableView.reloadData()
        }
    }
    @objc func addMale(_ sender: UIButton) {
        if (self.noOfFemale + self.noOfMale + self.frdList.count) < 5 {
            self.noOfMale += 1
            
            guard let cell = self.bookingTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? TableBookingDetailsCell else {return}
            cell.setGuestdata(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
                self.bookingTableView.reloadData()
        }
    }
    @objc func minusMale(_ sender: UIButton) {
        if self.noOfMale > 0 {
            self.noOfMale -= 1
            
            guard let cell = self.bookingTableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? TableBookingDetailsCell else {return}
            cell.setGuestdata(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
                self.bookingTableView.reloadData()
        }
    }
    
    @objc func onClickItsMe(_ sender: UITapGestureRecognizer) {
        self.selectedCostSplitType = .itsMe
        self.bookingTableView.reloadData()
    }
    
    @objc func onClickEqualSplite(_ sender: UITapGestureRecognizer) {
        self.selectedCostSplitType = .EqualSplite
        self.bookingTableView.reloadData()
    }
    
    @objc func onClickCustomSplite(_ sender: UITapGestureRecognizer) {
        self.selectedCostSplitType = .customSplite
        self.bookingTableView.reloadData()
    }
    
    @objc func onBtnCancelRequest(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickEditFriendList(_ sender: UIButton) {
        Navigate.to.inviteFriendPopUp(self, invitedFrdList: self.frdList, selectedGuest: (self.noOfMale+self.noOfFemale))
    }
    
}

extension TableBookingDetailsViewController: InvitedFriendDelegate {
    func invitedFrd(frdArray: [InviteFriendsModel]) {
        self.frdList = frdArray
        self.bookingTableView.reloadData()
    }
}
