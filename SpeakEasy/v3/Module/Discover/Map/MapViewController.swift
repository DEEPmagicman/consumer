//
//  MapViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit
import CoreLocation
import GoogleMaps
import SDWebImage

final class SegmentedTabView: UIView {

    var onSelectionChanged: ((Int) -> Void)?

    private(set) var selectedIndex: Int = 0 {
        didSet { updateSelection(animated: true) }
    }

    // MARK: - Private UI
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var buttons: [UIButton] = []
    private var indicatorLeading: NSLayoutConstraint!
    private var indicatorWidth: NSLayoutConstraint!

    private let items: [String]

    // MARK: - Init
    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.items = []
        super.init(coder: coder)
        setup()
    }

    deinit {
        onSelectionChanged = nil
        buttons.forEach {
            $0.removeTarget(nil, action: nil, for: .allEvents)
        }
    }

    // MARK: - Setup
    private func setup() {
        addSubview(stackView)
        addSubview(separatorLine)
        addSubview(indicatorView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Placeholder constraints — updated in layoutSubviews once width is known
        indicatorLeading = indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor)
        indicatorWidth = indicatorView.widthAnchor.constraint(equalToConstant: 44)
        indicatorLeading.isActive = true
        indicatorWidth.isActive = true

        for (index, title) in items.enumerated() {
            let btn = makeButton(title: title, index: index)
            buttons.append(btn)
            stackView.addArrangedSubview(btn)
        }
    }

    private func makeButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        // Default state — inactive color
        btn.setAttributedTitle(attributedTitle(title, isSelected: false), for: .normal)
        btn.setAttributedTitle(attributedTitle(title, isSelected: true), for: .selected)
        return btn
    }

    private func attributedTitle(_ text: String, isSelected: Bool) -> NSAttributedString {
        let color: UIColor = isSelected ? .white : UIColor(hex: "#737373")
        let font = UIFont(name: "Geist-SemiBold", size: 17)
            ?? UIFont.systemFont(ofSize: 17, weight: .semibold)

        return NSAttributedString(
            string: text,
            attributes: [.foregroundColor: color, .font: font]
        )
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !buttons.isEmpty else { return }
        let tabWidth = bounds.width / CGFloat(items.count)
        indicatorWidth.constant = tabWidth
        indicatorLeading.constant = CGFloat(selectedIndex) * tabWidth
    }

    // MARK: - Actions
    @objc private func tabTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        AppHaptic.selectionChanged()
        selectedIndex = sender.tag
        onSelectionChanged?(selectedIndex)
    }

    // MARK: - Update UI
    private func updateSelection(animated: Bool) {
        // Update button selected states
        for btn in buttons {
            btn.isSelected = btn.tag == selectedIndex
        }

        // Slide indicator
        let tabWidth = bounds.width / CGFloat(items.count)
        indicatorLeading.constant = CGFloat(selectedIndex) * tabWidth

        let update = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: update)
        } else {
            update()
        }
    }

    // MARK: - Public API
    func selectTab(at index: Int, animated: Bool = true) {
        guard index < items.count else { return }
        if animated {
            selectedIndex = index
        } else {
            selectedIndex = index
            updateSelection(animated: false)
        }
    }
}

class MapViewController: UIViewController {

    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var browsingLbl: UILabel!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var bottomPanelView: UIView!
    @IBOutlet weak var bottomPanelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedCityLbl: UILabel!
    private weak var cityChipView: UIView?
    private var cityChipWidthConstraint: NSLayoutConstraint?
    private var googleMapView: GMSMapView?
    private let discoverService = DiscoverService()

    // MARK: - Tab Bar
    private let segmentedTab = SegmentedTabView(items: ["Venues", "Events"])

    private var selectedIndex: Int = 0
    private var venueList: [ClipVenue] = []
    private var eventList: [Event] = []
    private var venueSkip = 0
    private var eventSkip = 0
    private var hasMoreVenues = true
    private var hasMoreEvents = true
    private var isLoadingVenues = false
    private var isLoadingEvents = false
    private var isInitialLoadingVenues = false
    private var isInitialLoadingEvents = false
    private var isPaginatingVenues = false
    private var isPaginatingEvents = false
    private var didReleaseOffscreenHeavyResources = false
    private var hasReleasedResources = false
    private var venueLoadID = 0
    private var eventLoadID = 0
    private let bottomPanelCollapsedHeight: CGFloat = 400
    private let bottomPanelCollapsedCornerRadius: CGFloat = 20
    private var bottomPanelPanStartHeight: CGFloat = 400
    private var isDraggingBottomPanelFromTable = false
    private var screenFilterCity: String?
    private var isBottomPanelExpanded: Bool {
        bottomPanelHeightConstraint.constant >= bottomPanelExpandedHeight - 1
    }
    private var bottomPanelExpandedHeight: CGFloat {
        let tabBottom = tabView.convert(tabView.bounds, to: view).maxY
        return max(bottomPanelCollapsedHeight, view.bounds.height - tabBottom)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSegmentedTab()
        setupCityChipLayout()
        setupTableView()
        setupMapView()
        setupBottomPanelGesture()
        setupBottomPanelAppearance()
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        updateBrowsingTitle()
        resetDataAndFetchCurrentTab()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreOffscreenHeavyResourcesIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isLeavingScreenPermanently {
            releaseResources()
        } else {
            releaseOffscreenHeavyResources()
        }
    }

