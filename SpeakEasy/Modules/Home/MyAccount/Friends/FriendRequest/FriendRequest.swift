//
//  FriendRequest.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 01/09/2022.
//

import UIKit

class FriendRequest: UIViewController {

    @IBOutlet weak var friendRequestTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
    }
}
//MARK: - Helper Methods
extension FriendRequest {
    private func registerCell(){
        self.friendRequestTableView.register(UINib(nibName: "SearchTVC", bundle: nil), forCellReuseIdentifier: "SearchTVC")
        self.friendRequestTableView.register(UINib(nibName: "ActiveRequestTVC", bundle: nil), forCellReuseIdentifier: "ActiveRequestTVC")
        self.friendRequestTableView.register(UINib(nibName: "ContactTVC", bundle: nil), forCellReuseIdentifier: "ContactTVC")
        self.friendRequestTableView.register(UINib(nibName: "FellowPeopleTVC", bundle: nil), forCellReuseIdentifier: "FellowPeopleTVC")
    }
}

//MARK: - UITableViewDataSource
extension FriendRequest: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return 3
        default:
           return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath .section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTVC", for: indexPath) as! SearchTVC
            cell.didTapSearchButton = {
                self.navigationController?.pushViewController(SearchAndAddFriend(), animated: false)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveRequestTVC", for: indexPath) as! ActiveRequestTVC
            if indexPath.row == 1{
                cell.viewShowMore.isHidden = false
            }else{
                cell.viewShowMore.isHidden = true
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTVC", for: indexPath) as! ContactTVC
            if indexPath.row == 2{
                cell.viewShowMore.isHidden = false
            }else{
                cell.viewShowMore.isHidden = true
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FellowPeopleTVC", for: indexPath) as! FellowPeopleTVC
            cell.viewShowMore.isHidden = false
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FellowPeopleTVC", for: indexPath) as! FellowPeopleTVC
            cell.viewShowMore.isHidden = true
            return cell
        }
    }
}
//MARK: - UITableViewDelegate
extension FriendRequest: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = FriendsHeaderView.instanceFromNib() as! FriendsHeaderView
        header.setData(section: section)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        default :
            return 40
        }
    }
}


