//
//  MVPVenueDetailVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit
import SDWebImage

final class MVPVenueDetailVc: UIViewController {

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var venueBgImg: UIImageView!
    @IBOutlet weak var venueTitleNameLbl: UILabelDeviceClass!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var contectNoLbl: UILabel!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var liveLbl: UILabel!
    
    var venueId = ""
    var isFromAppClip = false
    private var mvpDelegate = MVPPresenter()
    private var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backBtn.isHidden = isFromAppClip
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        WebSocketWrapper.shared.delegate.append(self)
        getVenueDetail()
    }
    
    func getVenueDetail(withLoader: Bool = true) {
        if withLoader {
            Loader.show()
        }
        mvpDelegate.getVenuesDetailForaMVP(venueId: self.venueId) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else {
                Loader.hide()
                return
            }
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
            if withLoader == false && self.navigationController?.viewControllers.last is MVPVenueDetailVc {
                Alert.showToast("Venue detail updated")
            }
            Loader.hide()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    private func setUpUI() {
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(venueDetails?.venueAttachment.first?.key ?? "")"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(venueDetails?.logo?.key ?? "")"
        venueBgImg.sd_setImage(with: URL(string: imgStr),completed: nil)
        logoImg.sd_setImage(with: URL(string: logoStr),completed: nil)
        venueTitleNameLbl.text = venueDetails?.name
        locationLbl.text = venueDetails?.address
        infoLbl.text = "Entry tickets can be purchased in-person at \(venueDetails?.name ?? "") by scanning the banner located outside the venue.\nPrices shown here are subject to change. Up to date prices will be shown upon ticket purchase at the venue."
        infoLbl.highlightBold(["in-person"], size: 15, textColor: .white)
        if venueDetails?.bookingStatus == "OPEN" {
            liveLbl.text = "LIVE"
            liveLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
        } else {
            liveLbl.text = "CLOSED"
            liveLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension MVPVenueDetailVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetails?.appClipTicket?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC
        cell.ticketTypeLbl.text = venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
        cell.infoLbl.text = venueDetails?.appClipTicket?[indexPath.row].description
        cell.ticketPriceLbl.text = "$\(venueDetails?.appClipTicket?[indexPath.row].price ?? 0)"
        if indexPath.row == (venueDetails?.appClipTicket?.count ?? 0) - 1 {
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        if venueDetails?.bookingStatus == "OPEN" && venueDetails?.appClipTicket?[indexPath.row].status == "ENABLED" {
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
        if venueDetails?.bookingStatus != "OPEN" { return }
        if venueDetails?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        Navigate.to.enterPhoneNumForMvpViewController(self, ticketPrice: venueDetails?.appClipTicket?[indexPath.row].price ?? 0, isGeneral: venueDetails?.appClipTicket?[indexPath.row].name == "GENERALTICKET", venueName: venueDetails?.name ?? "", ticketId: venueDetails?.appClipTicket?[indexPath.row].id ?? "", venueId: self.venueId)
    }
}

extension MVPVenueDetailVc: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if self.venueId == uniqueId {
            getVenueDetail(withLoader: false)
        }
    }
}
