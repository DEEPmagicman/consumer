//
//  ScanQRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView

class ScanQRCodeVC: UIViewController {
    
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var buyAnotherTicket: UIButton!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "CustomPagerViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    
    weak var delegate: QRCodeVCNavigationDelegate?
    var isAddOnsAvailable = false
    var bookingId = String()
    var qrImage = UIImage()
    var addOnsQR = UIImage()
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isAddOnsAvailable = booking?.addOnsBookingId ?? "" != "" ? true : false
        venueName.text = "-"
        setPageController()
        let attributedString = NSAttributedString(string: "Buy another ticket", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        buyAnotherTicket.setAttributedTitle(attributedString, for: .normal)
        let string = """
    {
        "id": "\(bookingId)",
        "type": "BOOKING"
    }
"""
        qrImage = generateQRCode(from: string) ?? UIImage()
        
        let string1 = """
    {
        "id": "\(bookingId)",
        "type": "ADD_ON"
    }
"""
        addOnsQR = generateQRCode(from: string1) ?? UIImage()
        getBooking(id: bookingId)
    }
    
    func setPageController(){
        pagerView.delegate = self
        pagerView.dataSource = self
        //        pagerView.itemSize = CGSize(width: 200, height: 180)
        pageControl.numberOfPages = isAddOnsAvailable ? 2 : 1
        pageControl.backgroundColor = .clear
        pageControl.itemSpacing = 8
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        delegate?.navigateToVenueDetail(venueId: booking?.venueObject?.id ?? "", venueUniqueId: booking?.venueObject?.uniqueId ?? "", venueTimeZone: booking?.venueObject?.timezone ?? "")
        dismiss(animated: true)
    }
    
    private func getBooking(id: String) {
        Loader.show()
        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.venueName.text = booking?.venueObject?.name ?? ""
                self.isAddOnsAvailable = booking?.addOnsBookingId ?? "" != "" ? true : false
        
                if booking?.addOnsBookingId ?? "" != "" {
                    self.getAddOnsBooking()
                    let string1 = """
                {
                    "id": "\(booking?.addOnsBookingId ?? "")",
                    "type": "ADD_ON"
                }
            """
                    self.addOnsQR = self.generateQRCode(from: string1) ?? UIImage()
                }
                DispatchQueue.main.async {
                    self.pagerView.reloadData()
                }
            } else {
                
            }
        }
    }
    
    private func getAddOnsBooking() {
        Loader.show()
        PaymentPresenter.getAddOnsBooking(venueId: booking?.venueId ?? "", addOnsBookingId: booking?.addOnsBookingId ?? "") { isSuccess, errMsg, booking in
            Loader.hide()
            if isSuccess {
                self.addOnsBooking = booking
                DispatchQueue.main.async {
                    self.pagerView.reloadData()
                }
            }
        }
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

extension ScanQRCodeVC: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return isAddOnsAvailable ? 2 : 1
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! CustomPagerViewCell
        
        cell.backupCode.text = booking?.venueObject?.bookingCode ?? ""
        cell.bookingDateTime.text = "Purchased on \(booking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: booking?.venueObject?.useTimezone ?? "") ?? "")"
        if index == 0 {
            cell.booking = booking
        } else {
            cell.addOnsBooking = addOnsBooking
        }
        cell.qrImage.image = index == 0 ? qrImage : addOnsQR
        cell.ticketsTableView.reloadData()
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

