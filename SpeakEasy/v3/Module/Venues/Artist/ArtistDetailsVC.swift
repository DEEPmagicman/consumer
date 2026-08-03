//
//  ArtistVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit
import SDWebImage

struct ArtistDetailsContext {
    let id: String
    let venueId: String
    let name: String
    let imageKey: String?

    var imageURL: String? {
        guard let imageKey,
              !imageKey.isEmpty else { return nil }

        if imageKey.lowercased().hasPrefix("http://") ||
            imageKey.lowercased().hasPrefix("https://") {
            return imageKey
        }

        return imageKey.imageURL
    }

    init(
        id: String,
        venueId: String,
        name: String,
        imageKey: String?
    ) {
        self.id = id
        self.venueId = venueId
        self.name = name
        self.imageKey = imageKey
    }

    init(artist: Artists, venueId: String) {
        self.id = artist.id ?? ""
        self.venueId = venueId
        self.name = artist.name
        self.imageKey = artist.artistImage?.key
    }
}

final class ArtistDetailsVC: UIViewController {

    @IBOutlet weak var segmentView: UIView!

    var artist: ArtistDetailsContext?

    private let containerView = UIView()
    private let contentView = UIView()
    private let headerImageView = UIImageView()
    private let headerGradientView = UIView()
    private let headerGradientLayer = CAGradientLayer()
    private let artistNameLabel = UILabel()
    private let followContainer = LiquidGlassBackgroundView(
        cornerRadius: 15,
        fillColor: UIColor.black.withAlphaComponent(0.18),
        borderColor: UIColor.white.withAlphaComponent(0.14),
        borderWidth: 0.8
    )
    private let followButton = UIButton(type: .custom)
    private let followLabel = UILabel()
    private let socialIconsView = UIView()
    private let spotifyIconView = UIView()
    private let spotifyMarkView = SpotifyMarkView()
    private let tabView = UIView()
    private let glassSegment = GlassSegmentView(titles: ["Upcoming events", "Past events"])
    private let pageVC = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var tabControllers: [UIViewController] = []
    private var selectedIndex = 0
    private weak var containerTopConstraint: NSLayoutConstraint?
    private var maxHeaderCollapseOffset: CGFloat = 0
    private var headerCollapseOffset: CGFloat = 0
    private var childScrollOffsets: [ObjectIdentifier: CGFloat] = [:]
    private var childPanTranslations: [ObjectIdentifier: CGFloat] = [:]
    private var registeredPanScrollIDs = Set<ObjectIdentifier>()
    private var isUpdatingChildScrollOffset = false
    private var isFollowing = false

    private let tabTopPadding: CGFloat = 370
    private let stickySegmentTopSpacing: CGFloat = 64
    private let headerExpansionDragMultiplier: CGFloat = 2.0
    private let headerExpansionStartTolerance: CGFloat = 12
    private let headerFadeStartProgress: CGFloat = 0.12
    private let headerFadeEndProgress: CGFloat = 0.44
    private let headerSnapThresholdProgress: CGFloat = 0.5
    private let headerSnapVelocityThreshold: CGFloat = 160

    override func viewDidLoad() {
        super.viewDidLoad()

        hideLegacyArtistLayout()
        setupLayout()
        setupHeader()
        setupTabs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerGradientLayer.frame = headerGradientView.bounds
        spotifyIconView.layer.cornerRadius = spotifyIconView.bounds.height / 2
        updateHeaderCollapseMetrics()
        applyHeaderCollapse(animated: false)
    }

    private func hideLegacyArtistLayout() {
        segmentView?.isHidden = true
        segmentView?.superview?.subviews.forEach { subview in
            guard subview !== segmentView else { return }
            guard !(subview is AppIconButton) else { return }
            subview.isHidden = true
        }
    }

