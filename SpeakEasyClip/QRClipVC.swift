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
    private var isAlertDisplayed = false
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "CustomPagerViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
    }
    
    func loadImage() {
        DispatchQueue.global().async {
            guard let imgUrl = URL(string: "\(SharedURL.amazonStorage)\(self.venueAttachment)") else { return } //                    let logoUrl = URL(string: "\(SharedURL.amazonStorage)\(self.venueLogo)")
            do {
                let imgData = try Data(contentsOf: imgUrl)
//                let logoData = try Data(contentsOf: logoUrl)
                DispatchQueue.main.async {
//                    self.venueImg.image = UIImage(data: imgData)
//                    self.venueLogoImg.image = UIImage(data: logoData)
                }
            } catch {}
        }
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
}
