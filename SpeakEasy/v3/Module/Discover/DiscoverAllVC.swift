//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class DiscoverAllVC: UIViewController {

    @IBOutlet weak var todaysEventsView: DiscoverSectionView!
    @IBOutlet weak var venuesView: DiscoverSectionView!
    @IBOutlet weak var allEventsView: DiscoverSectionView!
    @IBOutlet weak var premiumExperiencesView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var scrollView: UIScrollView!

    private var todaysEvents = [Event]()
    private var allEvents = [Event]()
    private var venues = [ClipVenue]()

    private let discoverService = DiscoverService()
    private var initialLoadID = 0
    private var activeLoadShowsSkeleton = true
    private weak var refreshControl: UIRefreshControl?
    private var isNavigatingToDiscoverItem = false

    var selectedCity: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        selectedCity = UserDefault.shared.activeCity
        setupPullToRefresh()
        setupSections()
        updatePremiumExperiencePromptVisibility()
        fetchInitialData()
        
        bottomConstraint.constant = AppDesign.adaptiveConstraint(
                smallDeviceValue: 65,
                regularDeviceValue: 75
            )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isNavigatingToDiscoverItem = false
    }

    @IBAction func onClickPremiumCloseBtn(_ sender: Any) {
        dismissPremiumExperiencePrompt()
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
        setupPremiumExperienceTap()
    }

    func setupActions() {

        todaysEventsView.onTapSeeAll = { [weak self] in
            guard let self else { return }

            Navigate.to.eventsListVC(
                self,
                mode: .tonight
            )
        }

        todaysEventsView.onTapEvent = { [weak self] event, _ in
            guard let self else { return }

            self.navigateToDiscoverItem { sender in
                Navigate.eventDetailsVC(
                    sender,
                    event: event
                )
            }
        }

        venuesView.onTapSeeAll = { [weak self] in
            guard let self else { return }
            Navigate.to.allVenueVC(self)
        }

        venuesView.onTapVenue = { [weak self] venue in
            guard let self else { return }

            self.navigateToDiscoverItem { sender in
                Navigate.to.premiumVenueVC(
                    sender,
                    venueDetails: venue
                )
            }
        }

        allEventsView.onTapSeeAll = { [weak self] in
            guard let self else { return }

            Navigate.to.eventsListVC(
                self,
                mode: .cityEvents
            )
        }

        allEventsView.onTapEvent = { [weak self] event, _ in
            guard let self else { return }

            self.navigateToDiscoverItem { sender in
                Navigate.eventDetailsVC(
                    sender,
                    event: event
                )
            }
        }

    }

    func setupPremiumExperienceTap() {
        premiumExperiencesView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(onTapPremiumExperiences)
        )
        tap.delegate = self
        premiumExperiencesView.addGestureRecognizer(tap)
    }

    @objc func onTapPremiumExperiences() {
        dismissPremiumExperiencePrompt()

        NotificationCenter.default.post(
            name: .openPremiumTabFromDiscover,
            object: self,
            userInfo: ["city": selectedCity]
        )
    }

    func updatePremiumExperiencePromptVisibility() {
        premiumExperiencesView.isHidden = UserDefault.shared.hasSeenDiscoverPremiumPrompt
    }

    func dismissPremiumExperiencePrompt() {
        UserDefault.shared.hasSeenDiscoverPremiumPrompt = true
        premiumExperiencesView.isHidden = true
    }

    func navigateToDiscoverItem(_ action: @escaping (DiscoverAllVC) -> Void) {
        guard !isNavigatingToDiscoverItem,
              presentedViewController == nil
        else {
            return
        }

        isNavigatingToDiscoverItem = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            action(self)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                self?.isNavigatingToDiscoverItem = false
            }
        }
    }

    func fetchInitialData() {

        let loadID = beginInitialLoading()

        fetchDiscoverData(loadID: loadID)
    }

    func beginInitialLoading(showsSkeleton: Bool = true) -> Int {
        initialLoadID += 1
        activeLoadShowsSkeleton = showsSkeleton

        if showsSkeleton {
            view.isHidden = true

            (parent as? DiscoverVC)?
                .showSkeletonScreen()
        }

        return initialLoadID
    }

    func setupPullToRefresh() {
        guard refreshControl == nil else { return }

        let control = UIRefreshControl()
        control.tintColor = .white
        control.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        scrollView.delegate = self
        scrollView.refreshControl = control
        refreshControl = control
    }

    @objc func onPullToRefresh() {
        refreshAllList(showsSkeleton: true)
    }
}

