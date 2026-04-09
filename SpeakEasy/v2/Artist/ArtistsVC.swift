//
//  ArtistsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit

final class ArtistsVC: UIViewController, SJSegmentedViewControllerViewSource {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Data
    private var artists: [String] = []
    private var isInitialLoading = true
    private var hasMore = true
    private var skip = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadArtists()
    }

    // MARK: - Segmented Scroll Source
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return collectionView
    }

    // MARK: - Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true

        collectionView.register(
            ArtistsCVC.nib,
            forCellWithReuseIdentifier: ArtistsCVC.identifier
        )

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 16
            layout.minimumInteritemSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
    }

    // MARK: - Data
    private func loadArtists() {
        guard hasMore else { return }

        // Dummy data for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let newItems = [
                "Artist 1",
                "Artist 2",
                "Artist 3",
                "Artist 4",
                "Artist 5",
                "Artist 6"
            ]

            if self.skip == 0 {
                self.artists.removeAll()
            }

            self.artists.append(contentsOf: newItems)
            self.skip = self.artists.count
            self.hasMore = false
            self.isInitialLoading = false
            self.collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ArtistsVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isInitialLoading ? 6 : artists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ArtistsCVC = collectionView.dequeue(
            withIdentifier: ArtistsCVC.identifier,
            for: indexPath
        )

        if isInitialLoading {
            cell.contentView.alpha = 0.6

            // If ArtistsCVC has shimmerView, use it here
            // cell.shimmerView.isHidden = false
        } else {
            cell.contentView.alpha = 1.0

            let artist = artists[indexPath.item]

            // Best: replace this with cell.setupData(...)
            if let titleLabel = cell.contentView.viewWithTag(100) as? UILabel {
                titleLabel.text = artist
            }

            // If you have shimmer
            // cell.shimmerView.isHidden = true
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ArtistsVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isInitialLoading else { return }

        let selectedArtist = artists[indexPath.item]
        Navigate.to.gotoArtistDetailsVC(self)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if indexPath.item == artists.count - 2 {
            loadArtists()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ArtistsVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let padding: CGFloat = 16 + 16 + 12
        let width = (collectionView.bounds.width - padding) / 2

        return CGSize(width: floor(width), height: 185)
    }
}
