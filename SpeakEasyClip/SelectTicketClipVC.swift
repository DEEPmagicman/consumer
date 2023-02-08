//
//  SelectTicketClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 26/01/23.
//

import UIKit

final class SelectTicketClipVC: UIViewController {
    
    @IBOutlet private weak var venueBgImg: UIImageView!
    @IBOutlet private weak var venueTitleNameLbl: UILabel!
    @IBOutlet private weak var logoImg: UIImageView!
    @IBOutlet private weak var liveCloseLbl: UILabel!
    @IBOutlet private weak var ticketTypeTableView: UITableView!
    @IBOutlet private weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var eventLocationLbl: UILabel!
    @IBOutlet weak var venueInfoLbl: UILabel!
    
    var isLive = true
    var venueDetail: ClipVenue?
    private var venueId = "VEN-BLLDGP"

    override func viewDidLoad() {
        super.viewDidLoad()
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        venueId = UserDefaults.standard.value(forKey: "venueId") as? String ?? ""
        getEventTicket()
    }
    
    private func getEventTicket() {
        guard let url = URL(string: "https://speakeasy-stag.cmdev.cc/appclip/\(venueId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        AppClipLoader.showLoader(self.view)
        URLSession.shared.dataTask(with: request) { data, respons, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {return AppClipLoader.hideLoader()}
            let decoder = JSONDecoder()
            guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {return AppClipLoader.hideLoader()}
            self.venueDetail = try? decoder.decode(ClipVenue.self, from: venueData)
            self.setUpUI()
            DispatchQueue.main.async {
                self.ticketTypeTableView.reloadData()
                AppClipLoader.hideLoader()
            }
        }.resume()
        
    }
    
    private func setUpUI() {
        let imgStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetail?.venueAttachment.first?.key ?? "")"
        let logoStr = "https://speakeasy-storage.s3.amazonaws.com/\(self.venueDetail?.logo?.key ?? "")"
        guard let imgUrl = URL(string: imgStr) else { return }
        guard let logoUrl = URL(string: logoStr) else { return }
        do {
            let imgData = try Data(contentsOf: imgUrl)
            let logoData = try Data(contentsOf: logoUrl)
            DispatchQueue.main.async {
                self.venueBgImg.image = UIImage(data: imgData)
                self.logoImg.image = UIImage(data: logoData)
            }
        } catch {}
        DispatchQueue.main.async {
            self.venueTitleNameLbl.text = self.venueDetail?.name
            self.eventLocationLbl.text = self.venueDetail?.address
            self.venueInfoLbl.text = "Entry tickets can only be purchased in-person at \(self.venueDetail?.name ?? "") by App Clip scan. Prices shown here are live and subject to change."
            self.venueInfoLbl.highlightBold(["only","in-person","live and subject to change."], size: 15, textColor: .white, underLineText: "only")
            if self.venueDetail?.bookingStatus == "OPEN" {
                self.liveCloseLbl.text = "LIVE"
                self.liveCloseLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
            } else {
                self.liveCloseLbl.text = "CLOSED"
                self.liveCloseLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
}

extension SelectTicketClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetail?.appClipTicket?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC

        cell.ticketTypeLbl.text = self.venueDetail?.appClipTicket?[indexPath.row].name
        cell.infoLbl.text = self.venueDetail?.appClipTicket?[indexPath.row].description
        cell.ticketPriceLbl.text = "$\(self.venueDetail?.appClipTicket?[indexPath.row].price ?? 0)"
        if indexPath.row == (self.venueDetail?.appClipTicket?.count ?? 0) - 1{
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        if self.venueDetail?.bookingStatus == "OPEN" {
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
        if self.venueDetail?.bookingStatus != "OPEN" { return }
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "EnterPhoneNumberClipVC")) as? EnterPhoneNumberClipVC {
            vc.ticketPrice = indexPath.row == 0 ? 50 : 90
            vc.isGeneralAdmission = indexPath.row == 0
            vc.venueName = self.venueDetail?.name ?? ""
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
