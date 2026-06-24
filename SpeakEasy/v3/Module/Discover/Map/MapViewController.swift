//
//  MapViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit
import MapKit

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
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
        ])

        // Placeholder constraints — updated in layoutSubviews once width is known
        indicatorLeading = indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor)
        indicatorWidth = indicatorView.widthAnchor.constraint(equalToConstant: 44)
        indicatorLeading.isActive = true
        indicatorWidth.isActive = true

        for (i, title) in items.enumerated() {
            let btn = makeButton(title: title, index: i)
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
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomPanelView: UIView!
    @IBOutlet weak var bottomPanelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedCityLbl: UILabel!
    private weak var cityChipView: UIView?
    private var cityChipWidthConstraint: NSLayoutConstraint?
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
        presentCityFilter()
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
            : nil

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
        mapView.delegate = self
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsUserLocation = false
        mapView.applySpeakEasyDarkStyle(showPointsOfInterest: true)
        
        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            ),
            animated: false
        )
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

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = selectedIndex == 0 ? "No venues found" : "No events found"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 18)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Try another city."
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 14)
        subtitleLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -32),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24)
        ])

        return container
    }

    private func refreshMapAnnotations(animated: Bool) {
        let oldAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(oldAnnotations)

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
                    imageURL: venuePinImageURL(venue),
                    kind: .venue(venue)
                )
            }
        } else {
            annotations = eventAnnotationsWithOffsets()
        }

        mapView.addAnnotations(annotations)
        updateMapRegion(for: annotations, animated: animated)
    }

    private func updateMapRegion(
        for annotations: [DiscoverMapAnnotation],
        animated: Bool
    ) {
        guard !annotations.isEmpty else { return }

        guard let coordinate = annotations.first?.coordinate else { return }

        mapView.setRegion(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 2600,
                longitudinalMeters: 2600
            ),
            animated: animated
        )
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
                    imageURL: eventPinImageURL(item.event),
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

    private func venuePinImageURL(_ venue: ClipVenue) -> String? {
        let key = venue.logo?.key ?? venue.venueAttachment?.first?.key ?? ""
        return key.isEmpty ? nil : key.imageURL
    }

    private func eventPinImageURL(_ event: Event) -> String? {
        let key = event.flyer?.key ?? event.venue?.logo?.key ?? ""
        return key.isEmpty ? nil : key.imageURL
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
            Navigate.to.venueVC(self, venueDetails: venueList[indexPath.row])
        } else {
            guard eventList.indices.contains(indexPath.row) else { return }
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

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(
        _ mapView: MKMapView,
        viewFor annotation: MKAnnotation
    ) -> MKAnnotationView? {
        guard let annotation = annotation as? DiscoverMapAnnotation else {
            return nil
        }

        let identifier = "DiscoverImagePin"
        let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier
        ) as? DiscoverImageAnnotationView ?? DiscoverImageAnnotationView(
            annotation: annotation,
            reuseIdentifier: identifier
        )

        annotationView.annotation = annotation
        annotationView.configure(imageURL: annotation.imageURL)
        return annotationView
    }

    func mapView(
        _ mapView: MKMapView,
        didSelect view: MKAnnotationView
    ) {
        guard let annotation = view.annotation as? DiscoverMapAnnotation else { return }
        mapView.deselectAnnotation(annotation, animated: false)
        navigate(to: annotation.kind)
    }
}

private final class DiscoverMapAnnotation: NSObject, MKAnnotation {

    enum Kind {
        case venue(ClipVenue)
        case event(Event)
    }

    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let imageURL: String?
    let kind: Kind

    init(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        subtitle: String?,
        imageURL: String?,
        kind: Kind
    ) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.kind = kind
        super.init()
    }
}

private final class DiscoverImageAnnotationView: MKAnnotationView {

    private let imageView = UIImageView()
    private let ringView = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = UIImage(named: "newSpeakeasy")
    }

    func configure(imageURL: String?) {
        imageView.sd_setImage(
            with: URL(string: imageURL ?? ""),
            placeholderImage: UIImage(named: "newSpeakeasy")
        )
    }

    private func setup() {
        frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        centerOffset = CGPoint(x: 0, y: -18)
        canShowCallout = false

        ringView.frame = bounds
        ringView.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.16)
        ringView.layer.cornerRadius = bounds.width / 2
        ringView.layer.borderColor = UIColor.white.withAlphaComponent(0.86).cgColor
        ringView.layer.borderWidth = 2
        ringView.layer.shadowColor = UIColor.black.cgColor
        ringView.layer.shadowOpacity = 0.35
        ringView.layer.shadowRadius = 8
        ringView.layer.shadowOffset = CGSize(width: 0, height: 3)
        addSubview(ringView)

        imageView.frame = bounds.insetBy(dx: 5, dy: 5)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.image = UIImage(named: "newSpeakeasy")
        addSubview(imageView)
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
            titleShimmer.trailingAnchor.constraint(lessThanOrEqualTo: actionShimmer.leadingAnchor, constant: -18),
            titleShimmer.heightAnchor.constraint(equalToConstant: 18),

            subtitleShimmer.leadingAnchor.constraint(equalTo: titleShimmer.leadingAnchor),
            subtitleShimmer.topAnchor.constraint(equalTo: titleShimmer.bottomAnchor, constant: 8),
            subtitleShimmer.widthAnchor.constraint(equalToConstant: 150),
            subtitleShimmer.heightAnchor.constraint(equalToConstant: 12),

            badgeShimmer.leadingAnchor.constraint(equalTo: titleShimmer.leadingAnchor),
            badgeShimmer.topAnchor.constraint(equalTo: subtitleShimmer.bottomAnchor, constant: 10),
            badgeShimmer.widthAnchor.constraint(equalToConstant: 86),
            badgeShimmer.heightAnchor.constraint(equalToConstant: 15),

            actionShimmer.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionShimmer.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionShimmer.widthAnchor.constraint(equalToConstant: 90),
            actionShimmer.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
