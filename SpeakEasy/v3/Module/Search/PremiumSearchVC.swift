//
//  PremiumSearchVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit
import SDWebImage

private enum PremiumSearchHeaderMetrics {
    static let horizontalPadding: CGFloat = 24
    static let topSpacing: CGFloat = 18
    static let titleHeight: CGFloat = 24
    static let titleContentSpacing: CGFloat = 18
    static let venueTitleContentSpacing: CGFloat = 6
    static let sectionSpacing: CGFloat = 26
    static let venueRowHeight: CGFloat = 54
    static let venueRowSpacing: CGFloat = 8
    static let maxDisplayedVenues = 3
    static let artistRowHeight: CGFloat = 99
    static let artistItemWidth: CGFloat = 84
    static let artistImageSize: CGFloat = 75
    static let artistItemSpacing: CGFloat = 10
    static let artistItemImageInset: CGFloat = (artistItemWidth - artistImageSize) / 2
    static let artistScrollLeadingInset: CGFloat = horizontalPadding - artistItemImageInset

    static func height(
        isLoading: Bool,
        venueCount: Int,
        artistCount: Int,
        showsEventTitle: Bool
    ) -> CGFloat {

        var height: CGFloat = 0

        if isLoading || venueCount > 0 {
            let rowCount = isLoading ? maxDisplayedVenues : min(venueCount, maxDisplayedVenues)
            height += titleHeight
            height += venueTitleContentSpacing
            height += CGFloat(rowCount) * venueRowHeight
            height += CGFloat(max(0, rowCount - 1)) * venueRowSpacing
            height += sectionSpacing
        }

        if isLoading || artistCount > 0 {
            height += titleHeight
            height += titleContentSpacing
            height += artistRowHeight
            height += sectionSpacing
        }

        if showsEventTitle {
            height += titleHeight
            height += titleContentSpacing
        }

        return max(height, 46)
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

final class PremiumSearchVC: UIViewController {

    private let headerView = PremiumSearchHeaderView()
    private let collectionView: UICollectionView
    private let emptyView = SearchEmptyStateView()
    private let searchService = SearchFlowService.shared
    private var venues: [SearchVenueItem] = []
    private var events: [SearchEventItem] = []
    private var artists: [SearchArtistItem] = []
    private var searchWorkItem: DispatchWorkItem?
    private var searchRequestId = UUID()
    private var currentQuery = ""
    private var displayedQuery: String?
    private var hasMoreVenues = false
    private var hasMoreEvents = false
    private var isInitialLoading = false
    private var isLoadingMoreEvents = false
    private var paginatingSection: Int?
    private let venueTake = 10
    private let eventTake = 10
    private var lastCollectionLayoutWidth: CGFloat = 0
    private var lastKeyboardBottomInset: CGFloat = -1
    private var appliedGradientBounds: CGRect = .zero
    private var emptyStateVisible = false
    private var heightCache: [String: CGFloat] = [:]

    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = false
        layout.headerToItemsSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
//        layout.sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = false
        layout.headerToItemsSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        layout.delegate = self
    }

    deinit {
        searchWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applySearch("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerView.reloadUser()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerView.searchView.focus()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if appliedGradientBounds != view.bounds {
            appliedGradientBounds = view.bounds
            view.applyScreenBgGradient()
        }
        refreshCollectionLayoutIfNeeded()
    }

    private func setupUI() {
        setupHeader()
        setupCollectionView()
        setupEmptyState()
        setupKeyboardObservers()
        setupConstraints()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self
        headerView.searchView.onTextChanged = { [weak self] text in
            self?.applySearch(text)
        }
        view.addSubview(headerView)
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )
        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )
        collectionView.register(
            PremiumSearchHeaderSupplementaryView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PremiumSearchHeaderSupplementaryView.identifier
        )
        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )
        view.addSubview(collectionView)
    }

    private func setupEmptyState() {
        emptyView.isHidden = true
        emptyView.alpha = 0
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: PremiumSearchHeaderMetrics.topSpacing),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -38),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            emptyView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }

    private func applySearch(_ text: String) {
        searchWorkItem?.cancel()
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query != currentQuery || isInitialLoading || displayedQuery != query else {
            return
        }

        currentQuery = query
        searchRequestId = UUID()
        isLoadingMoreEvents = false
        paginatingSection = nil
        updateEmptyState(animated: false)

        let requestId = searchRequestId
        let isFirstLoad = events.isEmpty && venues.isEmpty && artists.isEmpty
        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  self.searchRequestId == requestId,
                  self.currentQuery == query else { return }

            self.showInitialLoadingIfNeeded(clearExistingResults: true)
            self.loadSearch(
                reset: true,
                query: query,
                requestId: requestId
            )
        }

        searchWorkItem = workItem
        let delay: TimeInterval = isFirstLoad ? 0 : 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func loadSearch(
        reset: Bool,
        query: String,
        requestId: UUID
    ) {
        let oldCount = events.count
        let eventSkip = reset ? 0 : oldCount

        searchService.search(
            keyword: query,
            venueSkip: 0,
            venueTake: reset ? venueTake : 0,
            eventSkip: eventSkip,
            eventTake: eventTake
        ) { [weak self] isSuccess, _, result in
            DispatchQueue.main.async {
                guard let self,
                      self.searchRequestId == requestId,
                      self.currentQuery == query else { return }

                if reset {
                    self.isInitialLoading = false
                    self.displayedQuery = query
                }

                guard isSuccess else {
                    if reset {
                        self.venues.removeAll()
                        self.events.removeAll()
                        self.artists.removeAll()
                        self.hasMoreVenues = false
                        self.heightCache.removeAll(keepingCapacity: true)
                        self.reloadCollectionWithoutAnimation()
                    } else {
                        self.isLoadingMoreEvents = false
                        self.paginatingSection = nil
                        self.invalidatePaginationFooter()
                    }

                    self.hasMoreEvents = false
                    self.updateEmptyState(animated: true)
                    return
                }

                if reset {
                    self.venues = result.venues
                    self.events = result.events
                    self.artists = result.artists
                    self.hasMoreVenues = result.hasMoreVenues
                    self.hasMoreEvents = result.hasMoreEvents
                    self.heightCache.removeAll(keepingCapacity: true)
                    self.reloadCollectionWithoutAnimation()
                    self.updateEmptyState(animated: true)
                    return
                }

                let incomingEvents = result.events
                self.hasMoreEvents = result.hasMoreEvents

                guard !incomingEvents.isEmpty else {
                    self.isLoadingMoreEvents = false
                    self.paginatingSection = nil
                    self.invalidatePaginationFooter()
                    self.updateEmptyState(animated: true)
                    return
                }

                self.events += incomingEvents

                let newCount = self.events.count
                let indexPaths = (oldCount..<newCount).map {
                    IndexPath(item: $0, section: 0)
                }

                self.insertEventsWithoutAnimation(indexPaths)
                self.updateEmptyState(animated: true)
            }
        }
    }

    private func loadMoreEventsIfNeeded() {
        guard !isInitialLoading,
              !isLoadingMoreEvents,
              hasMoreEvents,
              !events.isEmpty else { return }

        isLoadingMoreEvents = true
        paginatingSection = 0

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
        }

        let query = currentQuery
        let requestId = searchRequestId

        loadSearch(
            reset: false,
            query: query,
            requestId: requestId
        )
    }

    private func reloadCollectionWithoutAnimation() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    private func insertEventsWithoutAnimation(_ indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else {
            isLoadingMoreEvents = false
            paginatingSection = nil
            invalidatePaginationFooter()
            return
        }

        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }

                self.isLoadingMoreEvents = false
                self.paginatingSection = nil

                UIView.performWithoutAnimation {
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }
        }
    }

    private func invalidatePaginationFooter() {
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.invalidateFooter()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func showInitialLoadingIfNeeded(clearExistingResults: Bool) {
        if clearExistingResults {
            venues.removeAll(keepingCapacity: true)
            events.removeAll(keepingCapacity: true)
            artists.removeAll(keepingCapacity: true)
            heightCache.removeAll(keepingCapacity: true)
            hasMoreVenues = false
            hasMoreEvents = false
            paginatingSection = nil
        }

        isLoadingMoreEvents = false
        isInitialLoading = true
        updateEmptyState(animated: false)
        reloadCollectionWithoutAnimation()
    }

    private func updateEmptyState(animated: Bool) {
        let shouldShow =
        !isInitialLoading &&
        !isLoadingMoreEvents &&
        events.isEmpty
        && venues.isEmpty
        && artists.isEmpty

        guard shouldShow != emptyStateVisible else { return }
        emptyStateVisible = shouldShow

        let updates = {
            self.emptyView.alpha = shouldShow ? 1 : 0
        }

        if shouldShow {
            emptyView.isHidden = false
        }

        let completion: (Bool) -> Void = { _ in
            if !shouldShow {
                self.emptyView.isHidden = true
            }
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                animations: updates,
                completion: completion
            )
        } else {
            updates()
            completion(true)
        }
    }

    private func refreshCollectionLayoutIfNeeded() {
        let width = collectionView.bounds.width
        guard width > 0,
              abs(width - lastCollectionLayoutWidth) > 0.5 else { return }

        lastCollectionLayoutWidth = width
        heightCache.removeAll(keepingCapacity: true)
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        updateCollectionInsetsForKeyboard(notification, isHiding: false)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        updateCollectionInsetsForKeyboard(notification, isHiding: true)
    }

    private func updateCollectionInsetsForKeyboard(
        _ notification: Notification,
        isHiding: Bool
    ) {
        let userInfo = notification.userInfo
        let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        let bottomInset: CGFloat
        if isHiding {
            bottomInset = 0
        } else if let frame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let convertedFrame = view.convert(frame, from: nil)
            bottomInset = max(0, view.bounds.maxY - convertedFrame.minY)
        } else {
            bottomInset = 0
        }

        guard abs(bottomInset - lastKeyboardBottomInset) > 0.5 else { return }
        lastKeyboardBottomInset = bottomInset

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    private static let maxDisplayedVenues = PremiumSearchHeaderMetrics.maxDisplayedVenues

    private var headerHeight: CGFloat {
        PremiumSearchHeaderMetrics.height(
            isLoading: isInitialLoading,
            venueCount: venues.count,
            artistCount: artists.count,
            showsEventTitle: isInitialLoading || !events.isEmpty
        )
    }
}

