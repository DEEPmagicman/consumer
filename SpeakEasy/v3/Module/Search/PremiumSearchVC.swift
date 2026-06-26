//
//  PremiumSearchVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit
import SDWebImage

final class PremiumSearchVC: UIViewController {

    private let headerView = PremiumSearchHeaderView()
    private let collectionView: UICollectionView
    private let emptyView = SearchEmptyStateView()
    private let searchService = SearchFlowService.shared
    private var venues: [SearchVenueItem] = []
    private var events: [SearchEventItem] = []
    private var searchWorkItem: DispatchWorkItem?
    private var searchRequestId = UUID()
    private var currentQuery = ""
    private var hasMoreVenues = false
    private var hasMoreEvents = false
    private var isInitialLoading = false
    private var isLoadingMoreEvents = false
    private let venueTake = 10
    private let eventTake = 10
    private var lastCollectionLayoutWidth: CGFloat = 0

    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = true
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = true
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        layout.delegate = self
    }

    deinit {
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
        view.applyScreenBgGradient()
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

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 22),
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
        currentQuery = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchRequestId = UUID()

        venues.removeAll()
        events.removeAll()
        hasMoreVenues = false
        hasMoreEvents = false
        isInitialLoading = true
        isLoadingMoreEvents = false
        updateEmptyState(animated: false)
        reloadCollectionWithoutAnimation()

        let requestId = searchRequestId
        let query = currentQuery
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchInitialSearch(
                query: query,
                requestId: requestId
            )
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35,
            execute: workItem
        )
    }

    private func fetchInitialSearch(
        query: String,
        requestId: UUID
    ) {
        searchService.search(
            keyword: query,
            venueSkip: 0,
            venueTake: venueTake,
            eventSkip: 0,
            eventTake: eventTake
        ) { [weak self] isSuccess, _, result in
            DispatchQueue.main.async {
                guard let self,
                      self.searchRequestId == requestId,
                      self.currentQuery == query else { return }

                self.isInitialLoading = false

                guard isSuccess else {
                    self.venues.removeAll()
                    self.events.removeAll()
                    self.hasMoreVenues = false
                    self.hasMoreEvents = false
                    self.reloadCollectionWithoutAnimation()
                    self.updateEmptyState(animated: true)
                    return
                }

                self.venues = result.venues
                self.events = result.events
                self.hasMoreVenues = result.hasMoreVenues
                self.hasMoreEvents = result.hasMoreEvents
                self.reloadCollectionWithoutAnimation()
                self.updateEmptyState(animated: true)
            }
        }
    }

    private func loadMoreEventsIfNeeded() {
        guard !isInitialLoading,
              !isLoadingMoreEvents,
              hasMoreEvents else { return }

        isLoadingMoreEvents = true
        let query = currentQuery
        let requestId = searchRequestId
        let currentCount = events.count

        searchService.search(
            keyword: query,
            venueSkip: 0,
            venueTake: 0,
            eventSkip: currentCount,
            eventTake: eventTake
        ) { [weak self] isSuccess, _, result in
            DispatchQueue.main.async {
                guard let self,
                      self.searchRequestId == requestId,
                      self.currentQuery == query else { return }

                self.isLoadingMoreEvents = false

                guard isSuccess else {
                    self.hasMoreEvents = false
                    return
                }

                self.events.append(contentsOf: result.events)
                self.hasMoreEvents = result.hasMoreEvents
                self.reloadCollectionWithoutAnimation()
                self.updateEmptyState(animated: true)
            }
        }
    }

    private func reloadCollectionWithoutAnimation() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
//            collectionView.layoutIfNeeded()
        }
    }

    private func updateEmptyState(animated: Bool) {
        let shouldShow =
        !isInitialLoading &&
        !isLoadingMoreEvents &&
        events.isEmpty

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

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    // Each venue row is 54pt tall; rows are separated by 8pt spacing.
    private static let venueRowHeight: CGFloat = 54
    private static let venueRowSpacing: CGFloat = 8
    private static let maxDisplayedVenues = 3

    private var headerHeight: CGFloat {
        var height: CGFloat = 0
        let displayedVenueCount = min(venues.count, Self.maxDisplayedVenues)
        let showsViewMoreVenues = hasMoreVenues || venues.count > Self.maxDisplayedVenues

        if isInitialLoading {
            // One shimmer row
            height += Self.venueRowHeight   // 54
            height += 16                    // spacing after shimmer
        } else if !venues.isEmpty {
            // Stack of venue rows + inter-row spacing
            height += CGFloat(displayedVenueCount) * Self.venueRowHeight
            height += CGFloat(max(0, displayedVenueCount - 1)) * Self.venueRowSpacing
            if showsViewMoreVenues {
                height += 8    // spacing after venues stack
                height += 24   // "View more venues" button
                height += 12   // spacing after button
            } else {
                height += 18   // spacing after venues stack (no button)
            }
        }

        // "Upcoming events" title + its bottom spacing
        height += 24   // title label height
        height += 14   // spacing after title

        return max(height, 46)
    }
}