    private func setupLayout() {
        view.backgroundColor = AppColor.primaryBlackColor

        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        view.insertSubview(headerImageView, at: 0)

        headerGradientView.translatesAutoresizingMaskIntoConstraints = false
        headerGradientView.isUserInteractionEnabled = false
        view.insertSubview(headerGradientView, aboveSubview: headerImageView)
        headerGradientView.layer.addSublayer(headerGradientLayer)
        configureHeaderGradient()

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        view.insertSubview(containerView, aboveSubview: headerGradientView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        containerView.addSubview(contentView)

        setupTabView()
        setupSocialIcons()
        setupFollowButton()
        setupArtistHeaderContent()

        let topConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor)
        containerTopConstraint = topConstraint

        NSLayoutConstraint.activate([
            topConstraint,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 430),

            headerGradientView.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            headerGradientView.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            headerGradientView.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            headerGradientView.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: tabTopPadding),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            tabView.heightAnchor.constraint(equalToConstant: 45)
        ])

        view.subviews
            .filter { $0 is AppIconButton }
            .forEach { view.bringSubviewToFront($0) }
    }

    private func setupArtistHeaderContent() {
        artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
        artistNameLabel.textColor = .white
        artistNameLabel.font = Constant.Font.geistRegular(size: 28)
        artistNameLabel.textAlignment = .center
        artistNameLabel.numberOfLines = 2
        artistNameLabel.adjustsFontSizeToFitWidth = true
        artistNameLabel.minimumScaleFactor = 0.78
        contentView.addSubview(artistNameLabel)

        NSLayoutConstraint.activate([
            artistNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            artistNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            artistNameLabel.bottomAnchor.constraint(equalTo: followContainer.topAnchor, constant: -15)
        ])
    }

    private func setupFollowButton() {
        followContainer.translatesAutoresizingMaskIntoConstraints = false
        followContainer.clipsToBounds = true
        contentView.addSubview(followContainer)

        followButton.translatesAutoresizingMaskIntoConstraints = false
        followButton.addTarget(self, action: #selector(onClickFollowBtn), for: .touchUpInside)
        followContainer.addSubview(followButton)

        followLabel.translatesAutoresizingMaskIntoConstraints = false
        followLabel.text = "Follow"
        followLabel.textColor = .white
        followLabel.font = Constant.Font.geistRegular(size: 14)
        followLabel.textAlignment = .center
        followContainer.addSubview(followLabel)

        NSLayoutConstraint.activate([
            followContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            followContainer.bottomAnchor.constraint(equalTo: socialIconsView.topAnchor, constant: -14),
            followContainer.heightAnchor.constraint(equalToConstant: 34),

            followLabel.leadingAnchor.constraint(equalTo: followContainer.leadingAnchor, constant: 16),
            followLabel.trailingAnchor.constraint(equalTo: followContainer.trailingAnchor, constant: -16),
            followLabel.centerYAnchor.constraint(equalTo: followContainer.centerYAnchor),

            followButton.topAnchor.constraint(equalTo: followContainer.topAnchor),
            followButton.leadingAnchor.constraint(equalTo: followContainer.leadingAnchor),
            followButton.trailingAnchor.constraint(equalTo: followContainer.trailingAnchor),
            followButton.bottomAnchor.constraint(equalTo: followContainer.bottomAnchor)
        ])
    }

    private func setupSocialIcons() {
        socialIconsView.translatesAutoresizingMaskIntoConstraints = false
        socialIconsView.backgroundColor = .clear
        contentView.addSubview(socialIconsView)

        spotifyIconView.translatesAutoresizingMaskIntoConstraints = false
        spotifyIconView.backgroundColor = .white
        spotifyIconView.clipsToBounds = true
        socialIconsView.addSubview(spotifyIconView)

        spotifyMarkView.translatesAutoresizingMaskIntoConstraints = false
        spotifyMarkView.backgroundColor = .clear
        spotifyIconView.addSubview(spotifyMarkView)

        NSLayoutConstraint.activate([
            socialIconsView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            socialIconsView.bottomAnchor.constraint(equalTo: tabView.topAnchor, constant: -39),
            socialIconsView.widthAnchor.constraint(equalToConstant: 28),
            socialIconsView.heightAnchor.constraint(equalToConstant: 28),

            spotifyIconView.centerXAnchor.constraint(equalTo: socialIconsView.centerXAnchor),
            spotifyIconView.centerYAnchor.constraint(equalTo: socialIconsView.centerYAnchor),
            spotifyIconView.widthAnchor.constraint(equalToConstant: 28),
            spotifyIconView.heightAnchor.constraint(equalTo: spotifyIconView.widthAnchor),

            spotifyMarkView.centerXAnchor.constraint(equalTo: spotifyIconView.centerXAnchor),
            spotifyMarkView.centerYAnchor.constraint(equalTo: spotifyIconView.centerYAnchor),
            spotifyMarkView.widthAnchor.constraint(equalToConstant: 19),
            spotifyMarkView.heightAnchor.constraint(equalToConstant: 19)
        ])
    }

    private func setupTabView() {
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.backgroundColor = .clear
        tabView.clipsToBounds = false
        contentView.addSubview(tabView)

        glassSegment.translatesAutoresizingMaskIntoConstraints = false
        glassSegment.setSelectedIndex(0, animated: false)
        tabView.addSubview(glassSegment)

        NSLayoutConstraint.activate([
            glassSegment.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            glassSegment.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
            glassSegment.topAnchor.constraint(equalTo: tabView.topAnchor),
            glassSegment.bottomAnchor.constraint(equalTo: tabView.bottomAnchor)
        ])

        glassSegment.onIndexChanged = { [weak self] index in
            self?.moveToPage(index)
        }
    }

    private func configureHeaderGradient() {
        headerGradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.06).cgColor,
            UIColor.black.withAlphaComponent(0.16).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor,
            UIColor.black.cgColor
        ]
        headerGradientLayer.locations = [0.0, 0.44, 0.78, 1.0]
        headerGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        headerGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private func setupHeader() {
        artistNameLabel.text = artist?.name ?? "Artist"

        guard let imageURL = artist?.imageURL,
              let url = URL(string: imageURL) else {
            headerImageView.image = Constant.Icon.uploadImage
            return
        }

        headerImageView.sd_setImage(
            with: url,
            placeholderImage: Constant.Icon.uploadImage
        )
    }

    private func setupTabs() {
        let upcomingVC = ArtistEventsListVC(
            artist: artist,
            timeVersion: .upcoming
        )
        let pastVC = ArtistEventsListVC(
            artist: artist,
            timeVersion: .past
        )

        upcomingVC.scrollDelegate = self
        pastVC.scrollDelegate = self

        tabControllers = [upcomingVC, pastVC]

        addChild(pageVC)
        contentView.addSubview(pageVC.view)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageVC.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageVC.view.topAnchor.constraint(equalTo: tabView.bottomAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        pageVC.didMove(toParent: self)
        pageVC.dataSource = self
        pageVC.delegate = self
        pageVC.setViewControllers([upcomingVC], direction: .forward, animated: false)
        resetTrackedOffset(for: upcomingVC)

        contentView.bringSubviewToFront(tabView)
    }

    private func moveToPage(_ index: Int) {
        guard index >= 0, index < tabControllers.count else { return }
        guard index != selectedIndex else { return }

        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse

        pageVC.setViewControllers(
            [tabControllers[index]],
            direction: direction,
            animated: true
        ) { [weak self] completed in
            guard let self else { return }

            if completed {
                self.selectedIndex = index
                self.glassSegment.setSelectedIndex(index, animated: true)
                self.resetTrackedOffset(for: self.tabControllers[index])
            }
        }
    }

    @objc private func onClickFollowBtn() {
        guard LoginRequiredCoordinator.isAuthenticated else {
            LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
                self?.onClickFollowBtn()
            }
            return
        }

        isFollowing.toggle()
        followLabel.text = isFollowing ? "Following" : "Follow"
        animateFollowTap()
    }

    private func animateFollowTap() {
        UIView.animate(
            withDuration: 0.08,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: {
                self.followContainer.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.22,
                    delay: 0,
                    usingSpringWithDamping: 0.74,
                    initialSpringVelocity: 0.6,
                    options: [.curveEaseOut, .beginFromCurrentState],
                    animations: {
                        self.followContainer.transform = .identity
                    }
                )
            }
        )
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
}

