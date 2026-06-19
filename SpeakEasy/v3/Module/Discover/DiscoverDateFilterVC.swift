//
//  DiscoverDateFilterVC.swift
//  SpeakEasy-Consumer
//

import UIKit

final class DiscoverDateFilterVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateCollectionView: UICollectionView!

    var selectedDates = [String]()
    private var selectedAPIDates = [String]()

    private var selectedDateIndex = 0

    // MARK: - Event Data
    private var eventList: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var selectedCity = UserDefault.shared.activeCity
    private var loadID = 0
    private var isNavigatingToEvent = false

    private let discoverService = DiscoverService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupDateCollectionView()
        setupEventCollectionView()

        fetchEvents(reset: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isNavigatingToEvent = false
    }

    func updateFilterDates(
        _ dates: [String],
        apiDates: [String]? = nil,
        city: String
    ) {

        selectedDates = dates
        selectedAPIDates = apiDates ?? dates
        selectedCity = city
        selectedDateIndex = 0

        guard isViewLoaded else {
            return
        }

        dateCollectionView.reloadData()

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }

        fetchEvents(reset: true)
    }

    // MARK: - Setup Date CollectionView
    private func setupDateCollectionView() {

        dateCollectionView.delegate = self
        dateCollectionView.dataSource = self

        dateCollectionView.register(
            DateSelectionCVC.nib,
            forCellWithReuseIdentifier: DateSelectionCVC.identifier
        )

        if let layout = dateCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {

            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 12

            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: 16,
                bottom: 0,
                right: 16
            )
        }

        dateCollectionView.showsHorizontalScrollIndicator = false
        dateCollectionView.showsVerticalScrollIndicator = false
    }

    // MARK: - Setup Event CollectionView
    private func setupEventCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )

        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )

        collectionView.register(
            EmptyCollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EmptyCollectionReusableView.identifier
        )

        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Fetch Events
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

        let city = selectedCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        discoverService.fetchDiscoverEvents(
            city: city.isEmpty ? UserDefault.shared.activeCity : city,
            skip: skip,
            timeWindow: selectedDateTimeWindow(),
            eventListType: .eventsInCity,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in

            guard let self else {
                return
            }

            guard self.loadID == requestID else {
                return
            }

            guard isSuccess,
                  let page else {
                self.isLoading = false
                self.isInitialLoading = false
                self.isPaginating = false
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                self.reloadUI()
                return
            }

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
                return
            }

            self.insertEventItems(indexPaths)
        }
    }

    private func selectedDateTimeWindow() -> DiscoverEventTimeWindow {
        let apiDate: String

        if selectedAPIDates.indices.contains(selectedDateIndex) {
            apiDate = selectedAPIDates[selectedDateIndex]
        } else if selectedDates.indices.contains(selectedDateIndex) {
            apiDate = selectedDates[selectedDateIndex]
        } else {
            apiDate = Date().string(format: .YYYYMMDD, isUTC: false)
        }

        return .selectedDay(apiDate)
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

    private func navigateToEvent(_ event: Event) {
        guard !isNavigatingToEvent,
              presentedViewController == nil
        else {
            return
        }

        isNavigatingToEvent = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            Navigate.eventDetailsVC(
                self,
                event: event
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                self?.isNavigatingToEvent = false
            }
        }
    }
}

extension DiscoverDateFilterVC:
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        if collectionView == dateCollectionView {
            return selectedDates.count
        }

        if isInitialLoading {
            return 6
        }

        return eventList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        // MARK: - Date CollectionView
        if collectionView == dateCollectionView {

            let cell: DateSelectionCVC = collectionView.dequeue(
                withIdentifier: DateSelectionCVC.identifier,
                for: indexPath
            )

            cell.configure(
                with: selectedDates[indexPath.item],
                isSelected: selectedDateIndex == indexPath.item
            )

            return cell
        }

        // MARK: - Event CollectionView
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

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        // MARK: - Date Selection
        if collectionView == dateCollectionView {

            selectedDateIndex = indexPath.item

            dateCollectionView.reloadData()

            DispatchQueue.main.async {

                self.dateCollectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            }

            fetchEvents(reset: true)
            return
        }

        // MARK: - Event Selection
        guard !isInitialLoading else {
            return
        }

        guard eventList.indices.contains(indexPath.item) else {
            return
        }

        collectionView.deselectItem(
            at: indexPath,
            animated: true
        )

        navigateToEvent(eventList[indexPath.item])
    }

    // MARK: - Pagination
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard scrollView == collectionView else {
            return
        }

        guard !isInitialLoading else {
            return
        }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }

    // MARK: - Size
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        // MARK: - Date CollectionView
        if collectionView == dateCollectionView {

            return CGSize(
                width: 100,
                height: 40
            )
        }

        // MARK: - Event CollectionView
        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {

        if collectionView == dateCollectionView {
            return 12
        }

        return 22
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {

        if collectionView == dateCollectionView {
            return 12
        }

        return 14
    }
}

// MARK: - PinterestLayoutDelegate

extension DiscoverDateFilterVC: PinterestLayoutDelegate {

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

extension DiscoverDateFilterVC: UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard collectionView == self.collectionView else {
            return
        }

        guard !isInitialLoading else {
            return
        }

        if indexPaths.contains(where: {
            $0.item >= self.eventList.count - 4
        }) {
            loadNextPageIfNeeded()
        }
    }
}
