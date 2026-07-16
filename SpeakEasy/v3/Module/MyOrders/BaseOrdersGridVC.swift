//
//  BaseOrdersGridVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 27/05/26.
//

import UIKit

class BaseOrdersGridVC: UIViewController {

    enum SectionType: Int, CaseIterable {
        case upcoming
        case past
    }

    // MARK: - UI
    let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()

    // MARK: - Data

    var upcomingTitle: String { "" }
    var pastTitle: String { "" }
    var emptyTitle: String { "No orders found" }
    var emptyStateStyle: V3EmptyStateStyle { .tickets }

    var upcomingItems: [Booking] = []
    var pastItems: [Booking] = []

    var upcomingSkip = 0
    var pastSkip = 0

    var upcomingHasMany = false
    var pastHasMany = false

    var isLoadingUpcoming = false
    var isLoadingPast = false

    var didLoadUpcoming = false
    var didLoadPast = false

    var isInitialLoading = true
    var isPaginating = false
    
    var paginationShimmerCount: Int {
        2
    }
    
    var paginatingSection: Int?
    var onOrdersScroll: ((UIScrollView) -> Void)?
    private var isPullRefreshing = false
    private var hasReleasedResources = false
    
    // MARK: - Init

    init() {

        let layout = PinterestLayout()

        layout.numberOfColumns = 2
        layout.showsHeaders = true
        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: AppDesign.useModernIOS26Design ? 14 : 50,
            right: 24
        )

        layout.interItemSpacing = 14
        layout.lineSpacing = 16

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        super.init(
            nibName: nil,
            bundle: nil
        )

        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadInitialData()
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

        refreshControl.removeTarget(
            self,
            action: #selector(onPullToRefresh),
            for: .valueChanged
        )
        refreshControl.endRefreshing()
        collectionView.refreshControl = nil
        collectionView.visibleCells.forEach {
            ($0 as? OrderCardShimmerCell)?.releaseResources()
            ($0 as? OrderCardCollectionCell)?.releaseResources()
        }
        collectionView
            .visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
            .forEach {
                ($0 as? PaginationShimmerFooterView)?.releaseResources()
            }
        collectionView.dataSource = nil
        collectionView.delegate = nil
        collectionView.prefetchDataSource = nil
        collectionView.backgroundView = nil
        onOrdersScroll = nil
        upcomingItems.removeAll()
        pastItems.removeAll()
    }

    // MARK: - Setup
    private func setupUI() {

        view.backgroundColor = .clear

        collectionView.backgroundColor = .clear

        collectionView.showsVerticalScrollIndicator = false

        collectionView.alwaysBounceVertical = true
        configurePullToRefresh()

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )
        
        collectionView.register(
            OrdersSectionHeaderView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionHeader,
            withReuseIdentifier:
                OrdersSectionHeaderView.identifier
        )
        
        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                PaginationShimmerFooterView.identifier
        )

        collectionView.register(
            OrdersEmptyFooterView.self,
            forSupplementaryViewOfKind:
                UICollectionView.elementKindSectionFooter,
            withReuseIdentifier:
                OrdersEmptyFooterView.reuseIdentifier
        )
        
        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier:
                OrderCardShimmerCell.identifier
        )

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([

            collectionView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),

            collectionView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),

            collectionView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),

            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    // MARK: - Load Data

    func loadInitialData() {

        loadUpcoming(reset: true)
        loadPast(reset: true)
    }

    func refreshOrders() {
        guard !UserDefault.shared.isGuest else {
            endPullRefreshIfNeeded()
            return
        }

        guard !isLoadingUpcoming,
              !isLoadingPast else {
            endPullRefreshIfNeeded()
            return
        }

        upcomingSkip = 0
        pastSkip = 0
        upcomingHasMany = false
        pastHasMany = false
        didLoadUpcoming = false
        didLoadPast = false
        isInitialLoading = true
        isPaginating = false
        paginatingSection = nil
        loadInitialData()
        finishPullRefreshIfReady()
    }

    func loadUpcoming(reset: Bool) { }

    func loadPast(reset: Bool) { }

    // MARK: - UI Refresh
    func reloadUI() {

        UIView.performWithoutAnimation {

            collectionView.reloadData()

            collectionView.layoutIfNeeded()
        }

        finishPullRefreshIfReady()
    }

    func configure(
        _ cell: OrderCardCollectionCell,
        booking: Booking
    ) { }

    func didSelect(
        _ booking: Booking
    ) { }

    private func item(
        at indexPath: IndexPath
    ) -> Booking? {

        if indexPath.section == SectionType.upcoming.rawValue {
            guard upcomingItems.indices.contains(indexPath.item) else { return nil }
            return upcomingItems[indexPath.item]
        }
        guard pastItems.indices.contains(indexPath.item) else { return nil }
        return pastItems[indexPath.item]
    }
    
    func insertOrderItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            
            self.collectionView.performBatchUpdates ({
                
                self.collectionView.insertItems(
                    at: indexPaths
                )
            }) { _ in
                self.isPaginating = false
                self.paginatingSection = nil
                if let layout = self.collectionView.collectionViewLayout as? PinterestLayout {
                            layout.invalidateFooter()
                        } else {
                            self.collectionView.collectionViewLayout.invalidateLayout()
                        }
            }
        }
    }

    private func configurePullToRefresh() {
        refreshControl.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.85)
        refreshControl.addTarget(
            self,
            action: #selector(onPullToRefresh),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl
    }

    @objc private func onPullToRefresh() {
        isPullRefreshing = true
        refreshOrders()
    }

    private func finishPullRefreshIfReady() {
        guard isPullRefreshing else { return }
        guard !isLoadingUpcoming,
              !isLoadingPast,
              didLoadUpcoming,
              didLoadPast else {
            return
        }

        endPullRefreshIfNeeded()
    }

    private func endPullRefreshIfNeeded() {
        DispatchQueue.main.async {
            self.isPullRefreshing = false
            guard self.refreshControl.isRefreshing else { return }
            self.refreshControl.endRefreshing()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension BaseOrdersGridVC:
UICollectionViewDataSource,
UICollectionViewDelegate {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {

        SectionType.allCases.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        // Initial shimmer
        if isInitialLoading {
            return 6
        }

        let count: Int

        switch SectionType(rawValue: section) {

        case .upcoming:
            count = upcomingItems.count

        case .past:
            count = pastItems.count

        case .none:
            count = 0
        }

        return count
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

        guard let booking = item(at: indexPath) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderCardShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        configure(cell, booking: booking)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        guard !isInitialLoading, let booking = item(at: indexPath) else { return }
        AppHaptic.cardOpen()
        didSelect(booking)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind ==
            UICollectionView.elementKindSectionFooter {

            let sectionHasNoData =
                !isInitialLoading &&
                sectionIsLoaded(indexPath.section) &&
                sectionItems(indexPath.section).isEmpty

            if sectionHasNoData {
                let footer =
                    collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier:
                            OrdersEmptyFooterView.reuseIdentifier,
                        for: indexPath
                    ) as! OrdersEmptyFooterView

                footer.configure(style: emptyStateStyle)

                return footer
            }

            let footer =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier:
                        PaginationShimmerFooterView.identifier,
                    for: indexPath
                ) as! PaginationShimmerFooterView

            footer.isHidden = (!isPaginating || paginatingSection != indexPath.section)

            return footer
        }

        
        let header =
            collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier:
                    OrdersSectionHeaderView.identifier,
                for: indexPath
            ) as! OrdersSectionHeaderView

        let isUpcoming =
            indexPath.section == 0

        let title: String

        if isUpcoming {

            title = upcomingTitle

        } else {

            title = pastTitle
        }
        
        header.configure(text: title)

        return header
    }
}

