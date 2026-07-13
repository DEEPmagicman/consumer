//
//  VenueExperiencesVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class VenueExperiencesVC: UIViewController,
                           SJSegmentedViewControllerViewSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!

    weak var scrollDelegate: ChildScrollDelegate?
    var venueId = ""

    private let emptyStateView = V3EmptyStateView(style: .premiumEvents)
    private var events: [Event] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupEmptyStateView()
        getEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshCollectionLayoutIfNeeded()
    }

    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return collectionView
    }
    
    @IBAction func onClickPermuimExp(_ sender: Any) {
        Navigate.to.presentPremiumExpPopUp(self)
    }
    
}

// MARK: - Setup

extension VenueExperiencesVC {

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
            top: 10,
            left: 24,
            bottom: 34,
            right: 24
        )

        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    private func setupEmptyStateView() {
        emptyView.subviews.forEach { $0.removeFromSuperview() }
        emptyStateView.configure(style: .premiumEvents)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor)
        ])
    }

    private func reloadUI() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    private func insertEventItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                self.isPaginating = false
                self.invalidateFooter()
            }
        }
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
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !events.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()

        getEvents(reset: false)
    }
}

// MARK: - API

extension VenueExperiencesVC {

    func refreshFromSocket() {
        guard isViewLoaded else { return }
        getEvents(reset: true)
    }

    func getEvents(reset: Bool = false) {

        guard !isLoading else { return }
        guard hasMore || reset else { return }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            events.removeAll()
            emptyView.isHidden = true
            collectionView.isHidden = false
            reloadUI()
        }

        VenuePresenter.getEventVenues(
            venueId: venueId,
            skip: skip,
            time: "UPCOMING",
            isPremium: true
        ) { [weak self] isSuccess,
            errMsg,
            list,
            hasMore in

            guard let self = self else { return }

            DispatchQueue.main.async {
                let oldCount = self.events.count

                self.isLoading = false

                if isSuccess {

                    let newItems = list.filter { newEvent in
                        !self.events.contains(where: {
                            $0.id == newEvent.id
                        })
                    }

                    self.events.append(contentsOf: newItems)

                    self.skip = self.events.count
                    self.hasMore = hasMore
                    let newCount = self.events.count
                    let wasInitialLoading = self.isInitialLoading
                    self.isInitialLoading = false

                    self.emptyView.isHidden = !self.events.isEmpty
                    self.collectionView.isHidden = self.events.isEmpty

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
                        return
                    }

                    self.insertEventItems(indexPaths)

                } else {
                    self.isInitialLoading = false
                    self.isPaginating = false
                    self.invalidateFooter()

                    self.emptyView.isHidden = false
                    self.collectionView.isHidden = true

                    print(errMsg ?? "Error")
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension VenueExperiencesVC: UICollectionViewDataSource {

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

        return events.count
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

        let event = events[indexPath.item]

        cell.configureDiscoverEvent(event)

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

extension VenueExperiencesVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard events.indices.contains(indexPath.item) else { return }

        let event = events[indexPath.item]

        Navigate.eventDetailsVC(
            self,
            event: event
        )
    }

    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {

        scrollDelegate?.childScrollViewDidScroll(scrollView)

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

// MARK: - UICollectionViewDataSourcePrefetching

extension VenueExperiencesVC:
    UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {

        guard !isInitialLoading else { return }

        if indexPaths.contains(where: {
            $0.item >= self.events.count - 4
        }) {
            loadNextPageIfNeeded()
        }
    }
}

// MARK: - PinterestLayoutDelegate

extension VenueExperiencesVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard events.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = events[indexPath.item]

        let imageHeight = width * 1.2

        let title = event.title
        let venue = event.venue?.name ?? ""

        let dateText = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: event.venue?.useTimezone ?? ""
        )

        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 14)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = title.boundingRect(
            with: CGSize(
                width: width,
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

        let venueHeight = venue.boundingRect(
            with: CGSize(
                width: width,
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

        let dateHeight = dateText.boundingRect(
            with: CGSize(
                width: width,
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

        let totalHeight =
            imageHeight +
            16 +
            titleHeight +
            3 +
            venueHeight +
            10 +
            dateHeight

        return ceil(totalHeight)
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
