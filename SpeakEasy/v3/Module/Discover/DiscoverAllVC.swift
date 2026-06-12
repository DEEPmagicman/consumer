//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit
import Combine

final class DiscoverAllVC: UIViewController {

    private enum InitialLoadSection: CaseIterable, Hashable {
        case tonightEvents
        case venues
        case allEvents
    }

    @IBOutlet weak var todaysEventsView: DiscoverSectionView!
    @IBOutlet weak var venuesView: DiscoverSectionView!
    @IBOutlet weak var allEventsView: DiscoverSectionView!
    @IBOutlet weak var premiumExperiencesView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    private var openVenueList = [ClipVenue]()
    private var closeVenueList = [ClipVenue]()

    private var openFrom = 0
    private var closeFrom = 0

    private var openHasMore = false
    private var closeHasMore = false

    private var tonightEventSkip = 0
    private var todaysEvents = [Event]()

    private var allEventSkip = 0
    private var allEvents = [Event]()
    private var allEventHasMore = false

    private let venueService = VenueService()
    private let eventService = EventService()
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingInitialLoadSections =
        Set(InitialLoadSection.allCases)
    private var initialLoadID = 0

    var selectedCity: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        selectedCity = UserDefault.shared.localCity
        setupSections()
        fetchInitialData()
        
        bottomConstraint.constant = AppDesign.adaptiveConstraint(
                smallDeviceValue: 65,
                regularDeviceValue: 75
            )
    }

    @IBAction func onClickPremiumCloseBtn(_ sender: Any) {
        premiumExperiencesView.isHidden = true
    }
}

// MARK: - Setup

private extension DiscoverAllVC {

    func setupSections() {

        todaysEventsView.configure(
            type: .tonightEvents,
            data: .events([])
        )

        venuesView.configure(
            type: .venues,
            data: .venues([])
        )

        allEventsView.configure(
            type: .allEvents,
            data: .events([])
        )

        setupActions()
    }

    func setupActions() {

        todaysEventsView.onTapSeeAll = { [weak self] in
            guard let self else { return }

            Navigate.to.eventsListVC(
                self
            )
        }

        todaysEventsView.onTapEvent = { [weak self] event, _ in
            guard let self else { return }

            Navigate.eventDetailsVC(
                self,
                event: event
            )
        }

        todaysEventsView.onReachEnd = { [weak self] in
//            self?.getTonightEvent()
        }

        venuesView.onTapSeeAll = { [weak self] in
            guard let self else { return }
            Navigate.to.allVenueVC(self)
        }

        venuesView.onTapVenue = { [weak self] venue in
            guard let self else { return }

            Navigate.to.venueVC(
                self,
                venueDetails: venue
            )
        }

        venuesView.onReachEnd = { [weak self] in
            guard let self else { return }

//            if self.openHasMore {
//                self.fetchAllOpenVenueForMVP()
//            }
        }

        allEventsView.onTapSeeAll = { [weak self] in
            guard let self else { return }

            Navigate.to.eventsListVC(
                self
            )
        }

        allEventsView.onTapEvent = { [weak self] event, _ in
            guard let self else { return }

            Navigate.eventDetailsVC(
                self,
                event: event
            )
        }

        allEventsView.onReachEnd = { [weak self] in
            guard let self else { return }

//            if self.allEventHasMore {
//                self.getAllEvents()
//            }
        }
    }

    func fetchInitialData() {

        let loadID = beginInitialLoading()

        getTonightEvent(loadID: loadID)
        getAllEvents(loadID: loadID)
        fetchAllOpenVenueForMVP(loadID: loadID)
    }

    func beginInitialLoading() -> Int {
        initialLoadID += 1

        pendingInitialLoadSections =
            Set(InitialLoadSection.allCases)

        view.isHidden = true

        (parent as? DiscoverVC)?
            .showSkeletonScreen()

        return initialLoadID
    }
}

// MARK: - API

private extension DiscoverAllVC {

    func getTonightEvent(loadID: Int) {

        eventService.fetchEvents(
            from: tonightEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: selectedCity
        ) { [weak self] _, _, eventList, hasMore in

            guard let self else { return }
            guard self.initialLoadID == loadID else { return }

            if self.tonightEventSkip == 0 {
                self.todaysEvents.removeAll()
            }

            self.todaysEvents.append(contentsOf: eventList)

            if hasMore {
                self.tonightEventSkip = self.todaysEvents.count
            }

            if todaysEvents.isEmpty {
                todaysEventsView.isHidden = true
            } else {
                todaysEventsView.isHidden = false

                self.todaysEventsView.configure(
                    type: .tonightEvents,
                    data: .events(self.todaysEvents),
                    city: selectedCity
                )
            }

            self.markInitialLoadFinished(
                .tonightEvents,
                loadID: loadID
            )
        }
    }