    deinit {
        releaseResources()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.applyScreenBgGradient()
    }
    // MARK: - Setup Segmented Tab

    private func setupSegmentedTab() {
        segmentedTab.translatesAutoresizingMaskIntoConstraints = false
        tabView.addSubview(segmentedTab)

        NSLayoutConstraint.activate([
            segmentedTab.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            segmentedTab.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
            segmentedTab.topAnchor.constraint(equalTo: tabView.topAnchor),
            segmentedTab.bottomAnchor.constraint(equalTo: tabView.bottomAnchor)
        ])

        segmentedTab.onSelectionChanged = { [weak self] index in
            guard let self else { return }
            self.applySelectedTab(index, animated: true, updateSegmentedTab: false)
        }
    }

    private func setupCityChipLayout() {
        guard let chipView = selectedCityLbl.superview else { return }

        cityChipView = chipView
        let widthConstraint = chipView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        cityChipWidthConstraint = widthConstraint
    }

    // MARK: - Setup TableView

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.isScrollEnabled = true

        tableView.register(
            UINib(nibName: "MapVenueTableViewCell", bundle: nil),
            forCellReuseIdentifier: "MapVenueTableViewCell"
        )

        tableView.register(
            UINib(nibName: "MapEventsTableViewCell", bundle: nil),
            forCellReuseIdentifier: "MapEventsTableViewCell"
        )

