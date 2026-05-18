//
//  EventsListVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 08/04/26.
//

import UIKit

final class EventsListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var cityTitleLbl: UILabel!
    private var eventList: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true

    private let horizontalMargin: CGFloat = 16
    private let interItemSpacing: CGFloat = 12
    private let lineSpacing: CGFloat = 16
    private let columns: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchEvents()
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(
            EventCollectionViewCell.nib,
            forCellWithReuseIdentifier: EventCollectionViewCell.identifier
        )
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = lineSpacing
        layout.minimumInteritemSpacing = interItemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalMargin, bottom: 0, right: horizontalMargin)
        collectionView.collectionViewLayout = layout
    }

    private var cellWidth: CGFloat {
        let totalMargins = horizontalMargin * 2
        let totalSpacing = interItemSpacing * (columns - 1)
        return floor((collectionView.bounds.width - totalMargins - totalSpacing) / columns)
    }

    private func fetchEvents() {
        guard !isLoading, hasMore else { return }
        isLoading = true

        EventPresenter.getEvents(
            from: skip,
            venueId: "",
            time: "UPCOMING",
            city: UserDefault.shared.localCity
        ) { [weak self] _, _, events, hasMore in
            guard let self else { return }
            self.eventList.append(contentsOf: events)
            self.skip = self.eventList.count
            self.hasMore = hasMore
            self.isInitialLoading = false
            self.isLoading = false
            self.collectionView.reloadData()
        }
    }

}

extension EventsListVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: EventCollectionViewCell = collectionView.dequeue(
            withIdentifier: EventCollectionViewCell.identifier,
            for: indexPath
        )
        cell.configure(with: .event(eventList[indexPath.row]))
        return cell
    }
}

extension EventsListVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !isInitialLoading else { return }
        if indexPath.item == eventList.count - 2 {
            fetchEvents()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isInitialLoading else { return }
        Navigate.eventDetailsVC(self, event: eventList[indexPath.item])
    }
}

extension EventsListVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: 240)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
}
