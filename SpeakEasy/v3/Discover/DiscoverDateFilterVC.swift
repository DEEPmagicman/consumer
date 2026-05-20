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

    // MARK: - Event Data
    private var eventList: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true

    // MARK: - Event Collection Layout
    private let horizontalMargin: CGFloat = 16
    private let interItemSpacing: CGFloat = 12
    private let lineSpacing: CGFloat = 16
    private let columns: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDateCollectionView()
        setupEventCollectionView()

        fetchEvents()
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

        collectionView.register(
            EventCollectionViewCell.nib,
            forCellWithReuseIdentifier: EventCollectionViewCell.identifier
        )

        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false

        let layout = UICollectionViewFlowLayout()

        layout.minimumLineSpacing = lineSpacing
        layout.minimumInteritemSpacing = interItemSpacing

        layout.sectionInset = UIEdgeInsets(
            top: 16,
            left: horizontalMargin,
            bottom: 16,
            right: horizontalMargin
        )

        collectionView.collectionViewLayout = layout
    }

    // MARK: - Fetch Events
    private func fetchEvents() {

        guard !isLoading, hasMore else {
            return
        }

        isLoading = true

        EventPresenter.getEvents(
            from: skip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, events, hasMore in

            guard let self else {
                return
            }

            self.eventList.append(contentsOf: events)

            self.skip = self.eventList.count
            self.hasMore = hasMore

            self.isLoading = false
            self.isInitialLoading = false

            self.collectionView.reloadData()
        }
    }

    // MARK: - Cell Width
    private var cellWidth: CGFloat {

        let totalMargins = horizontalMargin * 2
        let totalSpacing = interItemSpacing * (columns - 1)

        return floor(
            (collectionView.bounds.width - totalMargins - totalSpacing) / columns
        )
    }
}

extension DiscoverDateFilterVC:
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        if collectionView == dateCollectionView {
            return selectedDates.count
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
        let cell: EventCollectionViewCell = collectionView.dequeue(
            withIdentifier: EventCollectionViewCell.identifier,
            for: indexPath
        )

        cell.imageViewWidthConstraint.constant = 173
        cell.imageViewHeightConstraint.constant = 200

        cell.configure(
            with: .event(eventList[indexPath.item]),
            screenType: .discover
        )

        return cell
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

            return
        }

        // MARK: - Event Selection
        guard !isInitialLoading else {
            return
        }

        Navigate.eventDetailsVC(
            self,
            event: eventList[indexPath.item]
        )
    }

    // MARK: - Pagination
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {

        guard collectionView == self.collectionView else {
            return
        }

        guard !isInitialLoading else {
            return
        }

        if indexPath.item == eventList.count - 2 {
            fetchEvents()
        }
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
        return CGSize(
            width: cellWidth,
            height: 250
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {

        if collectionView == dateCollectionView {
            return 12
        }

        return lineSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {

        if collectionView == dateCollectionView {
            return 12
        }

        return interItemSpacing
    }
}