        tableView.register(
            MapTableShimmerCell.self,
            forCellReuseIdentifier: MapTableShimmerCell.identifier
        )
    }

    private func setupBottomPanelGesture() {
        bottomPanelView.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleBottomPanelPan(_:)))
        pan.delegate = self
        bottomPanelView.addGestureRecognizer(pan)
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handleTablePan(_:)))
        addTabSwipeGestures(to: bottomPanelView)
        addTabSwipeGestures(to: tableView)
    }

    private func setupBottomPanelAppearance() {
        bottomPanelView.clipsToBounds = true
        bottomPanelView.layer.cornerRadius = bottomPanelCollapsedCornerRadius
        if #available(iOS 11.0, *) {
            bottomPanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

    private func addTabSwipeGestures(to view: UIView) {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleTabSwipe(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleTabSwipe(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickFilterbtn(_ sender: Any) {
        return
    }

    @IBAction func onClickCityBtn(_ sender: Any) {
        presentCityFilter()
    }

    @objc private func handleTabSwipe(_ gesture: UISwipeGestureRecognizer) {
        let nextIndex: Int
        if gesture.direction == .left {
            nextIndex = min(selectedIndex + 1, 1)
        } else if gesture.direction == .right {
            nextIndex = max(selectedIndex - 1, 0)
        } else {
            return
        }

        guard nextIndex != selectedIndex else { return }
        applySelectedTab(nextIndex, animated: true)
    }

    private func applySelectedTab(
        _ index: Int,
        animated: Bool,
        updateSegmentedTab: Bool = true
    ) {
        selectedIndex = index
        if updateSegmentedTab {
            segmentedTab.selectTab(at: index, animated: animated)
        }
        updateBrowsingTitle()
        fetchCurrentTabIfNeeded()
        refreshMapAnnotations(animated: true)
        updateEmptyState()
        updatePaginationFooter()
        tableView.reloadData()
        tableView.setContentOffset(.zero, animated: false)
    }

    private func presentCityFilter() {
        let city = screenFilterCity ?? UserDefault.shared.filterCity
        let vc = Navigate.to.selectLocationVC(self)
        vc.persistsFilterSelection = false
        vc.selectedFilterCity = city
        vc.initialFilterCity = city
        vc.onSelectFilterCity = { [weak self] city in
            self?.applyScreenCityFilter(city)
        }
    }

    private func applyScreenCityFilter(_ city: String?) {
        let trimmedCity = city?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        screenFilterCity = trimmedCity?.isEmpty == false
            ? trimmedCity
            : UserDefault.shared.primaryDisplayCity

        updateBrowsingTitle()
        resetDataAndFetchCurrentTab()
        tableView.reloadData()
        tableView.setContentOffset(.zero, animated: false)
    }

    private func resolvedCity() -> String {
        let city = (screenFilterCity ?? UserDefault.shared.activeCity)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return city.isEmpty ? "Chicago" : city
    }

    private func updateBrowsingTitle() {
        let contentType = selectedIndex == 0 ? "venues" : "events"
        let city = resolvedCity()

        selectedCityLbl.text = city
        refreshCityChipLayout()
        browsingLbl.text = "Browsing \(contentType)"
    }

    private func setupMapView() {
        guard googleMapView == nil else { return }

        let camera = GMSCameraPosition(
            latitude: 41.8781,
            longitude: -87.6298,
            zoom: 11.5
        )
        let options = GMSMapViewOptions()
        options.frame = mapView.bounds
        options.camera = camera
        options.backgroundColor = .black

        let googleMapView = GMSMapView(options: options)
        googleMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        googleMapView.delegate = self
        googleMapView.isMyLocationEnabled = false
        googleMapView.settings.compassButton = false
        googleMapView.settings.myLocationButton = false
        googleMapView.settings.rotateGestures = false
        googleMapView.settings.tiltGestures = false
        googleMapView.mapStyle = try? GMSMapStyle(
            jsonString: Self.googleDarkMapStyle(showPointsOfInterest: false)
        )

        mapView.addSubview(googleMapView)
        self.googleMapView = googleMapView
    }

    private var isLeavingScreenPermanently: Bool {
        if transitionCoordinator?.isCancelled == true {
            return false
        }

        if isBeingDismissed ||
            navigationController?.isBeingDismissed == true ||
            parent?.isBeingDismissed == true ||
            presentingViewController?.isBeingDismissed == true {
            return true
        }

        guard let navigationController else {
            return false
        }

        return !isSelfOrAncestorInNavigationStack(navigationController)
    }

    private func isSelfOrAncestorInNavigationStack(
        _ navigationController: UINavigationController
    ) -> Bool {
        var viewController: UIViewController? = self

        while let currentViewController = viewController {
            if navigationController.viewControllers.contains(where: { $0 === currentViewController }) {
                return true
            }

            viewController = currentViewController.parent
        }

        return false
    }

    private func releaseOffscreenHeavyResources() {
        guard isViewLoaded, !didReleaseOffscreenHeavyResources else { return }
        didReleaseOffscreenHeavyResources = true

        tearDownGoogleMapView()
        cancelVisibleImageLoads()
        tableView.tableFooterView = UIView(frame: .zero)
    }

    private func restoreOffscreenHeavyResourcesIfNeeded() {
        guard didReleaseOffscreenHeavyResources else { return }
        didReleaseOffscreenHeavyResources = false

        setupMapView()
        refreshMapAnnotations(animated: false)
        tableView.reloadData()
        updatePaginationFooter()
        updateEmptyState()
    }

    private func releaseResources() {
        guard isViewLoaded, !hasReleasedResources else { return }
        hasReleasedResources = true
        didReleaseOffscreenHeavyResources = false

        venueLoadID += 1
        eventLoadID += 1
        isLoadingVenues = false
        isLoadingEvents = false
        isInitialLoadingVenues = false
        isInitialLoadingEvents = false
        isPaginatingVenues = false
        isPaginatingEvents = false

        segmentedTab.onSelectionChanged = nil
        tearDownGoogleMapView()
        cancelVisibleImageLoads()
        tableView.delegate = nil
        tableView.dataSource = nil
        tableView.prefetchDataSource = nil
        tableView.tableFooterView = nil
        tableView.backgroundView = nil
        tableView.panGestureRecognizer.removeTarget(
            self,
            action: #selector(handleTablePan(_:))
        )

        bottomPanelView.gestureRecognizers?.forEach {
            bottomPanelView.removeGestureRecognizer($0)
        }

        tableView.gestureRecognizers?
            .filter { $0 is UISwipeGestureRecognizer }
            .forEach { tableView.removeGestureRecognizer($0) }

        venueList.removeAll()
        eventList.removeAll()
        SDImageCache.shared.clearMemory()
    }

    private func tearDownGoogleMapView() {
        guard let googleMapView else { return }

        googleMapView.delegate = nil
        googleMapView.clear()
        googleMapView.removeFromSuperview()
        self.googleMapView = nil
    }

    private func cancelVisibleImageLoads() {
        tableView.visibleCells.forEach { cell in
            if let cell = cell as? MapVenueTableViewCell {
                cell.releaseImageResources()
            } else if let cell = cell as? MapEventsTableViewCell {
                cell.releaseImageResources()
            }
        }
        cancelImageLoads(in: tableView.tableFooterView)
        cancelImageLoads(in: tableView.backgroundView)
    }

    private func cancelImageLoads(in view: UIView?) {
        guard let view else { return }

        if let imageView = view as? UIImageView {
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = nil
        }

        view.subviews.forEach { cancelImageLoads(in: $0) }
    }

    private func resetDataAndFetchCurrentTab() {
        venueLoadID += 1
        eventLoadID += 1
        venueList.removeAll()
        eventList.removeAll()
        venueSkip = 0
        eventSkip = 0
        hasMoreVenues = true
        hasMoreEvents = true
        isLoadingVenues = false
        isLoadingEvents = false
        isInitialLoadingVenues = true
        isInitialLoadingEvents = true
        isPaginatingVenues = false
        isPaginatingEvents = false
        tableView.reloadData()
        updateEmptyState()
        updatePaginationFooter()
        refreshMapAnnotations(animated: false)
        fetchVenues(reset: true)
        fetchEvents(reset: true)
    }

    private func fetchCurrentTabIfNeeded(force: Bool = false) {
        if selectedIndex == 0 {
            guard !isLoadingVenues else { return }
            guard force || venueList.isEmpty else { return }
            fetchVenues(reset: force || venueList.isEmpty)
        } else {
            guard !isLoadingEvents else { return }
            guard force || eventList.isEmpty else { return }
            fetchEvents(reset: force || eventList.isEmpty)
        }
    }

    private func fetchVenues(reset: Bool = false) {
        guard !isLoadingVenues || reset else { return }
        guard hasMoreVenues || reset else { return }

        if reset {
            venueSkip = 0
            hasMoreVenues = true
            venueList.removeAll()
            isInitialLoadingVenues = true
            isPaginatingVenues = false
            tableView.reloadData()
            updateEmptyState()
            updatePaginationFooter()
        } else if !venueList.isEmpty {
            isPaginatingVenues = true
            updatePaginationFooter()
        }

        isLoadingVenues = true
        updateEmptyState()
        venueLoadID += 1
        let requestID = venueLoadID
        let city = resolvedCity()

        discoverService.fetchDiscoverVenues(
            city: city,
            skip: venueSkip,
            checkIsPremium: true,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in
            guard let self else { return }
            guard self.venueLoadID == requestID else { return }

            self.isLoadingVenues = false
            self.isInitialLoadingVenues = false

            guard isSuccess,
                  let page else {
                self.isPaginatingVenues = false
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                self.tableView.reloadData()
                self.updateEmptyState()
                self.updatePaginationFooter()
                return
            }

            self.venueList = reset
                ? page.list
                : self.venueList + self.uniqueVenues(from: page.list)
            self.venueSkip = self.venueList.count
            self.hasMoreVenues = page.hasMore
            self.isPaginatingVenues = false

            if self.selectedIndex == 0 {
                self.tableView.reloadData()
                self.updateEmptyState()
                self.updatePaginationFooter()
                self.refreshMapAnnotations(animated: true)
                self.loadNextPageIfContentNeedsMoreRows()
            }
        }
    }

    private func fetchEvents(reset: Bool = false) {
        guard !isLoadingEvents || reset else { return }
        guard hasMoreEvents || reset else { return }

        if reset {
            eventSkip = 0
            hasMoreEvents = true
            eventList.removeAll()
            isInitialLoadingEvents = true
            isPaginatingEvents = false
            tableView.reloadData()
            updateEmptyState()
            updatePaginationFooter()
        } else if !eventList.isEmpty {
            isPaginatingEvents = true
            updatePaginationFooter()
        }

        isLoadingEvents = true
        updateEmptyState()
        eventLoadID += 1
        let requestID = eventLoadID
        let city = resolvedCity()

        discoverService.fetchDiscoverEvents(
            city: city,
            skip: eventSkip,
            eventListType: .eventsInCity,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in
            guard let self else { return }
            guard self.eventLoadID == requestID else { return }

            self.isLoadingEvents = false
            self.isInitialLoadingEvents = false

            guard isSuccess,
                  let page else {
                self.isPaginatingEvents = false
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                self.tableView.reloadData()
                self.updateEmptyState()
                self.updatePaginationFooter()
                return
            }

            self.eventList = reset
                ? page.list
                : self.eventList + self.uniqueEvents(from: page.list)
            self.eventSkip = self.eventList.count
            self.hasMoreEvents = page.hasMore
            self.isPaginatingEvents = false

            if self.selectedIndex == 1 {
                self.tableView.reloadData()
                self.updateEmptyState()
                self.updatePaginationFooter()
                self.refreshMapAnnotations(animated: true)
                self.loadNextPageIfContentNeedsMoreRows()
            }
        }
    }

    private func loadNextPageIfNeeded() {
        if selectedIndex == 0 {
            guard !isInitialLoadingVenues else { return }
            guard !isLoadingVenues else { return }
            guard !isPaginatingVenues else { return }
            guard !venueList.isEmpty else { return }
            guard hasMoreVenues else { return }
            fetchVenues()
        } else {
            guard !isInitialLoadingEvents else { return }
            guard !isLoadingEvents else { return }
            guard !isPaginatingEvents else { return }
            guard !eventList.isEmpty else { return }
            guard hasMoreEvents else { return }
            fetchEvents()
        }
    }

    private func loadNextPageIfContentNeedsMoreRows() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.tableView.layoutIfNeeded()

            let contentHeight = self.tableView.contentSize.height
            let visibleHeight = self.tableView.bounds.height
            guard contentHeight > 0,
                  contentHeight <= visibleHeight + 80 else {
                return
            }

            self.loadNextPageIfNeeded()
        }
    }

    private func uniqueVenues(from newVenues: [ClipVenue]) -> [ClipVenue] {
        let existingIDs = Set(venueList.map { $0.id })
        return newVenues.filter { !existingIDs.contains($0.id) }
    }

    private func uniqueEvents(from newEvents: [Event]) -> [Event] {
        let existingIDs = Set(eventList.map { $0.id })
        return newEvents.filter { !existingIDs.contains($0.id) }
    }

    private func updateEmptyState() {
        let isLoading = selectedIndex == 0 ? isInitialLoadingVenues : isInitialLoadingEvents
        let isEmpty = selectedIndex == 0 ? venueList.isEmpty : eventList.isEmpty
        tableView.backgroundView = !isLoading && isEmpty
            ? makeEmptyStateView()
            : nil
    }

    private func updatePaginationFooter() {
        let isPaginating = selectedIndex == 0
            ? isPaginatingVenues
            : isPaginatingEvents
        let hasMore = selectedIndex == 0
            ? hasMoreVenues
            : hasMoreEvents

        guard isPaginating && hasMore else {
            tableView.tableFooterView = UIView(frame: .zero)
            return
        }

        let footerHeight: CGFloat = 164
        let footer = MapPaginationShimmerFooterView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.bounds.width,
                height: footerHeight
            )
        )
        tableView.tableFooterView = footer
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: tableView.bounds)
        container.backgroundColor = .clear

        let emptyView = V3EmptyStateView(
            style: selectedIndex == 0 ? .mapVenues : .events
        )
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emptyView)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: container.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func refreshMapAnnotations(animated: Bool) {
        googleMapView?.clear()

        let annotations: [DiscoverMapAnnotation]

        if selectedIndex == 0 {
            annotations = venueList.compactMap { venue in
                guard let coordinate = coordinate(for: venue) else { return nil }
                return DiscoverMapAnnotation(
                    coordinate: coordinate,
                    title: venue.name,
                    subtitle: [venue.address, venue.city]
                        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        .joined(separator: ", "),
                    imageURL: venuePinBackgroundImageURL(venue),
                    logoImageURL: venueLogoImageURL(venue),
                    kind: .venue(venue)
                )
            }
        } else {
            annotations = eventAnnotationsWithOffsets()
        }

        annotations.forEach { annotation in
            let marker = GMSMarker(position: annotation.coordinate)
            marker.title = annotation.title
            marker.snippet = annotation.subtitle
            marker.iconView = DiscoverImageMarkerView(
                imageURL: annotation.imageURL,
                logoImageURL: annotation.logoImageURL
            )
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.userData = annotation
            marker.map = googleMapView
        }

        updateMapRegion(for: annotations, animated: animated)
    }

    private func updateMapRegion(
        for annotations: [DiscoverMapAnnotation],
        animated: Bool
    ) {
        guard let googleMapView else { return }
        guard !annotations.isEmpty else { return }

        guard let coordinate = annotations.first?.coordinate else { return }

        let update = GMSCameraUpdate.setTarget(coordinate, zoom: 14)
        if animated {
            googleMapView.animate(with: update)
        } else {
            googleMapView.moveCamera(update)
        }
    }

    private static func googleDarkMapStyle(showPointsOfInterest: Bool) -> String {
        let poiVisibility = showPointsOfInterest ? "simplified" : "off"

        return """
        [
          { "elementType": "geometry", "stylers": [{ "color": "#242424" }] },
          { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
          { "elementType": "labels.text.fill", "stylers": [{ "color": "#8f8f8f" }] },
          { "elementType": "labels.text.stroke", "stylers": [{ "color": "#101010" }] },
          { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#3a3a3a" }] },
          { "featureType": "landscape", "elementType": "geometry", "stylers": [{ "color": "#222222" }] },
          { "featureType": "poi", "stylers": [{ "visibility": "\(poiVisibility)" }] },
          { "featureType": "poi", "elementType": "geometry", "stylers": [{ "color": "#262626" }] },
          { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{ "color": "#787878" }] },
          { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#343434" }] },
          { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#1a1a1a" }] },
          { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{ "color": "#8a8a8a" }] },
          { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#2c2c2c" }] },
          { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{ "color": "#111111" }] },
          { "featureType": "transit", "elementType": "geometry", "stylers": [{ "color": "#272727" }] },
          { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#111111" }] },
          { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#555555" }] }
        ]
        """
    }

    private func eventAnnotationsWithOffsets() -> [DiscoverMapAnnotation] {
        let coordinateItems = eventList.compactMap { event -> (event: Event, coordinate: CLLocationCoordinate2D)? in
            guard let coordinate = coordinate(for: event) else { return nil }
            return (event, coordinate)
        }

        let groupedItems = Dictionary(grouping: coordinateItems) {
            coordinateKey($0.coordinate)
        }

        return groupedItems.values.flatMap { items in
            items.enumerated().map { index, item in
                DiscoverMapAnnotation(
                    coordinate: offsetCoordinate(
                        item.coordinate,
                        index: index,
                        total: items.count
                    ),
                    title: item.event.title,
                    subtitle: item.event.venue?.name ?? item.event.customVenue?.name,
                    imageURL: eventPinBackgroundImageURL(item.event),
                    logoImageURL: eventVenueLogoImageURL(item.event),
                    kind: .event(item.event)
                )
            }
        }
    }

    private func offsetCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        index: Int,
        total: Int
    ) -> CLLocationCoordinate2D {
        guard total > 1 else { return coordinate }

        let angle = (Double(index) / Double(total)) * (Double.pi * 2)
        let radius = 0.00022

        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + (sin(angle) * radius),
            longitude: coordinate.longitude + (cos(angle) * radius)
        )
    }

    private func coordinateKey(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude)
    }

    private func coordinate(for venue: ClipVenue) -> CLLocationCoordinate2D? {
        guard venue.latitude != 0 || venue.longitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
    }

    private func coordinate(for event: Event) -> CLLocationCoordinate2D? {
        if let customVenue = event.customVenue,
           let latitude = customVenue.latitude,
           let longitude = customVenue.longitude,
           latitude != 0 || longitude != 0 {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        guard let venue = event.venue else { return nil }
        return coordinate(for: venue)
    }

    private func venuePinBackgroundImageURL(_ venue: ClipVenue) -> String? {
        let imageKey = venue.venueAttachment?.first?.key ?? venue.logo?.key ?? ""
        return imageKey.isEmpty ? nil : imageKey.imageURL
    }

    private func venueLogoImageURL(_ venue: ClipVenue) -> String? {
        let logoKey = venue.logo?.key ?? ""
        return logoKey.isEmpty ? nil : logoKey.imageURL
    }

    private func eventPinBackgroundImageURL(_ event: Event) -> String? {
        let key = event.flyer?.key ?? event.venue?.logo?.key ?? ""
        return key.isEmpty ? nil : key.imageURL
    }

    private func eventVenueLogoImageURL(_ event: Event) -> String? {
        let logoKey = event.venue?.logo?.key ?? ""
        return logoKey.isEmpty ? nil : logoKey.imageURL
    }

    private func navigate(to kind: DiscoverMapAnnotation.Kind) {
        switch kind {
        case .venue(let venue):
            Navigate.to.venueVC(self, venueDetails: venue)
        case .event(let event):
            Navigate.eventDetailsVC(self, event: event)
        }
    }

    private func refreshCityChipLayout() {
        updateCityChipWidth()
        selectedCityLbl.invalidateIntrinsicContentSize()
        selectedCityLbl.superview?.invalidateIntrinsicContentSize()
        selectedCityLbl.superview?.setNeedsLayout()
        selectedCityLbl.superview?.superview?.setNeedsLayout()

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

    private func updateCityChipWidth() {
        let city = selectedCityLbl.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let font = selectedCityLbl.font ?? Constant.Font.geistRegular(size: 13)
        let textWidth = ceil((city as NSString).size(withAttributes: [.font: font]).width)
        let width = 14 + 13 + 6 + textWidth + 19

        cityChipWidthConstraint?.constant = min(max(width, 96), 240)
    }

    @objc private func handleBottomPanelPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            bottomPanelPanStartHeight = bottomPanelHeightConstraint.constant
        case .changed:
            updateBottomPanelHeight(forTranslationY: translation.y)
        case .ended, .cancelled, .failed:
            finishBottomPanelPan(withVelocityY: gesture.velocity(in: view).y)
        default:
            break
        }
    }

    @objc private func handleTablePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            bottomPanelPanStartHeight = bottomPanelHeightConstraint.constant
            isDraggingBottomPanelFromTable = !isBottomPanelExpanded
        case .changed:
            if !isDraggingBottomPanelFromTable,
               tableView.contentOffset.y <= 0,
               translation.y > 0 {
                isDraggingBottomPanelFromTable = true
                bottomPanelPanStartHeight = bottomPanelHeightConstraint.constant
                gesture.setTranslation(.zero, in: view)
                tableView.setContentOffset(.zero, animated: false)
                return
            }

            guard isDraggingBottomPanelFromTable else { return }
            tableView.setContentOffset(.zero, animated: false)
            updateBottomPanelHeight(forTranslationY: translation.y)
        case .ended, .cancelled, .failed:
            guard isDraggingBottomPanelFromTable else { return }
            isDraggingBottomPanelFromTable = false
            tableView.setContentOffset(.zero, animated: false)
            finishBottomPanelPan(withVelocityY: gesture.velocity(in: view).y)
        default:
            break
        }
    }

    private func updateBottomPanelHeight(forTranslationY translationY: CGFloat) {
        let nextHeight = min(
            max(bottomPanelPanStartHeight - translationY, bottomPanelCollapsedHeight),
            bottomPanelExpandedHeight
        )
        bottomPanelHeightConstraint.constant = nextHeight
        setMapVisibility(forPanelHeight: nextHeight)
        view.layoutIfNeeded()
    }

    private func finishBottomPanelPan(withVelocityY velocityY: CGFloat) {
        let midpoint = bottomPanelCollapsedHeight + ((bottomPanelExpandedHeight - bottomPanelCollapsedHeight) * 0.45)
        let shouldExpand = velocityY < -350 || bottomPanelHeightConstraint.constant > midpoint
        let targetHeight = shouldExpand ? bottomPanelExpandedHeight : bottomPanelCollapsedHeight

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.bottomPanelHeightConstraint.constant = targetHeight
            self.setMapVisibility(forPanelHeight: targetHeight)
            self.view.layoutIfNeeded()
        }
    }

    private func setMapVisibility(forPanelHeight height: CGFloat) {
        let heightRange = max(bottomPanelExpandedHeight - bottomPanelCollapsedHeight, 1)
        let progress = min(max((height - bottomPanelCollapsedHeight) / heightRange, 0), 1)
        mapView.alpha = 1 - (progress * 0.7)
        browsingLbl.alpha = 1 - (progress * 0.15)
        bottomPanelView.layer.cornerRadius = bottomPanelCollapsedCornerRadius * (1 - progress)
    }

}

