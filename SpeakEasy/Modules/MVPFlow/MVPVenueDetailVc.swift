//
//  MVPVenueDetailVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit
import SDWebImage

class MVPVenueDetailVc: UIViewController {

    @IBOutlet weak var venueBgImg: UIImageView!
    @IBOutlet weak var venueTitleNameLbl: UILabelDeviceClass!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var contectNoLbl: UILabel!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    var mvpDelegate = MVPPresenter()
    var venueId = "63dbab0a27d61c05f21b9e11"
    var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        self.tableViewHeight.constant = 100*2
        mvpDelegate.getVenuesDetailForaMvp(venueId: self.venueId) { isSuccess, errMsg, venueDetail in
            if isSuccess {
                self.venueDetails = venueDetail
                self.setUpUI()
                self.ticketTypeTableView.reloadData()
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
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetails?.venueAttachment.first?.key ?? "")"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetails?.logo?.key ?? "")"
        venueBgImg.sd_setImage(with: URL(string: imgStr),completed: nil)
        logoImg.sd_setImage(with: URL(string: logoStr),completed: nil)
        venueTitleNameLbl.text = self.venueDetails?.name
        locationLbl.text = self.venueDetails?.address
        tableViewHeight.constant = CGFloat(100*(self.venueDetails?.appClipTicket.count ?? 0))
        infoLbl.highlightBold(["in-person"], size: 15, textColor: .white)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension MVPVenueDetailVc: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venueDetails?.appClipTicket.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        cell.ticketTypeLbl.text = self.venueDetails?.appClipTicket[indexPath.row].name
        cell.infoLbl.text = self.venueDetails?.appClipTicket[indexPath.row].description
        cell.ticketPriceLbl.text = "\(self.venueDetails?.appClipTicket[indexPath.row].price ?? 0)"
        if indexPath.row == (self.venueDetails?.appClipTicket.count ?? 0) - 1{
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
            return cell
    }
}

