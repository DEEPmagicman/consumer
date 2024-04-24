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
    @IBOutlet weak var upSellView: UIView!
    @IBOutlet weak var upSellBtn: UIButton!
    @IBOutlet weak var VIPTableBookingView: UIView!    
    @IBOutlet weak var tableBookNowBtn: UIButton!

    var isLive = true
    var venueDetail: ClipVenue?
    private var gradient: CAGradientLayer?
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var venueId = ""
    private var deepLink = ""
    private var doormanId = ""
    private var maxTicket = 20
    private var selectedType: TicketPriceType = .FREE
    private var upSellTickets = [UpSellTicket]()
    private var totalPrice: Double {
        var total = 0.0
        if venueDetail?.venueSettings?.coverTicketSettings?.isUpFront == true {
            venueDetail?.modifiedCoverTicket.forEach {
                if let quantity = $0.selectedQuantity {
                    total += ($0.price * Double(quantity))
                }
            }
        } else {
            venueDetail?.coverTicket?.forEach {
                if let quantity = $0.selectedQuantity {
                    total += ($0.price * Double(quantity))
                }
            }
        }
        return total
    }
    private var isMaxTicketReached: Bool {
        var total = 0
        venueDetail?.coverTicket?.forEach {
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
        deepLink = UserDefaults.standard.value(forKey: "deepLinkId") as? String ?? ""
        if venueId == "" {
            getDeepLinkData()
        } else {
            getVenueDetailsWithTickets()
        }
        upSellBtn.setTitle("Buy \(venueDetail?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Upsell")", for: .normal)
        tableBookNowBtn.layer.borderColor = UIColor.white.cgColor
        tableBookNowBtn.layer.borderWidth = 1
    }
    
    private func getDeepLinkData() {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/deep-link/\(self.deepLink)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    AppClipLoader.hideLoader()
                    return
                }
                self.venueId = json["venueId"] as? String ?? ""
                self.doormanId = json["doormanId"] as? String ?? ""
                self.getVenueDetailsWithTickets()
            }
        }.resume()
    }
    
    private func getAddOns() {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/add-ons?include=addOns") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if doormanId != "" {
            request.addValue(doormanId, forHTTPHeaderField: "doorman")
        }
        request.addValue(venueDetail?.id ?? "", forHTTPHeaderField: "venue")
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                AppClipLoader.hideLoader()
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    return
                }
                
                let decoder = JSONDecoder()
                
                if let addOns = json["list"] as? [[String: Any]] {
                    guard let addOnData = try? JSONSerialization.data(withJSONObject: addOns, options: .prettyPrinted) else {
                        return
                    }
                    
                    do {
                        self.upSellTickets = try decoder.decode([UpSellTicket].self, from: addOnData)
                        DispatchQueue.main.async {
                            self.upSellView.isHidden = self.upSellTickets.count <= 0
                        }
                    } catch (let error) {
                        print(error)
                    }
                }
            }
        }.resume()
    }
    
    private func getVenueDetailsWithTickets(withLoader: Bool = true) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/cover/\(venueId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if doormanId != "" {
            request.addValue(doormanId, forHTTPHeaderField: "doorman")
        }

        if withLoader {
            DispatchQueue.main.async {
                AppClipLoader.showLoader(self.view)
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                AppClipLoader.hideLoader()
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    return
                }
                
                let decoder = JSONDecoder()
                
                guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                    return
                }
                
                self.venueDetail = try? decoder.decode(ClipVenue.self, from: venueData)
                UserDefaults.standard.setValue(self.venueDetail?.id ?? "", forKey: "venueIdLong")
                
                self.setUpUI()
                self.getAddOns()
                self.updateContinueBtn(forceRemove: true)
            }
        }.resume()
    }
    
    private func setUpUI() {
        DispatchQueue.global(qos: .background).async {
            let imgStr = "\(SharedURL.amazonStorage)\(self.venueDetail?.venueAttachment?.first?.key ?? "")"
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
        }
        DispatchQueue.main.async {
            self.venueTitleNameLbl.text = self.venueDetail?.name
            self.venueInfoLbl.text = "Entry tickets can be purchased in-person at \(self.venueDetail?.name ?? "") by scanning the banner located outside the venue. \nPrices shown here are live and subject to change."
            self.venueInfoLbl.highlightBold(["in-person","live and subject to change."], size: 15, textColor: .white)
            if self.venueDetail?.venueSettings?.bookingStatus == "OPEN" {
                self.liveCloseLbl.text = "LIVE"
                self.liveCloseLbl.textColor = UIColor(red: 0.00, green: 1.00, blue: 0.58, alpha: 1.00)
                self.tonightLbl.alpha = 1
            } else {
                self.liveCloseLbl.text = "CLOSED"
                self.liveCloseLbl.textColor = UIColor(red: 121/255, green: 121/255, blue: 121/255, alpha: 1)
                self.tonightLbl.alpha = 0.5
            }
            if self.venueDetail?.coverTicket?.allSatisfy({ ticket in
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
            self.upSellBtn.setTitle("Buy \(self.venueDetail?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Upsell")", for: .normal)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableViewHeight.constant = ticketTypeTableView.contentSize.height
    }
    
    @IBAction func onClickTableBook(_ sender: Any) {
        guard let url = URL(string: String(format: SharedURL.tableBookingURL, venueDetail?.id ?? "")) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func onClickContinue(_ sender: Any) {
        if upSellTickets.count > 0 {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "UpSellClipVC")) as? UpSellClipVC {
                vc.venue = venueDetail
                vc.upSellTicket = upSellTickets
                vc.bookingType = selectedType
                navigationController?.interactivePopGestureRecognizer?.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC, let selectedTickets = venueDetail?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
                if selectedTickets.count > 0 {
                    vc.selectedCoverTickets = selectedTickets
                    vc.totalPrice = totalPrice
                    vc.venue = venueDetail
                    navigationController?.interactivePopGestureRecognizer?.delegate = self
                    navigationController?.pushViewController(vc, animated: true)
                    updateContinueBtn(forceRemove: true)
                } else {
                    guard let url = URL(string: String(format: SharedURL.tableBookingURL, venueDetail?.id ?? "")) else {
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    @objc private func upSellTicket() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "UpSellClipVC")) as? UpSellClipVC {
//            if selectedTickets.count > 0 {
                vc.venue = venueDetail
                vc.upSellTicket = upSellTickets
                navigationController?.interactivePopGestureRecognizer?.delegate = self
                navigationController?.pushViewController(vc, animated: true)
//            }
        }
    }
    
    @IBAction func onClickUpsellBtn(_ sender: Any) {
        forceRemoveFreeTicket()
        forceRemoveCustomTicket()
        forceRemovePaidTicket()
        ticketTypeTableView.reloadData()
        upSellTicket()
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = venueDetail?.coverTicket?[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                venueDetail?.coverTicket?[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                venueDetail?.coverTicket?[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                updateContinueBtn(forceRemove: (venueDetail?.coverTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
//            Alert.showToast("Max ticket selection reached")
            return
        }
        if let totalTicket = venueDetail?.coverTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetail?.coverTicket?[sender.tag].selectedQuantity = totalTicket + 1
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
                self.venueDetail?.coverTicket?.indices.forEach {
                    self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
                }
                if self.venueDetail?.availableTimeSlot == true {
                    self.continueBtn.isHidden = false
                    self.VIPTableBookingView.isHidden = false
                    self.scrollViewBottomConstraint.constant = 128
                } else {
                    self.VIPTableBookingView.isHidden = true
                    self.continueBtn.isHidden = true
                    self.scrollViewBottomConstraint.constant = 20
                }
                self.ticketTypeTableView.reloadData()
                return
            }
            self.VIPTableBookingView.isHidden = true
            self.continueBtn.isHidden = false
            self.scrollViewBottomConstraint.constant = 98
            switch self.selectedType {
            case .FREE:
                if self.upSellView.isHidden == true {
                    self.continueBtn.setTitle("GET MY FREE TICKET", for: .normal)
                } else {
                    self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
                }
            case .PAID, .CUSTOM:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT", for: .normal)
            }
        }
    }
    
    private func forceRemoveFreeTicket() {
        self.venueDetail?.coverTicket?.indices.forEach {
            if venueDetail?.coverTicket?[$0].price ?? 0 < 2 && venueDetail?.coverTicket?[$0].name.lowercased().contains("general") == true {
                self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
            }
        }
//        selectedType = .PAID
    }

    private func forceRemovePaidTicket() {
        self.venueDetail?.coverTicket?.indices.forEach {
            if venueDetail?.coverTicket?[$0].price ?? 0 < 2 && venueDetail?.coverTicket?[$0].name.lowercased().contains("general") == true {
            } else if venueDetail?.coverTicket?[$0].isCustom ?? false != true {
                self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
            }
        }
//        selectedType = .FREE
    }
    
    private func forceRemoveCustomTicket() {
        self.venueDetail?.coverTicket?.indices.forEach {
            if venueDetail?.coverTicket?[$0].isCustom == true {
                self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
            }
        }
    }
}

extension SelectTicketClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        venueDetail?.coverTicket?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketTypeTVC", for: indexPath) as! TicketTypeTVC
        cell.ticketTypeLbl.text = self.venueDetail?.coverTicket?[indexPath.row].customName ?? "" == "" ? self.venueDetail?.coverTicket?[indexPath.row].name : self.venueDetail?.coverTicket?[indexPath.row].customName
        cell.infoLbl.text = self.venueDetail?.coverTicket?[indexPath.row].description
        cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Double(self.venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        if venueDetail?.coverTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.coverTicket?[indexPath.row].name.lowercased().contains("general") == true {
            cell.ticketPriceLbl.text = "FREE"
            cell.plusBtn.alpha = 0.5
            cell.plusBtn.isUserInteractionEnabled = false
        } else if venueDetail?.coverTicket?[indexPath.row].isCustom == true && venueDetail?.coverTicket?[indexPath.row].price ?? 0 == 0 {
            cell.ticketPriceLbl.text = "FREE"
            cell.plusBtn.alpha = 0.5
            cell.plusBtn.isUserInteractionEnabled = false
        } else {
            if venueDetail?.venueSettings?.coverTicketSettings?.isUpFront == true {
                let price = venueDetail?.modifiedCoverTicket[indexPath.row].isCustom == true ? Double(venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat(true) : Double(venueDetail?.modifiedCoverTicket[indexPath.row].price ?? 0).decimalFormat(true)
                let dPrice = price.components(separatedBy: ".")[1]
                cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Int(dPrice) == 0 ? "\(Int(price.components(separatedBy: ".")[0]) ?? 0)" : price)"
            } else {
                let price = Double(venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat(true)
                let dPrice = price.components(separatedBy: ".")[1]
                cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Int(dPrice) == 0 ? "\(Int(price.components(separatedBy: ".")[0]) ?? 0)" : price)"
            }
            cell.plusBtn.isUserInteractionEnabled = true
        }
        if venueDetail?.coverTicket?[indexPath.row].selectedQuantity ?? 0 >= 1 {
            cell.ticketPlusMinusView.isHidden = false
            cell.sideArrow.isHidden = true
        } else {
            cell.ticketPlusMinusView.isHidden = true
            cell.sideArrow.isHidden = false
        }
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.totalTicketLbl.text = "\(venueDetail?.coverTicket?[indexPath.row].selectedQuantity ?? 0)"
        if self.venueDetail?.venueSettings?.bookingStatus == "OPEN" && self.venueDetail?.coverTicket?[indexPath.row].status == "ENABLED" {
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
        if venueDetail?.venueSettings?.bookingStatus != "OPEN" { return }
        if venueDetail?.coverTicket?[indexPath.row].status != "ENABLED" { return }
        if venueDetail?.coverTicket?[indexPath.row].selectedQuantity != nil { return }
        if isMaxTicketReached {
//            Alert.showToast("Max ticket selection reached")
            return
        }
        venueDetail?.coverTicket?[indexPath.row].selectedQuantity = 1
        if venueDetail?.coverTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.coverTicket?[indexPath.row].name.lowercased().contains("general") == true {
            forceRemovePaidTicket()
            forceRemoveCustomTicket()
            selectedType = .FREE
        } else if venueDetail?.coverTicket?[indexPath.row].isCustom == true {
            forceRemovePaidTicket()
            forceRemoveFreeTicket()
            selectedType = venueDetail?.coverTicket?[indexPath.row].price == 0 ? .FREE : .CUSTOM
        } else {
            forceRemoveFreeTicket()
            forceRemoveCustomTicket()
            selectedType = .PAID
        }
        ticketTypeTableView.reloadData()
        updateContinueBtn()
        scrollViewBottomConstraint.constant = 98
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if venueDetail?.coverTicket?[indexPath.row].status == "DISABLED" {
            return 0
        }
        return UITableView.automaticDimension
    }
}

extension SelectTicketClipVC: WebSocketCallBackDelegate {
    func didValueChange(venueId: String, uniqueId: String, isPriceUpdated: Bool, isVenueStatusUpdate: Bool) {
        if uniqueId == self.venueId {
            getVenueDetailsWithTickets(withLoader: false)
        }
    }
    
    func updateTicketPrice(ticket: [CoverTicket]) {
        if ticket.first?.venueId == self.venueDetail?.id {
            getVenueDetailsWithTickets(withLoader: false)
            updateContinueBtn(forceRemove: true)
            ticketTypeTableView.reloadData()
        }
    }
    
    func didGenderWiseTicketChange(venueId: String, uniqueId: String) {
        if uniqueId == self.venueId {
            getVenueDetailsWithTickets(withLoader: false)
        }
    }
    
    func updateAddOnsTicketPrice(ticket: [UpSellTicket]) {
        getAddOns()
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
        numberFormatter.minimumFractionDigits = !valueDouble ? 0 : 2
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
