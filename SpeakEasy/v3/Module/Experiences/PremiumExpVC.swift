//
//  PremiumExpVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import UIKit

final class PremiumExpVC: UIViewController {
    
    private let bgImageView = UIImageView()
    private let blurView = VisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    
    private let headerView = PremiumHeaderView()
    private let titleLabel = UILabel()
    private let separatorView = UIView()
    private let sectionTitleLabel = UILabel()
    private let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()
    
    private let emptyView = UIView()
    private let emptyTitleLabel = UILabel()
    private let emptySubTitleLabel = UILabel()
    
    private let service = PremiumExperienceService()
    private var items: [PremiumExperienceItem] = []
    
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0
    private var hasPresentedIntro = false
    private var selectedCity: String = UserDefault.shared.activeCity
    
    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: 44,
            right: 24
        )
        layout.interItemSpacing = 20
        layout.lineSpacing = 16
        
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        
        super.init(nibName: nil, bundle: nil)
        layout.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showIntroIfNeeded()
        loadPremiumExperiences(reset: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        headerView.configure(city: selectedCity)
        headerView.reloadUser()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        refreshCollectionLayoutIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = AppColor.primaryBlackColor

        setupBackground()
        setupHeader()
        setupCollectionView()
        setupEmptyView()
        setupConstraints()
    }

    private func setupBackground() {
        bgImageView.image = UIImage(resource: .premiumExpBg)
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bgImageView)

        blurView.blurRadius = 18
        blurView.colorTint = AppColor.primaryBlackColor
        blurView.colorTintAlpha = 0.18
        blurView.alpha = 0.80
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)

        dimView.backgroundColor = AppColor.primaryBlackColor.withAlphaComponent(0.42)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
    }

    private func setupHeader() {
        headerView.delegate = self
        view.addSubview(headerView)

        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82
        titleLabel.attributedText = makeTitleText()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        separatorView.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.10)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorView)

        sectionTitleLabel.text = "Top picks for you"
        sectionTitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.94)
        sectionTitleLabel.font = Constant.Font.geistMedium(size: 16)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionTitleLabel)
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.contentInset.bottom = .zero
        collectionView.verticalScrollIndicatorInsets.bottom = .zero
        collectionView.translatesAutoresizingMaskIntoConstraints = false

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

        refreshControl.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.8)
        refreshControl.addTarget(
            self,
            action: #selector(onRefresh),
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
    }

    private func setupEmptyView() {
        emptyView.isHidden = true
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)

        emptyTitleLabel.text = "No premium experiences yet"
        emptyTitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.92)
        emptyTitleLabel.font = Constant.Font.geistMedium(size: 18)
        emptyTitleLabel.textAlignment = .center

        emptySubTitleLabel.text = "Check back soon for curated access."
        emptySubTitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.58)
        emptySubTitleLabel.font = Constant.Font.geistRegular(size: 14)
        emptySubTitleLabel.textAlignment = .center

        let stack = UIStackView(
            arrangedSubviews: [
                emptyTitleLabel,
                emptySubTitleLabel
            ]
        )
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(stack)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -70),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: emptyView.trailingAnchor, constant: -32)
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            separatorView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 13),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            sectionTitleLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 20),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            collectionView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeTitleText() -> NSAttributedString {
        
        let attributed = NSMutableAttributedString()
        
        let image = UIImage(resource: .premiumExpStartIcon)
        
        let attachment = NSTextAttachment()
        attachment.image = image
        
        attachment.bounds = CGRect(
            x: 0,
            y: -2,
            width: 16,
            height: 20
        )
        
        attributed.append(NSAttributedString(attachment: attachment))
        attributed.append(NSAttributedString(string: "  "))
        
        attributed.append(
            NSAttributedString(
                string: "Premium Experiences",
                attributes: [
                    .font: Constant.Font.geistMedium(size: 24),
                    .foregroundColor: AppColor.primaryWhiteColor
                ]
            )
        )

        return attributed
    }

    private func showIntroIfNeeded() {

        guard !hasPresentedIntro else { return }
        guard UserDefault.shared.hasSeenPremiumIntro != true else { return }

        hasPresentedIntro = true

        let intro = PremiumExperienceIntroVC()

        intro.onExplore = { [weak self, weak intro] in
            guard let self, let intro else { return }

            UIView.animate(withDuration: 0.25, animations: {
                intro.view.alpha = 0
            }) { _ in
                intro.willMove(toParent: nil)
                intro.view.removeFromSuperview()
                intro.removeFromParent()
            }
        }

        addChild(intro)
        intro.view.frame = view.bounds
        view.addSubview(intro.view)
        intro.didMove(toParent: self)
    }

    @objc private func onRefresh() {
        loadPremiumExperiences(reset: true, showsInitialShimmer: false)
    }
}

private extension PremiumExpVC {

