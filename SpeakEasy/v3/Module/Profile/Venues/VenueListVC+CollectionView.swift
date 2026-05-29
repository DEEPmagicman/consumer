//
//  VenueListVC+CollectionView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 29/05/26.
//

import UIKit

extension VenueListVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        isInitialLoading ? 8 : venues.count
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

        guard let venue = venue(at: indexPath) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: VenueGridShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VenueGridCell.identifier,
            for: indexPath
        ) as! VenueGridCell

        cell.configure(venue)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isInitialLoading, let venue = venue(at: indexPath) else { return }

        let vc = VenueVC(nibName: "VenueVC", bundle: nil)
        vc.venueDetails = venue
        navigationController?.pushViewController(vc, animated: true)
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
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else { return }

        loadNextPageIfNeeded()
    }
}

extension VenueListVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        width
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        isPaginating ? 220 : 0
    }
}
