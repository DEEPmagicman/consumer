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
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var closeLblView: UIView!
    @IBOutlet weak var closeLbl: UILabel!

    var isLive = true
    var venueDetail: ClipVenue?
    private var gradient: CAGradientLayer?
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var venueId = ""
    private var maxTicket = 20
    private var selectedType: TicketPriceType = .FREE
    private var totalPrice: Int {
        var total = 0
        venueDetail?.appClipTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += ($0.price * quantity)
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        var total = 0
        venueDetail?.appClipTicket?.forEach {
            if let quantity = $0.selectedQuantity {
                total += quantity
            }
        }
        return total >= maxTicket
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradient = venueBgImg.setGradientColor()
        venueImgHeightObservation = venueBgImg.observe(\.bounds, options: []) { [weak self] _, _ in
            self?.gradient = self?.venueBgImg.setGradientColor()
        }
        WebSocketWrapper.shared.delegate.append(self)
        ticketTypeTableView.register(UINib(nibName: "TicketTypeTVC", bundle: nil), forCellReuseIdentifier: "TicketTypeTVC")
        ticketTypeTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        venueId = UserDefaults.standard.value(forKey: "venueId") as? String ?? ""
        getEventTicket()
    }
    
    private func getEventTicket(withLoader: Bool = true) {
        guard let url = URL(string: "\(SharedURL.baseURL)/appclip/\(venueId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
//        request.addValue("timezone", forHTTPHeaderField: TimeZone.current.identifier.lowercased())
//        request.addValue("app_version", forHTTPHeaderField: Bundle.main.releaseVersionNumber)
//        request.addValue("build_number", forHTTPHeaderField: Bundle.main.buildVersionNumber)
//        request.addValue("platform", forHTTPHeaderField: "ios")
//        request.addValue("app_bundle_id", forHTTPHeaderField: Bundle.main.bundleIdentifier ?? "invalid bundle id")

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
            UserDefaults.standard.setValue(self.venueDetail?.id ?? "", forKey: "venueIdLong")
            self.setUpUI()
            DispatchQueue.main.async {
                self.updateContinueBtn(forceRemove: true)
                AppClipLoader.hideLoader()
            }
        }.resume()
    }
    
    private func setUpUI() {
        let imgStr = "\(SharedURL.amazonStorage)\(self.venueDetail?.venueAttachment.first?.key ?? "")"
        let logoStr = "\(SharedURL.amazonStorage)\(self.venueDetail?.logo?.key ?? "")"
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
            if self.venueDetail?.appClipTicket?.allSatisfy({ ticket in
                ticket.status == "DISABLED"
            }) == true {
                self.infoView.isHidden = true
                self.closeLblView.isHidden = false
            } else {
                self.infoView.isHidden = false
                self.closeLblView.isHidden = true
            }
            if self.venueDetail == nil {
                self.closeLbl.text = "Venue not found"
                self.infoView.isHidden = true
                self.closeLblView.isHidden = false
                self.liveCloseLbl.isHidden = true
                self.tonightLbl.isHidden = true
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC, let selectedTickets = venueDetail?.appClipTicket?.filter({ $0.selectedQuantity != nil }) {
            vc.selectedAppClipTickets = selectedTickets
            vc.totalPrice = totalPrice
            vc.venue = venueDetail
            navigationController?.interactivePopGestureRecognizer?.delegate = self
            navigationController?.pushViewController(vc, animated: true)
            updateContinueBtn(forceRemove: true)
        }
    }

    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = venueDetail?.appClipTicket?[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                venueDetail?.appClipTicket?[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                venueDetail?.appClipTicket?[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                updateContinueBtn(forceRemove: (venueDetail?.appClipTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
//            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = venueDetail?.appClipTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetail?.appClipTicket?[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else {
//                Alert.showToast("Max ticket selection reached")
            }
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.venueDetail?.appClipTicket?.indices.forEach {
                    self.venueDetail?.appClipTicket?[$0].selectedQuantity = nil
                }
                self.continueBtn.isHidden = true
                self.scrollViewBottomConstraint.constant = 20
                self.ticketTypeTableView.reloadData()
                return
            }
            self.continueBtn.isHidden = false
            switch self.selectedType {
            case .FREE:
                self.continueBtn.setTitle("GET MY FREE TICKET", for: .normal)
            case .PAID:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT -  \(self.venueDetail?.venueSettings?.currencySymbol ?? "$")\(Double(self.totalPrice).decimalFormat(true))", for: .normal)
            }
        }
    }
    
    private func forceRemoveFreeTicket() {
        self.venueDetail?.appClipTicket?.indices.forEach {
            if venueDetail?.appClipTicket?[$0].price ?? 0 < 2 && venueDetail?.appClipTicket?[$0].name.lowercased().contains("general") == true {
                self.venueDetail?.appClipTicket?[$0].selectedQuantity = nil
            }
        }
        selectedType = .PAID
    }

    private func forceRemovePaidTicket() {
        self.venueDetail?.appClipTicket?.indices.forEach {
            if venueDetail?.appClipTicket?[$0].price ?? 0 < 2 && venueDetail?.appClipTicket?[$0].name.lowercased().contains("general") == true {
            } else {
                self.venueDetail?.appClipTicket?[$0].selectedQuantity = nil
            }
        }
        selectedType = .FREE
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
        cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Double(self.venueDetail?.appClipTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        if venueDetail?.appClipTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.appClipTicket?[indexPath.row].name.lowercased().contains("general") == true {
            cell.ticketPriceLbl.text = "FREE"
            cell.plusBtn.alpha = 0.5
            cell.plusBtn.isUserInteractionEnabled = false
        } else {
            cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Double(venueDetail?.appClipTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
            cell.plusBtn.isUserInteractionEnabled = true
        }
        if venueDetail?.appClipTicket?[indexPath.row].selectedQuantity ?? 0 >= 1 {
            cell.ticketPlusMinusView.isHidden = false
        } else {
            cell.ticketPlusMinusView.isHidden = true
        }
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.totalTicketLbl.text = "\(venueDetail?.appClipTicket?[indexPath.row].selectedQuantity ?? 0)"
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
        if venueDetail?.bookingStatus != "OPEN" { return }
        if venueDetail?.appClipTicket?[indexPath.row].status != "ENABLED" { return }
        if venueDetail?.appClipTicket?[indexPath.row].selectedQuantity != nil { return }
        if isMaxTicketReached {
//            Alert.showToast("Max ticket selection reached")
            return
        }
        venueDetail?.appClipTicket?[indexPath.row].selectedQuantity = 1
        if venueDetail?.appClipTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.appClipTicket?[indexPath.row].name.lowercased().contains("general") == true {
            forceRemovePaidTicket()
        } else {
            forceRemoveFreeTicket()
        }
        ticketTypeTableView.reloadData()
        updateContinueBtn()
        continueBtn.isHidden = false
        scrollViewBottomConstraint.constant = 98
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if venueDetail?.appClipTicket?[indexPath.row].status == "DISABLED" {
            return 0
        }
        return UITableView.automaticDimension
    }
}

extension SelectTicketClipVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool, isWaitTimeUpdated: Bool) {
        if uniqueId == self.venueId {
            getEventTicket(withLoader: false)
        }
    }
    
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
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

extension Double {
    func decimalFormat(_ valueDouble: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if valueDouble {
            if let newValue =  Double(String(format: "%.2f", NSNumber(value: self).doubleValue)) {
                return String(numberFormatter.string(from: NSNumber(value: newValue)) ?? "")
            } else {
                return "0.00"
            }
        } else {
            return String(numberFormatter.string(from: NSNumber(value: self)) ?? "")
        }
    }

}
