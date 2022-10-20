//
//  InviteFriends.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

struct InviteFriendsHeadersData {
    var title: String
    var count: String
    var backGroundColor: UIColor
}

struct InviteFriendsModel {
    var name: String
    var img: String
}

class InviteFriends: BaseController {
    
    @IBOutlet weak var imgBrandLogo: RoundedImage!
    @IBOutlet weak var inviteFriendsTableView: UITableView!
    
    var arrHeadersData: [InviteFriendsHeadersData] = [
        InviteFriendsHeadersData(title: Strings.SELECTED_BOOKING.rawValue , count: "", backGroundColor: .clear),
        InviteFriendsHeadersData(title: Strings.INVITE_FRIENDS.rawValue , count: "Max: 5", backGroundColor: .clear),
        InviteFriendsHeadersData(title: "" , count: "", backGroundColor: .clear),
        InviteFriendsHeadersData(title: "" , count: "", backGroundColor: .clear),
        InviteFriendsHeadersData(title: Strings.INVITE_FROM_CONTACTS.rawValue , count: "", backGroundColor: Global.APP_COLOR_CALENDAR_BG)
    ]
    
    var arrOfFriends = [
        InviteFriendsModel(name: "Henry", img: "henry"),
        InviteFriendsModel(name: "Paul", img: "paul"),
        InviteFriendsModel(name: "Abby", img: "abby"),
        InviteFriendsModel(name: "Madison", img: "madison"),
        InviteFriendsModel(name: "Ben", img: "Friend")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        self.setData()
    }
    
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnProceed(_ sender: UIButton) {
        Utility.main.topViewController()?.navigationController?.pushViewController(AdditionalGuest(), animated: true)
    }
}

//MARK: - Helper Methods
extension InviteFriends {
    private func registerCell(){
        self.inviteFriendsTableView.register(UINib(nibName: "SelectedBookingTVC", bundle: nil), forCellReuseIdentifier: "SelectedBookingTVC")
        self.inviteFriendsTableView.register(UINib(nibName: "SearchFriendTVC", bundle: nil), forCellReuseIdentifier: "SearchFriendTVC")
        self.inviteFriendsTableView.register(UINib(nibName: "FriendTVC", bundle: nil), forCellReuseIdentifier: "FriendTVC")
        self.inviteFriendsTableView.register(UINib(nibName: "TableBookingInviteFriendsTVC", bundle: nil), forCellReuseIdentifier: "TableBookingInviteFriendsTVC")
        self.inviteFriendsTableView.register(UINib(nibName: "InviteFromContactTVC", bundle: nil), forCellReuseIdentifier: "InviteFromContactTVC")
    }
    private func setData(){
        self.imgBrandLogo.image = VenueDetails.hotVenuesData?.imgBrandLogo
    }
}

//MARK: - UITableViewDataSource
extension InviteFriends: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.arrHeadersData.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedBookingTVC", for: indexPath) as! SelectedBookingTVC
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableBookingInviteFriendsTVC", for: indexPath) as! TableBookingInviteFriendsTVC
            
            cell.didEmptyArrClosure = {
                cell.collectionViewHeightManage()
            }
            
            cell.tableViewReference = tableView
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchFriendTVC", for: indexPath) as! SearchFriendTVC
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FriendTVC", for: indexPath) as! FriendTVC
            cell.arrOfFriends = self.arrOfFriends
            
            cell.didSelectFriend = { friend in
//             self.arrOfFriends.removeAll(where: { friend.name == $0.name })
                
                let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! TableBookingInviteFriendsTVC
                cell.arrInvitedFriends.append(friend)
                cell.collectionViewHeightManage()
                cell.collectionView.reloadSections(IndexSet(integer: 0))
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InviteFromContactTVC", for: indexPath) as! InviteFromContactTVC
            return cell
        }
    }
}
//MARK: - UITableViewDelegate
extension InviteFriends: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = InviteFriendsHeaderView.instanceFromNib() as! InviteFriendsHeaderView
        let data = self.arrHeadersData[section]
        header.setData(data: data)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section < self.arrHeadersData.count && self.arrHeadersData[section].title == "" {
            return 0
        }else {
            return 40
        }
    }
}
