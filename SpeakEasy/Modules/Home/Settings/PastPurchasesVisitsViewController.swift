//
//  PastPurchases&VisitsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class PastPurchasesVisitsViewController: UIViewController {

    @IBOutlet weak var pastPurchasesTableView: UITableView!
    
    private let demoDates = ["Fri, Feb 25", "Sat, Feb 26", "Sat, Feb 27"]
    private let demoPrices = ["Forward Day + Nightclub", "TAO Nightclub, Chicago", "TAO Nightclub, Chicago"]
    private let demoNames = ["Live Cover Ticket", "NIGHTMRE & DJ Diox XO DJ Heavy", "TAO Friday"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pastPurchasesTableView.delegate = self
        pastPurchasesTableView.dataSource = self
        pastPurchasesTableView.register(UINib(nibName: "DetailTVC", bundle: nil), forCellReuseIdentifier: "DetailTVC")
        pastPurchasesTableView.setupPadding()
        pastPurchasesTableView.groupStyleSpacing()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension PastPurchasesVisitsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demoDates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailTVC", for: indexPath) as! DetailTVC
        cell.selectionStyle = .none
        cell.nameLbl.text = demoNames[indexPath.row]
        cell.dateLbl.text = demoDates[indexPath.row]
        cell.priceLbl.text = demoPrices[indexPath.row]
        if demoNames[indexPath.row] == "Live Cover Ticket" {
            cell.upcomingImage.image = Constant.Icon.liveCover
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.checkOutVC(self, venueName: "", venueId: "", venueAttachment: "", venueLogo: "", selectedTickets: [], totalPrice: 40)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.pastPurchasesTableView else {return}
        
        let visibleCells = tableView.visibleCells

        if visibleCells.count == 0 {
            return
        }

        guard let topCell = visibleCells.first else {
            return
        }

        for cell in visibleCells {
            cell.contentView.alpha = 0.9
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
