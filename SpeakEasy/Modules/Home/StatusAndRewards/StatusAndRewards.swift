//
//  StatusAndRewards.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class StatusAndRewards: UIViewController {
    
    @IBOutlet weak var tableViewReward: UITableView!
    
    var arrStatusAndRewardDataSet = [
        StatusAndRewardDataSet(brand: UIImage(named: "ic-tao"), eventCover: UIImage(named: "ic-artist"), isPerformer: true, isTable: false, isGroupInvite: false, isTicket: true, venueName: "TAO Chicago", performerName: "Steve Aoki", ticketDescription: "GA + Skip Line", date: "Thursday, June 30", rewardDescription: "FREE", rewardName: "FOR THE USUALS", imgVenue: UIImage(named: "RewardCoverTAO"), imgVenueLogo: UIImage(named: "taoMedium"), rewardNote: "Hey Tamas! Enjoy this free ticket from TAO. Hoep to see you soon!", hasEventBanner: true),
                                     StatusAndRewardDataSet(brand: UIImage(named: "ic-prism"), eventCover: UIImage(named: "ic-prism-cover"), isPerformer: false, isTable: true, isGroupInvite: true, isTicket: false, venueName: "PRYSM Chicago", performerName: nil, ticketDescription: nil, date: "Sunday, August 7", rewardDescription: "20% OFF", rewardName: "HIGH SPENDER USUAL", imgVenue: UIImage(named: "RewardCoverPrysm"), imgVenueLogo: UIImage(named: "prysmMedium"), rewardNote: "Hey Tamas, join us for a table. We've included 20% off for you for this weekend. We hope to see you at PRYSM.", hasEventBanner: false),
        StatusAndRewardDataSet(brand: UIImage(named: "ic-tao"), eventCover: UIImage(named: "ic-await-approval-bg"), isPerformer: false, isTable: true, isGroupInvite: true, isTicket: false, venueName: "TAO Chicago", performerName: nil, ticketDescription: nil, date: "Saturday, August 6", rewardDescription: "20% OFF", rewardName: "FOR OUR VIPs", imgVenue: UIImage(named: "RewardCoverTAO"), imgVenueLogo: UIImage(named: "taoMedium"), rewardNote: "Hey Tamas, join us for a table. We've included 20% off for you for this weekend. We hope to see you at TAO.", hasEventBanner: true),
                                     StatusAndRewardDataSet(brand: UIImage(named: "ic-rocbar"), eventCover: UIImage(named: "ic-rocbar-cover"), isPerformer: false, isTable: false, isGroupInvite: false, isTicket: true, venueName: "ROCBAR", performerName: nil, ticketDescription: "General Admission", date: "Saturday, July 9", rewardDescription: "FREE", rewardName: "FOR THE LADIES", imgVenue: UIImage(named: "RewardCoverRoc"), imgVenueLogo: UIImage(named: "rocbarMedium"), rewardNote: "Hi ladies! We hope to see you at Rocbar this Saturday for FREE!", hasEventBanner: false)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
    }
    func registerCell() {
        self.tableViewReward.register(UINib(nibName: "StatusAndRewardsTVC", bundle: nil), forCellReuseIdentifier: "StatusAndRewardsTVC")
    }
}

extension StatusAndRewards: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrStatusAndRewardDataSet.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewReward.dequeueReusableCell(withIdentifier: "StatusAndRewardsTVC", for: indexPath) as? StatusAndRewardsTVC else { return UITableViewCell() }
        let data = self.arrStatusAndRewardDataSet[indexPath.row]
        cell.setData(data: data)
        return cell
    }
    
}

extension StatusAndRewards: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = RewardDetails()
        vc.rewardData = arrStatusAndRewardDataSet[indexPath.row]
        vc.isShowEvent = arrStatusAndRewardDataSet[indexPath.row].rewardDescription == "FREE"
        vc.isFree = arrStatusAndRewardDataSet[indexPath.row].rewardDescription == "FREE"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.tableViewReward else {return}
        
        let visibleCells = tableView.visibleCells

        if visibleCells.count == 0 {
            return
        }

        guard let topCell = visibleCells.first else {
            return
        }

        for cell in visibleCells {
            cell.contentView.alpha = 1.0
        }

        let cellHeight = topCell.frame.size.height - 1
        let tableViewTopPosition = tableView.frame.origin.y
        
        let topCellPositionInTableView = tableView.rectForRow(at: tableView.indexPath(for: topCell)!)

        let topCellPosition = tableView.convert(topCellPositionInTableView, to: tableView.superview).origin.y

        let modifier: CGFloat = 1.5
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier

        topCell.contentView.alpha = topCellOpacity
    }
}