    func loadPremiumExperiences(
        reset: Bool,
        showsInitialShimmer: Bool = true
    ) {
        guard !isLoading else {
            refreshControl.endRefreshing()
            return
        }

        guard hasMore || reset else {
            isPaginating = false
            invalidateFooter()
            refreshControl.endRefreshing()
            return
        }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isPaginating = false
            isInitialLoading = showsInitialShimmer

            if showsInitialShimmer {
                items.removeAll()
                reloadUI()
            }
        }

        service.fetchPremiumExperiences(
            skip: skip,
            city: selectedCity
        ) { [weak self] isSuccess, errMsg, newItems, hasMore in
            guard let self else { return }

            self.refreshControl.endRefreshing()
            self.isLoading = false

            let wasInitialLoading = self.isInitialLoading
            self.isInitialLoading = false

            guard isSuccess else {
                self.isPaginating = false
                if reset {
                    self.items.removeAll()
                }
                self.reloadUI()
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                return
            }

            let oldCount = self.items.count
            let uniqueItems = newItems.filter { item in
                !self.items.contains(where: { $0.id == item.id })
            }

            self.items = reset ? newItems : self.items + uniqueItems
            self.skip = self.items.count
            self.hasMore = hasMore

            if reset || wasInitialLoading {
                self.isPaginating = false
                self.reloadUI()
                return
            }

            let newCount = self.items.count
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(item: $0, section: 0)
            }

            guard !indexPaths.isEmpty else {
                self.isPaginating = false
                self.invalidateFooter()
                return
            }

            self.insertItems(indexPaths)
        }
    }

    func reloadUI() {
        updateEmptyState()

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    func insertItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                self.isPaginating = false
                self.invalidateFooter()
                self.updateEmptyState()
            }
        }
    }

    func updateEmptyState() {
        let shouldShowEmpty = !isInitialLoading && items.isEmpty
        emptyView.isHidden = !shouldShowEmpty
        collectionView.isHidden = shouldShowEmpty
        sectionTitleLabel.isHidden = shouldShowEmpty
    }

    func invalidateFooter() {
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.invalidateFooter()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    func refreshCollectionLayoutIfNeeded() {
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
    }

    func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !items.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()
        loadPremiumExperiences(reset: false)
    }

    func presentCityFilter() {
        let vc = Navigate.to.selectLocationVC(self)
        vc.persistsFilterSelection = false
        vc.selectedFilterCity = selectedCity
        vc.initialFilterCity = selectedCity
        vc.onSelectFilterCity = { [weak self] city in
            self?.applyCity(city)
        }
    }
}

extension PremiumExpVC {

    func applyCity(_ city: String?) {
        let trimmedCity = city?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedCity = trimmedCity?.isEmpty == false
            ? trimmedCity!
            : UserDefault.shared.activeCity

        guard resolvedCity.caseInsensitiveCompare(selectedCity) != .orderedSame else {
            headerView.configure(city: selectedCity)
            return
        }

        selectedCity = resolvedCity
        headerView.configure(city: resolvedCity)

        guard isViewLoaded else { return }
        loadPremiumExperiences(reset: true)
    }
}

extension PremiumExpVC: PremiumHeaderViewDelegate {
    func premiumHeaderDidTapProfile(_ view: PremiumHeaderView) {
        LoginRequiredCoordinator.perform(from: self) { [weak self] in
            guard let self else { return }
            Navigate.to.profileMenuVC(self)
        }
    }

    func premiumHeaderDidTapLocation(_ view: PremiumHeaderView) {
        presentCityFilter()
    }

    func premiumHeaderDidTapHelp(_ view: PremiumHeaderView) {
        Navigate.to.presentPremiumExpPopUp(self)
    }
}

extension PremiumExpVC: UICollectionViewDataSource, UICollectionViewDelegate {

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
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard items.indices.contains(indexPath.item) else { return }
        let item = items[indexPath.item]
        guard let event = item.event else {
            Alert.showToast(Constant.String.somethingWrong)
            return
        }

//        Navigate.eventDetailsVC(self, event: event)
        Navigate.to.premiumEventContainerVC(
            self,
            event: event,
            seatingAreas: item.seatingAreas
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PremiumExperiencePaginationFooterView.identifier,
            for: indexPath
        ) as! PremiumExperiencePaginationFooterView

        footer.isHidden = !(isPaginating && hasMore)
        return footer
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isInitialLoading else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let threshold: CGFloat = 420

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }
}

extension PremiumExpVC: UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard !isInitialLoading else { return }

        if indexPaths.contains(where: { $0.item >= items.count - 4 }) {
            loadNextPageIfNeeded()
        }
    }
}

extension PremiumExpVC: PinterestLayoutDelegate {
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

        let item = items[indexPath.item]
        let imageHeight = width * 1.08

        let titleHeight = item.title.boundingRect(
            with: CGSize(width: width - 4, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Constant.Font.geistMedium(size: 15)],
            context: nil
        ).height

        return ceil(imageHeight + 10 + titleHeight + 3 + 12 + 3 + 15 + 16 + 32)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        isPaginating && hasMore ? 300 : 0
    }
}