// MARK: - PinterestLayoutDelegate

extension BaseOrdersGridVC:
PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {

        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard let booking = item(at: indexPath) else {
            return 0.1
        }

        let imageHeight = width * 1.2

        let title =
            booking.event?.title ??
            booking.inviteLink?.name ??
            Constant.String.liveCoverTicket

        let venue =
            booking.venueObject?.name ?? ""

        let dateText: String = {

            if let event = booking.event {

                return event.startDateTime.convertDateFormat(
                    from: .yyyyMMddHHmmss,
                    to: .MMMDDATHMMA,
                    useDayLightSavingTime: true,
                    customTimeZone:
                        booking.venueObject?.useTimezone ?? ""
                )
            }

            return booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .MMMDDATHMMA
            )
        }()

        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 13)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = ceil(titleFont.lineHeight * 2)
        let venueHeight = ceil(venueFont.lineHeight)
        let dateHeight = ceil(dateFont.lineHeight)

        let height = imageHeight
            + 16
            + titleHeight
            + 3
            + venueHeight
            + 10
            + dateHeight
        
        return height
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {

        if isPaginating && paginatingSection == section {
            return 260
        }

        guard !isInitialLoading else { return 0 }
        guard sectionIsLoaded(section) else { return 0 }
        guard sectionItems(section).isEmpty else { return 0 }

        return 238
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onOrdersScroll?(scrollView)

        guard !isInitialLoading else { return }
        guard !UserDefault.shared.isGuest else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }
    
    private func loadNextPageIfNeeded() {
        guard !isPaginating else { return }

        let visibleSections = Set(
            collectionView.indexPathsForVisibleItems.map { $0.section }
        )

        if visibleSections.contains(0),
           upcomingHasMany,
           !isLoadingUpcoming,
           !upcomingItems.isEmpty {

            isPaginating = true
            paginatingSection = 0
            collectionView.collectionViewLayout.invalidateLayout()

            loadUpcoming(reset: false)
            return
        }

        if visibleSections.contains(1),
           pastHasMany,
           !isLoadingPast,
           !pastItems.isEmpty {

            isPaginating = true
            paginatingSection = 1
            collectionView.collectionViewLayout.invalidateLayout()

            loadPast(reset: false)
        }
    }
}

private extension BaseOrdersGridVC {

    func sectionItems(_ section: Int) -> [Booking] {
        section == SectionType.upcoming.rawValue ? upcomingItems : pastItems
    }

    func sectionIsLoaded(_ section: Int) -> Bool {
        section == SectionType.upcoming.rawValue ? didLoadUpcoming : didLoadPast
    }
}

private final class OrdersEmptyFooterView: UICollectionReusableView {

    static let reuseIdentifier = "OrdersEmptyFooterView"

    private let emptyStateView = V3EmptyStateView(style: .tickets)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(style: V3EmptyStateStyle) {
        emptyStateView.configure(style: style)
    }

    private func setupUI() {
        backgroundColor = .clear

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
