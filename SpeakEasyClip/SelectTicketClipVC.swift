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
    @IBOutlet weak var disclaimerText: UILabel!
    @IBOutlet weak var disclaimerInSideView: UIView!
    @IBOutlet weak var disclaimerView: UIView!
    @IBOutlet weak var tableBookNowBtn: UIButton!
    @IBOutlet weak var languageSwitchBtn: UIButton!
    @IBOutlet weak var languageSwitchImg: UIImageView!
    @IBOutlet weak var languageSwitchLbl: UILabel!

    var isLive = true
    var venueDetail: ClipVenue?
    private var gradient: CAGradientLayer?
    private var venueImgHeightObservation: NSKeyValueObservation?
    private var venueId: String {
        get {
            return UserDefaults.standard.value(forKey: "venueId") as? String ?? ""
        }
    }
    private var deepLink: String {
        get {
            return UserDefaults.standard.value(forKey: "deepLinkId") as? String ?? ""
        }
    }
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
    var venueImageData = Data()
    var customPaidTicket: CoverTicket? {
        venueDetail?.coverTicket?.first(where: { $0.isCustom == true && $0.price > 0 && $0.selectedQuantity ?? 0 != 0 })
    }
    var defaultPaidTicket: CoverTicket? {
        venueDetail?.coverTicket?.first(where: { $0.isCustom == false && $0.price > 0 && $0.selectedQuantity ?? 0 != 0  })
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

        if venueId == "" {
            getDeepLinkData()
        } else {
            getVenueDetailsWithTickets()
        }
        upSellBtn.setTitle("Buy upsell".localize(args: (self.venueDetail?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Upsell".localize())), for: .normal)

        tableBookNowBtn.layer.borderColor = UIColor.white.cgColor
        tableBookNowBtn.layer.borderWidth = 1
        
        setupLanguageSelection()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeepLink(_:)), name: Notification.Name("DeepLinkReceived"), object: nil)
    }
    
    @objc func handleDeepLink(_ notification: Notification) {
        self.navigationController?.popToRootViewController(animated: false)
        
        if venueId == "" {
            getDeepLinkData()
        } else {
            getVenueDetailsWithTickets()
        }
    }
    
    private func getDeepLinkData() {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/deep-link/\(self.deepLink)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        request.addValue(UserDefaults.standard.language, forHTTPHeaderField: "language")

        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                var json = [String: Any]()
                if !SharedURL.isEncryptionEnabled {
                    guard let data = data,
                          let dataJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        AppClipLoader.hideLoader()
                        return
                    }
                    json = dataJson;
                } else {
                    guard let data = data, let response = String(data: data, encoding: .utf8) else { return }
                    json =  response.decrypted() ?? [:]
                }
                
                UserDefaults.standard.set(json["venueId"] as? String ?? "", forKey: "venueId")
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
        request.addValue(UserDefaults.standard.language, forHTTPHeaderField: "language")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                AppClipLoader.hideLoader()
                let decoder = JSONDecoder()
                if !SharedURL.isEncryptionEnabled {
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        return
                    }
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
                } else {
                    guard let data = data, let response = String(data: data, encoding: .utf8) else { return }
                    let json =  response.decrypted() ?? [:]
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
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        request.addValue(UserDefaults.standard.language, forHTTPHeaderField: "language")
        
        if withLoader {
            DispatchQueue.main.async {
                AppClipLoader.showLoader(self.view)
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                AppClipLoader.hideLoader()
                let decoder = JSONDecoder()
                if !SharedURL.isEncryptionEnabled {
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        return
                    }
                    guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                        return
                    }
                    self.venueDetail = try? decoder.decode(ClipVenue.self, from: venueData)
                } else {
                    guard let data = data, let response = String(data: data, encoding: .utf8) else { return }
                    let json =  response.decrypted() ?? [:]
                    guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                        return
                    }
                    self.venueDetail = try? decoder.decode(ClipVenue.self, from: venueData)
                }
                UserDefaults.standard.setValue(self.venueDetail?.id ?? "", forKey: "venueIdLong")
                VenueImageManager.shared.customQRData = self.venueDetail?.venueSettings?.coverTicketViewSettings
                VenueImageManager.shared.isEnableCoverTicketViewSettings = self.venueDetail?.venueSettings?.isEnableCoverTicketViewSettings ?? false
                if let color = self.venueDetail?.venueSettings?.whiteLabelColor {
                    self.continueBtn.backgroundColor = UIColor(hex: color)
                }
                self.setUpUI()
                self.getAddOns()
                if VenueImageManager.shared.customQRData != nil { self.getCustomImage() }
                self.updateContinueBtn(forceRemove: true)
            }
        }.resume()
    }
    
    private func getCustomImage() {
        DispatchQueue.global(qos: .background).async {
            let imgStr = "\(self.venueDetail?.venueSettings?.coverTicketViewSettings?.image ?? "")"
            guard let imgUrl = URL(string: imgStr) else { return }
            do {
                let imgData = try Data(contentsOf: imgUrl)
                DispatchQueue.main.async {
                    VenueImageManager.shared.customQRImage = imgData
                }
            } catch {}
        }
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
                    self.venueImageData = imgData
                    VenueImageManager.shared.venueImage = imgData
                    self.logoImg.image = UIImage(data: logoData)
                }
            } catch {}
        }
        DispatchQueue.main.async {
            self.venueTitleNameLbl.text = self.venueDetail?.name
//            self.venueInfoLbl.text = "Entry tickets can be purchased in-person at \(self.venueDetail?.name ?? "") by scanning the banner located outside the venue. \nPrices shown here are live and subject to change."
//            self.venueInfoLbl.highlightBold(["in-person","live and subject to change."], size: 15, textColor: .white)
            if self.venueDetail?.venueSettings?.bookingStatus == "OPEN" {
                self.liveCloseLbl.text = "LIVE".localize()
                self.liveCloseLbl.textColor = UIColor(red: 0.00, green: 1.00, blue: 0.58, alpha: 1.00)
                self.tonightLbl.alpha = 1
            } else {
                self.liveCloseLbl.text = "CLOSED".localize()
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
                self.closeLbl.text = "Venue not found".localize()
                self.infoView.isHidden = true
                self.closeLblView.isHidden = false
                self.liveCloseLbl.isHidden = true
                self.tonightLbl.isHidden = true
            }
            self.upSellBtn.setTitle("Buy upsell".localize(args: (self.venueDetail?.venueSettings?.addOnsBookingSettings?.pageTitle ?? "Upsell".localize())), for: .normal)
        }
        
        self.disclaimerView.isHidden = self.venueDetail?.venueSettings?.showCoverDisclaimer ?? false == false
        self.disclaimerInSideView.layer.cornerRadius = 8
        self.disclaimerInSideView.layer.borderWidth = 1
        if self.venueDetail?.venueSettings?.whiteLabelColor ?? "" != "" {
            let color = self.venueDetail?.venueSettings?.whiteLabelColor ?? ""
            self.disclaimerInSideView.layer.borderColor = UIColor(hex: color).cgColor
        } else {
            self.disclaimerInSideView.layer.borderColor = UIColor(hex: "F581FE").cgColor
        }
        self.disclaimerText.text = self.venueDetail?.venueSettings?.coverDisclaimerText ?? ""
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
                vc.venueImageData = venueImageData
                navigationController?.interactivePopGestureRecognizer?.delegate = self
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String(describing: "CheckOutClipVC")) as? CheckOutClipVC, let selectedTickets = venueDetail?.coverTicket?.filter({ $0.selectedQuantity != nil }) {
                if selectedTickets.count > 0 {
                    vc.selectedCoverTickets = selectedTickets
                    vc.totalPrice = totalPrice
                    vc.venue = venueDetail
                    vc.venueImageData = venueImageData
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
                vc.venueImageData = venueImageData
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
                let ticket = venueDetail?.coverTicket?.first(where: { $0.price >= 2 && $0.selectedQuantity != nil })
                if ticket != nil { selectedType = .PAID } else { selectedType = .FREE }
                ticketTypeTableView.reloadData()
                selectedType = (defaultPaidTicket == nil && customPaidTicket == nil) ? .FREE : .PAID
                updateContinueBtn(forceRemove: (venueDetail?.coverTicket?.firstIndex(where: { $0.selectedQuantity != nil })) == nil)
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        
        if let totalTicket = venueDetail?.coverTicket?[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                venueDetail?.coverTicket?[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            }
        }
    }
    
    func updateContinueBtn(forceRemove: Bool = false) {
        DispatchQueue.main.async {
            if forceRemove {
                self.venueDetail?.coverTicket?.indices.forEach {
                    self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
                }
                    self.VIPTableBookingView.isHidden = true
                    self.continueBtn.isHidden = true
                    self.scrollViewBottomConstraint.constant = 20
//                }
                self.ticketTypeTableView.reloadData()
                return
            }
            self.VIPTableBookingView.isHidden = true
            self.continueBtn.isHidden = false
            self.scrollViewBottomConstraint.constant = 98
            switch self.selectedType {
            case .FREE:
                if self.upSellView.isHidden == true {
                    self.continueBtn.setTitle("GET MY FREE TICKET".localize(), for: .normal)
                } else {
                    self.continueBtn.setTitle("CONTINUE TO CHECKOUT".localize(), for: .normal)
                }
            case .PAID, .CUSTOM:
                self.continueBtn.setTitle("CONTINUE TO CHECKOUT".localize(), for: .normal)
            }
        }
    }
    
    func forceRemoveAllTicket() {
        self.venueDetail?.coverTicket?.indices.forEach {
            self.venueDetail?.coverTicket?[$0].selectedQuantity = nil
        }
        ticketTypeTableView.reloadData()
        updateContinueBtn(forceRemove: true)
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
        cell.ticketTypeLbl.text = self.venueDetail?.coverTicket?[indexPath.row].customName ?? "" == "" ? venueDetail?.coverTicket?[indexPath.row].displayName : venueDetail?.coverTicket?[indexPath.row].displayCustomName
        cell.infoLbl.text = self.venueDetail?.coverTicket?[indexPath.row].displayDescription
        cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Double(self.venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat(true))"
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        cell.plusBtn.isUserInteractionEnabled = isMaxTicketReached ? false : true
        if venueDetail?.coverTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.coverTicket?[indexPath.row].name.lowercased().contains("general") == true {
            cell.ticketPriceLbl.text = "FREE".localize()
        } else if venueDetail?.coverTicket?[indexPath.row].isCustom == true && venueDetail?.coverTicket?[indexPath.row].price ?? 0 == 0 {
            cell.ticketPriceLbl.text = "FREE".localize()
        } else {
            if venueDetail?.venueSettings?.coverTicketSettings?.isUpFront == true {
                let price = venueDetail?.modifiedCoverTicket[indexPath.row].isCustom == true ? Double(venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat(true) : Double(venueDetail?.modifiedCoverTicket[indexPath.row].price ?? 0).decimalFormat(true)
                let dPrice = price.components(separatedBy: ".")[1]
                cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(Int(dPrice) == 0 ? "\(Int(price.components(separatedBy: ".")[0]) ?? 0)" : price)"
            } else {
                let price = Double(venueDetail?.coverTicket?[indexPath.row].price ?? 0).decimalFormat()
                cell.ticketPriceLbl.text = "\(venueDetail?.venueSettings?.currencySymbol ?? "$")\(price)"
            }
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
            return
        }
        venueDetail?.coverTicket?[indexPath.row].selectedQuantity = 1
        
        let selectedTicket = venueDetail?.coverTicket?[indexPath.row]
        if selectedTicket?.isCustom == false {
            if selectedTicket?.price ?? 0 >= 2 {
                if customPaidTicket != nil {
                    forceRemoveCustomTicket()
                }
                
            }
        } else if selectedTicket?.isCustom == true {
            if selectedTicket?.price ?? 0 > 0 {
                if defaultPaidTicket != nil {
                    forceRemovePaidTicket()
                }
                selectedType = .PAID
            }
        }
        selectedType = (defaultPaidTicket == nil && customPaidTicket == nil) ? .FREE : .PAID
//        if venueDetail?.coverTicket?[indexPath.row].price ?? 0 < 2 && venueDetail?.coverTicket?[indexPath.row].name.lowercased().contains("general") == true {
//            forceRemoveCustomTicket()
//            
//            let selected = venueDetail?.coverTicket?.filter({ $0.selectedQuantity ?? 0 != 0 })
//            if let paid = selected?.filter({ $0.price > 2 }), paid.count != 0 {
//                selectedType = .PAID
//            } else {
//                selectedType = .FREE
//            }
//        } else if venueDetail?.coverTicket?[indexPath.row].isCustom == true {
//            forceRemovePaidTicket()
//            forceRemoveFreeTicket()
//            selectedType = venueDetail?.coverTicket?[indexPath.row].price == 0 ? .FREE : .CUSTOM
//        } else {
//            forceRemoveCustomTicket()
//            selectedType = .PAID
//        }
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

extension SelectTicketClipVC {

    private func setupLanguageSelection() {
        let actionClosure = { (action: UIAction) in
            UserDefaults.standard.set([Language(language: action.title).rawValue], forKey: "AppleLanguages")
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            }
        }
        
        let dataSource = ["English", "Español"]
        var menuChildren: [UIMenuElement] = []
        for data in dataSource {
            menuChildren.append(UIAction(title: data, image: UIImage(named: Language(language: data).rawValue.uppercased()), state: Language(language: data).rawValue == UserDefaults.standard.language ? .on : .off, handler: actionClosure))
        }
        languageSwitchBtn.menu = UIMenu(options: .displayInline, children: menuChildren)
        languageSwitchBtn.showsMenuAsPrimaryAction = true
        if #available(iOS 15.0, *) {
            languageSwitchBtn.changesSelectionAsPrimaryAction = true
        }
        languageSwitchBtn.setTitle("", for: .normal)
        languageSwitchLbl.text = UserDefaults.standard.language.uppercased()
        languageSwitchImg.image = UIImage(named: UserDefaults.standard.language.uppercased())
    }
}

extension Double {
    func decimalFormat(_ valueDouble: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = valueDouble ? 2 : 0
        numberFormatter.numberStyle = .decimal
        if valueDouble {
            if let newValue =  Double(String(format: "%.2f", NSNumber(value: self).doubleValue)) {
                return String(numberFormatter.string(from: NSNumber(value: newValue)) ?? "")
            } else {
                return "0.00"
            }
        } else {
            let decimalPrice = Int(String(self).components(separatedBy: ".").last ?? "0")
            numberFormatter.minimumFractionDigits = decimalPrice ?? 0 > 0 ? 2 : 0
            return String(numberFormatter.string(from: NSNumber(value: self)) ?? "")
        }
    }

}

class VenueImageManager {
    
    static let shared = VenueImageManager()
    
    var venueImage = Data()
    var customQRData: CoverTicketViewSettings?
    var isEnableCoverTicketViewSettings: Bool = false
    var customQRImage = Data()
    
    init() {}
}
