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
        static let visibleItemCount: CGFloat = 2.5
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 10
        static let minItemWidth: CGFloat = 132
        static let maxItemWidth: CGFloat = 148
        static let titleTopPadding: CGFloat = 10
        static let collectionTopOffset: CGFloat = 55
        static let venueItemHeight: CGFloat = 210
        static let eventItemHeight: CGFloat = 222
        static let defaultSectionHeight: CGFloat =
        collectionTopOffset +
        eventItemHeight

        static func itemWidth(for availableWidth: CGFloat) -> CGFloat {
            let resolvedWidth = availableWidth > 0
            ? availableWidth
            : UIScreen.main.bounds.width

            let visibleWidth = resolvedWidth
            - horizontalInset
            - (itemSpacing * 2)

            return min(
                maxItemWidth,
                max(
                    minItemWidth,
                    floor(visibleWidth / visibleItemCount)
                )
            )
        }

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
    private var currentHeight: CGFloat = DiscoverSectionLayout.defaultSectionHeight
    private var lastAppliedCollectionWidth: CGFloat = 0

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

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = collectionView.bounds.width
        guard abs(width - lastAppliedCollectionWidth) > 0.5 else {
            return
        }

        lastAppliedCollectionWidth = width
        applyCollectionLayout()
        updateSectionHeight(animated: false)
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
            layout.itemSize = currentItemSize()
            layout.minimumLineSpacing = DiscoverSectionLayout.itemSpacing
            layout.minimumInteritemSpacing = DiscoverSectionLayout.itemSpacing
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: DiscoverSectionLayout.horizontalInset,
                bottom: 0,
                right: DiscoverSectionLayout.horizontalInset
            )
        }

        collectionView.register(
            EventCollectionViewCell.nib,
            forCellWithReuseIdentifier: EventCollectionViewCell.identifier
        )
    }

    func updateSectionHeight(animated: Bool) {
        let itemSize = currentItemSize()
        let itemHeight = currentItemHeight()

        applyCollectionLayout(itemSize: itemSize)

        updateHeightConstraint(
            in: collectionView.constraints,
            to: itemHeight
        )

        currentHeight = currentSectionHeight()

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

    func currentItemSize() -> CGSize {
        let itemWidth = DiscoverSectionLayout.itemWidth(
            for: collectionView.bounds.width
        )

        return CGSize(
            width: itemWidth,
            height: currentItemHeight()
        )
    }

    func currentItemHeight() -> CGFloat {
        switch sectionType {
        case .venues:
            return DiscoverSectionLayout.venueItemHeight

        case .tonightEvents,
             .allEvents,
             .premiumExperiences:
            return DiscoverSectionLayout.eventItemHeight
        }
    }

    func currentSectionHeight() -> CGFloat {
        DiscoverSectionLayout.collectionTopOffset + currentItemHeight()
    }

    func applyCollectionLayout(itemSize: CGSize? = nil) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        layout.estimatedItemSize = .zero
        layout.itemSize = itemSize ?? currentItemSize()
        layout.minimumLineSpacing = DiscoverSectionLayout.itemSpacing
        layout.minimumInteritemSpacing = DiscoverSectionLayout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: DiscoverSectionLayout.horizontalInset,
            bottom: 0,
            right: DiscoverSectionLayout.horizontalInset
        )
        layout.invalidateLayout()
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

        collectionView.deselectItem(
            at: indexPath,
            animated: true
        )

        switch sectionData {

        case .events(let events):
            guard events.indices.contains(indexPath.item) else {
                return
            }

            AppHaptic.cardOpen()
            onTapEvent?(
                events[indexPath.item],
                indexPath
            )

        case .venues(let venues):
            guard venues.indices.contains(indexPath.item) else {
                return
            }

            AppHaptic.cardOpen()
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

        return currentItemSize()
    }
}
