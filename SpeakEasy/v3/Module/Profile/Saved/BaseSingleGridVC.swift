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
    private let emptyView = V3EmptyStateView(style: .savedEvents)

    var emptyTitle: String { "No data found" }
    var emptyStateStyle: V3EmptyStateStyle { .savedEvents }
    var onBrowseEvents: (() -> Void)?

    var items: [Booking] = []
    var skip = 0
    var hasMany = false

    var isInitialLoading = true
    var isLoading = false
    var isPaginating = false
    private var hasReleasedResources = false

    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 16

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isLeavingScreenPermanently {
            releaseResources()
        }
    }

    deinit {
        releaseResources()
    }

    private var isLeavingScreenPermanently: Bool {
        if transitionCoordinator?.isCancelled == true {
            return false
        }

        return isBeingDismissed ||
            navigationController?.isBeingDismissed == true ||
            navigationController?.viewControllers.contains(where: { $0 === self }) == false
    }

    private func releaseResources() {
        guard isViewLoaded, !hasReleasedResources else { return }
        hasReleasedResources = true

        collectionView.visibleCells.forEach {
            ($0 as? OrderCardShimmerCell)?.releaseResources()
            ($0 as? OrderCardCollectionCell)?.releaseResources()
        }
        collectionView
            .visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
            .forEach {
                ($0 as? PaginationShimmerFooterView)?.releaseResources()
            }
        collectionView.dataSource = nil
        collectionView.delegate = nil
        collectionView.prefetchDataSource = nil
        collectionView.backgroundView = nil
        emptyView.onBrowseEvents = nil
        onBrowseEvents = nil
        items.removeAll()
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

        emptyView.isHidden = true
        emptyView.onBrowseEvents = { [weak self] in
            self?.onBrowseEvents?()
        }
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func loadData(reset: Bool) {}

    func configure(_ cell: OrderCardCollectionCell, booking: Booking) {}

    func didSelect(_ booking: Booking) {}

    func reloadUI() {
        let isEmpty = !isInitialLoading && items.isEmpty

        emptyView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        emptyView.configure(style: emptyStateStyle)

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
        
        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 13)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = ceil(titleFont.lineHeight * 2)
        let venueHeight = ceil(venueFont.lineHeight)
        let dateHeight = ceil(dateFont.lineHeight)

        let height = imageHeight
            + 16
            + titleHeight
            + 3
            + venueHeight
            + 10
            + dateHeight
        
        return height
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        isPaginating ? 300 : 0
    }
}
