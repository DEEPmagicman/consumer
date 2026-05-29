//
//  BaseSingleGridVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import Foundation
import UIKit

class BaseSingleGridVC: UIViewController {

    let collectionView: UICollectionView
    private let emptyView = UILabel()

    var emptyTitle: String { "No data found" }

    var items: [Booking] = []
    var skip = 0
    var hasMany = false

    var isInitialLoading = true
    var isLoading = false
    var isPaginating = false

    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData(reset: true)
    }

    private func setupUI() {
        view.backgroundColor = .clear

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )

        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )

        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        view.addSubview(collectionView)

        emptyView.textColor = UIColor.white.withAlphaComponent(0.55)
        emptyView.font = Constant.Font.geistMedium(size: 16)
        emptyView.textAlignment = .center
        emptyView.numberOfLines = 0
        emptyView.isHidden = true
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    func loadData(reset: Bool) {}

    func configure(_ cell: OrderCardCollectionCell, booking: Booking) {}

    func didSelect(_ booking: Booking) {}

    func reloadUI() {
        let isEmpty = !isInitialLoading && items.isEmpty

        emptyView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        emptyView.text = emptyTitle

        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    func insertItems(_ indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else {
            isPaginating = false
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isPaginating = false

            if let layout = self.collectionView.collectionViewLayout as? PinterestLayout {
                layout.invalidateFooter()
            } else {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    private func item(at indexPath: IndexPath) -> Booking? {
        guard items.indices.contains(indexPath.item) else { return nil }
        return items[indexPath.item]
    }

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isLoading else { return }
        guard !isPaginating else { return }
        guard hasMany else { return }
        guard !items.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()
        loadData(reset: false)
    }
}

// MARK: - Collection

extension BaseSingleGridVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        isInitialLoading ? 6 : items.count
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

        guard let booking = item(at: indexPath) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderCardShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        configure(cell, booking: booking)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isInitialLoading, let booking = item(at: indexPath) else { return }
        didSelect(booking)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionFooter {

            let footer =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: PaginationShimmerFooterView.identifier,
                    for: indexPath
                ) as! PaginationShimmerFooterView

            footer.isHidden = !isPaginating

            return footer
        }

        if kind == UICollectionView.elementKindSectionHeader {

            return UICollectionReusableView()
        }

        return UICollectionReusableView()
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

// MARK: - PinterestLayoutDelegate

extension BaseSingleGridVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard let booking = item(at: indexPath) else {
            return 0.1
        }

        let imageHeight = width * 1.2

        let title = booking.event?.title ??
        booking.inviteLink?.name ??
        Constant.String.liveCoverTicket

        let venue = booking.venueObject?.name ?? ""

        let dateText: String = {
            if let event = booking.event {
                return event.startDateTime.convertDateFormat(
                    from: .yyyyMMddHHmmss,
                    to: .MMMDDATHMMA,
                    useDayLightSavingTime: true,
                    customTimeZone: booking.venueObject?.useTimezone ?? ""
                )
            }

            return booking.createdAt.convertDateFormat(
                from: .yyyyMMddTHHmmssSSSz,
                to: .MMMDDATHMMA
            )
        }()

        let titleHeight = title.height(
            width: width,
            font: Constant.Font.geistMedium(size: 15)
        )

        let venueHeight = venue.height(
            width: width,
            font: Constant.Font.geistMedium(size: 14)
        )

        let dateHeight = dateText.height(
            width: width,
            font: Constant.Font.geistMedium(size: 14)
        )

        return ceil(imageHeight + 16 + titleHeight + 4 + venueHeight + 10 + dateHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        isPaginating ? 300 : 0
    }
}
