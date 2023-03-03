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
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var venueInfoLbl: UILabel!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tonightLbl: UILabel!

    var isLive = true
    var venueDetail: ClipVenue?
    private var venueId = ""
    private var selectedTicketIndex: Int?
    private var totalTicket = 1
    private var maxTicket = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketWrapper.shared.delegate.append(self)
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        venueId = UserDefaults.standard.value(forKey: "venueId") as? String ?? ""
        getEventTicket()
    }
    
    private func getEventTicket(withLoader: Bool = true) {
        guard let url = URL(string: "https://api.speakeasygo.com/appclip/\(venueId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if withLoader {
            AppClipLoader.showLoader(self.view)
        }
        URLSession.shared.dataTask(with: request) { data, respons, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                AppClipLoader.hideLoader()
                return
            }
            let decoder = JSONDecoder()
            guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                AppClipLoader.hideLoader()
                return
            }
            self.venueDetail = try? decoder.decode(ClipVenue.self, from: venueData)
            self.setUpUI()
            DispatchQueue.main.async {
                self.updateContinueBtn(forceRemove: true)
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
            self.venueInfoLbl.text = "Entry tickets can be purchased in-person at \(self.venueDetail?.name ?? "") by scanning the banner located outside the venue. \nPrices shown here are live and subject to change."
            self.venueInfoLbl.highlightBold(["in-person","live and subject to change."], size: 15, textColor: .white)
            if self.venueDetail?.bookingStatus == "OPEN" {
                self.liveCloseLbl.text = "LIVE"
                self.liveCloseLbl.textColor = UIColor(red: 84/255, green: 209/255, blue: 24/255, alpha: 1)
                self.tonightLbl.alpha = 1
            } else {
                self.liveCloseLbl.text = "CLOSED"
                self.liveCloseLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
                self.tonightLbl.alpha = 0.5
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC, let index = selectedTicketIndex {
            vc.totalTicket = self.totalTicket
            vc.ticketInfo = self.venueDetail?.appClipTicket?[index].description ?? ""
            vc.ticketPrice = self.venueDetail?.appClipTicket?[index].price ?? 0
            vc.isGeneralAdmission = index == 0
            vc.venueName = self.venueDetail?.name ?? ""
            vc.appClipTicketId = self.venueDetail?.appClipTicket?[index].id ?? ""
            vc.venueAttachment = self.venueDetail?.venueAttachment.first?.key ?? ""
            vc.venueLogo = self.venueDetail?.logo?.key ?? ""
            navigationController?.interactivePopGestureRecognizer?.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func minusBtnClick(_ sender: UIButton) {
        if totalTicket > 1 {
            totalTicket -= 1
            ticketTypeTableView.reloadData()
            updateContinueBtn()
        } else if totalTicket == 1 {
            updateContinueBtn(forceRemove: true)
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if totalTicket < maxTicket {
            totalTicket += 1
            ticketTypeTableView.reloadData()
            updateContinueBtn()
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 20
                self.selectedTicketIndex = nil
                self.totalTicket = 1
                self.ticketTypeTableView.reloadData()
                return
            }
            let price = self.venueDetail?.appClipTicket?[self.selectedTicketIndex ?? 0].price ?? 0
            self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  $\(self.totalTicket*price)", for: .normal)
        }
    }
}

extension SelectTicketClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetail?.appClipTicket?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC

        cell.ticketTypeLbl.text = self.venueDetail?.appClipTicket?[indexPath.row].name == "GENERALTICKET" ? "General Admission" : "VIP Skip the Line"
        cell.infoLbl.text = self.venueDetail?.appClipTicket?[indexPath.row].description
        cell.ticketPriceLbl.text = "$\(self.venueDetail?.appClipTicket?[indexPath.row].price ?? 0)"
        if venueDetail?.appClipTicket?[indexPath.row].price ?? 0 >= 5 {
            cell.ticketPriceLbl.text = "$\(venueDetail?.appClipTicket?[indexPath.row].price ?? 0)"
        } else {
            cell.ticketPriceLbl.text = "FREE"
        }
        cell.ticketPlusMinusView.isHidden = !(indexPath.row == selectedTicketIndex)
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.totalTicketLbl.text = "\(totalTicket)"
        cell.plusBtn.alpha = totalTicket == maxTicket ? 0.5 : 1
        if self.venueDetail?.bookingStatus == "OPEN" && self.venueDetail?.appClipTicket?[indexPath.row].status == "ENABLED" {
            cell.ticketPriceLbl.textColor = .white
            cell.ticketTypeLbl.textColor = .white

        } else {
            cell.ticketPriceLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
            cell.ticketTypeLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if venueDetail?.bookingStatus != "OPEN" || venueDetail?.appClipTicket?[indexPath.row].price ?? 0 < 5 { return }
        if venueDetail?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        
        selectedTicketIndex = indexPath.row
        totalTicket = 1
        ticketTypeTableView.reloadData()
        updateContinueBtn()
        continueBtn.isHidden = false
        scrollViewBottomConstraint.constant = 98
    }
}

extension SelectTicketClipVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if uniqueId == self.venueId {
            getEventTicket(withLoader: false)
        }
    }
}

extension SelectTicketClipVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
