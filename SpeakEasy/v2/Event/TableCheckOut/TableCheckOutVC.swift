//
//  TableCheckOutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Deep on 03/01/26.
//

import UIKit

class TableCheckOutVC: UIViewController {
    
    @IBOutlet weak var mainContentView: UIView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueNameNavigationLbl: UILabel!
    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    
    private var tablesListVC: TablesListVC?
    
    var event: Event?
    var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = TablesListVC()
        vc.event = event
        tablesListVC = vc
        setupChildVCs()
        setupUI()
    }
    
    private func setupUI() {
        
        if let venue = event?.venue {
            self.venueDetails = venue
        }
        venueLogoImg.sd_setImage(
            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
            placeholderImage: Constant.Icon.uploadImage
        )
        venueNameLbl.text = venueDetails?.name ?? ""
        venueNameNavigationLbl.text = venueDetails?.name ?? ""
        eventNameLbl.text = event?.title
      
        if let customText = event?.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            timeLbl.text = customText
            
        } else {
            
            let timezone = venueDetails?.useTimezone ?? ""
            
            let dateText = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .EEEMMMD,
                customTimeZone: timezone
            )
            
            let startTime = event?.startDateTime.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            )
            
            let endTime = event?.endDateTime?.convertDateFormat(
                from: .yyyyMMddHHmmss,
                to: .hmma,
                customTimeZone: timezone
            ) ?? "LATE"
            
            timeLbl.text = "\(dateText ?? "") at \(startTime ?? "") - \(endTime)"
        
        }
        
        if let hex = self.event?.whiteLabelColor {
            let color = UIColor(hex: hex)
            timeLbl.textColor = color
        }
        
    }
    
    @IBAction func onCloseTapped(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    private func showChild(_ vc: UIViewController) {

        children.forEach { child in
            child.view.isHidden = true
        }

        vc.view.isHidden = false
    }
    
    private func setupChildVCs() {

        if let tablesListVC = tablesListVC {
            addChildView(tablesListVC)
        }
    }
    
    private func addChildView(_ vc: UIViewController) {
        addChild(vc)
        mainContentView.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: mainContentView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor)
        ])

        vc.didMove(toParent: self)
    }
}
