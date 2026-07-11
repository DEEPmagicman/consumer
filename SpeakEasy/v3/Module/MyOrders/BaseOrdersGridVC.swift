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
    private let emptyView = UILabel()

    // MARK: - Data

    var upcomingTitle: String { "" }
    var pastTitle: String { "" }
    var emptyTitle: String { "No orders found" }

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
    
    // MARK: - Init

    init() {

        let layout = PinterestLayout()

        layout.numberOfColumns = 2
        layout.showsHeaders = true
        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: 34,
            right: 24
        )

        layout.interItemSpacing = 14
        layout.lineSpacing = 22

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

    // MARK: - Setup
    private func setupUI() {

        view.backgroundColor = .clear

        collectionView.backgroundColor = .clear

        collectionView.showsVerticalScrollIndicator = false

        collectionView.alwaysBounceVertical = true

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
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier:
                OrderCardShimmerCell.identifier
        )

        view.addSubview(collectionView)

        emptyView.textColor =
            UIColor.white.withAlphaComponent(0.55)

        emptyView.font =
            Constant.Font.geistMedium(size: 16)

        emptyView.textAlignment = .center

        emptyView.numberOfLines = 0

        emptyView.isHidden = true

        emptyView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyView)

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
            ),

            emptyView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),

            emptyView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: -40
            ),

            emptyView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 40
            ),

            emptyView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -40
            )
        ])
    }

    // MARK: - Load Data

    func loadInitialData() {

        loadUpcoming(reset: true)
        loadPast(reset: true)
    }

    func refreshOrders() {
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
    }

    func loadUpcoming(reset: Bool) { }

    func loadPast(reset: Bool) { }

    // MARK: - UI Refresh
    func reloadUI() {

        let hasNoData =
            didLoadUpcoming &&
            didLoadPast &&
            upcomingItems.isEmpty &&
            pastItems.isEmpty

        emptyView.isHidden = !hasNoData

        collectionView.isHidden = hasNoData

        emptyView.text = emptyTitle

        UIView.performWithoutAnimation {

            collectionView.reloadData()

            collectionView.layoutIfNeeded()
        }
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
        didSelect(booking)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind ==
            UICollectionView.elementKindSectionFooter {

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

            title =
                upcomingItems.isEmpty
                ? "No Upcoming Orders"
                : upcomingTitle

        } else {

            title =
                pastItems.isEmpty
                ? "No Past Orders"
                : pastTitle
        }
        
        header.configure( text: title, isEmpty: isUpcoming ? upcomingItems.isEmpty : pastItems.isEmpty )

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

        let titleFont =
            Constant.Font.geistMedium(size: 15)

        let venueFont =
            Constant.Font.geistMedium(size: 14)

        let dateFont =
            Constant.Font.geistMedium(size: 14)

        let textWidth = width

        let titleHeight =
            title.boundingRect(
                with: CGSize(
                    width: textWidth,
                    height: .greatestFiniteMagnitude
                ),
                options: [
                    .usesLineFragmentOrigin,
                    .usesFontLeading
                ],
                attributes: [
                    .font: titleFont
                ],
                context: nil
            ).height

        let venueHeight =
            venue.boundingRect(
                with: CGSize(
                    width: textWidth,
                    height: .greatestFiniteMagnitude
                ),
                options: [
                    .usesLineFragmentOrigin,
                    .usesFontLeading
                ],
                attributes: [
                    .font: venueFont
                ],
                context: nil
            ).height

        let dateHeight =
            dateText.boundingRect(
                with: CGSize(
                    width: textWidth,
                    height: .greatestFiniteMagnitude
                ),
                options: [
                    .usesLineFragmentOrigin,
                    .usesFontLeading
                ],
                attributes: [
                    .font: dateFont
                ],
                context: nil
            ).height

        // MARK: Final Height

        let totalHeight =
            imageHeight +
            16 +
            titleHeight +
            4 +
            venueHeight +
            10 +
            dateHeight

        return ceil(totalHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {

        guard isPaginating else { return 0 }
        guard paginatingSection == section else { return 0 }
        
        return isPaginating ? 300 : 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