    func getAllEvents(loadID: Int) {

        eventService.fetchEvents(
            from: allEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: selectedCity
        ) { [weak self] _, _, eventList, hasMore in

            guard let self else { return }
            guard self.initialLoadID == loadID else { return }

            if self.allEventSkip == 0 {
                self.allEvents.removeAll()
            }

            self.allEvents.append(contentsOf: eventList)

            if hasMore {
                self.allEventSkip = self.allEvents.count
            }

            self.allEventHasMore = hasMore

            if allEvents.isEmpty {
                allEventsView.isHidden = true
            } else {
                allEventsView.isHidden = false

                self.allEventsView.configure(
                    type: .allEvents,
                    data: .events(self.allEvents),
                    city: selectedCity
                )
            }

            self.markInitialLoadFinished(
                .allEvents,
                loadID: loadID
            )
        }
    }

    func fetchAllOpenVenueForMVP(loadID: Int) {

        venueService.fetchVenuesForDiscover(
            skip: openFrom,
            bookingStatus: VenueStatus.open.rawValue, city: selectedCity
        ) { [weak self] isSuccess, errMsg, venues, hasMore in

            guard let self else { return }
            guard self.initialLoadID == loadID else { return }

            if isSuccess {

                if self.openFrom == 0 {
                    self.openVenueList.removeAll()
                }

                self.openVenueList.append(contentsOf: venues)

                if hasMore {
                    self.openFrom = self.openVenueList.count
                }

                self.openHasMore = hasMore

                self.venuesView.configure(
                    type: .venues,
                    data: .venues(self.openVenueList),
                    city: selectedCity
                )

                if hasMore {
                    self.markInitialLoadFinished(
                        .venues,
                        loadID: loadID
                    )
                } else {
                    self.fetchAllCloseVenueForMVP(loadID: loadID)
                }

            } else {

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )

                self.markInitialLoadFinished(
                    .venues,
                    loadID: loadID
                )
            }
        }
    }

    func fetchAllCloseVenueForMVP(loadID: Int) {

        venueService.fetchVenuesForDiscover(
            skip: closeFrom,
            bookingStatus: VenueStatus.close.rawValue, city: selectedCity
        ) { [weak self] isSuccess, errMsg, venues, hasMore in

            guard let self else { return }
            guard self.initialLoadID == loadID else { return }

            if isSuccess {

                if self.closeFrom == 0 {
                    self.closeVenueList.removeAll()
                }

                self.closeVenueList.append(contentsOf: venues)

                self.openVenueList.append(contentsOf: venues)

                if hasMore {
                    self.closeFrom = self.closeVenueList.count
                }

                self.closeHasMore = hasMore

                self.venuesView.configure(
                    type: .venues,
                    data: .venues(self.openVenueList),
                    city: selectedCity
                )

                self.markInitialLoadFinished(
                    .venues,
                    loadID: loadID
                )

            } else {

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )

                self.markInitialLoadFinished(
                    .venues,
                    loadID: loadID
                )
            }
        }
    }
}

// MARK: - Refresh

private extension DiscoverAllVC {

    func refreshAllList() {

        todaysEvents.removeAll()
        allEvents.removeAll()

        openVenueList.removeAll()
        closeVenueList.removeAll()

        tonightEventSkip = 0
        allEventSkip = 0

        openFrom = 0
        closeFrom = 0

        todaysEventsView.configure(
            type: .tonightEvents,
            data: .events([]),
            city: selectedCity
        )

        venuesView.configure(
            type: .venues,
            data: .venues([]),
            city: selectedCity
        )

        allEventsView.configure(
            type: .allEvents,
            data: .events([]),
            city: selectedCity
        )

        fetchInitialData()
    }

    private func markInitialLoadFinished(
        _ section: InitialLoadSection,
        loadID: Int
    ) {

        guard initialLoadID == loadID else {
            return
        }

        pendingInitialLoadSections.remove(section)
        checkAndHideSkeleton()
    }

    func checkAndHideSkeleton() {

        guard pendingInitialLoadSections.isEmpty else {
            return
        }

        DispatchQueue.main.async {

            (self.parent as? DiscoverVC)?
                .hideSkeletonScreen()

            self.view.isHidden = false
        }
    }
}

// MARK: - City Reload

extension DiscoverAllVC {

    func reloadCityData(city: String) {

        selectedCity = city
        refreshAllList()
    }
}
