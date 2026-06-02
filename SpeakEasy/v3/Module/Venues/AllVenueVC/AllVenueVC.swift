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
    private var venueService = VenueService()

    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = false
    private var isPaginating = false
    
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
        Navigate.to.filtersVC(self)
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
        let city = UserDefault.shared.localCity
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return city.isEmpty ? "New York" : city
    }

    // MARK: - Cell Width Calculation

    private var cellWidth: CGFloat {
        let totalHorizontalPadding = horizontalMargin * 2
        let totalSpacing = interItemSpacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalHorizontalPadding - totalSpacing
        return floor(availableWidth / columns)
    }

    // MARK: - Fetch

    private func fetchVenues(showLoader: Bool = true) {
        guard !isLoading, hasMore else { return }

        isLoading = true

        if venueList.isEmpty {
            isInitialLoading = true
            collectionView.reloadData()
        } else {
            isPaginating = true
            collectionView.collectionViewLayout.invalidateLayout()
        }

        venueService.fetchVenueList(
            skip: skip,
            status: VenueStatus.open.rawValue
        ) { [weak self] isSuccess, errMsg, venues, hasMore in
            guard let self else { return }

            self.isLoading = false
            self.isInitialLoading = false
            self.isPaginating = false

            if isSuccess {
                self.venueList.append(contentsOf: venues)
                self.skip = self.venueList.count
                self.hasMore = hasMore
            } else {
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
            }

            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
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