extension PremiumSearchVC: PremiumSearchHeaderViewDelegate {
    func premiumSearchHeaderDidTapProfile(_ view: PremiumSearchHeaderView) {
        LoginRequiredCoordinator.perform(from: self) { [weak self] in
            guard let self else { return }
            Navigate.to.profileMenuVC(self)
        }
    }

    func premiumSearchHeaderDidTapMap(_ view: PremiumSearchHeaderView) {
        Navigate.to.gotoMapVC(self)
    }

    func premiumSearchHeaderDidTapSearch(_ view: PremiumSearchHeaderView) {
        headerView.searchView.focus()
    }

    func premiumSearchHeaderDidTapClear(_ view: PremiumSearchHeaderView) {
        applySearch("")
    }
}

extension PremiumSearchVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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

        guard events.indices.contains(indexPath.item) else { return cell }

        let item = events[indexPath.item]
        cell.configure(
            OrderCardViewModel(
                imageURL: item.imageURL,
                placeholder: UIImage(resource: .premiumExpBg),
                badgeText: nil,
                title: item.title,
                subtitle: item.venueName?.uppercased() ?? "",
                dateText: item.dateText,
                statusText: nil,
                statusBgColor: nil,
                statusTextColor: nil
            )
        )

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

            footer.isHidden = !isLoadingMoreEvents || paginatingSection != indexPath.section
            return footer
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PremiumSearchHeaderSupplementaryView.identifier,
            for: indexPath
        ) as! PremiumSearchHeaderSupplementaryView

        // Cap visible venues while "View more venues" is hidden for now.
        let displayedVenues = Array(venues.prefix(PremiumSearchVC.maxDisplayedVenues))

        header.configure(
            venues: displayedVenues,
            artists: artists,
            showsVenue: !venues.isEmpty,
            showsViewMoreVenues: false,
            isLoading: isInitialLoading,
            showsEventTitle: isInitialLoading || !events.isEmpty
        )

        header.onViewVenue = { [weak self] venue in
            guard let self else { return }
            if let venueDetails = venue.venue {
                Navigate.to.premiumVenueVC(self, venueDetails: venueDetails)
            }
        }

        header.onViewMoreVenues = { [weak self] in
            guard let self else { return }
            Navigate.to.searchVenueVC(
                self,
                keyword: self.currentQuery,
                mode: .global
            )
        }

        header.onViewArtist = { [weak self] artist in
            guard let self else { return }
            Navigate.to.gotoArtistDetailsVC(
                self,
                artist: ArtistDetailsContext(
                    id: artist.id,
                    venueId: "",
                    name: artist.name,
                    imageKey: artist.artist?.artistImage?.key ?? artist.imageURL
                )
            )
        }

        return header
    }
}

