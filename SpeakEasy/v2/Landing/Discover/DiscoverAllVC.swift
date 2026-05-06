import UIKit
import Combine
import Hero

final class DiscoverAllVC: UIViewController {
    
    @IBOutlet weak var tonightEventCollectionView: UICollectionView!
    @IBOutlet weak var venueListCollectionView: UICollectionView!
    @IBOutlet weak var allEventsCollectionView: UICollectionView!
    @IBOutlet weak var venueTitleLable: UILabel!
    @IBOutlet weak var todaysEventsView: UIView!
    @IBOutlet weak var premiumExperiencesView: UIView!
    @IBOutlet weak var premiumExerienceParentView: UIView!
    @IBOutlet weak var eventsInCityTitleLbl: UILabel!
    @IBOutlet weak var eventsInCityView: UIView!

    // NOTE: shimmerView removed from here — it lives in parent DiscoverVC

    // MARK: - Loading States
    var isTonightEventInitialLoading = true
    var isAllEventInitialLoading     = true
    var isVenueInitialLoading        = true
    
    // MARK: - Venue
    private var openVenueList  = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()
    private var openFrom       = 0
    private var closeFrom      = 0
    private var openHasMore    = false
    private var closeHasMore   = false
    
    // MARK: - Tonight Events
    private var tonightEventSkip = 0
    private var todaysEvents     = [Event]()
    
    // MARK: - All Events
    private var allEventSkip  = 0
    private var allEvents     = [Event]()
    private var allEventHasMore = false
    
    private var presenter    = MVPPresenter()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        bindSelectedCity()
        setupHero()
        setVenueListForSelectedCity()
        
        getTonightEvent()
        getAllEvents()
        
        premiumExperiencesView.setHorizontalGradientColor(
            colors: [
                UIColor(hex: "#292929").withAlphaComponent(0.1).cgColor,
                UIColor(hex: "#FFCE51").withAlphaComponent(0.1).cgColor
            ]
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        premiumExperiencesView.setHorizontalGradientColor(
            colors: [
                UIColor(hex: "#292929").withAlphaComponent(0.1).cgColor,
                UIColor(hex: "#FFCE51").withAlphaComponent(0.1).cgColor
            ]
        )
    }
    
    // MARK: - Setup

    private func registerCells() {
        tonightEventCollectionView.register(EventCVC.nib,    forCellWithReuseIdentifier: EventCVC.identifier)
        venueListCollectionView.register(VenueCVC.nib,       forCellWithReuseIdentifier: VenueCVC.identifier)
        allEventsCollectionView.register(EventV2CVC.nib,     forCellWithReuseIdentifier: EventV2CVC.identifier)
    }
    
    private func setupHero() {
        hero.isEnabled = true
        navigationController?.hero.isEnabled = true
        navigationController?.hero.navigationAnimationType = .auto
    }

    // MARK: - Skeleton control

    /// Checks if ALL three APIs have finished.
    /// Only when all three are done does it tell the parent to hide the shimmer.
    private func checkAndHideSkeleton() {
        guard !isTonightEventInitialLoading,
              !isAllEventInitialLoading,
              !isVenueInitialLoading else { return }

        DispatchQueue.main.async {
            (self.parent as? DiscoverVC)?.hideSkeletonScreen()
        }
    }
    
    // MARK: - API Calls
    
    private func getTonightEvent() {
        EventPresenter.getEvents(
            from: tonightEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in
            guard let self else { return }
            
            if self.tonightEventSkip == 0 { self.todaysEvents.removeAll() }
            self.todaysEvents.append(contentsOf: eventList)
            if hasMore { self.tonightEventSkip = self.todaysEvents.count }
            
            self.isTonightEventInitialLoading       = false
            self.todaysEventsView.isHidden          = self.todaysEvents.isEmpty
            self.tonightEventCollectionView.reloadData()

            self.checkAndHideSkeleton()  // ✅ check after this API done
        }
    }
    
    private func getAllEvents() {
        EventPresenter.getEvents(
            from: allEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in
            guard let self else { return }
            
            if self.allEventSkip == 0 { self.allEvents.removeAll() }
            self.allEvents.append(contentsOf: eventList)
            if hasMore { self.allEventSkip = self.allEvents.count }
            
            self.allEventHasMore                   = hasMore
            self.isAllEventInitialLoading          = false
            self.eventsInCityView.isHidden         = self.allEvents.isEmpty
            self.allEventsCollectionView.reloadData()

            self.checkAndHideSkeleton()  // ✅ check after this API done
        }
    }
    