extension MapViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view === bottomPanelView,
           let touchedView = touch.view,
           touchedView.isDescendant(of: tableView) {
            return false
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let includesBottomPanel = gestureRecognizer.view === bottomPanelView
            || otherGestureRecognizer.view === bottomPanelView
        let includesTablePan = gestureRecognizer === tableView.panGestureRecognizer
            || otherGestureRecognizer === tableView.panGestureRecognizer
        return includesBottomPanel || includesTablePan
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MapViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedIndex == 0,
           isInitialLoadingVenues {
            return 4
        }

        if selectedIndex == 1,
           isInitialLoadingEvents {
            return 4
        }

        return selectedIndex == 0 ? venueList.count : eventList.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if (selectedIndex == 0 && isInitialLoadingVenues)
            || (selectedIndex == 1 && isInitialLoadingEvents) {
            return tableView.dequeueReusableCell(
                withIdentifier: MapTableShimmerCell.identifier,
                for: indexPath
            )
        }

        if selectedIndex == 0 {
            guard venueList.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "MapVenueTableViewCell",
                for: indexPath
            ) as? MapVenueTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.configure(with: venueList[indexPath.row])

            return cell

        } else {
            guard eventList.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "MapEventsTableViewCell",
                for: indexPath
            ) as? MapEventsTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.configure(with: eventList[indexPath.row])

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !(selectedIndex == 0 && isInitialLoadingVenues) else { return }
        guard !(selectedIndex == 1 && isInitialLoadingEvents) else { return }

        if selectedIndex == 0 {
            guard venueList.indices.contains(indexPath.row) else { return }
            AppHaptic.cardOpen()
            Navigate.to.venueVC(self, venueDetails: venueList[indexPath.row])
        } else {
            guard eventList.indices.contains(indexPath.row) else { return }
            AppHaptic.cardOpen()
            Navigate.eventDetailsVC(self, event: eventList[indexPath.row])
        }
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard !(selectedIndex == 0 && isInitialLoadingVenues) else { return }
        guard !(selectedIndex == 1 && isInitialLoadingEvents) else { return }

        let count = selectedIndex == 0 ? venueList.count : eventList.count
        guard count > 0,
              indexPath.row >= count - 3 else {
            return
        }

        loadNextPageIfNeeded()
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 120
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        guard !(selectedIndex == 0 && isInitialLoadingVenues) else { return }
        guard !(selectedIndex == 1 && isInitialLoadingEvents) else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let threshold: CGFloat = 360

        guard offsetY > contentHeight - visibleHeight - threshold else { return }
        loadNextPageIfNeeded()
    }
}