extension PremiumSearchVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isInitialLoading,
              events.indices.contains(indexPath.item),
              let event = events[indexPath.item].event else { return }

        Navigate.eventDetailsVC(self, event: event)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isInitialLoading else { return }
        guard !isLoadingMoreEvents else { return }
        guard hasMoreEvents else { return }
        guard !events.isEmpty else { return }

        let offsetY = scrollView.contentOffset.y
        let visibleHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height

        guard contentHeight > visibleHeight else { return }

        let threshold: CGFloat = 280

        if offsetY + visibleHeight + threshold >= contentHeight {
            loadMoreEventsIfNeeded()
        }
    }
}

extension PremiumSearchVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        if isInitialLoading {
            return ceil((width * 1.2) + 16 + 18 + 10 + 15 + 12 + 14)
        }

        guard events.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = events[indexPath.item]
        let cacheKey = "\(event.id)-\(Int(width.rounded(.toNearestOrAwayFromZero)))"
        if let cachedHeight = heightCache[cacheKey] {
            return cachedHeight
        }

        let imageHeight = width * 1.2
        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 14)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = event.title.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: titleFont],
            context: nil
        ).height

        let venueHeight = (event.venueName ?? "").boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: venueFont],
            context: nil
        ).height

        let dateHeight = (event.dateText ?? "").boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: dateFont],
            context: nil
        ).height

        let height = ceil(imageHeight + 16 + titleHeight + 3 + venueHeight + 10 + dateHeight)
        heightCache[cacheKey] = height
        return height
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        headerHeight
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        guard isLoadingMoreEvents else { return 0 }
        guard paginatingSection == section else { return 0 }

        return 300
    }
}

