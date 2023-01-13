//
//  CostSplit.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 06/09/2022.
//

import UIKit

struct CostSplitModel {
    
    var name: String
    var discount: String
    var price: String
    var img: String
}

class CostSplit: BaseController {
    
    @IBOutlet weak var imgBrandLogo: RoundedImage!
    @IBOutlet weak var costSplitTableView: UITableView!
    var tagValue = 1
    
    var arrItsOnMe = [CostSplitModel]()
    
    var arrSplitEquality =
    [CostSplitModel(name: "You", discount: "20%", price: "$100", img: "you"),
     CostSplitModel(name: "Paul", discount: "20%", price: "$100", img: "paul"),
     CostSplitModel(name: "Henry", discount: "20%", price: "$100", img: "henry"),
     CostSplitModel(name: "Aby", discount: "20%", price: "$100", img: "abby"),
     CostSplitModel(name: "Madison", discount: "20%", price: "$100", img: "madison")]
    
    
    var arrCustomSplit =
    [CostSplitModel(name: "You", discount: "50%", price: "$0", img: "you"),
     CostSplitModel(name: "Paul", discount: "50%", price: "$0", img: "paul"),
     CostSplitModel(name: "Henry", discount: "0%", price: "$0", img: "henry"),
     CostSplitModel(name: "Aby", discount: "0%", price: "$0", img: "abby"),
     CostSplitModel(name: "Madison", discount: "0%", price: "$0", img: "madison"),
     CostSplitModel(name: "Madison", discount: "0%", price: "$00", img: "you")]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    private func setUI() {
        self.registerCell()
        self.setData()
    }
    private func setData(){
        self.imgBrandLogo.image = VenueDetails.hotVenuesData?.imgBrandLogo
    }
    private func registerCell(){
        self.costSplitTableView.register(UINib(nibName: "CostSplitTVC", bundle: nil), forCellReuseIdentifier: "CostSplitTVC")
        self.costSplitTableView.register(UINib(nibName: "CostSplitSelectionTVC", bundle: nil), forCellReuseIdentifier: "CostSplitSelectionTVC")
        self.costSplitTableView.register(UINib(nibName: "CostSplitSelectedBookingTVC", bundle: nil), forCellReuseIdentifier: "CostSplitSelectedBookingTVC")
        
    }
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnProceed(_ sender: RoundedButton) {
        let bookingInvites = PendingBookingAwait()
        let booking = BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .SubmitRequest)
        bookingInvites.booking = booking

        Utility.main.topViewController()?.navigationController?.pushViewController(bookingInvites, animated: true)

    }
}

//MARK: - UITableViewDataSource
extension CostSplit: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
      return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0,1:
            return 1
        case 2:
            switch self.tagValue {
            case 1:
                return self.arrItsOnMe.count
            case 2:
                return self.arrSplitEquality.count
            default:
                return self.arrCustomSplit.count
            }
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CostSplitSelectedBookingTVC", for: indexPath) as! CostSplitSelectedBookingTVC
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CostSplitSelectionTVC", for: indexPath) as! CostSplitSelectionTVC
            cell.didTapCodeSplitOptions = { tag in
                self.tagValue = tag
                tableView.reloadData()
            }
            cell.setData(tag: self.tagValue)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CostSplitTVC", for: indexPath) as! CostSplitTVC
            cell.tagValue = self.tagValue
            
            switch self.tagValue {
            case 1:
                let data = self.arrItsOnMe[indexPath.row]
                cell.setData(data: data)
                return cell
                
            case 2:
                let data = self.arrSplitEquality[indexPath.row]
                cell.setData(data: data)
                return cell
            default:
                let data = self.arrCustomSplit[indexPath.row]
                cell.setData(data: data)
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    
}
//MARK: - UITableViewDelegate
extension CostSplit: UITableViewDelegate {
    
    //    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //        let header = CostSplitHeaderView.instanceFromNib() as! CostSplitHeaderView
    //        header.didTapCodeSplitOptions = { tag in
    //            self.tagValue = tag
    //            tableView.reloadData()
    //
    //        }
    //        header.setData(tag: self.tagValue)
    //        return header
    //    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.costSplitTableView else {return}
        
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
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier
        
        topCell.contentView.alpha = topCellOpacity
    }
    
}

