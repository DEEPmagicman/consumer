//
//  EventsListVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 08/04/26.
//

import UIKit

final class EventsListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cityTitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var topRightSideBtn: AppIconButton!
    
    private var eventList: [Event] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    
    var venue: SearchVenueItem? = nil

    private let eventService = EventService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCollectionView()
        fetchEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickTopRightSideBtn(_ sender: Any) {
        if let venue = venue {
            Navigate.to.searchEventVC(self, venueID: venue.id)
        } else {
            Navigate.to.filtersVC(self)
        }
    }
    
    private func setupUI() {
        if let venue = venue {
            topRightSideBtn.iconTypeValue = AppIconType.search.rawValue
            topRightSideBtn.iconSize = 14
            topRightSideBtn.buttonSize = 40
            
            titleLbl.text = venue.name
        }
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
        layout.lineSpacing = 22
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    private func fetchEvents(reset: Bool = false) {
        guard !isLoading else { return }
        guard hasMore || reset else { return }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            eventList.removeAll()
            reloadUI()
        }

        eventService.fetchEvents(
            from: skip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, events, hasMore in

            guard let self else { return }

            let oldCount = self.eventList.count

            self.eventList = reset
                ? events
                : self.eventList + events

            let newCount = self.eventList.count

            self.skip = self.eventList.count
            self.hasMore = hasMore
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
                return
            }

            self.insertEventItems(indexPaths)
        }
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
