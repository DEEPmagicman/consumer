//
//  VenueExperiencesVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class VenueExperiencesVC: UIViewController,
                           SJSegmentedViewControllerViewSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!

    weak var scrollDelegate: ChildScrollDelegate?
    var venueId = ""

    private let emptyStateView = V3EmptyStateView(style: .premiumEvents)
    private let noInternetView = V3NoInternetView()
    private let venueService = VenueService()
    private var items: [PremiumExperienceItem] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0
    private var showsNoInternetView = false
    private var didMoveFixedHeaderIntoCollection = false

    override func viewDidLoad() {
        super.viewDidLoad()

        moveFixedHeaderIntoCollectionIfNeeded()
        setupCollectionView()
        setupEmptyStateView()
        getEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshCollectionLayoutIfNeeded()
        updateScrollAvailability()
    }

    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return collectionView
    }
    
    @IBAction func onClickPermuimExp(_ sender: Any) {
        Navigate.to.presentPremiumExpPopUp(self)
    }
    
}

// MARK: - Setup

extension VenueExperiencesVC {

    private func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        collectionView.register(
            PremiumExperienceCell.self,
            forCellWithReuseIdentifier: PremiumExperienceCell.identifier
        )

        collectionView.register(
            PremiumExperienceShimmerCell.self,
            forCellWithReuseIdentifier: PremiumExperienceShimmerCell.identifier
        )

        collectionView.register(
            PremiumExperiencePaginationFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PremiumExperiencePaginationFooterView.identifier
        )

        collectionView.register(
            EmptyCollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EmptyCollectionReusableView.identifier
        )

        collectionView.register(
            PremiumExperiencesHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PremiumExperiencesHeaderView.reuseIdentifier
        )

        let layout = PinterestLayout()

        layout.numberOfColumns = 2

        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: 34,
            right: 24
        )

        layout.interItemSpacing = 20
        layout.lineSpacing = 16
        layout.showsHeaders = true
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    private func moveFixedHeaderIntoCollectionIfNeeded() {
        guard !didMoveFixedHeaderIntoCollection else { return }
        didMoveFixedHeaderIntoCollection = true

        view.subviews.forEach { subview in
            guard subview !== collectionView,
                  subview !== emptyView
            else { return }

            subview.isHidden = true
        }

        let rootConstraints = view.constraints.filter { constraint in
            constraint.firstItem === collectionView ||
            constraint.secondItem === collectionView ||
            constraint.firstItem === emptyView ||
            constraint.secondItem === emptyView
        }

        NSLayoutConstraint.deactivate(rootConstraints)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyStateView() {
        emptyView.subviews.forEach { $0.removeFromSuperview() }
        emptyStateView.configure(style: .premiumEvents)
        emptyStateView.isHidden = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyStateView)

        noInternetView.isHidden = true
        noInternetView.onTryAgain = { [weak self] in
            self?.getEvents(reset: true)
        }
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(noInternetView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            noInternetView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            noInternetView.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor)
        ])
    }

    private func reloadUI() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        updateScrollAvailability()
    }

    private func insertEventItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                self.isPaginating = false
                self.invalidateFooter()
                self.updateScrollAvailability()
            }
        }
    }

    private func invalidateFooter() {
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.invalidateFooter()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func refreshCollectionLayoutIfNeeded() {
        let width = collectionView.bounds.width

        guard width > 0,
              abs(width - lastCollectionLayoutWidth) > 0.5 else {
            return
        }

        lastCollectionLayoutWidth = width

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
        updateScrollAvailability()
    }

    private func updateScrollAvailability() {
        let topOffsetY = -collectionView.adjustedContentInset.top
        let visibleHeight = collectionView.bounds.height
        let verticalInset = collectionView.adjustedContentInset.top + collectionView.adjustedContentInset.bottom
        let hasScrollableContent = isInitialLoading ||
            collectionView.contentSize.height + verticalInset > visibleHeight + 1

        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = hasScrollableContent
        collectionView.bounces = hasScrollableContent

        if !hasScrollableContent,
           abs(collectionView.contentOffset.y - topOffsetY) > 0.5 {
            collectionView.setContentOffset(
                CGPoint(x: collectionView.contentOffset.x, y: topOffsetY),
                animated: false
            )
        }
    }

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !items.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()

        getEvents(reset: false)
    }
}

// MARK: - API

extension VenueExperiencesVC {

    func refreshFromSocket() {
        guard isViewLoaded else { return }
        getEvents(reset: true)
    }

    func getEvents(reset: Bool = false) {

        guard !isLoading else { return }
        guard hasMore || reset else { return }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            items.removeAll()
            emptyView.isHidden = true
            collectionView.isHidden = false
            reloadUI()
        }

