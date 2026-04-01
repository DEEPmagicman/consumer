//
//  VenueHeaderVC.swift
//  Doorman
//
//  Created by Square Infosoft on 28/03/25.
//

protocol ScrollCallBackDelegate: AnyObject {
  func onChangeScrollListener(lastContentOffset: CGFloat, offSet: CGFloat)
}

import UIKit

final class VenueHeaderVC: UIViewController {
    
    var venueDetails: ClipVenue?
    
    @IBOutlet weak var coverTicketView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let isEmpty = venueDetails?.coverTicket?.isEmpty ?? true
        coverTicketView.isHidden = isEmpty
    }
    
    
    
    @IBAction func onClickBuyTicket(_ sender: Any) {
        Navigate.to.coverTicketListVC(self, venueDetails: venueDetails)
    }
}