// MARK: - PremiumSearchHeaderSupplementaryView

private final class PremiumSearchHeaderSupplementaryView: UICollectionReusableView {

    private let stackView = UIStackView()
    // Up to maxDisplayedVenues venue rows, lazily created
    private var venueRows: [PremiumSearchVenueResultView] = []
    private var venueShimmerRows: [PremiumSearchVenueShimmerView] = []
    private let viewMoreVenuesButton = UIButton(type: .system)
    private let venueTitleLabel = UILabel()
    private let artistTitleLabel = UILabel()
    private let artistScrollContainer = UIView()
    private let artistScrollView = UIScrollView()
    private let artistStackView = UIStackView()
    private let artistShimmerContainer = UIView()
    private let artistShimmerStackView = UIStackView()
    private let titleLabel = UILabel()
    private var artistViews: [PremiumSearchArtistResultView] = []
    private var configuredArtistIDs: [String] = []

    var onViewVenue: ((SearchVenueItem) -> Void)?
    var onViewMoreVenues: (() -> Void)?
    var onViewArtist: ((SearchArtistItem) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onViewVenue = nil
        onViewMoreVenues = nil
        onViewArtist = nil
    }

    private func setup() {
        backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)

        venueTitleLabel.text = "Venue"
        venueTitleLabel.textColor = .white
        venueTitleLabel.font = Constant.Font.geistRegular(size: 18)
        stackView.addArrangedSubview(venueTitleLabel)

