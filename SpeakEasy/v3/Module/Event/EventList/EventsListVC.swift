//
//  EventsListVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 08/04/26.
//

import UIKit

enum EventsListMode {
    case cityEvents
    case tonight
    case venueSearch
}

enum EventsListScreenType {
    case discoverExperiences
    case allEvents

    var listMode: EventsListMode {
        switch self {
        case .discoverExperiences:
            return .tonight
        case .allEvents:
            return .cityEvents
        }
    }
}

final class EventsListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cityTitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var topRightSideBtn: AppIconButton!
    @IBOutlet weak var topTitleView: LiquidGlassBackgroundView!
    @IBOutlet weak var topViewLeftSideConstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewRightSideConstraint: NSLayoutConstraint!
    
    private var eventList: [Event] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0
    private var screenFilterCity: String?
    private var loadID = 0
    private var topTitleWidthConstraint: NSLayoutConstraint?
    private var hasReleasedResources = false
    private var showsNoInternetView = false

    var venue: SearchVenueItem?
    var listMode: EventsListMode = .cityEvents

    private let discoverService = DiscoverService()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCollectionView()
        fetchEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
        refreshCollectionLayoutIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isLeavingScreenPermanently {
            releaseResources()
        }
    }

    deinit {
        releaseResources()
    }

    private var isLeavingScreenPermanently: Bool {
        if transitionCoordinator?.isCancelled == true {
            return false
        }

        if isBeingDismissed ||
            navigationController?.isBeingDismissed == true ||
            parent?.isBeingDismissed == true {
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

    private func releaseResources() {
        guard isViewLoaded, !hasReleasedResources else { return }
        hasReleasedResources = true
        loadID += 1
        isLoading = false
        isPaginating = false

        collectionView.visibleCells.forEach {
            ($0 as? OrderCardShimmerCell)?.releaseResources()
            ($0 as? OrderCardCollectionCell)?.releaseResources()
        }
        collectionView
            .visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
            .forEach {
                ($0 as? PaginationShimmerFooterView)?.releaseResources()
            }
        collectionView.delegate = nil
        collectionView.dataSource = nil
        collectionView.prefetchDataSource = nil
        collectionView.backgroundView = nil
        topRightSideBtn?.releaseResources()
        topTitleView?.releaseResources()
        eventList.removeAll()
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickTopRightSideBtn(_ sender: Any) {
        if let venue = venue {
            AppHaptic.navigation()
            Navigate.to.searchEventVC(self, venueID: venue.venueUniqueId)
        } else {
            return
        }
    }

    @IBAction func onClickCityBtn(_ sender: Any) {
        guard venue == nil else { return }
        AppHaptic.selectionChanged()
        presentCityFilter()
    }

    private func setupUI() {
        setupTopTitleSizing()

        if let venue = venue {
            topRightSideBtn.isHidden = false
            topRightSideBtn.iconTypeValue = AppIconType.search.rawValue
            topRightSideBtn.iconSize = 14
            topRightSideBtn.buttonSize = 40

            titleLbl.text = venue.name
            cityTitleLbl.text = ""
            cityTitleLbl.isHidden = true
            topTitleView.cornerRadius = 20
            topViewLeftSideConstraint.constant = 20
            topViewRightSideConstraint.constant = 20
        } else {
            topRightSideBtn.isHidden = true
            updateCityTitle()
        }

        refreshTopTitleLayout()
    }

    private func setupTopTitleSizing() {
        titleLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)
        cityTitleLbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cityTitleLbl.setContentHuggingPriority(.required, for: .horizontal)

        guard topTitleWidthConstraint == nil else { return }

        let widthConstraint = topTitleView.widthAnchor.constraint(equalToConstant: 180)
        widthConstraint.priority = .required
        widthConstraint.isActive = true
        topTitleWidthConstraint = widthConstraint
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )

        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )

        collectionView.register(
            OrdersSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: OrdersSectionHeaderView.identifier
        )

        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        collectionView.register(
            EmptyCollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EmptyCollectionReusableView.identifier
        )

        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: 34,
            right: 24
        )
        layout.interItemSpacing = 14
        layout.lineSpacing = 16
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    private func fetchEvents(reset: Bool = false) {
        guard !isLoading || reset else { return }
        guard hasMore || reset else { return }

        isLoading = true
        loadID += 1
        let requestID = loadID

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            eventList.removeAll()
            reloadUI()
        }

        discoverService.fetchDiscoverEvents(
            city: resolvedCity(),
            venueId: venue?.venueUniqueId,
            skip: skip,
            eventListType: eventListType(),
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in

            guard let self,
                  !self.hasReleasedResources else { return }
            guard self.loadID == requestID else { return }

            guard isSuccess,
                  let page else {
                self.isLoading = false
                self.isInitialLoading = false
                self.isPaginating = false
                self.showsNoInternetView = V3NoInternetView.isNoInternet(errMsg)
                if !self.showsNoInternetView {
                    Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                }
                self.reloadUI()
                return
            }

            self.showsNoInternetView = false
            let oldCount = self.eventList.count

            self.eventList = reset
                ? page.list
                : self.eventList + page.list

            let newCount = self.eventList.count

            self.skip = self.eventList.count
            self.hasMore = page.hasMore
            self.isLoading = false

            let wasInitialLoading = self.isInitialLoading
            self.isInitialLoading = false

            if wasInitialLoading || reset {
                self.isPaginating = false
                self.reloadUI()
                return
            }

            let indexPaths = (oldCount..<newCount).map {
                IndexPath(item: $0, section: 0)
            }

            guard !indexPaths.isEmpty else {
                self.isPaginating = false
                self.invalidateFooter()
                self.updateEmptyState()
                return
            }

            self.insertEventItems(indexPaths)
        }
    }

    private func eventListType() -> DiscoverEventListType {
        switch listMode {
        case .cityEvents:
            return .eventsInCity
        case .tonight:
            return .eventsTonight
        case .venueSearch:
            return .eventsInCity
        }
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

        updateCityTitle()
        fetchEvents(reset: true)
    }

    private func resolvedCity() -> String {
        let city = screenFilterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let city,
           !city.isEmpty {
            return city
        }

        return UserDefault.shared.activeCity
    }

    private func updateCityTitle() {
        switch listMode {
        case .cityEvents:
            titleLbl.text = "Events in \(resolvedCity())"
            cityTitleLbl.text = ""
            cityTitleLbl.isHidden = true
            self.topTitleView.cornerRadius = 20
            topViewLeftSideConstraint.constant = 20
            topViewRightSideConstraint.constant = 20
            
        case .tonight:
            titleLbl.text = "Events Tonight"
            cityTitleLbl.text = resolvedCity()
            cityTitleLbl.isHidden = false

        case .venueSearch:
            titleLbl.text = venue?.name ?? "Events"
            cityTitleLbl.text = ""
            cityTitleLbl.isHidden = true
        }

        refreshTopTitleLayout()
    }

    private func refreshTopTitleLayout() {
        let screenWidth = view.bounds.width > 0
            ? view.bounds.width
            : UIScreen.main.bounds.width

        let titleText = titleLbl.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cityText = cityTitleLbl.isHidden
            ? ""
            : (cityTitleLbl.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")

        let titleWidth = ceil((titleText as NSString).size(
            withAttributes: [.font: titleLbl.font ?? Constant.Font.geistRegular(size: 18)]
        ).width)
        let cityWidth = ceil((cityText as NSString).size(
            withAttributes: [.font: cityTitleLbl.font ?? Constant.Font.geistMedium(size: 9)]
        ).width)

        let horizontalPadding = topViewLeftSideConstraint.constant + topViewRightSideConstraint.constant
        let maxWidth = max(140, screenWidth - (topRightSideBtn.isHidden ? 132 : 152))
        let minWidth: CGFloat = cityTitleLbl.isHidden ? 132 : 160
        let targetWidth = min(max(max(titleWidth, cityWidth) + horizontalPadding, minWidth), maxWidth)

        guard abs((topTitleWidthConstraint?.constant ?? 0) - targetWidth) > 0.5 else {
            return
        }

        topTitleWidthConstraint?.constant = targetWidth
        titleLbl.invalidateIntrinsicContentSize()
        cityTitleLbl.invalidateIntrinsicContentSize()
        topTitleView.invalidateIntrinsicContentSize()
        topTitleView.setNeedsLayout()
        topTitleView.superview?.setNeedsLayout()

        UIView.performWithoutAnimation {
            view.layoutIfNeeded()
        }
    }

    private func reloadUI() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }

        updateEmptyState()
    }

    private func insertEventItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                self.isPaginating = false
                self.invalidateFooter()
                self.updateEmptyState()
            }
        }
    }

    private func updateEmptyState() {
        collectionView.backgroundView = !isInitialLoading && eventList.isEmpty
            ? makeEmptyStateView()
            : nil
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: collectionView.bounds)
        container.backgroundColor = .clear

        if showsNoInternetView {
            return V3NoInternetView.backgroundView(
                frame: collectionView.bounds
            ) { [weak self] in
                self?.fetchEvents(reset: true)
            }
        }

        let emptyView = V3EmptyStateView(style: .events)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emptyView)

        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -24),
            emptyView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            emptyView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24)
        ])

        return container
    }

    private func invalidateFooter() {
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.invalidateFooter()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func refreshCollectionLayoutIfNeeded() {
        let width = collectionView.bounds.width

        guard width > 0,
              abs(width - lastCollectionLayoutWidth) > 0.5 else {
            return
        }

        lastCollectionLayoutWidth = width

        UIView.performWithoutAnimation {
            refreshTopTitleLayout()
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !eventList.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()

        fetchEvents(reset: false)
    }
}

// MARK: - UICollectionViewDataSource

extension EventsListVC: UICollectionViewDataSource {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if isInitialLoading {
            return 6
        }

        return eventList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if isInitialLoading {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderCardShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        guard eventList.indices.contains(indexPath.item) else {
            return cell
        }

        cell.configureDiscoverEvent(eventList[indexPath.item])

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PaginationShimmerFooterView.identifier,
                for: indexPath
            ) as! PaginationShimmerFooterView

            footer.isHidden = !(isPaginating && hasMore)
            return footer
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EmptyCollectionReusableView.identifier,
            for: indexPath
        )

        header.isHidden = true
        return header
    }
}