    private func fetchAllOpenVenueForMVP() {
        presenter.getVenueListForMVP(from: openFrom, status: VenueStatus.open.rawValue) { [weak self] isSuccess, errMsg, venues, hasMore in
            guard let self else { return }
            
            if isSuccess {
                if self.openFrom == 0 { self.openVenueList.removeAll() }
                self.openVenueList.append(contentsOf: venues)
                if hasMore { self.openFrom = self.openVenueList.count }
                self.openHasMore = hasMore

                if !hasMore { self.fetchAllCloseVenueForMVP() }

                self.isVenueInitialLoading = false
                self.venueListCollectionView.reloadData()

                // ✅ Only check here if there are no close venues to fetch
                // fetchAllCloseVenueForMVP will call checkAndHideSkeleton itself
                if hasMore { self.checkAndHideSkeleton() }

            } else {
                // API failed — still mark done so shimmer doesn't hang forever
                self.isVenueInitialLoading = false
                self.checkAndHideSkeleton()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? "Something went wrong", message: "")
            }
        }
    }
    
    private func fetchAllCloseVenueForMVP() {
        presenter.getVenueListForMVP(from: closeFrom, status: VenueStatus.close.rawValue) { [weak self] isSuccess, errMsg, venues, hasMore in
            guard let self else { return }
            
            if isSuccess {
                if self.closeFrom == 0 { self.closeVenueList.removeAll() }
                self.closeVenueList.append(contentsOf: venues)
                self.openVenueList.append(contentsOf: venues)
                if hasMore { self.closeFrom = self.closeVenueList.count }
                
                self.closeHasMore          = hasMore
                self.isVenueInitialLoading = false
                self.venueListCollectionView.reloadData()

                self.checkAndHideSkeleton()  // ✅ final venue API done

            } else {
                self.isVenueInitialLoading = false
                self.checkAndHideSkeleton()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? "Something went wrong", message: "")
            }
        }
    }
    
    // MARK: - DiscoverAllVC — fix openEventDetails completely

    private func openEventDetails(_ collectionView: UICollectionView,
                                   event: Event,
                                   indexPath: IndexPath) {
        let suffix = collectionView.accessibilityIdentifier ?? ""

        // ✅ Step 1 — clear ALL hero IDs across ALL collection views first
        clearAllHeroIDs()

        // ✅ Step 2 — set ONLY the tapped cell
        if let cell = collectionView.cellForItem(at: indexPath) as? EventCVC {
            cell.applyHeroIDs(event: event, suffix: suffix)
        } else if let cell = collectionView.cellForItem(at: indexPath) as? EventV2CVC {
            cell.image.hero.id     = "event.image.\(event.id ?? "").\(suffix)"
            cell.eventName.hero.id = "event.title.\(event.id ?? "").\(suffix)"
        }

        Navigate.eventDetailsVC(self, event: event, heroSuffix: suffix)

        // ✅ Step 3 — clear immediately after push so back-transition is clean
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.clearAllHeroIDs()
        }
    }

    // ✅ Clears ALL cells across ALL three collection views
    private func clearAllHeroIDs() {
        tonightEventCollectionView.visibleCells.forEach {
            ($0 as? EventCVC)?.clearHeroIDs()
        }
        allEventsCollectionView.visibleCells.forEach {
            ($0 as? EventCVC)?.clearHeroIDs()
            ($0 as? EventV2CVC)?.clearHeroIDs()
        }
    }
    
    // MARK: - Refresh
    // Called on city change — re-show parent shimmer then reload everything

    private func refreshAllList() {
        isTonightEventInitialLoading = true
        isAllEventInitialLoading     = true
        isVenueInitialLoading        = true

        // Tell parent to show shimmer again while we reload
        (parent as? DiscoverVC)?.showSkeletonScreen()
        
        todaysEvents.removeAll()
        allEvents.removeAll()
        openVenueList.removeAll()
        closeVenueList.removeAll()
        
        tonightEventSkip = 0
        allEventSkip     = 0
        openFrom         = 0
        closeFrom        = 0
        
        tonightEventCollectionView.reloadData()
        allEventsCollectionView.reloadData()
        venueListCollectionView.reloadData()
        
        getTonightEvent()
        getAllEvents()
        fetchAllOpenVenueForMVP()
    }
    
    // MARK: - City Binding
    
    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.setVenueListForSelectedCity()
                self?.refreshAllList()
            }
            .store(in: &cancellables)
    }
    
    private func resolvedCity() -> String {
        let city = UserDefault.shared.localCity.trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty ? "New York" : city
    }
    
    private func setVenueListForSelectedCity() {
        let city = resolvedCity()
        venueTitleLable.text      = "Venues in \(city)"
        eventsInCityTitleLbl.text = "Events in \(city)"
        fetchAllOpenVenueForMVP()
    }
    
    // MARK: - Actions

    @IBAction func onClickBookNow(_ sender: Any) {
        Navigate.to.premiumExperiencesVC(self)
    }

    @IBAction func onClickVenueSeeAllBtn(_ sender: Any) {
        Navigate.to.allVenueVC(self)
    }

    @IBAction func onClickDiscoverSeeAllBtn(_ sender: Any) {
        Navigate.to.eventsListVC(self, screenType: .discoverExperiences)
    }

    @IBAction func onClickEventsSeeAllBtn(_ sender: Any) {
        Navigate.to.eventsListVC(self, screenType: .allEvents)
    }
}

