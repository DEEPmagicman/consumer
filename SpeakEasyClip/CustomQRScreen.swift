//
//  CustomQRScreen.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 21/06/24.
//

import UIKit
import FSPagerView

final class CustomQRScreen: UIViewController {
    
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var customImage: UIImageView!
    @IBOutlet weak var customBtn: UIButton!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var buyAnotherTicketBtn: UIButton!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "PagerViewTVC", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    @IBOutlet weak var anotherTicketBtnView: UIView!
    @IBOutlet weak var customImageHeight: NSLayoutConstraint!
    
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
    var guestInfo = String()
    var qrBorderColorHex: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        qrImage = generateQRCode(from: string)
        addOnsQR = generateQRCode(from: string1)
        pagerView.reloadData()
        customImage.image = UIImage(data: VenueImageManager.shared.venueImage)
        customBtn.setTitle(VenueImageManager.shared.customQRData?.button?.text.uppercased(), for: .normal)
        customBtn.backgroundColor = UIColor(hex: VenueImageManager.shared.customQRData?.button?.color ?? "")
        customBtn.setTitleColor(UIColor(hex: VenueImageManager.shared.customQRData?.button?.fontColor ?? ""), for: .normal)
        buyAnotherTicketBtn.setTitleColor(UIColor(hex: VenueImageManager.shared.customQRData?.fontColorA ?? ""), for: .normal)
        anotherTicketBtnView.backgroundColor = UIColor(hex: VenueImageManager.shared.customQRData?.fontColorA ?? "")
        if VenueImageManager.shared.customQRData?.button?.text == "open_sans" {
            customBtn.titleLabel?.font = UIFont(name: "OpenSans-Regular", size: 15)
        } else if VenueImageManager.shared.customQRData?.button?.text == "motor" {
            customBtn.titleLabel?.font = UIFont(name: "Motor-Regular", size: 15)
        } else if VenueImageManager.shared.customQRData?.button?.text == "avenir" {
            customBtn.titleLabel?.font = UIFont(name: "Avenir-Regular", size: 15)
        } else {
            customBtn.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 15)
        }
        customImage.image = UIImage(data: VenueImageManager.shared.customQRImage)
        bgView.backgroundColor = UIColor(hex: VenueImageManager.shared.customQRData?.background ?? "")
        resizeLandscapeImageView(imageViewFrameWidth: UIScreen.main.bounds.width, image: customImage.image ?? UIImage())
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        WebSocketWrapper.shared.delegate.append(self)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        print("---Screen tapped at")
    }
    
    func setPageController() {
        pagerView.delegate = self
        pagerView.dataSource = self
        
        pageControl.numberOfPages = (isOnlyAddOnsAvailable || selectedAddOns.count == 0) ? 1 : 2
        pageControl.backgroundColor = .clear
        pageControl.itemSpacing = 8
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        pageControl.setFillColor(UIColor(hex: VenueImageManager.shared.customQRData?.fontColorA ?? ""), for: .selected)
        pageControl.setFillColor(UIColor(hex: VenueImageManager.shared.customQRData?.fontColorB ?? ""), for: .normal)
    }
    
    @IBAction func onClickBuyAnother(_ sender: Any) {
        if isAlertDisplayed {
            navigationController?.popToRootViewController(animated: true)
        } else {
            alertPopup("", "Make sure that you've received a booking SMS or take a screen-shot of QR before buying another ticket.")
            isAlertDisplayed = true
        }
    }
    
    @IBAction func onClickCustomBtn(_ sender: Any) {
        guard let url = URL(string: VenueImageManager.shared.customQRData?.button?.link ?? "") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    
    private func resizeLandscapeImageView(imageViewFrameWidth: CGFloat, image: UIImage) {
        let widthOffset = image.size.width - imageViewFrameWidth
        let widthOffsetPercentage = (widthOffset * 100) / image.size.width
        let heightOffset = (widthOffsetPercentage * image.size.height) / 100
        let effectiveHeight = image.size.height - heightOffset
        customImageHeight.constant = effectiveHeight
    }
}

extension CustomQRScreen: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return (isOnlyAddOnsAvailable || selectedAddOns.count == 0) ? 1 : 2
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! PagerViewTVC

        cell.backupCode.text = bookingCode
        cell.bookingDateTime.text = "Purchased on".localize() + " \(createdAT)"
        cell.guestName.text = guestInfo
        cell.qrBorderColorHex = qrBorderColorHex
        
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
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

extension CustomQRScreen: WebSocketCallBackDelegate {
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

