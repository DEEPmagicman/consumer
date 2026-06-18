//
//  DiscoverSectionView.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 14/05/26.
//

import UIKit

enum DiscoverSectionType {
    case tonightEvents
    case venues
    case allEvents
    case premiumExperiences
}

enum DiscoverSectionData {
    case events([Event])
    case venues([ClipVenue])
}

final class DiscoverSectionView: UIView {

    private enum DiscoverSectionLayout {
        static let itemWidth: CGFloat = 143
        static let titleTopPadding: CGFloat = 10
        static let headerHeight: CGFloat = 28
        static let headerToCollectionSpacing: CGFloat = 10
        static let itemHeight: CGFloat = 210
        static let sectionHeight: CGFloat =
        titleTopPadding +
        headerHeight +
        headerToCollectionSpacing +
        itemHeight
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    var onTapSeeAll: (() -> Void)?
    var onTapEvent: ((Event, IndexPath) -> Void)?
    var onTapVenue: ((ClipVenue) -> Void)?
    var onReachEnd: (() -> Void)?

    private var sectionType: DiscoverSectionType = .tonightEvents
    private var sectionData: DiscoverSectionData?
    private var currentHeight: CGFloat = DiscoverSectionLayout.sectionHeight

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: currentHeight
        )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(
        type: DiscoverSectionType,
        data: DiscoverSectionData,
        city: String = UserDefault.shared.activeCity
    ) {

        self.sectionType = type
        self.sectionData = data

        let resolvedCity = city
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let displayCity = resolvedCity.isEmpty
        ? UserDefault.shared.activeCity
        : resolvedCity

        switch type {

        case .tonightEvents:

            titleLabel.text = "Events Tonight"

        case .venues:

            titleLabel.text = "Venues in \(displayCity)"

        case .allEvents:

            titleLabel.text = "Events in \(displayCity)"

        case .premiumExperiences:

            titleLabel.text = "Premium Experiences"
        }

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        updateSectionHeight(animated: true)
    }
}

// MARK: - Private

private extension DiscoverSectionView {

    func setupView() {

        let view = Bundle.main.loadNibNamed(
            "DiscoverSectionView",
            owner: self,
            options: nil
        )?.first as! UIView

        view.frame = bounds

        view.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        addSubview(view)

        setupCollectionView()
    }

    func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.showsHorizontalScrollIndicator = false
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.itemSize = CGSize(
                width: DiscoverSectionLayout.itemWidth,
                height: DiscoverSectionLayout.itemHeight
            )
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: 16,
                bottom: 0,
                right: 16
            )
        }

        collectionView.register(
            EventCollectionViewCell.nib,
            forCellWithReuseIdentifier: EventCollectionViewCell.identifier
        )
    }

    func updateSectionHeight(animated: Bool) {

        updateHeightConstraint(
            in: collectionView.constraints,
            to: DiscoverSectionLayout.itemHeight
        )

        currentHeight = DiscoverSectionLayout.sectionHeight

        updateHeightConstraint(
            in: constraints,
            to: currentHeight
        )

        invalidateIntrinsicContentSize()

        let updates = {
            self.collectionView.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }

        guard animated,
              window != nil
        else {
            updates()
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [
                .curveEaseInOut,
                .allowUserInteraction
            ],
            animations: updates
        )
    }

    func updateHeightConstraint(
        in constraints: [NSLayoutConstraint],
        to height: CGFloat
    ) {

        constraints
            .first {
                $0.firstAttribute == .height &&
                $0.secondItem == nil
            }?
            .constant = ceil(height)
    }

    @IBAction func onClickSeeAllButton(_ sender: UIButton) {
        onTapSeeAll?()
    }
}

// MARK: - UICollectionView

extension DiscoverSectionView:
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        switch sectionData {

        case .events(let events):
            return events.count

        case .venues(let venues):
            return venues.count

        case .none:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: EventCollectionViewCell = collectionView.dequeue(
            withIdentifier: EventCollectionViewCell.identifier,
            for: indexPath
        )

        switch sectionData {

        case .events(let events):

            switch sectionType {

            case .premiumExperiences:

                cell.configure(
                    with: .premiumExperience(events[indexPath.item])
                )

            default:

                cell.configure(
                    with: .event(events[indexPath.item])
                )
            }

        case .venues(let venues):

            cell.configure(
                with: .venue(venues[indexPath.item])
            )

        case .none:
            break
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        switch sectionData {

        case .events(let events):

            onTapEvent?(
                events[indexPath.item],
                indexPath
            )

        case .venues(let venues):

            onTapVenue?(
                venues[indexPath.item]
            )

        case .none:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {

        switch sectionData {

        case .events(let events):

            if indexPath.item == events.count - 2 {
                onReachEnd?()
            }

        case .venues(let venues):

            if indexPath.item == venues.count - 2 {
                onReachEnd?()
            }

        case .none:
            break
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        return CGSize(
            width: DiscoverSectionLayout.itemWidth,
            height: DiscoverSectionLayout.itemHeight
        )
    }
}
