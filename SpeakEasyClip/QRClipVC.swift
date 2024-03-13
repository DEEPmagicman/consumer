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
    private var isAlertDisplayed = false
//    var isAddOnsAvailable = false
    var bookingCode = String()
    var createdAT = String()
    var appClipTicket = [AppClipTicket]()
    var selectedAddOns = [UpSellTicket]()
    var qrImage:UIImage? = nil
    var addOnsQR:UIImage? = nil
    var isOnlyAddOnsAvailable = false
    
    @IBOutlet weak var venueNameLbl: UILabel!
    
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
        qrImage = generateQRCode(from: string)
        addOnsQR = generateQRCode(from: string1)
        pagerView.reloadData()
    }
    
    func loadImage() {
        DispatchQueue.global().async {
            guard let imgUrl = URL(string: "\(SharedURL.amazonStorage)\(self.venueAttachment)") else { return }
            do {
                let imgData = try Data(contentsOf: imgUrl)
                DispatchQueue.main.async {
                    self.venueImg.image = UIImage(data: imgData)
                }
            } catch {}
        }
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
        let msgText = """
        Thank you for checking into \(venueName) with Speakeasy!

        Access Your Ticket Here: \(String(format: SharedURL.QAWebURL, bookingId))

        Download Speakeasy on the Apple App Store to stay updated on covers and wait times at your favorite venues. We hope to see you there!

        Link to App: \(SharedURL.appStoreURL)
        """
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
        cell.bookingDateTime.text = "Purchased on \(createdAT)"
        
        if isOnlyAddOnsAvailable {
            if index == 0 {
                cell.qrImage.image = addOnsQR
                cell.addOnsBookingHasItem = selectedAddOns
            }
        } else {
            if index == 0 {
                cell.uniqueTickets = appClipTicket
            } else {
                cell.addOnsBookingHasItem = selectedAddOns
            }
            cell.qrImage.image = index == 0 ? qrImage : addOnsQR
            cell.ticketsTableView.reloadData()
        }
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