extension PremiumSearchVC: PremiumSearchHeaderViewDelegate {
    func premiumSearchHeaderDidTapProfile(_ view: PremiumSearchHeaderView) {
        if UserDefault.shared.isLoggedIn == true {
            Navigate.to.profileMenuVC(self)
        } else {
            Navigate.to.openPhoneLoginPopup(self)
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
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PremiumSearchHeaderSupplementaryView.identifier,
            for: indexPath
        ) as! PremiumSearchHeaderSupplementaryView

        // Cap at 5 venues for display; "view more" button handles the rest
        let displayedVenues = Array(venues.prefix(PremiumSearchVC.maxDisplayedVenues))
        let showsViewMoreVenues = hasMoreVenues || venues.count > PremiumSearchVC.maxDisplayedVenues

        header.configure(
            venues: displayedVenues,
            showsVenue: !venues.isEmpty,
            showsViewMoreVenues: showsViewMoreVenues,
            isLoading: isInitialLoading,
            showsEventTitle: true
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
        let threshold: CGFloat = 240
        let offsetY = scrollView.contentOffset.y
        let visibleHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height

        guard contentHeight > 0,
              offsetY + visibleHeight + threshold >= contentHeight else {
            return
        }

        loadMoreEventsIfNeeded()
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

        return ceil(imageHeight + 16 + titleHeight + 3 + venueHeight + 10 + dateHeight)
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
        0
    }
}

// MARK: - PremiumSearchHeaderSupplementaryView

private final class PremiumSearchHeaderSupplementaryView: UICollectionReusableView {

    private let stackView = UIStackView()
    // Up to maxDisplayedVenues venue rows, lazily created
    private var venueRows: [PremiumSearchVenueResultView] = []
    private let venueShimmerView = PremiumSearchVenueShimmerView()
    private let viewMoreVenuesButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    var onViewVenue: ((SearchVenueItem) -> Void)?
    var onViewMoreVenues: (() -> Void)?

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
    }

    private func setup() {
        backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)

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

        stackView.addArrangedSubview(venueShimmerView)

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
        viewMoreVenuesButton.heightAnchor.constraint(equalToConstant: 24).isActive = true

        titleLabel.text = "Upcoming events"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        stackView.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(
        venues: [SearchVenueItem],
        showsVenue: Bool,
        showsViewMoreVenues: Bool,
        isLoading: Bool,
        showsEventTitle: Bool
    ) {
        // Wire up venue rows
        for (index, row) in venueRows.enumerated() {
            if showsVenue && index < venues.count {
                row.configure(venues[index])
                row.isHidden = false
                // 8pt gap between rows, 0 after the last visible row
                // (spacing after the whole block is set on venueShimmerView/button below)
                let isLastVenueRow = index == venues.count - 1
                stackView.setCustomSpacing(isLastVenueRow ? 0 : 8, after: row)
            } else {
                row.isHidden = true
                stackView.setCustomSpacing(0, after: row)
            }
        }

        venueShimmerView.isHidden = !isLoading

        // Spacing after the venue block (last row or shimmer) before "view more" / title
        let lastVisibleVenueRow = venueRows.last(where: { !$0.isHidden })
        if let last = lastVisibleVenueRow {
            stackView.setCustomSpacing(showsViewMoreVenues ? 8 : 18, after: last)
        }
        stackView.setCustomSpacing(isLoading ? 16 : 0, after: venueShimmerView)

        viewMoreVenuesButton.isHidden = !showsViewMoreVenues
        stackView.setCustomSpacing(showsViewMoreVenues ? 12 : 0, after: viewMoreVenuesButton)

        titleLabel.isHidden = !showsEventTitle
        titleLabel.text = "Upcoming events"
        stackView.setCustomSpacing(14, after: titleLabel)
    }

    @objc private func onViewMoreVenuesPressed() {
        onViewMoreVenues?()
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
            heightAnchor.constraint(equalToConstant: 54),

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

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        [
            imageView,
            titleView,
            subtitleView,
            buttonView
        ].forEach {
            if newWindow == nil {
                $0.stopShimmer()
            } else {
                $0.startShimmer()
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
        button.setTitle("View venue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 10)
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(onButton), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54),

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
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "newSpeakeasy"))
        } else {
            imageView.image = UIImage(named: "newSpeakeasy") ?? Constant.Icon.uploadImage
        }
    }

    @objc private func onButton() {
        guard let venue else { return }
        onViewVenue?(venue)
    }
}
