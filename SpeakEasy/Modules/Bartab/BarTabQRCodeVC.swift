//
//  BarTabQRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 02/07/25.
//

import UIKit
import FSPagerView
import PassKit

final class BarTabQRCodeVC: UIViewController {
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var buyAnotherTicket: UIButton!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "CustomPagerViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    @IBOutlet weak var addToWalletBtn: PKAddPassButton!
    @IBOutlet weak var bgImage: UIImageView!
    
    weak var delegate: QRCodeVCNavigationDelegate?
    var qrImage: UIImage? = nil
    var booking: BarTabBooking?
    var venue: ClipVenue?
    var posCheckId = String()
    var barTabId = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bgImage.sd_setImage(with: URL(string: (venue?.venueAttachment?.first?.key ?? "").imageURL))
        venueName.text = venue?.name ?? "" == "" ? "-" : venue?.name
        let attributedString = NSAttributedString(string: "Buy another ticket", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        buyAnotherTicket.setAttributedTitle(attributedString, for: .normal)
        
        let string = """
        {
            "id": "\(barTabId)",
            "type": "BAR_TAB"
        }
    """
        qrImage = generateQRCode(from: string) ?? UIImage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)
        getBarTabPaymentDetails()
        pagerView.delegate = self
        pagerView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebSocketWrapper.shared.delegate.append(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }
    
    @objc func refreshData() {
        getBarTabPaymentDetails()
    }
    
    private func getBarTabPaymentDetails() {
        Loader.show()
        BarTabPresenter.getBarTabPaymentDetails(posCheckId: posCheckId) { [weak self] isSuccess, errMsg, barTabBooking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.booking = barTabBooking
                DispatchQueue.main.async {
                    self.pagerView.reloadData()
                }
            }
        }
    }
    
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        pagerView.reloadData()
        let uniqueId = booking?.venue?.uniqueId ?? ""
        let timeZone = booking?.venue?.timezone ?? ""
        delegate?.navigateToVenueDetail(venueId: booking?.venueId ?? "", venueUniqueId: uniqueId, venueTimeZone: timeZone)
        dismiss(animated: true)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
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

extension BarTabQRCodeVC: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        1
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! CustomPagerViewCell
        cell.backupCode.text = booking?.venue?.bookingCode ?? ""
        cell.bookingDateTime.text = "Purchased on \(booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: booking?.venue?.useTimezone ?? "") ?? "")"
        cell.guestNameLbl.text = "\(UserDefault.shared.user?.firstName ?? "") \(UserDefault.shared.user?.lastName ?? "") - \(booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMDDYYYYHMMA, isUTC: true, customTimeZone: booking?.venue?.useTimezone ?? "") ?? "")"
       
            cell.barTabBooking = booking
            DispatchQueue.main.async {
                cell.qrImage.image = self.qrImage
            }
        cell.ticketsTableView.reloadData()
        return cell
    }
}

extension BarTabQRCodeVC: WebSocketCallBackDelegate {
//    func checkInTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
//        if booking?.id ?? "" == bookingId {
//            booking?.bookingHasCheckIn = checkIndata
//            pagerView.reloadData()
//        }
//    }
//    
//    func unCheckTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
//        if booking?.id ?? "" == bookingId {
//            booking?.bookingHasCheckIn = checkIndata
//            pagerView.reloadData()
//        }
//    }
}
