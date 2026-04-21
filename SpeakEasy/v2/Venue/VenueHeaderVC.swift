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
    @IBOutlet weak var followBtnLbl: UILabel!
    @IBOutlet weak var followBtn: UIButton!
    
    private var isFollowing: Bool = false
    private var isLoading: Bool = false
    
    var headerHeight: CGFloat {
        return hasAvailableTickets ? 110 : 50
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        coverTicketView.isHidden = !hasAvailableTickets
        
        isFollowing = venueDetails?.isFollowing ?? false
        updateFollowUI()
    }
    
    private func updateFollowUI() {
        followBtnLbl.text = isFollowing ? "Following" : "Follow"
//        followBtn.backgroundColor = isFollowing ? .lightGray : .black
//        followBtnLbl.textColor = isFollowing ? .black : .white
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
    
    @IBAction func onClickFollowBtn(_ sender: Any) {
//        guard !isLoading else { return }
        guard let venueId = venueDetails?.id else { return }
        
        isLoading = true
        isFollowing.toggle()
        updateFollowUI()
        
        if isFollowing {
            followVenueAPI(venueId: venueId)
        } else {
            unfollowVenueAPI(venueId: venueId)
        }
    }
}

extension VenueHeaderVC {
    
    private func followVenueAPI(venueId: String) {
//        APIManager.shared.followVenue(venueId: venueId) { [weak self] success in
//            guard let self = self else { return }
            self.isLoading = false
            
//            if !success {
                // revert UI if failed
                self.isFollowing = true
                self.updateFollowUI()
//            }
//        }
    }
    
    private func unfollowVenueAPI(venueId: String) {
//        APIManager.shared.unfollowVenue(venueId: venueId) { [weak self] success in
//            guard let self = self else { return }
            self.isLoading = false
//            
//            if !success {
                self.isFollowing = false
                self.updateFollowUI()
//            }
//        }
    }
}
