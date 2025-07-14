//
//  BarTabQRCodeClipVC.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 02/07/25.
//

import UIKit
import FSPagerView

final class BarTabQRCodeClipVC: UIViewController {
    
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "PagerViewTVC", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    
    var barBooking: BarTabBooking?
    var venue: ClipVenue?
    var barTabId = String()
    var qrImage: UIImage? = nil
    private var isAlertDisplayed = false
    var guestInfo = String()
    var appClipTicket = [CoverTicket]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
        venueImg.setGradientColor()
        venueNameLbl.text = venue?.name
        let string = """
            {
                "id": "\(barTabId)",
                "type": "BAR_TAB"
            }
    """
        qrImage = generateQRCode(from: string)
        pagerView.reloadData()
        WebSocketWrapper.shared.delegate.append(self)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)
        pagerView.delegate = self
        pagerView.dataSource = self
    }
    
    @objc func refreshData() {
        getBarBooking()
    }
    
    private func getBarBooking() {
        AppClipLoader.showLoader(self.view)
        guard let userURL = URL(string: "\(SharedURL.baseURL)/consumer/bar-tab/\(barTabId)/payments-details/") else { return }
        var request = URLRequest(url: userURL, timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                AppClipLoader.hideLoader()
                self.alertPopup("Alert", "Data not found")
                return
            }
            AppClipLoader.hideLoader()
            if let data = try? JSONDecoder().decode(BarTabBooking.self, from: data) {
                self.barBooking = data
                self.pagerView.reloadData()
            }
        }
        task.resume()
    }
    
    func loadImage() {
        venueImg.image = UIImage(data: VenueImageManager.shared.venueImage)
    }
    
    func shareSocialWith(text: String) {
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onClickBuyAnother(_ sender: Any) {
        if isAlertDisplayed {
            navigationController?.popToRootViewController(animated: true)
        } else {
            alertPopup("", "Make sure that you've received a booking SMS or take a screen-shot of QR before buying another ticket.")
            isAlertDisplayed = true
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
}

extension BarTabQRCodeClipVC: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        1
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! PagerViewTVC
        cell.openTabBtnHeight.constant = 50
        cell.openTabBtn.isHidden = false
        cell.backupCode.text = venue?.bookingCode
        cell.bookingDateTime.text = "Purchased on \(barBooking?.createdAt.convertDateFormat(from: "yyyy-MM-dd'T'HH:mm:ss.SSSz", to: "h:mma MMMM dd", isUTC: true, customTimeZone: self.venue?.useTimezone ?? "") ?? "")"
        cell.uniqueTickets = appClipTicket
        cell.barTabBooking = barBooking
        cell.qrImage.image = qrImage
        cell.ticketsTableView.reloadData()
        cell.guestName.text = guestInfo
        cell.openTabBtn.addTarget(self, action: #selector(openTabBtn), for: .touchUpInside)
        if let color = self.venue?.venueSettings?.whiteLabelColor {
            cell.openTabBtn.backgroundColor = UIColor(hex: color)
        }
        return cell
    }
    
    @objc func openTabBtn() {
        let url = "\(SharedURL.webBaseURL)/\(barBooking?.venue?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "")/bar-tab/\(barBooking?.id ?? "")"
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension BarTabQRCodeClipVC: WebSocketCallBackDelegate {
    func checkinBarBooking(barItems: [BarTabHasItem]) {
        if barBooking?.id ?? "" == barItems.first?.barTabId {
            barBooking?.barTabHasItems = barItems
            pagerView.reloadData()
        }
    }
    
    func uncheckBarBooking(barItems: [BarTabHasItem]) {
        if barBooking?.id ?? "" == barItems.first?.barTabId {
            barBooking?.barTabHasItems = barItems
            pagerView.reloadData()
        }
    }
}
