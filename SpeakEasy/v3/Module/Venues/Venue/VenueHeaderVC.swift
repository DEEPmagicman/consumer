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
    var onFollowStateChanged: ((ClipVenue, Bool) -> Void)?
    
    @IBOutlet weak var coverTicketView: UIView!
    @IBOutlet weak var followBtnLbl: UILabel!
    @IBOutlet weak var followBtn: UIButton!
    
    private var isFollowing: Bool = false
    private var isLoading: Bool = false
    private var followedVenueId: String?
    private let venueService = VenueService()
    
    var headerHeight: CGFloat {
        return 130
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        coverTicketView.layer.cornerRadius = 20
        coverTicketView.clipsToBounds = true
        coverTicketView.borderColor = UIColor(hex: "#FFFFFF", alpha: 0.10)
    }
    
    private func setupUI() {
        coverTicketView.isHidden = !hasAvailableTickets
        
        followedVenueId = venueDetails?.venueFollowedId
        isFollowing =
        venueDetails?.isFollowing == true ||
        followedVenueId != nil
        updateFollowUI()
    }
    
    private func updateFollowUI() {
        followBtnLbl.text = isFollowing ? "Following" : "Follow"
        followBtn.isUserInteractionEnabled = !isLoading
        followBtnLbl.alpha = isLoading ? 0.65 : 1
//        followBtn.backgroundColor = isFollowing ? .lightGray : .black
//        followBtnLbl.textColor = isFollowing ? .black : .white
    }

    private func applyFollowState(
        isFollowing: Bool,
        followedVenueId: String?,
        notify: Bool
    ) {
        self.isFollowing = isFollowing
        self.followedVenueId = followedVenueId
        venueDetails?.isFollowing = isFollowing
        venueDetails?.venueFollowedId = followedVenueId
        updateFollowUI()

        if notify, let venue = venueDetails {
            onFollowStateChanged?(venue, isFollowing)
        }
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
        guard !isLoading else { return }
        guard !UserDefault.shared.isGuest else { return }
        guard let venueUniqueId = venueDetails?.uniqueId else { return }
        
        let previousState = isFollowing
        let previousFollowedVenueId = followedVenueId

        isLoading = true
        isFollowing.toggle()
        updateFollowUI()
        
        if isFollowing {
            followVenueAPI(
                venueUniqueId: venueUniqueId,
                previousState: previousState,
                previousFollowedVenueId: previousFollowedVenueId
            )
        } else {
            guard let followedVenueId else {
                resolveAndUnfollowVenueAPI(
                    venueUniqueId: venueUniqueId,
                    previousState: previousState,
                    previousFollowedVenueId: previousFollowedVenueId
                )
                return
            }

            unfollowVenueAPI(
                followedVenueId: followedVenueId,
                previousState: previousState,
                previousFollowedVenueId: previousFollowedVenueId
            )
        }
    }
}

extension VenueHeaderVC {
    
    private func followVenueAPI(
        venueUniqueId: String,
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {
        venueService.followVenue(uniqueId: venueUniqueId) { [weak self] isSuccess, _, relation in
            guard let self = self else { return }
            self.isLoading = false

            guard isSuccess,
                  let id = relation?.id,
                  !id.isEmpty
            else {
                self.rollbackFollowState(
                    previousState: previousState,
                    previousFollowedVenueId: previousFollowedVenueId
                )
                return
            }

            self.applyFollowState(
                isFollowing: true,
                followedVenueId: id,
                notify: true
            )
        }
    }
    
    private func unfollowVenueAPI(
        followedVenueId: String,
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {
        venueService.unfollowVenue(followedVenueId: followedVenueId) { [weak self] isSuccess, _, _ in
            guard let self = self else { return }
            self.isLoading = false

            guard isSuccess else {
                self.rollbackFollowState(
                    previousState: previousState,
                    previousFollowedVenueId: previousFollowedVenueId
                )
                return
            }

            self.applyFollowState(
                isFollowing: false,
                followedVenueId: nil,
                notify: true
            )
        }
    }

    private func resolveAndUnfollowVenueAPI(
        venueUniqueId: String,
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {

        venueService.fetchFollowedVenueId(
            uniqueId: venueUniqueId,
            search: venueDetails?.name
        ) { [weak self] followedVenueId in

            guard let self = self else { return }

            guard let followedVenueId,
                  !followedVenueId.isEmpty
            else {

                self.rollbackFollowState(
                    previousState: previousState,
                    previousFollowedVenueId: previousFollowedVenueId
                )
                return
            }

            self.followedVenueId = followedVenueId
            self.venueDetails?.venueFollowedId = followedVenueId

            self.unfollowVenueAPI(
                followedVenueId: followedVenueId,
                previousState: previousState,
                previousFollowedVenueId: previousFollowedVenueId
            )
        }
    }

    private func rollbackFollowState(
        previousState: Bool,
        previousFollowedVenueId: String?
    ) {
        isLoading = false
        applyFollowState(
            isFollowing: previousState,
            followedVenueId: previousFollowedVenueId,
            notify: false
        )
    }
}
