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

    private var eventList: [Event] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0
    private var screenFilterCity: String?
    private var loadID = 0

    var venue: SearchVenueItem? = nil
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

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickTopRightSideBtn(_ sender: Any) {
        if let venue = venue {
            Navigate.to.searchEventVC(self, venueID: venue.id)
        } else {
            presentCityFilter()
        }
    }

    @IBAction func onClickCityBtn(_ sender: Any) {
        presentCityFilter()
    }

    private func setupUI() {
        if let venue = venue {
            topRightSideBtn.iconTypeValue = AppIconType.search.rawValue
            topRightSideBtn.iconSize = 14
            topRightSideBtn.buttonSize = 40

            titleLbl.text = venue.name
            cityTitleLbl.text = ""
        } else {
            updateCityTitle()
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
            skip: skip,
            timeWindow: eventTimeWindow(),
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in

            guard let self else { return }
            guard self.loadID == requestID else { return }

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
                self.updateEmptyState()
                return
            }

            self.insertEventItems(indexPaths)
        }
    }

    private func eventTimeWindow() -> DiscoverEventTimeWindow {
        switch listMode {
        case .cityEvents:
            return .cityEvents()
        case .tonight:
            return .tonight()
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
            : nil

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
            cityTitleLbl.isHidden = true
        case .tonight:
            titleLbl.text = "Events Tonight"
            cityTitleLbl.text = resolvedCity()
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

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No events found"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 18)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Try another city."
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
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
