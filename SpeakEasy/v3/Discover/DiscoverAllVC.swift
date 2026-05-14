//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit
import Combine

final class DiscoverAllVC: UIViewController {

    @IBOutlet weak var todaysEventsView: DiscoverSectionView!
    @IBOutlet weak var venuesView: DiscoverSectionView!
    @IBOutlet weak var allEventsView: DiscoverSectionView!

    @IBOutlet weak var premiumExperiencesView: UIView!
    @IBOutlet weak var premiumExerienceParentView: UIView!

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

    private let presenter = MVPPresenter()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true

        setupSections()
        bindSelectedCity()
        fetchInitialData()
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
                self,
                screenType: .discoverExperiences
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
            self?.getTonightEvent()
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

            if self.openHasMore {
                self.fetchAllOpenVenueForMVP()
            }
        }

        allEventsView.onTapSeeAll = { [weak self] in
            guard let self else { return }

            Navigate.to.eventsListVC(
                self,
                screenType: .allEvents
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

            if self.allEventHasMore {
                self.getAllEvents()
            }
        }
    }

    func fetchInitialData() {

        getTonightEvent()
        getAllEvents()
        fetchAllOpenVenueForMVP()
    }
}

// MARK: - API

private extension DiscoverAllVC {

    func getTonightEvent() {

        EventPresenter.getEvents(
            from: tonightEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in

            guard let self else { return }

            if self.tonightEventSkip == 0 {
                self.todaysEvents.removeAll()
            }

            self.todaysEvents.append(contentsOf: eventList)

            if hasMore {
                self.tonightEventSkip = self.todaysEvents.count
            }

            self.todaysEventsView.configure(
                type: .tonightEvents,
                data: .events(self.todaysEvents)
            )

            self.checkAndHideSkeleton()
        }
    }

    func getAllEvents() {

        EventPresenter.getEvents(
            from: allEventSkip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, eventList, hasMore in

            guard let self else { return }

            if self.allEventSkip == 0 {
                self.allEvents.removeAll()
            }

            self.allEvents.append(contentsOf: eventList)

            if hasMore {
                self.allEventSkip = self.allEvents.count
            }

            self.allEventHasMore = hasMore

            self.allEventsView.configure(
                type: .allEvents,
                data: .events(self.allEvents)
            )

            self.checkAndHideSkeleton()
        }
    }

    func fetchAllOpenVenueForMVP() {

        presenter.getVenueListForMVP(
            from: openFrom,
            status: VenueStatus.open.rawValue
        ) { [weak self] isSuccess, errMsg, venues, hasMore in

            guard let self else { return }

            if isSuccess {

                if self.openFrom == 0 {
                    self.openVenueList.removeAll()
                }

                self.openVenueList.append(contentsOf: venues)

                if hasMore {
                    self.openFrom = self.openVenueList.count
                }

                self.openHasMore = hasMore

                if !hasMore {
                    self.fetchAllCloseVenueForMVP()
                }

                self.venuesView.configure(
                    type: .venues,
                    data: .venues(self.openVenueList)
                )

                self.checkAndHideSkeleton()

            } else {

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )
            }
        }
    }

    func fetchAllCloseVenueForMVP() {

        presenter.getVenueListForMVP(
            from: closeFrom,
            status: VenueStatus.close.rawValue
        ) { [weak self] isSuccess, errMsg, venues, hasMore in

            guard let self else { return }

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
                    data: .venues(self.openVenueList)
                )

                self.checkAndHideSkeleton()

            } else {

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
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

        fetchInitialData()
    }

    func checkAndHideSkeleton() {

        DispatchQueue.main.async {

            (self.parent as? DiscoverVC)?
                .hideSkeletonScreen()

            self.view.isHidden = false
        }
    }
}

// MARK: - City Binding

private extension DiscoverAllVC {

    func bindSelectedCity() {

        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in

                self?.refreshAllList()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions

extension DiscoverAllVC {

    @IBAction func onClickBookNow(_ sender: Any) {

        Navigate.to.premiumExperiencesVC(self)
    }
}