extension MapViewController: UITableViewDataSourcePrefetching {

    func tableView(
        _ tableView: UITableView,
        prefetchRowsAt indexPaths: [IndexPath]
    ) {
        guard !(selectedIndex == 0 && isInitialLoadingVenues) else { return }
        guard !(selectedIndex == 1 && isInitialLoadingEvents) else { return }

        let count = selectedIndex == 0 ? venueList.count : eventList.count
        guard count > 0,
              indexPaths.contains(where: { $0.row >= count - 4 }) else {
            return
        }

        loadNextPageIfNeeded()
    }
}

// MARK: - GMSMapViewDelegate

extension MapViewController: GMSMapViewDelegate {

    func mapView(
        _ mapView: GMSMapView,
        didTap marker: GMSMarker
    ) -> Bool {
        guard let annotation = marker.userData as? DiscoverMapAnnotation else { return false }
        AppHaptic.cardOpen()
        navigate(to: annotation.kind)
        return true
    }
}

private final class DiscoverMapAnnotation: NSObject {

    enum Kind {
        case venue(ClipVenue)
        case event(Event)
    }

    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let imageURL: String?
    let logoImageURL: String?
    let kind: Kind

    init(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        subtitle: String?,
        imageURL: String?,
        logoImageURL: String?,
        kind: Kind
    ) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.logoImageURL = logoImageURL
        self.kind = kind
        super.init()
    }
}