// MARK: - Sticky Header Coordination

extension ArtistDetailsVC: ChildScrollDelegate {

    var isHeaderFullyCollapsed: Bool {
        return headerCollapseOffset >= maxHeaderCollapseOffset - 0.5
    }

    func childScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isUpdatingChildScrollOffset else { return }
        guard maxHeaderCollapseOffset > 0 else { return }

        let scrollID = ObjectIdentifier(scrollView)
        registerPanHandlerIfNeeded(for: scrollView, scrollID: scrollID)

        let currentOffsetY = scrollView.contentOffset.y
        let previousOffsetY = childScrollOffsets[scrollID] ?? currentOffsetY
        let deltaY = currentOffsetY - previousOffsetY
        let topOffsetY = topContentOffsetY(for: scrollView)

        childScrollOffsets[scrollID] = currentOffsetY

        guard abs(deltaY) > 0.1 else { return }

        if deltaY > 0, headerCollapseOffset < maxHeaderCollapseOffset {
            consumeUpwardScroll(deltaY, from: scrollView, scrollID: scrollID, topOffsetY: topOffsetY)
        }
    }

    private func updateHeaderCollapseMetrics() {
        let tabFrame = tabView.convert(tabView.bounds, to: view)
        let stickyTopY = view.safeAreaInsets.top + stickySegmentTopSpacing
        let newMaxOffset = max(0, tabFrame.minY - stickyTopY + headerCollapseOffset)

        guard abs(newMaxOffset - maxHeaderCollapseOffset) > 0.5 else { return }

        maxHeaderCollapseOffset = newMaxOffset
        headerCollapseOffset = min(headerCollapseOffset, maxHeaderCollapseOffset)
    }

    private func applyHeaderCollapse(animated: Bool) {
        headerCollapseOffset = min(max(headerCollapseOffset, 0), maxHeaderCollapseOffset)
        containerTopConstraint?.constant = -headerCollapseOffset

        let progress: CGFloat
        if maxHeaderCollapseOffset > 0 {
            progress = min(1, max(0, headerCollapseOffset / maxHeaderCollapseOffset))
        } else {
            progress = 0
        }

        let visibleAlpha = headerContentAlpha(for: progress)
        artistNameLabel.alpha = visibleAlpha
        followContainer.alpha = visibleAlpha
        socialIconsView.alpha = visibleAlpha

        let updates = {
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }

    private func headerContentAlpha(for progress: CGFloat) -> CGFloat {
        return 1 - smoothProgress(
            progress,
            start: headerFadeStartProgress,
            end: headerFadeEndProgress
        )
    }

    private func smoothProgress(_ value: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return value >= end ? 1 : 0 }

        let normalized = min(1, max(0, (value - start) / (end - start)))
        return normalized * normalized * (3 - 2 * normalized)
    }

    private func resetTrackedOffset(for viewController: UIViewController) {
        guard let scrollView = observedScrollView(for: viewController) else { return }
        let scrollID = ObjectIdentifier(scrollView)
        childScrollOffsets[scrollID] = scrollView.contentOffset.y
        childPanTranslations.removeValue(forKey: scrollID)
        registerPanHandlerIfNeeded(for: scrollView, scrollID: scrollID)
    }

    private func observedScrollView(for viewController: UIViewController) -> UIScrollView? {
        guard viewController.isViewLoaded else { return nil }

        if let eventsVC = viewController as? ArtistEventsListVC {
            return eventsVC.collectionView
        }

        return nil
    }

    private func consumeUpwardScroll(
        _ deltaY: CGFloat,
        from scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        topOffsetY: CGFloat
    ) {
        let consumed = min(deltaY, maxHeaderCollapseOffset - headerCollapseOffset)
        guard consumed > 0 else { return }

        headerCollapseOffset = min(maxHeaderCollapseOffset, headerCollapseOffset + consumed)
        applyHeaderCollapse(animated: false)
        let targetOffsetY = max(topOffsetY, scrollView.contentOffset.y - consumed)
        set(scrollView, contentOffsetY: targetOffsetY, scrollID: scrollID)
    }

    private func consumeDownwardScroll(
        _ deltaY: CGFloat,
        from scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        topOffsetY: CGFloat
    ) {
        let consumed = min(deltaY, headerCollapseOffset)
        guard consumed > 0 else { return }

        headerCollapseOffset = max(0, headerCollapseOffset - consumed)
        applyHeaderCollapse(animated: false)
        set(scrollView, contentOffsetY: topOffsetY, scrollID: scrollID)
    }

    private func set(
        _ scrollView: UIScrollView,
        contentOffsetY: CGFloat,
        scrollID: ObjectIdentifier
    ) {
        isUpdatingChildScrollOffset = true
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: contentOffsetY),
            animated: false
        )
        isUpdatingChildScrollOffset = false
        childScrollOffsets[scrollID] = scrollView.contentOffset.y
    }

    private func topContentOffsetY(for scrollView: UIScrollView) -> CGFloat {
        return -scrollView.adjustedContentInset.top
    }

    private func settleHeaderAfterScrollEnds(
        for scrollView: UIScrollView,
        scrollID: ObjectIdentifier,
        velocityY: CGFloat
    ) {
        guard maxHeaderCollapseOffset > 0 else { return }
        guard headerCollapseOffset > 0,
              headerCollapseOffset < maxHeaderCollapseOffset
        else {
            return
        }

        let progress = headerCollapseOffset / maxHeaderCollapseOffset
        let shouldCollapse: Bool

        if abs(velocityY) >= headerSnapVelocityThreshold {
            shouldCollapse = velocityY < 0
        } else {
            shouldCollapse = progress >= headerSnapThresholdProgress
        }

        headerCollapseOffset = shouldCollapse ? maxHeaderCollapseOffset : 0
        set(scrollView, contentOffsetY: topContentOffsetY(for: scrollView), scrollID: scrollID)
        applyHeaderCollapse(animated: true)
    }

    private func registerPanHandlerIfNeeded(for scrollView: UIScrollView, scrollID: ObjectIdentifier) {
        guard !registeredPanScrollIDs.contains(scrollID) else { return }

        registeredPanScrollIDs.insert(scrollID)
        scrollView.panGestureRecognizer.addTarget(
            self,
            action: #selector(handleChildPan(_:))
        )
    }

    @objc private func handleChildPan(_ gesture: UIPanGestureRecognizer) {
        guard let scrollView = gesture.view as? UIScrollView else { return }

        let scrollID = ObjectIdentifier(scrollView)

        if gesture.state == .ended ||
            gesture.state == .cancelled ||
            gesture.state == .failed {
            settleHeaderAfterScrollEnds(
                for: scrollView,
                scrollID: scrollID,
                velocityY: gesture.velocity(in: view).y
            )
            childPanTranslations.removeValue(forKey: scrollID)
            return
        }

        guard !isUpdatingChildScrollOffset else { return }

        let currentTranslationY = gesture.translation(in: view).y
        let topOffsetY = topContentOffsetY(for: scrollView)

        guard headerCollapseOffset > 0 else {
            childPanTranslations[scrollID] = currentTranslationY
            return
        }

        switch gesture.state {
        case .began:
            childPanTranslations[scrollID] = currentTranslationY

        case .changed:
            guard scrollView.contentOffset.y <= topOffsetY + headerExpansionStartTolerance else {
                childPanTranslations[scrollID] = currentTranslationY
                return
            }

            let previousTranslationY = childPanTranslations[scrollID] ?? currentTranslationY
            let deltaY = currentTranslationY - previousTranslationY

            childPanTranslations[scrollID] = currentTranslationY

            guard deltaY > 0 else { return }

            consumeDownwardScroll(
                deltaY * headerExpansionDragMultiplier,
                from: scrollView,
                scrollID: scrollID,
                topOffsetY: topOffsetY
            )

        default:
            childPanTranslations.removeValue(forKey: scrollID)
        }
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension ArtistDetailsVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }

        return tabControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index < tabControllers.count - 1 else {
            return nil
        }

        return tabControllers[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = tabControllers.firstIndex(of: currentVC) else {
            return
        }

        selectedIndex = index
        glassSegment.setSelectedIndex(index, animated: true)
        resetTrackedOffset(for: currentVC)
    }
}