        venueService.fetchVenuePremiumExperiences(
            venueId: venueId,
            skip: skip,
            time: "UPCOMING",
        ) { [weak self] isSuccess,
            errMsg,
            list,
            hasMore in

            guard let self = self else { return }

            DispatchQueue.main.async {
                let oldCount = self.items.count

                self.isLoading = false

                if isSuccess {
                    self.showsNoInternetView = false

                    let newItems = list
                        .filter { newItem in
                            !self.items.contains(where: {
                                $0.id == newItem.id
                            })
                    }

                    self.items.append(contentsOf: newItems)

                    self.skip = self.items.count
                    self.hasMore = hasMore
                    let newCount = self.items.count
                    let wasInitialLoading = self.isInitialLoading
                    self.isInitialLoading = false

                    self.emptyView.isHidden = !self.items.isEmpty
                    self.collectionView.isHidden = self.items.isEmpty
                    self.emptyStateView.isHidden = self.showsNoInternetView
                    self.noInternetView.isHidden = !self.showsNoInternetView

                    if wasInitialLoading || reset {
                        self.isPaginating = false
                        self.reloadUI()
                        return
                    }

                    let indexPaths = (oldCount..<newCount).map {
                        IndexPath(item: $0, section: 0)
                    }

                    guard !indexPaths.isEmpty else {
                        self.isPaginating = false
                        self.invalidateFooter()
                        self.updateScrollAvailability()
                        return
                    }

                    self.insertEventItems(indexPaths)

                } else {
                    self.isInitialLoading = false
                    self.isPaginating = false
                    self.invalidateFooter()
                    self.updateScrollAvailability()
                    self.showsNoInternetView =
                        V3NoInternetView.isNoInternet(errMsg)

                    self.emptyView.isHidden = false
                    self.collectionView.isHidden = true
                    self.emptyStateView.isHidden = self.showsNoInternetView
                    self.noInternetView.isHidden = !self.showsNoInternetView

                    print(errMsg ?? "Error")
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension VenueExperiencesVC: UICollectionViewDataSource {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if isInitialLoading {
            return 6
        }

        return items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if isInitialLoading {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: PremiumExperienceShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PremiumExperienceCell.identifier,
            for: indexPath
        ) as! PremiumExperienceCell

        guard items.indices.contains(indexPath.item) else {
            return cell
        }

        cell.configure(items[indexPath.item])

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PremiumExperiencePaginationFooterView.identifier,
                for: indexPath
            ) as! PremiumExperiencePaginationFooterView

            footer.isHidden = !(isPaginating && hasMore)
            return footer
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PremiumExperiencesHeaderView.reuseIdentifier,
            for: indexPath
        ) as! PremiumExperiencesHeaderView

        header.onInfoTapped = { [weak self] in
            guard let self else { return }
            Navigate.to.presentPremiumExpPopUp(self)
        }
        return header
    }
}

// MARK: - UICollectionViewDelegate

extension VenueExperiencesVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard items.indices.contains(indexPath.item) else { return }

        let item = items[indexPath.item]
        guard let event = item.event else {
            Alert.showToast(Constant.String.somethingWrong)
            return
        }

        Navigate.eventDetailsVC(
            self,
            event: event
        )
    }

    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {

        scrollDelegate?.childScrollViewDidScroll(scrollView)

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension VenueExperiencesVC:
    UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {

        guard !isInitialLoading else { return }

        if indexPaths.contains(where: {
            $0.item >= self.items.count - 4
        }) {
            loadNextPageIfNeeded()
        }
    }
}

// MARK: - PinterestLayoutDelegate

extension VenueExperiencesVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        if isInitialLoading {
            return ceil((width * 1.08) + 12 + 17 + 8 + 12 + 8 + 13 + 16 + 32)
        }

        guard items.indices.contains(indexPath.item) else {
            return 0.1
        }

        let imageHeight = width * 1.08

        let titleFont = Constant.Font.geistMedium(size: 15)
        let titleHeight = titleFont.lineHeight * 2

        return ceil(imageHeight + 10 + titleHeight + 3 + 12 + 3 + 15 + 16 + 22)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {

        return 64
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {

        return isPaginating && hasMore ? 300 : 0
    }
}

private final class PremiumExperiencesHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "PremiumExperiencesHeaderView"

    var onInfoTapped: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let infoButton = AppIconButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onInfoTapped = nil
    }

    private func setupUI() {
        backgroundColor = .clear

        iconView.image = UIImage(resource: .premiumExperienceIcon)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Premium Experiences"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        infoButton.iconTypeValue = AppIconType.questionMark.rawValue
        infoButton.iconSize = 14
        infoButton.buttonSize = 40
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.addTarget(self, action: #selector(onClickInfo), for: .touchUpInside)

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(infoButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 11),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -12),

            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            infoButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 40),
            infoButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func onClickInfo() {
        onInfoTapped?()
    }
}