private final class DiscoverImageMarkerView: UIView {

    private enum Layout {
        static let markerSize: CGFloat = 46
        static let logoSize: CGFloat = 34
    }

    private let imageView = UIImageView()
    private let dimView = UIView()
    private let logoImageView = UIImageView()

    init(
        imageURL: String?,
        logoImageURL: String?
    ) {
        super.init(frame: CGRect(x: 0, y: 0, width: Layout.markerSize, height: Layout.markerSize))
        setup()
        configure(
            imageURL: imageURL,
            logoImageURL: logoImageURL
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        imageView.sd_cancelCurrentImageLoad()
        logoImageView.sd_cancelCurrentImageLoad()
    }

    private func setup() {

        imageView.frame = bounds
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.image = UIImage(named: "newSpeakeasy")
        addSubview(imageView)

        logoImageView.frame = CGRect(
            x: (Layout.markerSize - Layout.logoSize) / 2,
            y: (Layout.markerSize - Layout.logoSize) / 2,
            width: Layout.logoSize,
            height: Layout.logoSize
        ).insetBy(dx: 3, dy: 3)
        logoImageView.contentMode = .scaleAspectFit
        addSubview(logoImageView)
    }

    private func configure(
        imageURL: String?,
        logoImageURL: String?
    ) {
        let scale = UIScreen.main.scale

        imageView.sd_setImage(
            with: URL(string: imageURL ?? ""),
            placeholderImage: UIImage(named: "newSpeakeasy"),
            options: [.scaleDownLargeImages],
            context: [
                .imageThumbnailPixelSize: NSValue(
                    cgSize: CGSize(width: 46 * scale, height: 46 * scale)
                )
            ]
        )

        logoImageView.sd_setImage(
            with: URL(string: logoImageURL ?? ""),
            placeholderImage: nil,
            options: [.scaleDownLargeImages],
            context: [
                .imageThumbnailPixelSize: NSValue(
                    cgSize: CGSize(width: 34 * scale, height: 34 * scale)
                )
            ]
        )
    }
}

private final class MapTableShimmerCell: UITableViewCell {