enum ArtistEventTimeVersion: String {
    case upcoming = "UPCOMING"
    case past = "PAST"

    var emptySubtitle: String {
        switch self {
        case .upcoming:
            return "This artist does not have upcoming events here yet."
        case .past:
            return "This artist does not have past events here yet."
        }
    }
}

final class ArtistEventsListVC: UIViewController {

    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )

    weak var scrollDelegate: ChildScrollDelegate?

    private let artist: ArtistDetailsContext?
    private let timeVersion: ArtistEventTimeVersion
    private let discoverService = DiscoverService()
    private var events: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0

    init(
        artist: ArtistDetailsContext?,
        timeVersion: ArtistEventTimeVersion
    ) {
        self.artist = artist
        self.timeVersion = timeVersion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.artist = nil
        self.timeVersion = .upcoming
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        getEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshCollectionLayoutIfNeeded()
    }

    private func setupCollectionView() {
        view.backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = true
        collectionView.layer.masksToBounds = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )
        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )
        collectionView.register(
            EmptyCollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EmptyCollectionReusableView.identifier
        )
        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(
            top: 22,
            left: 32,
            bottom: 34,
            right: 16
        )
        layout.interItemSpacing = 14
        layout.lineSpacing = 16
        layout.delegate = self
        collectionView.collectionViewLayout = layout

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func getEvents(reset: Bool = false) {
        guard !isLoading || reset else { return }
        guard hasMore || reset else { return }

        guard timeVersion == .upcoming else {
            isInitialLoading = false
            isPaginating = false
            isLoading = false
            hasMore = false
            events.removeAll()
            reloadUI()
            return
        }

        let artistId = artist?.id ?? ""
        let venueId = artist?.venueId ?? ""

        guard !artistId.isEmpty else {
            isInitialLoading = false
            events.removeAll()
            reloadUI()
            return
        }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            events.removeAll()
            reloadUI()
        }

        discoverService.fetchArtistEvents(
            artistId: artistId,
            venueId: venueId,
            skip: skip,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in
            DispatchQueue.main.async {
                guard let self else { return }

                let oldCount = self.events.count
                self.isLoading = false

                guard isSuccess,
                      let page else {
                    let wasInitialLoading = self.isInitialLoading
                    self.isInitialLoading = false
                    self.isPaginating = false
                    self.hasMore = false
                    if wasInitialLoading || self.events.isEmpty {
                        self.reloadUI()
                    } else {
                        self.invalidateFooter()
                        self.updateEmptyState()
                    }
                    if let errMsg {
                        Alert.showToast(errMsg)
                    }
                    return
                }

                let incomingEvents = reset
                    ? page.list
                    : page.list.filter { newEvent in
                        !self.events.contains { $0.id == newEvent.id }
                    }

                if reset {
                    self.events = incomingEvents
                } else {
                    self.events.append(contentsOf: incomingEvents)
                }

                self.skip = self.events.count
                self.hasMore = page.hasMore

                let wasInitialLoading = self.isInitialLoading
                self.isInitialLoading = false

                if wasInitialLoading || reset {
                    self.isPaginating = false
                    self.reloadUI()
                    return
                }

                let newCount = self.events.count
                let indexPaths = (oldCount..<newCount).map {
                    IndexPath(item: $0, section: 0)
                }

                guard !indexPaths.isEmpty else {
                    self.isPaginating = false
                    self.invalidateFooter()
                    self.updateEmptyState()
                    return
                }

                self.insertEventItems(indexPaths)
            }
        }
    }

    private func reloadUI() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        updateEmptyState()
    }

    private func insertEventItems(_ indexPaths: [IndexPath]) {
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

    private func updateEmptyState() {
        collectionView.backgroundView = !isInitialLoading && events.isEmpty
            ? makeEmptyStateView()
            : nil
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: collectionView.bounds)
        container.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No events found"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 18)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = timeVersion.emptySubtitle
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
        ])

        return container
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
    }

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !events.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()

        getEvents(reset: false)
    }
}

