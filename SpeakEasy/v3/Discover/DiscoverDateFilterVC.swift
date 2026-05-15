//
//  DiscoverDateFilterVC.swift
//  SpeakEasy-Consumer
//

import UIKit

final class DiscoverDateFilterVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateCollectionView: UICollectionView!

    var selectedDates = [String]()

    private var selectedDateIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

//        collectionView.register(
//            DateSelectionHeader.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
//            withReuseIdentifier: "DateSelectionHeader"
//        )

        collectionView.register(
            EventCollectionViewCell.nib,
            forCellWithReuseIdentifier: EventCollectionViewCell.identifier
        )

        dateCollectionView.register(
            DateSelectionCVC.nib,
            forCellWithReuseIdentifier: DateSelectionCVC.identifier
        )

        setupCollectionView()
    }

    private func setupCollectionView() {

        let layout = UICollectionViewFlowLayout()

        let spacing: CGFloat = 16
        let itemsPerRow: CGFloat = 2

        let totalSpacing =
        (itemsPerRow + 1) * spacing

        let itemWidth =
        (view.frame.width - totalSpacing) / itemsPerRow

        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: spacing,
            bottom: spacing,
            right: spacing
        )

        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing

        layout.itemSize = CGSize(
            width: itemWidth,
            height: 228
        )

        collectionView.collectionViewLayout = layout
    }
}

extension DiscoverDateFilterVC:
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout {

//    func collectionView(
//        _ collectionView: UICollectionView,
//        viewForSupplementaryElementOfKind kind: String,
//        at indexPath: IndexPath
//    ) -> UICollectionReusableView {
//
//        if kind == UICollectionView.elementKindSectionHeader {
//
//            let header =
//            collectionView.dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: "DateSelectionHeader",
//                for: indexPath
//            )
//
//            return header
//        }
//
//        return UICollectionReusableView()
//    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {

        if collectionView == dateCollectionView {

            return CGSize(
                width: collectionView.frame.width,
                height: 0
            )

        } else {

            return CGSize(
                width: collectionView.frame.width,
                height: 40
            )
        }
    }

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {

        return collectionView == dateCollectionView
        ? 1
        : selectedDates.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        if collectionView == dateCollectionView {
            return selectedDates.count
        }

        return 3
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

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

        } else {

            let cell: EventCollectionViewCell = collectionView.dequeue(
                withIdentifier: EventCollectionViewCell.identifier,
                for: indexPath
            )

            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        guard collectionView == dateCollectionView else {
            return
        }

        selectedDateIndex = indexPath.item
        self.dateCollectionView.reloadData()
    }
}