        // Pre-create 5 venue rows; show/hide as needed
        for _ in 0 ..< 5 {
            let row = PremiumSearchVenueResultView()
            row.onViewVenue = { [weak self] venue in
                self?.onViewVenue?(venue)
            }
            venueRows.append(row)
            stackView.addArrangedSubview(row)
            row.isHidden = true
        }

        for _ in 0 ..< PremiumSearchHeaderMetrics.maxDisplayedVenues {
            let row = PremiumSearchVenueShimmerView()
            venueShimmerRows.append(row)
            stackView.addArrangedSubview(row)
            row.isHidden = true
        }

        viewMoreVenuesButton.setTitle("View more venues", for: .normal)
        viewMoreVenuesButton.setTitleColor(.white.withAlphaComponent(0.85), for: .normal)
        viewMoreVenuesButton.titleLabel?.font = Constant.Font.geistMedium(size: 13)
        viewMoreVenuesButton.contentHorizontalAlignment = .left
        viewMoreVenuesButton.addTarget(
            self,
            action: #selector(onViewMoreVenuesPressed),
            for: .touchUpInside
        )
        stackView.addArrangedSubview(viewMoreVenuesButton)
        viewMoreVenuesButton.heightAnchor
            .constraint(equalToConstant: 24)
            .withPriority(.defaultHigh)
            .isActive = true

        artistTitleLabel.text = "Artists"
        artistTitleLabel.textColor = .white
        artistTitleLabel.font = Constant.Font.geistRegular(size: 18)
        stackView.addArrangedSubview(artistTitleLabel)

        artistScrollContainer.translatesAutoresizingMaskIntoConstraints = false
        artistScrollContainer.backgroundColor = .clear
        artistScrollContainer.clipsToBounds = false
        stackView.addArrangedSubview(artistScrollContainer)

        artistScrollView.translatesAutoresizingMaskIntoConstraints = false
        artistScrollView.backgroundColor = .clear
        artistScrollView.showsHorizontalScrollIndicator = false
        artistScrollView.showsVerticalScrollIndicator = false
        artistScrollView.alwaysBounceHorizontal = true
        artistScrollView.contentInset = UIEdgeInsets(
            top: 0,
            left: PremiumSearchHeaderMetrics.artistScrollLeadingInset,
            bottom: 0,
            right: PremiumSearchHeaderMetrics.horizontalPadding
        )
        artistScrollView.scrollIndicatorInsets = artistScrollView.contentInset
        addSubview(artistScrollView)

        artistStackView.translatesAutoresizingMaskIntoConstraints = false
        artistStackView.axis = .horizontal
        artistStackView.alignment = .top
        artistStackView.spacing = PremiumSearchHeaderMetrics.artistItemSpacing
        artistScrollView.addSubview(artistStackView)

        for _ in 0..<10 {
            let view = PremiumSearchArtistResultView()
            view.onViewArtist = { [weak self] artist in
                self?.onViewArtist?(artist)
            }
            artistViews.append(view)
            artistStackView.addArrangedSubview(view)
            view.isHidden = true
        }

        artistShimmerContainer.translatesAutoresizingMaskIntoConstraints = false
        artistShimmerContainer.backgroundColor = .clear
        stackView.addArrangedSubview(artistShimmerContainer)

        artistShimmerStackView.translatesAutoresizingMaskIntoConstraints = false
        artistShimmerStackView.axis = .horizontal
        artistShimmerStackView.alignment = .top
        artistShimmerStackView.spacing = PremiumSearchHeaderMetrics.artistItemSpacing
        artistShimmerContainer.addSubview(artistShimmerStackView)

        for _ in 0 ..< 3 {
            artistShimmerStackView.addArrangedSubview(PremiumSearchArtistShimmerItemView())
        }