extension ArtistEventsListVC: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if isInitialLoading {
            return 6
        }

        return events.count
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

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        )

        guard events.indices.contains(indexPath.item) else {
            return cell
        }

        (cell as? OrderCardCollectionCell)?
            .configureDiscoverEvent(events[indexPath.item])
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
                withReuseIdentifier: PaginationShimmerFooterView.identifier,
                for: indexPath
            )

            footer.isHidden = !(isPaginating && hasMore)
            return footer
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EmptyCollectionReusableView.identifier,
            for: indexPath
        )
        header.isHidden = true
        return header
    }
}

extension ArtistEventsListVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard events.indices.contains(indexPath.item) else { return }

        Navigate.eventDetailsVC(self, event: events[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

extension ArtistEventsListVC: UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard !isInitialLoading else { return }

        if indexPaths.contains(where: { $0.item >= events.count - 4 }) {
            loadNextPageIfNeeded()
        }
    }
}

extension ArtistEventsListVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {

        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard events.indices.contains(indexPath.item) else {
            return 0.1
        }

        let imageHeight = width * 1.2

        let titleFont = Constant.Font.geistMedium(size: 14)
        let venueFont = Constant.Font.geistMedium(size: 12)
        let dateFont = Constant.Font.geistMedium(size: 12)

