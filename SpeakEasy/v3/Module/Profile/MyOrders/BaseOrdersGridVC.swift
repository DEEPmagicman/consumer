//
//  BaseOrdersGridVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 27/05/26.
//

import UIKit

class BaseOrdersGridVC: UIViewController {

    enum SectionType: Int, CaseIterable {
        case upcoming
        case past
    }

    private let collectionView: UICollectionView
    private let emptyView = UILabel()

    var upcomingTitle: String { "" }
    var pastTitle: String { "" }
    var emptyTitle: String { "No orders found" }

    var upcomingItems: [Booking] = []
    var pastItems: [Booking] = []

    var upcomingSkip = 0
    var pastSkip = 0

    var upcomingHasMany = false
    var pastHasMany = false

    var isLoadingUpcoming = false
    var isLoadingPast = false
    var didLoadUpcoming = false
    var didLoadPast = false

    init() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(260)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(285)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            group.interItemSpacing = .fixed(16)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 24
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 34, trailing: 24)

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(48)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(OrderCardCollectionCell.self, forCellWithReuseIdentifier: OrderCardCollectionCell.identifier)
        collectionView.register(
            OrdersSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: OrdersSectionHeaderView.identifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
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
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    func loadInitialData() {
        loadUpcoming(reset: true)
        loadPast(reset: true)
    }

    func reloadUI() {
        collectionView.reloadData()

        let hasNoData = didLoadUpcoming &&
        didLoadPast &&
        upcomingItems.isEmpty &&
        pastItems.isEmpty

        emptyView.isHidden = !hasNoData
        collectionView.isHidden = hasNoData
        emptyView.text = emptyTitle
    }

    func loadUpcoming(reset: Bool) {}
    func loadPast(reset: Bool) {}

    func configure(_ cell: OrderCardCollectionCell, booking: Booking) {}
    func didSelect(_ booking: Booking) {}
}

// MARK: - CollectionView

extension BaseOrdersGridVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        SectionType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch SectionType(rawValue: section) {
        case .upcoming:
            return upcomingItems.count
        case .past:
            return pastItems.count
        case .none:
            return 0
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        let booking = item(at: indexPath)
        configure(cell, booking: booking)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelect(item(at: indexPath))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: OrdersSectionHeaderView.identifier,
            for: indexPath
        ) as! OrdersSectionHeaderView

        header.configure(
            title: indexPath.section == 0 ? upcomingTitle : pastTitle
        )

        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard !UserDefault.shared.isGuest else { return }

        if indexPath.section == SectionType.upcoming.rawValue,
           indexPath.item == upcomingItems.count - 1,
           upcomingHasMany,
           !isLoadingUpcoming {
            loadUpcoming(reset: false)
        }

        if indexPath.section == SectionType.past.rawValue,
           indexPath.item == pastItems.count - 1,
           pastHasMany,
           !isLoadingPast {
            loadPast(reset: false)
        }
    }

    private func item(at indexPath: IndexPath) -> Booking {
        if indexPath.section == SectionType.upcoming.rawValue {
            return upcomingItems[indexPath.item]
        } else {
            return pastItems[indexPath.item]
        }
    }
}