        titleLabel.text = "Upcoming events"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 18)
        stackView.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PremiumSearchHeaderMetrics.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PremiumSearchHeaderMetrics.horizontalPadding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            venueTitleLabel.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.titleHeight).withPriority(.defaultHigh),
            artistTitleLabel.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.titleHeight).withPriority(.defaultHigh),
            titleLabel.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.titleHeight).withPriority(.defaultHigh),

            artistScrollContainer.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistRowHeight).withPriority(.defaultHigh),
            artistShimmerContainer.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistRowHeight).withPriority(.defaultHigh),
            artistScrollView.topAnchor.constraint(equalTo: artistScrollContainer.topAnchor),
            artistScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artistScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            artistScrollView.bottomAnchor.constraint(equalTo: artistScrollContainer.bottomAnchor),

            artistShimmerStackView.topAnchor.constraint(equalTo: artistShimmerContainer.topAnchor),
            artistShimmerStackView.leadingAnchor.constraint(
                equalTo: artistShimmerContainer.leadingAnchor,
                constant: -PremiumSearchHeaderMetrics.artistItemImageInset
            ),
            artistShimmerStackView.trailingAnchor.constraint(lessThanOrEqualTo: artistShimmerContainer.trailingAnchor),
            artistShimmerStackView.bottomAnchor.constraint(equalTo: artistShimmerContainer.bottomAnchor),

            artistStackView.topAnchor.constraint(equalTo: artistScrollView.contentLayoutGuide.topAnchor),
            artistStackView.leadingAnchor.constraint(equalTo: artistScrollView.contentLayoutGuide.leadingAnchor),
            artistStackView.trailingAnchor.constraint(equalTo: artistScrollView.contentLayoutGuide.trailingAnchor),
            artistStackView.bottomAnchor.constraint(equalTo: artistScrollView.contentLayoutGuide.bottomAnchor),
            artistStackView.heightAnchor.constraint(equalTo: artistScrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func configure(
        venues: [SearchVenueItem],
        artists: [SearchArtistItem],
        showsVenue: Bool,
        showsViewMoreVenues: Bool,
        isLoading: Bool,
        showsEventTitle: Bool
    ) {
        let showsVenueTitle = isLoading || showsVenue
        venueTitleLabel.isHidden = !showsVenueTitle
        stackView.setCustomSpacing(
            showsVenueTitle ? PremiumSearchHeaderMetrics.venueTitleContentSpacing : 0,
            after: venueTitleLabel
        )

        // Wire up venue rows
        for (index, row) in venueRows.enumerated() {
            if showsVenue && index < venues.count {
                row.configure(venues[index])
                row.isHidden = false
                let isLastVenueRow = index == venues.count - 1
                stackView.setCustomSpacing(
                    isLastVenueRow ? 0 : PremiumSearchHeaderMetrics.venueRowSpacing,
                    after: row
                )
            } else {
                row.isHidden = true
                stackView.setCustomSpacing(0, after: row)
            }
        }

        for (index, row) in venueShimmerRows.enumerated() {
            row.isHidden = !isLoading
            row.setAnimating(isLoading)
            stackView.setCustomSpacing(
                isLoading && index < venueShimmerRows.count - 1
                    ? PremiumSearchHeaderMetrics.venueRowSpacing
                    : 0,
                after: row
            )
        }

        // Spacing after the venue block (last row or shimmer) before "view more" / title
        let lastVisibleVenueRow = venueRows.last(where: { !$0.isHidden })
        if let last = lastVisibleVenueRow {
            stackView.setCustomSpacing(PremiumSearchHeaderMetrics.sectionSpacing, after: last)
        }
        if let lastShimmerRow = venueShimmerRows.last {
            stackView.setCustomSpacing(
                isLoading ? PremiumSearchHeaderMetrics.sectionSpacing : 0,
                after: lastShimmerRow
            )
        }

        viewMoreVenuesButton.isHidden = !showsViewMoreVenues
        stackView.setCustomSpacing(
            showsViewMoreVenues ? PremiumSearchHeaderMetrics.titleContentSpacing : 0,
            after: viewMoreVenuesButton
        )

        configureArtists(artists)
        let showsArtists = !isLoading && !artists.isEmpty
        let showsArtistShimmer = isLoading
        artistTitleLabel.isHidden = !(showsArtists || showsArtistShimmer)
        artistScrollContainer.isHidden = !showsArtists
        artistScrollView.isHidden = !showsArtists
        artistShimmerContainer.isHidden = !showsArtistShimmer
        artistShimmerStackView.arrangedSubviews
            .compactMap { $0 as? PremiumSearchArtistShimmerItemView }
            .forEach { $0.setAnimating(showsArtistShimmer) }
        stackView.setCustomSpacing(
            (showsArtists || showsArtistShimmer) ? PremiumSearchHeaderMetrics.titleContentSpacing : 0,
            after: artistTitleLabel
        )
        stackView.setCustomSpacing(
            showsArtists ? PremiumSearchHeaderMetrics.sectionSpacing : 0,
            after: artistScrollContainer
        )
        stackView.setCustomSpacing(
            showsArtistShimmer ? PremiumSearchHeaderMetrics.sectionSpacing : 0,
            after: artistShimmerContainer
        )

        titleLabel.isHidden = !showsEventTitle
        titleLabel.text = "Upcoming events"
        stackView.setCustomSpacing(
            showsEventTitle ? PremiumSearchHeaderMetrics.titleContentSpacing : 0,
            after: titleLabel
        )
    }

    private func configureArtists(_ artists: [SearchArtistItem]) {
        let artistIDs = artists.map(\.id)
        if artistIDs == configuredArtistIDs {
            return
        }
        configuredArtistIDs = artistIDs

        if artists.count > artistViews.count {
            for _ in artistViews.count..<artists.count {
                let view = PremiumSearchArtistResultView()
                view.onViewArtist = { [weak self] artist in
                    self?.onViewArtist?(artist)
                }
                artistViews.append(view)
                artistStackView.addArrangedSubview(view)
            }
        }

        for (index, view) in artistViews.enumerated() {
            if artists.indices.contains(index) {
                view.configure(artists[index])
                view.isHidden = false
            } else {
                view.prepareForDisplayReuse()
                view.isHidden = true
            }
        }
    }

    @objc private func onViewMoreVenuesPressed() {
        onViewMoreVenues?()
    }
}