        let titleHeight = ceil(titleFont.lineHeight * 2)
        let venueHeight = ceil(venueFont.lineHeight)
        let dateHeight = ceil(dateFont.lineHeight)

        return imageHeight
            + 16
            + titleHeight
            + 3
            + venueHeight
            + 4
            + dateHeight
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        return 0.1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        return isPaginating && hasMore ? 300 : 0
    }
}

private final class SpotifyMarkView: UIView {

    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()

        let lineWidth: CGFloat = max(1.4, rect.width * 0.08)
        let arcs = [
            (y: rect.height * 0.35, width: rect.width * 0.68),
            (y: rect.height * 0.50, width: rect.width * 0.56),
            (y: rect.height * 0.64, width: rect.width * 0.44)
        ]

        for arc in arcs {
            let path = UIBezierPath()
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.move(to: CGPoint(x: rect.midX - arc.width / 2, y: arc.y))
            path.addCurve(
                to: CGPoint(x: rect.midX + arc.width / 2, y: arc.y + rect.height * 0.06),
                controlPoint1: CGPoint(x: rect.midX - arc.width * 0.15, y: arc.y - rect.height * 0.08),
                controlPoint2: CGPoint(x: rect.midX + arc.width * 0.22, y: arc.y - rect.height * 0.02)
            )
            path.stroke()
        }
    }
}