// MARK: - CollectionView

extension DiscoverAllVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case venueListCollectionView:   return isVenueInitialLoading       ? 0 : min(openVenueList.count, 5)
        case tonightEventCollectionView: return isTonightEventInitialLoading ? 0 : todaysEvents.count
        case allEventsCollectionView:   return isAllEventInitialLoading    ? 0 : allEvents.count
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
            
        case tonightEventCollectionView:
            let cell: EventCVC = collectionView.dequeue(
                withIdentifier: EventCVC.identifier, for: indexPath)
            cell.bgImg.hero.id        = nil
            cell.eventTitleLbl.hero.id = nil
            // No cell shimmer — full-screen skeleton covers this
            cell.setupData(event: todaysEvents[indexPath.item])
            return cell
            
        case venueListCollectionView:
            let cell: VenueCVC = collectionView.dequeue(
                withIdentifier: VenueCVC.identifier, for: indexPath)
            cell.configure(with: openVenueList[indexPath.item])
            return cell
            
        case allEventsCollectionView:
            let cell: EventV2CVC = collectionView.dequeue(
                withIdentifier: EventV2CVC.identifier, for: indexPath)
            cell.image.hero.id     = nil
            cell.eventName.hero.id = nil
            cell.setupData(event: allEvents[indexPath.item])
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case tonightEventCollectionView:
            openEventDetails(collectionView,
                             event: todaysEvents[indexPath.item],
                             indexPath: indexPath)
        case allEventsCollectionView:
            openEventDetails(collectionView,
                             event: allEvents[indexPath.item],
                             indexPath: indexPath)
        case venueListCollectionView:
            Navigate.to.venueVC(self, venueDetails: openVenueList[indexPath.item])
        default:
            break
        }
    }
    
}

import UIKit

// MARK: - ShimmerView
// Single reusable shimmer tile. Add as subview, call startAnimating().


// MARK: - HomeSkeletonView
// Place this as a full-screen overlay on top of DiscoverAllVC's root view.
// Call startShimmer() to show, stopShimmer() to hide.

final class HomeSkeletonView: UIView {

    private var allShimmerViews: [ShimmerView] = []
    private var didSetup = false