// MARK: - API

private extension DiscoverAllVC {

    func fetchDiscoverData(loadID: Int) {

        discoverService.fetchDiscover(
            city: selectedCity,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, data in

            guard let self else { return }
            guard self.initialLoadID == loadID else { return }

            guard isSuccess,
                  let data else {

                if self.activeLoadShowsSkeleton {
                    Alert.showAlertSheet(
                        style: .alert,
                        title: errMsg ?? "Something went wrong",
                        message: ""
                    )
                }

                self.finishInitialLoad(loadID: loadID)
                return
            }

            self.todaysEvents = data.eventsTonight
            self.allEvents = data.events
            self.venues = data.venues

            self.todaysEventsView.isHidden =
            data.eventsTonight.isEmpty

            self.allEventsView.isHidden =
            data.events.isEmpty

            self.venuesView.isHidden =
            data.venues.isEmpty

            self.todaysEventsView.configure(
                type: .tonightEvents,
                data: .events(data.eventsTonight),
                city: self.selectedCity
            )

            self.venuesView.configure(
                type: .venues,
                data: .venues(data.venues),
                city: self.selectedCity
            )

            self.allEventsView.configure(
                type: .allEvents,
                data: .events(data.events),
                city: self.selectedCity
            )

            self.finishInitialLoad(loadID: loadID)
        }
    }
}

// MARK: - Refresh

private extension DiscoverAllVC {

    func refreshAllList(
        showsSkeleton: Bool = true,
        clearsExistingContent: Bool = true
    ) {

        if clearsExistingContent {
            todaysEvents.removeAll()
            allEvents.removeAll()
            venues.removeAll()

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
        }

        let loadID = beginInitialLoading(showsSkeleton: showsSkeleton)
        fetchDiscoverData(loadID: loadID)
    }

    private func finishInitialLoad(
        loadID: Int
    ) {

        guard initialLoadID == loadID else {
            return
        }

        DispatchQueue.main.async {

            if self.activeLoadShowsSkeleton {
                (self.parent as? DiscoverVC)?
                    .hideSkeletonScreen()
            }

            self.view.isHidden = false
            self.refreshControl?.endRefreshing()
        }
    }
}

// MARK: - City Reload

extension DiscoverAllVC {

    func reloadCityData(
        city: String,
        showsLoading: Bool = true
    ) {

        let resolvedCity = city
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let nextCity = resolvedCity.isEmpty
            ? UserDefault.shared.activeCity
            : resolvedCity

        guard nextCity != selectedCity else {
            return
        }

        selectedCity = nextCity

        let hasContent =
            !todaysEvents.isEmpty ||
            !allEvents.isEmpty ||
            !venues.isEmpty

        let shouldShowSkeleton =
            showsLoading || !hasContent

        refreshAllList(
            showsSkeleton: shouldShowSkeleton,
            clearsExistingContent: shouldShowSkeleton
        )
    }
}

extension DiscoverAllVC: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        var touchedView = touch.view

        while let view = touchedView {
            if view is UIControl {
                return false
            }

            touchedView = view.superview
        }

        return true
    }
}

extension DiscoverAllVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        (parent as? DiscoverVC)?
            .discoverHeaderScrollViewDidScroll(scrollView)
    }
}

extension DiscoverAllVC: DiscoverHeaderScrollable {
    var discoverHeaderScrollView: UIScrollView? {
        scrollView
    }
}
