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
    @IBOutlet weak var liveLbl: UILabel!
    
    var mvpDelegate = MVPPresenter()
    var venueId = "63dbab0a27d61c05f21b9e11"
    var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    private func setUpUI() {
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetails?.venueAttachment.first?.key ?? "")"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetails?.logo?.key ?? "")"
        venueBgImg.sd_setImage(with: URL(string: imgStr),completed: nil)
        logoImg.sd_setImage(with: URL(string: logoStr),completed: nil)
        venueTitleNameLbl.text = self.venueDetails?.name
        locationLbl.text = self.venueDetails?.address
        infoLbl.text = "Entry tickets can be purchased in-person at \(venueDetails?.name ?? "") by scanning the banner located outside the venue.   Prices shown here are subject to change. Up to date prices will be shown upon ticket purchase at the venue."
        infoLbl.highlightBold(["in-person"], size: 15, textColor: .white)
        if self.venueDetails?.bookingStatus == "OPEN" {
            self.liveLbl.text = "LIVE"
            self.liveLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
        } else {
            self.liveLbl.text = "CLOSED"
            self.liveLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venueDetails?.appClipTicket?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC
        cell.ticketTypeLbl.text = self.venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
        cell.infoLbl.text = self.venueDetails?.appClipTicket?[indexPath.row].description
        cell.ticketPriceLbl.text = "$\(self.venueDetails?.appClipTicket?[indexPath.row].price ?? 0)"
        if indexPath.row == (self.venueDetails?.appClipTicket?.count ?? 0) - 1{
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        if self.venueDetails?.bookingStatus == "OPEN" && self.venueDetails?.appClipTicket?[indexPath.row].status == "ENABLED" {
            cell.ticketPriceLbl.textColor = .white
            cell.ticketTypeLbl.textColor = .white
            cell.sideArrow.isHidden = false
        } else {
            cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            cell.sideArrow.isHidden = true
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.venueDetails?.bookingStatus != "OPEN" { return }
        if self.venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        Navigate.to.enterPhoneNumForMvpViewController(self, ticketPrice: self.venueDetails?.appClipTicket?[indexPath.row].price ?? 0, isGeneral: self.venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET", venueName: self.venueDetails?.name ?? "", ticketId: self.venueDetails?.appClipTicket?[indexPath.row].id ?? "")
    }
}

