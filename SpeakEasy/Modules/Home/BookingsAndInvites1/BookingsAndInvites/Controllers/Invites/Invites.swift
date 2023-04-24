//
//  Invites.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 30/08/2022.
//

import UIKit


class Invites: BaseController {

    @IBOutlet weak var tableView: UITableView!
    
    var arrDataSet = ["FREE","50% split","FREE","50% split"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.register(UINib(nibName: "InvitesTVC", bundle: nil), forCellReuseIdentifier: "InvitesTVC")
    }

}


//MARK: TableView
extension Invites: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrDataSet.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "InvitesTVC") as! InvitesTVC
        cell.btnBookingInvites.tag = indexPath.row
        cell.btnBookingInvites.addTarget(self, action: #selector(onBtnBookingInvites(_:)), for: .touchUpInside)
        
        let data = self.arrDataSet[indexPath.row]
        cell.setData(data: data)
        return cell
    }
    @objc func onBtnBookingInvites(_ sender: UIButton) {
        if arrDataSet[sender.tag] == "FREE" {
            Navigate.to.VIPBookingInviteNew(self, isFree: true)
        } else {
            Navigate.to.VIPBookingInviteNew(self, isFree: false)
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

        let modifier: CGFloat = 1.5
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier

        topCell.contentView.alpha = topCellOpacity
    }
}

