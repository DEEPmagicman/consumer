//
//  QRClipVC.swift
//  SpeakEasyClip
//
//  Created by MAC on 05/03/24.
//

import UIKit
import FSPagerView

final class QRClipVC: UIViewController {
    
    var venueAttachment = ""
    var venueLogo = ""
    var venueName = ""
    var bookingId = ""
    var addOnBookingId = ""
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    private var isAlertDisplayed = false
    var bookingCode = String()
    var createdAT = String()
    var appClipTicket = [CoverTicket]()
    var selectedAddOns = [UpSellTicket]()
    var qrImage:UIImage? = nil
    var addOnsQR:UIImage? = nil
    var isOnlyAddOnsAvailable = false
    var venueImageData = Data()
    var guestInfo = String()
    var qrBorderColorHex: String?
    
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var swipeLbl: UILabel!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var venueImg: UIImageView!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "PagerViewTVC", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
        venueImg.setGradientColor()
        venueNameLbl.text = venueName
        setPageController()
        let string = """
                {
                    "id": "\(bookingId)",
                    "type": "BOOKING"
                }
        """
        let string1 = """
                {
                    "id": "\(addOnBookingId)",
                    "type": "ADD_ON"
                }
        """
        swipeLbl.isHidden = (isOnlyAddOnsAvailable || selectedAddOns.count == 0) ? true : false
        qrImage = generateQRCode(from: string)
        addOnsQR = generateQRCode(from: string1)
        pagerView.reloadData()
        WebSocketWrapper.shared.delegate.append(self)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func refreshData() {
        if isOnlyAddOnsAvailable {
            getAddOnsBooking {}
        } else {
            getBooking {
                self.getAddOnsBooking {}
            }
        }
    }
    
    private func getBooking(completion: @escaping (()-> Void)) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/booking/\(self.bookingId)?include%5B%5D=bookingHasItem&include%5B%5D=bookingHasCheckIn.bookingItemCheckIn&include%5B%5D=bookingDetails") else { return }
        var request = URLRequest(url: url)
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "GET"
        
        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                guard let data = data else {
                    AppClipLoader.hideLoader()
                    return
                }
                
                var json = [String: Any]()

                if !SharedURL.isEncryptionEnabled {
                    guard let dataJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        AppClipLoader.hideLoader()
                        return
                    }
                    json = dataJson;
                } else {
                    guard let response = String(data: data, encoding: .utf8) else { return }
                    json =  response.decrypted() ?? [:]
                }
                
                if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                    let booking = try? JSONDecoder().decode(Booking.self, from: data)
                    self.booking = booking
                }
                
                self.pagerView.reloadData()
                AppClipLoader.hideLoader()
                completion()
            }
        }.resume()
    }
    
    private func getAddOnsBooking(completion: @escaping (()-> Void)) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/add-ons/\(self.addOnBookingId)?include%5B%5D=addOnsBookingHasItem.addOns&include%5B%5D=addOnsBookingHasCheckIn.addOnsBookingItemCheckIn") else { return }
        var request = URLRequest(url: url)
        let date = Date().toString(dateFormat: .yyyyMMddHHmmss, timeZone: TimeZone(identifier: "UTC")).encryptedHeader()
        request.addValue(date, forHTTPHeaderField: "token")
        
        request.httpMethod = "GET"
        
        DispatchQueue.main.async {
            AppClipLoader.showLoader(self.view)
        }
        
        URLSession.shared.dataTask(with: request) { data, respons, error in
            DispatchQueue.main.async {
                guard let data = data else {
                    AppClipLoader.hideLoader()
                    return
                }
                
                var json = [String: Any]()

                if !SharedURL.isEncryptionEnabled {
                    guard let dataJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                        AppClipLoader.hideLoader()
                        return
                    }
                    json = dataJson;
                } else {
                    guard let response = String(data: data, encoding: .utf8) else { return }
                    json =  response.decrypted() ?? [:]
                }
                
                if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                    let addOnsBooking = try? JSONDecoder().decode(AddOnsBooking.self, from: data)
                    self.addOnsBooking = addOnsBooking
                }

                self.pagerView.reloadData()
                AppClipLoader.hideLoader()
                completion()
            }
        }.resume()
    }
    
    func loadImage() {
        venueImg.image = UIImage(data: VenueImageManager.shared.venueImage)
    }
    
    func setPageController() {
        pagerView.delegate = self
        pagerView.dataSource = self
        
        pageControl.numberOfPages = (isOnlyAddOnsAvailable || selectedAddOns.count == 0) ? 1 : 2
        pageControl.backgroundColor = .clear
        pageControl.itemSpacing = 8
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = "shareText".localize(args: "\(venueName)", "\(isOnlyAddOnsAvailable ? String(format: SharedURL.addOnsShareURL, venueName.lowercased().replacingOccurrences(of: " ", with: "-"), addOnBookingId) : String(format: SharedURL.coverShareURL, venueName.lowercased().replacingOccurrences(of: " ", with: "-"), bookingId))", "\(SharedURL.appStoreURL)")
        shareSocialWith(text: msgText)
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

extension QRClipVC: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return (isOnlyAddOnsAvailable || selectedAddOns.count == 0) ? 1 : 2
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! PagerViewTVC

        cell.backupCode.text = bookingCode
        cell.qrBorderColorHex = qrBorderColorHex
        cell.bookingDateTime.text = "Purchased on".localize() + " \(createdAT)"
        
        if isOnlyAddOnsAvailable {
            if index == 0 {
                cell.addOnsBookingHasItem = selectedAddOns
                cell.addOnsBooking = addOnsBooking
                cell.qrImage.image = addOnsQR
            }
        } else {
            if index == 0 {
                cell.uniqueTickets = appClipTicket
                cell.booking = booking
                cell.qrImage.image = qrImage
            } else {
                cell.addOnsBookingHasItem = selectedAddOns
                cell.addOnsBooking = addOnsBooking
                cell.qrImage.image = addOnsQR
            }
        }
        cell.ticketsTableView.reloadData()
        cell.guestName.text = guestInfo
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

extension QRClipVC: WebSocketCallBackDelegate {
    func checkInTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
        if booking?.id ?? "" == bookingId {
            booking?.bookingHasCheckIn = checkIndata
            pagerView.reloadData()
        }
    }
    
    func unCheckTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
        if booking?.id ?? "" == bookingId {
            booking?.bookingHasCheckIn = checkIndata
            pagerView.reloadData()
        }
    }
    
    func checkInAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) {
        if addOnsBooking?.id ?? "" == bookingId {
            addOnsBooking?.addOnsBookingHasCheckIn = checkIndata
            pagerView.reloadData()
        }
    }
    
    func unCheckAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) {
        if addOnsBooking?.id ?? "" == bookingId {
            addOnsBooking?.addOnsBookingHasCheckIn = checkIndata
            pagerView.reloadData()
        }
    }
}
