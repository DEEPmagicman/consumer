//
//  AllVenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/25.
//

import UIKit

final class AllVenueVC: UIViewController {

    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backbtn: AppIconButton!

    private var venueList: [ClipVenue] = []
    private var discoverService = DiscoverService()

    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = false
    private var isPaginating = false
    private var screenFilterCity: String?
    private var loadID = 0

    // MARK: - Layout Constants
    private let horizontalMargin: CGFloat = 20
    private let interItemSpacing: CGFloat = 16
    private let lineSpacing: CGFloat = 16
    private let columns: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupVenueTitle()
        fetchVenues()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.applyScreenBgGradient(direction: .topToBottom)
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickFilterBtn(_ sender: Any) {
        presentCityFilter()
    }

    @IBAction func onClickCityBtn(_ sender: Any) {
        presentCityFilter()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        collectionView.register(
            VenueGridCell.self,
            forCellWithReuseIdentifier: VenueGridCell.identifier
        )

        collectionView.register(
            VenueGridShimmerCell.self,
            forCellWithReuseIdentifier: VenueGridShimmerCell.identifier
        )

        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        collectionView.contentInset = UIEdgeInsets(
            top: 4,
            left: horizontalMargin,
            bottom: 24,
            right: horizontalMargin
        )

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = interItemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.scrollDirection = .vertical
        layout.footerReferenceSize = .zero

        collectionView.collectionViewLayout = layout
    }

    private func setupVenueTitle() {
        cityLbl.text = "Venues in \(resolvedCity())"
    }

    private func resolvedCity() -> String {
        let city = (screenFilterCity ?? UserDefault.shared.activeCity)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty ? "Chicago" : city
    }

    // MARK: - Cell Width Calculation

    private var cellWidth: CGFloat {
        let totalHorizontalPadding = horizontalMargin * 2
        let totalSpacing = interItemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
        return floor(availableWidth / columns)
    }

    // MARK: - Fetch

    private func fetchVenues(showLoader: Bool = true, reset: Bool = false) {
        guard !isLoading || reset else { return }
        guard hasMore || reset else { return }

        isLoading = true
        loadID += 1
        let requestID = loadID

        if reset {
            skip = 0
            hasMore = true
            isPaginating = false
            venueList.removeAll()
        }

        if venueList.isEmpty {
            isInitialLoading = true
            updateEmptyState()
            collectionView.reloadData()
        } else {
            isPaginating = true
            collectionView.collectionViewLayout.invalidateLayout()
        }

        discoverService.fetchDiscoverVenues(
            city: resolvedCity(),
            skip: skip,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in
            guard let self else { return }
            guard self.loadID == requestID else { return }

            self.isLoading = false
            self.isInitialLoading = false
            self.isPaginating = false

            if isSuccess,
               let page {
                self.venueList.append(contentsOf: page.list)
                self.skip = self.venueList.count
                self.hasMore = page.hasMore
            } else {
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
            }

            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.updateEmptyState()
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

        setupVenueTitle()
        fetchVenues(reset: true)
    }

    private func updateEmptyState() {
        collectionView.backgroundView = !isInitialLoading && venueList.isEmpty
            ? makeEmptyStateView()
            : nil
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: collectionView.bounds)
        container.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No venues found"
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
}

// MARK: - UICollectionViewDataSource

extension AllVenueVC: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return isInitialLoading ? 8 : venueList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if isInitialLoading {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: VenueGridShimmerCell.identifier,
                for: indexPath
            )
        }

        guard venueList.indices.contains(indexPath.item) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: VenueGridShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VenueGridCell.identifier,
            for: indexPath
        ) as! VenueGridCell

        cell.configure(venueList[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension AllVenueVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }

        // Trigger pagination 2 items before the end
        if indexPath.item == venueList.count - 2 {
            fetchVenues(showLoader: false)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard venueList.indices.contains(indexPath.item) else { return }

        Navigate.to.venueVC(self, venueDetails: venueList[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PaginationShimmerFooterView.identifier,
            for: indexPath
        ) as! PaginationShimmerFooterView

        footer.isHidden = !isPaginating
        return footer
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isInitialLoading else { return }
        guard !isLoading else { return }
        guard hasMore else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        if offsetY > contentHeight - visibleHeight - 400 {
            fetchVenues(showLoader: false)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AllVenueVC: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return interItemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return lineSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        return isPaginating
        ? CGSize(width: collectionView.bounds.width, height: 220)
        : .zero
    }
}