// MARK: - UICollectionViewDelegate

extension EventsListVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard eventList.indices.contains(indexPath.item) else { return }

        AppHaptic.cardOpen()
        Navigate.eventDetailsVC(
            self,
            event: eventList[indexPath.item]
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isInitialLoading else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }
}

// MARK: - PinterestLayoutDelegate

extension EventsListVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {

        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard eventList.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = eventList[indexPath.item]

        let imageHeight = width * 1.2

        let title = event.title
        let venue = event.displayVenueName

        let dateText = event.eventCardDateText()

        let titleFont = Constant.Font.geistMedium(size: 14)
        let venueFont = Constant.Font.geistMedium(size: 12)
        let dateFont = Constant.Font.geistMedium(size: 12)

        let titleHeight = ceil(titleFont.lineHeight * 2)
        let venueHeight = ceil(venueFont.lineHeight)
        let dateHeight = ceil(dateFont.lineHeight)

        let height = imageHeight
            + 16
            + titleHeight
            + 3
            + venueHeight
            + 4
            + dateHeight
        
        return height
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        return 0.1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        return isPaginating && hasMore ? 300 : 0
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension EventsListVC: UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard !isInitialLoading else { return }

        if indexPaths.contains(where: {
            $0.item >= self.eventList.count - 4
        }) {
            loadNextPageIfNeeded()
        }
    }
}

final class EmptyCollectionReusableView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isHidden = true
    }
}
