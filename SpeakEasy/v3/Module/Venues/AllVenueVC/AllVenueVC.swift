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
    private var presenter = MVPPresenter()

    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = false

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
        collectionView.register(VenueCVC.nib, forCellWithReuseIdentifier: VenueCVC.identifier)
        collectionView.contentInset = UIEdgeInsets(
            top: 16,
            left: horizontalMargin,
            bottom: 16,
            right: horizontalMargin
        )
        collectionView.showsVerticalScrollIndicator = false

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = interItemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.scrollDirection = .vertical
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
        }

        presenter.getVenueListForMVP(
            from: skip,
            status: VenueStatus.open.rawValue, city: nil
        ) { [weak self] isSuccess, errMsg, venues, hasMore in
            guard let self = self else { return }

            self.isInitialLoading = false

            if isSuccess {
                self.venueList.append(contentsOf: venues)
                self.skip = self.venueList.count
                self.hasMore = hasMore
                self.collectionView.reloadData()
            } else {
                self.collectionView.reloadData()
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }

            self.isLoading = false
        }
    }
}

// MARK: - UICollectionViewDataSource

extension AllVenueVC: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return isInitialLoading ? 0 : venueList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell: VenueCVC = collectionView.dequeue(
            withIdentifier: VenueCVC.identifier,
            for: indexPath
        )

        if isInitialLoading {
//            cell.showSkeleton()
            return cell
        }

        let venue = venueList[indexPath.item]
        cell.configure(with: venue)
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

        let venue = venueList[indexPath.item]
        Navigate.to.venueVC(self, venueDetails: venue)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AllVenueVC: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // Height can be adjusted to match your design
        return CGSize(width: cellWidth, height: cellWidth )
    }

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
}