    private let shimmerContent = MapRowShimmerContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        shimmerContent.releaseResources()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        shimmerContent.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerContent)

        NSLayoutConstraint.activate([
            shimmerContent.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            shimmerContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            shimmerContent.heightAnchor.constraint(equalToConstant: 92)
        ])
    }
}

private final class MapPaginationShimmerFooterView: UIView {

    private let firstRow = MapRowShimmerContentView()
    private let secondRow = MapRowShimmerContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        firstRow.releaseResources()
        secondRow.releaseResources()
    }

    private func setup() {
        backgroundColor = .clear

        [firstRow, secondRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            firstRow.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            firstRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            firstRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            firstRow.heightAnchor.constraint(equalToConstant: 58),

            secondRow.topAnchor.constraint(equalTo: firstRow.bottomAnchor, constant: 12),
            secondRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            secondRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            secondRow.heightAnchor.constraint(equalToConstant: 58),
            secondRow.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }
}

private final class MapRowShimmerContentView: UIView {

    private let imageShimmer = ShimmerViewV3(frame: .zero, lighter: true)
    private let titleShimmer = ShimmerViewV3(frame: .zero, lighter: true)
    private let subtitleShimmer = ShimmerViewV3(frame: .zero, lighter: true)
    private let badgeShimmer = ShimmerViewV3(frame: .zero, lighter: true)
    private let actionShimmer = ShimmerViewV3(frame: .zero, lighter: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        let shimmerViews = [
            imageShimmer,
            titleShimmer,
            subtitleShimmer,
            badgeShimmer,
            actionShimmer
        ]

        if newWindow == nil {
            shimmerViews.forEach { $0.stopShimmer() }
        } else {
            shimmerViews.forEach { $0.startShimmer() }
        }
    }

