//
//  ScanQRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView
import PassKit

class ScanQRCodeVC: UIViewController {
    
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var buyAnotherTicket: UIButton!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "CustomPagerViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    @IBOutlet weak var addToWalletBtn: PKAddPassButton!
    @IBOutlet weak var swipeLbl: UILabel!
    
    weak var delegate: QRCodeVCNavigationDelegate?
    var isAddOnsAvailable = false
    var bookingId = String()
    var qrImage:UIImage? = nil
    var addOnsQR:UIImage? = nil
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    var addOnsBookingId: String?
    var isOnlyAddOnAvailable = false
    var venueId = String()
    var venueNameText: String? = ""
    private var pass: PKPass?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isAddOnsAvailable = booking?.addOnsBookingId ?? "" != "" ? true : false
        venueName.text = venueNameText ?? "" == "" ? "-" : venueNameText
        setPageController()
        let attributedString = NSAttributedString(string: "Buy another ticket", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        buyAnotherTicket.setAttributedTitle(attributedString, for: .normal)
        
        if isOnlyAddOnAvailable {
            getAddOnsBooking()
            swipeLbl.isHidden = true
        } else {
            let string = """
        {
            "id": "\(bookingId)",
            "type": "BOOKING"
        }
    """
            qrImage = generateQRCode(from: string) ?? UIImage()
            getBooking(id: bookingId)
            swipeLbl.isHidden = isAddOnsAvailable ? false : true
        }
        addToWalletBtn.addPassButtonStyle = .blackOutline
        addToWalletBtn.addTarget(self, action: #selector(addToWalletBtnTapped), for: .touchUpInside)
        addToWalletBtn.isHidden = isOnlyAddOnAvailable ? true : false
    }
    
    @objc private func addToWalletBtnTapped() {
        var url = URL(string: "")
        url = URL(string: APIBuilder.appClipAppleWallet(booking?.id ?? ""))
        
        guard let url = url else { return }
        let pkl = PKPassLibrary()
        if let pass = pass {
            if pkl.containsPass(pass) {
                Alert.showToast("Ticket already Added", vc: self)
            } else {
                presentAddPKPass(pass)
            }
            return
        }
        Loader.show()
        URLSession.shared.fetchData(at: url) { [weak self] data, error in
            guard let self = self else {
                Loader.hide()
                return
            }
            if let data = data {
                do {
                    let pass = try PKPass(data: data)
                    Loader.hide()
                    self.presentAddPKPass(pass)
                    self.pass = pass
                } catch {
                    Loader.hide()
                    Alert.showAlertSheet(style: .alert, title: "Incorrect data", message: "")
                }
            } else {
                Loader.hide()
                Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
            }
        }
    }
    
    private func presentAddPKPass(_ pass: PKPass) {
        if let vc = PKAddPassesViewController(pass: pass) {
            DispatchQueue.main.async {
                vc.delegate = self
                self.present(vc, animated: true)
            }
        }
    }
    
    func setPageController() {
        pagerView.delegate = self
        pagerView.dataSource = self
        pageControl.numberOfPages = isAddOnsAvailable ? 2 : 1
        pageControl.backgroundColor = .clear
        pageControl.itemSpacing = 8
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
//        delegate?.navigateToVenueDetail(venueId: booking?.venueObject?.id ?? 0, venueUniqueId: booking?.venueObject?.uniqueId ?? "", venueTimeZone: booking?.venueObject?.timezone ?? "")
        delegate?.navigateToVenueDetail(venueId: booking?.venueId ?? "", venueUniqueId: booking?.venueObject?.uniqueId ?? "", venueTimeZone: "asia/kolkata")
        pagerView.reloadData()
        let uniqueId = addOnsBooking != nil ? addOnsBooking?.venue.uniqueId ?? "" : booking?.venueObject?.uniqueId ?? ""
        let timeZone = addOnsBooking != nil ? addOnsBooking?.venue.timezone ?? "" : booking?.venueObject?.timezone ?? ""
//        delegate?.navigateToVenueDetail(venueId: venueId, venueUniqueId: uniqueId, venueTimeZone: timeZone)
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
                self.swipeLbl.isHidden = self.isAddOnsAvailable ? false : true
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
                self.setPageController()
            }
        }
    }
    
    private func getAddOnsBooking() {
        Loader.show()
        let bookingId = booking != nil ? booking?.addOnsBookingId ?? "" : addOnsBookingId ?? ""
        PaymentPresenter.getAddOnsBooking(addOnsBookingId: bookingId) {[weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.addOnsBooking = booking
                let string1 = """
            {
                "id": "\(booking?.id ?? "")",
                "type": "ADD_ON"
            }
        """
                self.addOnsQR = self.generateQRCode(from: string1) ?? UIImage()
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
        if isOnlyAddOnAvailable {
            cell.addOnsBooking = addOnsBooking
            cell.backupCode.text = addOnsBooking?.venue.bookingCode ?? ""
            cell.bookingDateTime.text = "Purchased on \(addOnsBooking?.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: booking?.venueObject?.useTimezone ?? "") ?? "")"
            if index == 0 {
                cell.qrImage.image = addOnsQR
            }
        } else {
            if index == 0 {
                cell.booking = booking
            } else {
                cell.addOnsBooking = addOnsBooking
            }
            DispatchQueue.main.async {
                cell.qrImage.image = index == 0 ? self.qrImage : self.addOnsQR
            }
        }
        cell.ticketsTableView.reloadData()
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
        if !isOnlyAddOnAvailable {
            addToWalletBtn.isHidden = pagerView.currentIndex == 0 ? false : true
        }
    }
}

extension ScanQRCodeVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        let pkl = PKPassLibrary()
        if let pass = pass, pkl.containsPass(pass) {
            Alert.showToast("Ticket added to wallet", vc: self)
        }
    }
}
