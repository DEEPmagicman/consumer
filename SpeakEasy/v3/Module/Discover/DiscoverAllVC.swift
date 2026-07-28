//
//  DiscoverAllVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class DiscoverAllVC: UIViewController {

    private enum Layout {
        static let smallDeviceBottomSpacing: CGFloat = 65
        static let regularDeviceBottomSpacing: CGFloat = 75
        static let navigationResetDelay: TimeInterval = 0.75
    }

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
    private let noInternetView = V3NoInternetView()
    private let emptyStateView = V3EmptyStateView(style: .mapVenues)

    var selectedCity: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.isHidden = true
        selectedCity = UserDefault.shared.activeCity
        setupPullToRefresh()
        setupSections()
        setupNoInternetView()
        setupEmptyStateView()
        updatePremiumExperiencePromptVisibility()
        fetchInitialData()
        
        bottomConstraint.constant = AppDesign.adaptiveConstraint(
                smallDeviceValue: Layout.smallDeviceBottomSpacing,
                regularDeviceValue: Layout.regularDeviceBottomSpacing
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
        configureSections()
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

    func setupNoInternetView() {
        noInternetView.isHidden = true
        noInternetView.onTryAgain = { [weak self] in
            self?.refreshAllList(showsSkeleton: true)
        }
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noInternetView)

        NSLayoutConstraint.activate([
            noInternetView.topAnchor.constraint(equalTo: view.topAnchor),
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupEmptyStateView() {
        emptyStateView.isHidden = true
        emptyStateView.isUserInteractionEnabled = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func onTapPremiumExperiences() {

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

            DispatchQueue.main.asyncAfter(deadline: .now() + Layout.navigationResetDelay) { [weak self] in
                self?.isNavigatingToDiscoverItem = false
            }
        }
    }

    func configureSections(
        city: String? = nil,
        tonightEvents: [Event] = [],
        venues: [ClipVenue] = [],
        allEvents: [Event] = []
    ) {
        let city = city ?? selectedCity

        todaysEventsView.configure(
            type: .tonightEvents,
            data: .events(tonightEvents),
            city: city
        )

        venuesView.configure(
            type: .venues,
            data: .venues(venues),
            city: city
        )

        allEventsView.configure(
            type: .allEvents,
            data: .events(allEvents),
            city: city
        )
    }

    func clearSectionContent() {
        todaysEvents.removeAll()
        allEvents.removeAll()
        venues.removeAll()
        configureSections()
    }

    func applyDiscoverData(_ data: DiscoverHomeData) {
        todaysEvents = data.eventsTonight
        allEvents = data.events
        venues = data.venues

        todaysEventsView.isHidden = data.eventsTonight.isEmpty
        allEventsView.isHidden = data.events.isEmpty
        venuesView.isHidden = data.venues.isEmpty

        configureSections(
            city: selectedCity,
            tonightEvents: data.eventsTonight,
            venues: data.venues,
            allEvents: data.events
        )
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

                if V3NoInternetView.isNoInternet(errMsg) {
                    self.showNoInternetView()
                    self.finishInitialLoad(loadID: loadID)
                    return
                }

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

            self.hideNoInternetView()
            self.applyDiscoverData(data)
            self.updateEmptyStateVisibility()
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
            clearSectionContent()
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

    func showNoInternetView() {
        todaysEventsView.isHidden = true
        allEventsView.isHidden = true
        venuesView.isHidden = true
        premiumExperiencesView.isHidden = true
        emptyStateView.isHidden = true
        noInternetView.isHidden = false
        view.bringSubviewToFront(noInternetView)
    }

    func hideNoInternetView() {
        noInternetView.isHidden = true
        updatePremiumExperiencePromptVisibility()
    }

    func updateEmptyStateVisibility() {
        let shouldShow =
        noInternetView.isHidden &&
        todaysEvents.isEmpty &&
        allEvents.isEmpty &&
        venues.isEmpty

        emptyStateView.isHidden = !shouldShow

        if shouldShow {
            premiumExperiencesView.isHidden = true
            view.bringSubviewToFront(emptyStateView)
        } else if noInternetView.isHidden {
            updatePremiumExperiencePromptVisibility()
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