// MARK: - PremiumSearchArtistResultView

private final class PremiumSearchArtistResultView: UIControl {

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private var artist: SearchArtistItem?
    private var representedImageURL: String?

    var onViewArtist: ((SearchArtistItem) -> Void)?

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

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = PremiumSearchHeaderMetrics.artistImageSize / 2
        addSubview(imageView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.font = Constant.Font.geistMedium(size: 12)
        nameLabel.numberOfLines = 1
        addSubview(nameLabel)

        addTarget(self, action: #selector(onTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistItemWidth),
            heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistRowHeight),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistImageSize),
            imageView.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistImageSize),

            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    func configure(_ item: SearchArtistItem) {
        artist = item
        nameLabel.text = item.name

        if let imageURL = item.imageURL,
           !imageURL.isEmpty,
           let url = URL(string: imageURL) {
            guard representedImageURL != imageURL else { return }
            representedImageURL = imageURL
            imageView.sd_cancelCurrentImageLoad()
            let targetPixelSize = CGSize(
                width: PremiumSearchHeaderMetrics.artistImageSize * UIScreen.main.scale,
                height: PremiumSearchHeaderMetrics.artistImageSize * UIScreen.main.scale
            )
            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "premiumExpBg"),
                options: [.retryFailed, .continueInBackground, .scaleDownLargeImages],
                context: [.imageThumbnailPixelSize: NSValue(cgSize: targetPixelSize)]
            )
        } else {
            representedImageURL = nil
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = UIImage(named: "premiumExpBg") ?? Constant.Icon.uploadImage
        }
    }

    func prepareForDisplayReuse() {
        artist = nil
        nameLabel.text = nil
        representedImageURL = nil
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
    }

    @objc private func onTap() {
        guard let artist else { return }
        onViewArtist?(artist)
    }
}

// MARK: - PremiumSearchArtistShimmerItemView

