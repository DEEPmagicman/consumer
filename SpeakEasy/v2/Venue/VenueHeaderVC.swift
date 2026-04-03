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
    
    var headerHeight: CGFloat {
        return hasAvailableTickets ? 110 : 50
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        coverTicketView.isHidden = !hasAvailableTickets
    }
    
    private var hasAvailableTickets: Bool {
        let tickets = venueDetails?.coverTicket ?? []
        
        let filtered = tickets.filter {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }
        
        return !filtered.isEmpty
    }
    
    @IBAction func onClickBuyTicket(_ sender: Any) {
        Navigate.to.coverTicketListVC(self, venueDetails: venueDetails)
    }
}