    func releaseResources() {
        [
            imageShimmer,
            titleShimmer,
            subtitleShimmer,
            badgeShimmer,
            actionShimmer
        ].forEach {
            $0.stopShimmer()
            $0.removeFromSuperview()
        }
    }

    private func setup() {
        backgroundColor = .clear

        imageShimmer.layer.cornerRadius = 8
        titleShimmer.layer.cornerRadius = 5
        subtitleShimmer.layer.cornerRadius = 5
        badgeShimmer.layer.cornerRadius = 7
        actionShimmer.layer.cornerRadius = 12

        [
            imageShimmer,
            titleShimmer,
            subtitleShimmer,
            badgeShimmer,
            actionShimmer
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            $0.startShimmer()
        }

        NSLayoutConstraint.activate([
            imageShimmer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageShimmer.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageShimmer.widthAnchor.constraint(equalToConstant: 65),
            imageShimmer.heightAnchor.constraint(equalToConstant: 65),

            titleShimmer.leadingAnchor.constraint(equalTo: imageShimmer.trailingAnchor, constant: 15),
            titleShimmer.topAnchor.constraint(equalTo: imageShimmer.topAnchor, constant: 4),
            titleShimmer.trailingAnchor.constraint(equalTo: actionShimmer.leadingAnchor, constant: -18),
            titleShimmer.heightAnchor.constraint(equalToConstant: 18),

            subtitleShimmer.leadingAnchor.constraint(equalTo: titleShimmer.leadingAnchor),
            subtitleShimmer.topAnchor.constraint(equalTo: titleShimmer.bottomAnchor, constant: 8),
            subtitleShimmer.widthAnchor.constraint(equalToConstant: 150),
            subtitleShimmer.heightAnchor.constraint(equalToConstant: 12),

//            badgeShimmer.leadingAnchor.constraint(equalTo: titleShimmer.leadingAnchor),
//            badgeShimmer.topAnchor.constraint(equalTo: subtitleShimmer.bottomAnchor, constant: 10),
//            badgeShimmer.widthAnchor.constraint(equalToConstant: 86),
//            badgeShimmer.heightAnchor.constraint(equalToConstant: 15),

            actionShimmer.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionShimmer.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionShimmer.widthAnchor.constraint(equalToConstant: 90),
            actionShimmer.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