private final class PremiumSearchArtistShimmerItemView: UIView {

    private let imageView = ShimmerViewV3(frame: .zero, lighter: true)
    private let textView = ShimmerViewV3()

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

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = PremiumSearchHeaderMetrics.artistImageSize / 2
        imageView.layer.cornerCurve = .continuous
        addSubview(imageView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerRadius = 6
        textView.layer.cornerCurve = .continuous
        addSubview(textView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistItemWidth),
            heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistRowHeight),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistImageSize),
            imageView.heightAnchor.constraint(equalToConstant: PremiumSearchHeaderMetrics.artistImageSize),

            textView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            textView.centerXAnchor.constraint(equalTo: centerXAnchor),
            textView.widthAnchor.constraint(equalToConstant: 62),
            textView.heightAnchor.constraint(equalToConstant: 12)
        ])

        startShimmer()
    }

    func setAnimating(_ isAnimating: Bool) {
        if isAnimating {
            startShimmer()
        } else {
            stopShimmer()
        }
    }

    private func startShimmer() {
        imageView.startShimmer()
        textView.startShimmer()
    }

    private func stopShimmer() {
        imageView.stopShimmer()
        textView.stopShimmer()
    }
}

// MARK: - PremiumSearchVenueShimmerView

private final class PremiumSearchVenueShimmerView: UIView {

    private let imageView = ShimmerViewV3(frame: .zero, lighter: true)
    private let titleView = ShimmerViewV3()
    private let subtitleView = ShimmerViewV3(frame: .zero, lighter: true)
    private let buttonView = ShimmerViewV3(frame: .zero, lighter: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        backgroundColor = .clear

        [
            imageView,
            titleView,
            subtitleView,
            buttonView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerCurve = .continuous
            addSubview($0)
            $0.startShimmer()
        }

        imageView.layer.cornerRadius = 6
        buttonView.layer.cornerRadius = 14

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54).withPriority(.defaultHigh),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),

            buttonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonView.widthAnchor.constraint(equalToConstant: 80),
            buttonView.heightAnchor.constraint(equalToConstant: 28),

            titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: buttonView.leadingAnchor, constant: -12),
            titleView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),
            titleView.widthAnchor.constraint(equalToConstant: 150),
            titleView.heightAnchor.constraint(equalToConstant: 14),

            subtitleView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 6),
            subtitleView.widthAnchor.constraint(equalToConstant: 46),
            subtitleView.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    func setAnimating(_ isAnimating: Bool) {
        [
            imageView,
            titleView,
            subtitleView,
            buttonView
        ].forEach {
            if isAnimating {
                $0.startShimmer()
            } else {
                $0.stopShimmer()
            }
        }
    }
}

// MARK: - PremiumSearchVenueResultView

private final class PremiumSearchVenueResultView: UIView {

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)
    private var venue: SearchVenueItem?
    private var representedImageURL: String?
    var onViewVenue: ((SearchVenueItem) -> Void)?

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

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        addSubview(imageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 14)
        addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Venue"
        subtitleLabel.textColor = .white.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 10)
        addSubview(subtitleLabel)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Book", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 10)
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(onButton), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54).withPriority(.defaultHigh),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),

            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(_ item: SearchVenueItem) {
        venue = item
        titleLabel.text = item.name

        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
            guard representedImageURL != imageURL else { return }
            representedImageURL = imageURL
            imageView.sd_cancelCurrentImageLoad()
            let targetPixelSize = CGSize(
                width: 40 * UIScreen.main.scale,
                height: 40 * UIScreen.main.scale
            )
            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "newSpeakeasy"),
                options: [.retryFailed, .continueInBackground, .scaleDownLargeImages],
                context: [.imageThumbnailPixelSize: NSValue(cgSize: targetPixelSize)]
            )
        } else {
            representedImageURL = nil
            imageView.sd_cancelCurrentImageLoad()
            imageView.image = UIImage(named: "newSpeakeasy") ?? Constant.Icon.uploadImage
        }
    }

    @objc private func onButton() {
        guard let venue else { return }
        onViewVenue?(venue)
    }
}
