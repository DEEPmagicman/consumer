//
//  AdditionalGuest.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

class AdditionalGuest: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var maxNoOfPeople = 8
    var noOfMale = 0
    var noOfFemale = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnProceed(_ sender: RoundedButton) {
        Utility.main.topViewController()?.navigationController?.pushViewController(CostSplit(), animated: true)
        
    }
}

//MARK: - Helper Methods
extension AdditionalGuest {
    private func registerCell(){
        self.tableView.register(UINib(nibName: "AdditionalGuestsTVC", bundle: nil), forCellReuseIdentifier: "AdditionalGuestsTVC")
        self.tableView.register(UINib(nibName: "InviteFromContactTVC", bundle: nil), forCellReuseIdentifier: "InviteFromContactTVC")
        
    }
}

//MARK: - UITableViewDataSource
extension AdditionalGuest: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath .section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AdditionalGuestsTVC", for: indexPath) as! AdditionalGuestsTVC
            cell.btnAddFemail.addTarget(self, action: #selector(addFemale(_:)), for: .touchUpInside)
            cell.btnMinusFemale.addTarget(self, action: #selector(minusFemale(_:)), for: .touchUpInside)
            cell.btnAddMail.addTarget(self, action: #selector(addMale(_:)), for: .touchUpInside)
            cell.btnMinusMale.addTarget(self, action: #selector(minusMale(_:)), for: .touchUpInside)
            cell.setData(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InviteFromContactTVC", for: indexPath) as! InviteFromContactTVC
            return cell
        }
    }
    @objc func addFemale(_ sender: UIButton) {
        if self.noOfFemale + self.noOfMale < self.maxNoOfPeople {
            self.noOfFemale += 1
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AdditionalGuestsTVC else {return}
            cell.setData(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
        }
    }
    @objc func minusFemale(_ sender: UIButton) {
        if self.noOfFemale > 0 {
            self.noOfFemale -= 1
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AdditionalGuestsTVC else {return}
            cell.setData(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
        }
    }
    @objc func addMale(_ sender: UIButton) {
        if self.noOfFemale + self.noOfMale < self.maxNoOfPeople {
            self.noOfMale += 1
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AdditionalGuestsTVC else {return}
            cell.setData(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
        }
    }
    @objc func minusMale(_ sender: UIButton) {
        if self.noOfMale > 0 {
            self.noOfMale -= 1
            
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AdditionalGuestsTVC else {return}
            cell.setData(noOfMale: self.noOfMale, noOfFemale: self.noOfFemale)
        }
    }
}
//MARK: - UITableViewDelegate
extension AdditionalGuest: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = InviteFriendsHeaderView.instanceFromNib() as! InviteFriendsHeaderView
        header.setAdditionalGuestData(section: section)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 40
        default :
            return 0
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.tableView else {return}
        
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
        
        let modifier: CGFloat = 2.5
        let topCellOpacity = 2.0 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier
        
        topCell.contentView.alpha = topCellOpacity
    }
}