    // MARK: - Layout trigger

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didSetup, bounds.width > 0 else { return }
        didSetup = true
        setupUI()
    }

    // MARK: - Build skeleton layout

    private func setupUI() {
        backgroundColor = UIColor(hex: "#111111")

        let W       = bounds.width
        let pad: CGFloat = 16
        var y: CGFloat   = 20

        // ─────────────────────────────────────────
        // 1.  FILTER CHIPS  (New York | All Dates | Premium Experiences)
        // ─────────────────────────────────────────
        let chipWidths: [CGFloat] = [90, 80, 150]
        var chipX: CGFloat = pad
        for cw in chipWidths {
            make(CGRect(x: chipX, y: y, width: cw, height: 32), corner: 16)
            chipX += cw + 10
        }
        y += 32 + 28

        // ─────────────────────────────────────────
        // 2.  "EVENTS TONIGHT" section
        // ─────────────────────────────────────────

        // Section header: title + "See all"
        make(CGRect(x: pad,       y: y, width: 140, height: 15), corner: 6)
        make(CGRect(x: W - pad - 48, y: y, width: 48, height: 13), corner: 6)
        y += 15 + 14

        // Event cards  —  298 × 298 image, 3 text skeleton lines inside at bottom
        let eventCardW: CGFloat = 298
        let eventCardH: CGFloat = 298

        // Bottom text block height: 3 lines × ~14pt + 2 gaps × 8pt = 58pt + 12pt padding = 70pt
        let textBlockH: CGFloat = 70

        var cardX: CGFloat = pad
        for _ in 0..<2 {

            // ── shimmer card (uniform colour, no split) ──
            make(CGRect(x: cardX, y: y,
                        width: eventCardW, height: eventCardH), corner: 12)

            // text lines start 12pt from card bottom, inset 12pt from card edge
            let tx  = cardX + 12
            let ty1 = y + eventCardH - textBlockH + 10     // title
            let ty2 = ty1 + 22                              // venue
            let ty3 = ty2 + 20                              // date

            // title  — lighter shimmer so it stands out against the card bg
            makeLighter(CGRect(x: tx, y: ty1,
                               width: eventCardW * 0.80, height: 13), corner: 6)
            // venue name
            makeLighter(CGRect(x: tx, y: ty2,
                               width: 85, height: 11), corner: 5)
            // date / time
            makeLighter(CGRect(x: tx, y: ty3,
                               width: 130, height: 11), corner: 5)

            cardX += eventCardW + 12
        }

        y += eventCardH + 24

        // ─────────────────────────────────────────
        // 3.  "VENUES IN CITY" section
        // ─────────────────────────────────────────
        make(CGRect(x: pad, y: y, width: 150, height: 15), corner: 6)
        make(CGRect(x: W - pad - 48, y: y, width: 48, height: 13), corner: 6)
        y += 15 + 14

        let venueCardW: CGFloat = 156
        let venueCardH: CGFloat = 156
        var venueX: CGFloat = pad
        for _ in 0..<3 {
            make(CGRect(x: venueX, y: y,
                        width: venueCardW, height: venueCardH), corner: 12)
            make(CGRect(x: venueX, y: y + venueCardH + 8,
                        width: venueCardW * 0.75, height: 11), corner: 5)
            make(CGRect(x: venueX, y: y + venueCardH + 8 + 16,
                        width: venueCardW * 0.55, height: 10), corner: 5)
            venueX += venueCardW + 12
        }

        y += venueCardH + 8 + 16 + 10 + 28

        // ─────────────────────────────────────────
        // 4.  "EVENTS IN CITY" section
        // ─────────────────────────────────────────
//        make(CGRect(x: pad,       y: y, width: 140, height: 15), corner: 6)
//        make(CGRect(x: W - pad - 48, y: y, width: 48, height: 13), corner: 6)
//        y += 15 + 14
//
//        let allEventW: CGFloat = W - pad * 2
//        let allEventH: CGFloat = 180
//        for i in 0..<2 {
//            let ey = y + CGFloat(i) * (allEventH + 14)
//            make(CGRect(x: pad, y: ey,
//                        width: allEventW, height: allEventH), corner: 12)
//            make(CGRect(x: pad, y: ey + allEventH + 6,
//                        width: allEventW * 0.7, height: 13), corner: 6)
//            make(CGRect(x: pad, y: ey + allEventH + 6 + 18,
//                        width: allEventW * 0.45, height: 11), corner: 5)
//        }
    }

    // MARK: - Helpers

    /// Standard shimmer tile — same base colour as card backgrounds.
    private func make(_ frame: CGRect, corner: CGFloat = 8) {
        let sv = ShimmerView(frame: frame)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    /// Slightly lighter shimmer tile — used for text skeleton lines that sit
    /// INSIDE a card so they remain visible against the card background.
    private func makeLighter(_ frame: CGRect, corner: CGFloat = 6) {
        let sv = ShimmerView(frame: frame, lighter: true)
        sv.layer.cornerRadius = corner
        sv.clipsToBounds = true
        addSubview(sv)
        allShimmerViews.append(sv)
    }

    // MARK: - Public control

    func startShimmer() {
        isHidden = false
        allShimmerViews.forEach { $0.startAnimating() }
    }

    func stopShimmer() {
        allShimmerViews.forEach { $0.stopAnimating() }
        isHidden = true
    }
}


extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255,
            blue:  CGFloat( rgb & 0x0000FF)         / 255,
            alpha: alpha
        )
    }
}
