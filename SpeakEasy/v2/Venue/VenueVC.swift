import UIKit

//
//  VenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

protocol ChildScrollDelegate: AnyObject {
    func childScrollViewDidScroll(_ scrollView: UIScrollView)
    var isHeaderFullyCollapsed: Bool { get }
}

final class VenueVC: UIViewController {

    @IBOutlet weak var venueView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var buyticketView: UIView!
    @IBOutlet weak var coverTicketView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabView: UIView!

    @IBOutlet weak var bgView: UIView!

    var presenter = MVPPresenter()
    private var shimmerView: VenueShimmerView?
    private let posterHeaderView = VenuePosterHeaderView()
    private let navTitleStackView = UIStackView()
    private let navVenueNameLabel = UILabel()
    private let navVenueCityLabel = UILabel()

    private let glassSegment = GlassSegmentView(titles: ["Events", "Premium", "Artists"])

    private let pageVC = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var tabControllers: [UIViewController] = []
    private var selectedIndex: Int = 0

    private weak var containerTopConstraint: NSLayoutConstraint?
    private var maxHeaderCollapseOffset: CGFloat = 0
    private var headerCollapseOffset: CGFloat = 0
    private var childScrollOffsets: [ObjectIdentifier: CGFloat] = [:]
    private var childPanTranslations: [ObjectIdentifier: CGFloat] = [:]
    private var registeredPanScrollIDs = Set<ObjectIdentifier>()
    private var isUpdatingChildScrollOffset = false
    private let stickySegmentTopSpacing: CGFloat = 64
    private let headerExpansionDragMultiplier: CGFloat = 2.0
    private let headerExpansionStartTolerance: CGFloat = 12
    private let headerFadeStartProgress: CGFloat = 0.12
    private let headerFadeEndProgress: CGFloat = 0.42
    private let navTitleFadeStartProgress: CGFloat = 0.52
    private let navTitleFadeEndProgress: CGFloat = 0.82
    private let headerSnapThresholdProgress: CGFloat = 0.5
    private let headerSnapVelocityThreshold: CGFloat = 160

    var venueDetails: ClipVenue?
    var uniqueId: String? = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        captureContainerTopConstraint()
        setupNavTitleView()
        setupPosterBackground()
        setUpData()
//        showShimmer()
        getVenueDetails()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderCollapseMetrics()
        applyHeaderCollapse(animated: false)
    }

    private func showShimmer() {
        if let shimmerView {
            view.bringSubviewToFront(shimmerView)
            shimmerView.start()
            return
        }

        let shimmer = VenueShimmerView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shimmer)
        view.bringSubviewToFront(shimmer)

        NSLayoutConstraint.activate([
            shimmer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shimmer.topAnchor.constraint(equalTo: view.topAnchor),
            shimmer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.shimmerView = shimmer
        shimmer.start()
    }

    private func getVenueDetails() {
        presenter.getVenuesDetailForaMVP(
            venueId: (venueDetails?.uniqueId ?? uniqueId) ?? "",
            venueTimeZone: venueDetails?.useTimezone ?? "",
            doormanId: ""
        ) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else { return }

            if isSuccess, let venue = venueDetail {
                self.venueDetails = venue
                self.hideShimmer()
                self.setUpData()
                self.setUpTabs()
            } else {
                self.hideShimmer()
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )
            }
        }
    }

    private func hideShimmer() {
        shimmerView?.stop()
        shimmerView = nil
    }

    private func setUpData() {
        venueName.text = displayVenueName
        updateNavTitleText()
        updateCoverTicketViewVisibility()
        updatePosterBackgroundImage()

        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        venueLogo.sd_setImage(with: URL(string: logoUrl), completed: nil)

//        if let url = URL(string: imageUrlString) {
//            bgImage.sd_setImage(with: url, placeholderImage: UIImage(named: "newSpeakeasy"))
//        } else {
//            bgImage.image = UIImage(named: "newSpeakeasy")
//        }
    }

    private func setupPosterBackground() {
        guard posterHeaderView.superview == nil else {
            updatePosterBackgroundImage()
            return
        }

        self.bgView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: self.bgView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: self.bgView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: self.bgView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: self.bgView.bottomAnchor)
        ])

//        posterHeaderView.configure(style: .gradientImage)
        updatePosterBackgroundImage()
    }

    private func updatePosterBackgroundImage() {
        let imageKey = venueDetails?.venueAttachment?.first?.key ?? ""
        let imageUrlString = imageKey.isEmpty ? "" : "\(SharedURL.amazonStorage)\(imageKey)"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    private func setUpTabs() {
        createTabControllers()
        setupPageVC()
        setupGlassSegment()

        view.bringSubviewToFront(tabView)
    }

    private func createTabControllers() {
        let vc1 = VenueEventsVC(nibName: "VenueEventsVC", bundle: nil)
        vc1.title = "Events"
        vc1.venueId = venueDetails?.id ?? ""
        vc1.scrollDelegate = self

        let vc2 = VenueExperiencesVC(nibName: "VenueExperiencesVC", bundle: nil)
        vc2.title = "Premium"
        vc2.venueId = venueDetails?.id ?? ""
        vc2.scrollDelegate = self

        let vc3 = ArtistsVC(nibName: "ArtistsVC", bundle: nil)
        vc3.title = "Artists"
        vc3.scrollDelegate = self

        tabControllers = [vc1, vc2, vc3]
    }

    private func setupGlassSegment() {
        glassSegment.translatesAutoresizingMaskIntoConstraints = false
        glassSegment.isUserInteractionEnabled = true
        glassSegment.setSelectedIndex(0, animated: false)

        tabView.isUserInteractionEnabled = true
        tabView.clipsToBounds = false

        tabView.subviews.forEach { $0.removeFromSuperview() }
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

        view.bringSubviewToFront(tabView)
    }

    private func setupPageVC() {
        guard let firstVC = tabControllers.first else { return }

        addChild(pageVC)
        containerView.addSubview(pageVC.view)

        pageVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageVC.view.leadingAnchor.constraint(equalTo: venueView.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: venueView.trailingAnchor),
            pageVC.view.topAnchor.constraint(equalTo: venueView.topAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: venueView.bottomAnchor)
        ])

        pageVC.didMove(toParent: self)

        pageVC.dataSource = self
        pageVC.delegate = self

        pageVC.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        )
        resetTrackedOffset(for: firstVC)
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
            guard let self = self else { return }

            if completed {
                self.selectedIndex = index
                self.glassSegment.setSelectedIndex(index, animated: true)
                self.resetTrackedOffset(for: self.tabControllers[index])
            }
        }
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickShare(_ sender: Any) {
        let msgText = "Check out \(venueDetails?.name ?? "Venue") on Speakeasy. \(String(format: APIBuilder.venueWebURL, venueDetails?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "Venue", venueDetails?.uniqueId ?? "")) Download the app to directly connect with your favorite venues & never miss out! \(SharedURL.appStoreURL)"
        Utility.main.shareSocialWith(text: msgText)
    }

    @IBAction func onClickBuyTicket(_ sender: Any) {
        guard hasAvailableTickets else { return }
        Navigate.to.coverTicketListVC(self, venueDetails: venueDetails)
    }

}

// MARK: - Sticky Header Coordination
private extension VenueVC {

    var displayVenueName: String {
        let name = (venueDetails?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Venue" : name
    }

    var displayVenueCity: String {
        return (venueDetails?.city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasAvailableTickets: Bool {
        let tickets = venueDetails?.coverTicket ?? []
        return tickets.contains {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        }
    }

    func updateCoverTicketViewVisibility() {
        coverTicketView.isHidden = !hasAvailableTickets
        view.setNeedsLayout()
    }

    func setupNavTitleView() {
        navTitleStackView.axis = .vertical
        navTitleStackView.alignment = .center
        navTitleStackView.distribution = .fill
        navTitleStackView.spacing = 1
        navTitleStackView.alpha = 0
        navTitleStackView.isUserInteractionEnabled = false
        navTitleStackView.translatesAutoresizingMaskIntoConstraints = false

        navVenueNameLabel.font = Constant.Font.geistMedium(size: 20)
        navVenueNameLabel.textColor = .white
        navVenueNameLabel.textAlignment = .center
        navVenueNameLabel.numberOfLines = 1
        navVenueNameLabel.lineBreakMode = .byTruncatingTail
        navVenueNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        navVenueCityLabel.font = Constant.Font.geistMedium(size: 12)
        navVenueCityLabel.textColor = UIColor(hex:"#A1A1A1")
        navVenueCityLabel.textAlignment = .center
        navVenueCityLabel.numberOfLines = 1
        navVenueCityLabel.lineBreakMode = .byTruncatingTail
        navVenueCityLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        navTitleStackView.addArrangedSubview(navVenueNameLabel)
        navTitleStackView.addArrangedSubview(navVenueCityLabel)
        view.addSubview(navTitleStackView)

        NSLayoutConstraint.activate([
            navTitleStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            navTitleStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            navTitleStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 72),
            navTitleStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -72)
        ])
    }

    func updateNavTitleText() {
        navVenueNameLabel.text = displayVenueName
        navVenueCityLabel.text = displayVenueCity
        navVenueCityLabel.isHidden = displayVenueCity.isEmpty
    }

    func captureContainerTopConstraint() {
        containerTopConstraint = view.constraints.first(where: { constraint in
            guard let firstView = constraint.firstItem as? UIView else { return false }
            return firstView === containerView && constraint.firstAttribute == .top
        })
    }

    func updateHeaderCollapseMetrics() {
        let tabFrame = tabView.convert(tabView.bounds, to: view)
        let stickyTopY = view.safeAreaInsets.top + stickySegmentTopSpacing
        let newMaxOffset = max(0, tabFrame.minY - stickyTopY + headerCollapseOffset)

        guard abs(newMaxOffset - maxHeaderCollapseOffset) > 0.5 else { return }

        maxHeaderCollapseOffset = newMaxOffset
        headerCollapseOffset = min(headerCollapseOffset, maxHeaderCollapseOffset)
    }

    func applyHeaderCollapse(animated: Bool) {
        headerCollapseOffset = min(max(headerCollapseOffset, 0), maxHeaderCollapseOffset)
        containerTopConstraint?.constant = -headerCollapseOffset

        let progress: CGFloat
        if maxHeaderCollapseOffset > 0 {
            progress = min(1, max(0, headerCollapseOffset / maxHeaderCollapseOffset))
        } else {
            progress = 0
        }

        let visibleAlpha = headerContentAlpha(for: progress)
        containerView.subviews.forEach { subview in
            if subview === buyticketView || subview === venueView {
                return
            }

            if pageVC.isViewLoaded, subview === pageVC.view {
                return
            }

            subview.alpha = visibleAlpha
        }
        updateBuyTicketHeaderAlpha(visibleAlpha)
        updateNavTitleAlpha(navTitleAlpha(for: progress))

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

    func updateBuyTicketHeaderAlpha(_ alpha: CGFloat) {
        buyticketView.subviews.forEach { subview in
            if let stackView = subview as? UIStackView {
                stackView.arrangedSubviews.forEach { arrangedSubview in
                    guard arrangedSubview !== tabView else { return }
                    arrangedSubview.alpha = alpha
                }
            } else if subview !== tabView {
                subview.alpha = alpha
            }
        }
    }

    func updateNavTitleAlpha(_ alpha: CGFloat) {
        navTitleStackView.alpha = alpha
        view.bringSubviewToFront(navTitleStackView)
    }

    func headerContentAlpha(for progress: CGFloat) -> CGFloat {
        return 1 - smoothProgress(
            progress,
            start: headerFadeStartProgress,
            end: headerFadeEndProgress
        )
    }

    func navTitleAlpha(for progress: CGFloat) -> CGFloat {
        return smoothProgress(
            progress,
            start: navTitleFadeStartProgress,
            end: navTitleFadeEndProgress
        )
    }

    func smoothProgress(_ value: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return value >= end ? 1 : 0 }

        let normalized = min(1, max(0, (value - start) / (end - start)))
        return normalized * normalized * (3 - 2 * normalized)
    }

    func resetTrackedOffset(for viewController: UIViewController) {
        guard let scrollView = observedScrollView(for: viewController) else { return }
        let scrollID = ObjectIdentifier(scrollView)
        childScrollOffsets[scrollID] = scrollView.contentOffset.y
        childPanTranslations.removeValue(forKey: scrollID)
        registerPanHandlerIfNeeded(for: scrollView, scrollID: scrollID)
    }

    func observedScrollView(for viewController: UIViewController) -> UIScrollView? {
        guard viewController.isViewLoaded else { return nil }

        if let eventsVC = viewController as? VenueEventsVC {
            return eventsVC.collectionView
        }

        if let experiencesVC = viewController as? VenueExperiencesVC {
            return experiencesVC.collectionView
        }

        if let artistsVC = viewController as? ArtistsVC {
            return artistsVC.tableView
        }

        return nil
    }
}

// MARK: - ChildScrollDelegate
extension VenueVC: ChildScrollDelegate {

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

        let targetOffset = shouldCollapse ? maxHeaderCollapseOffset : 0
        headerCollapseOffset = targetOffset
        set(scrollView, contentOffsetY: topContentOffsetY(for: scrollView), scrollID: scrollID)
        applyHeaderCollapse(animated: true)
    }

    func registerPanHandlerIfNeeded(for scrollView: UIScrollView, scrollID: ObjectIdentifier) {
        guard !registeredPanScrollIDs.contains(scrollID) else { return }

        registeredPanScrollIDs.insert(scrollID)
        scrollView.panGestureRecognizer.addTarget(
            self,
            action: #selector(handleChildPan(_:))
        )
    }

    @objc func handleChildPan(_ gesture: UIPanGestureRecognizer) {
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

        guard headerCollapseOffset > 0 else {
            childPanTranslations[scrollID] = currentTranslationY
            return
        }

        let topOffsetY = topContentOffsetY(for: scrollView)

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
extension VenueVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index > 0
        else {
            return nil
        }

        return tabControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = tabControllers.firstIndex(of: viewController),
              index < tabControllers.count - 1
        else {
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
              let index = tabControllers.firstIndex(of: currentVC)
        else {
            return
        }

        selectedIndex = index
        glassSegment.setSelectedIndex(index, animated: true)
        resetTrackedOffset(for: currentVC)
    }
}

// MARK: - VenueShimmerView

final class VenueShimmerView: UIView {

    private var shimmerViews: [ShimmerViewV3] = []
    private var didBuildLayout = false
    private var lastLayoutSize: CGSize = .zero
    private var shouldAnimate = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            return
        }

        didBuildLayout = false
        setNeedsLayout()

        if shouldAnimate {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard window != nil else {
            return
        }

        guard bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        let widthChanged =
            abs(bounds.width - lastLayoutSize.width) > 0.5

        guard !didBuildLayout ||
              widthChanged else {
            return
        }

        didBuildLayout = true
        lastLayoutSize = bounds.size
        rebuildLayout()
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    private func rebuildLayout() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        shimmerViews.forEach {
            $0.stopShimmer()
            $0.removeFromSuperview()
        }

        shimmerViews.removeAll()

        let width = bounds.width
        let pad: CGFloat = 16
        let safeTop = safeAreaInsets.top
        let heroHeight = min(
            max(bounds.height * 0.34, 250),
            320
        )

        makeShimmer(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: heroHeight
            ),
            corner: 0
        )

        let navButtonSize: CGFloat = 40

        makeShimmer(
            CGRect(
                x: pad,
                y: safeTop + 12,
                width: navButtonSize,
                height: navButtonSize
            ),
            corner: navButtonSize / 2
        )

        makeShimmer(
            CGRect(
                x: width - pad - navButtonSize,
                y: safeTop + 12,
                width: navButtonSize,
                height: navButtonSize
            ),
            corner: navButtonSize / 2
        )

        let logoSize: CGFloat = 74

        makeShimmer(
            CGRect(
                x: (width - logoSize) / 2,
                y: heroHeight - 102,
                width: logoSize,
                height: logoSize
            ),
            corner: logoSize / 2
        )

        makeShimmer(
            CGRect(
                x: (width - 164) / 2,
                y: heroHeight - 16,
                width: 164,
                height: 26
            ),
            corner: 13
        )

        var y = heroHeight + 34

        makeShimmer(
            CGRect(
                x: pad,
                y: y,
                width: width - pad * 2,
                height: 54
            ),
            corner: 16
        )

        y += 74

        makeShimmer(
            CGRect(
                x: pad,
                y: y,
                width: width - pad * 2,
                height: 44
            ),
            corner: 22
        )

        y += 76

        for _ in 0..<4 {
            makeVenueRow(y: y, width: width, pad: pad)
            y += 100
        }

        CATransaction.commit()

        if shouldAnimate {
            shimmerViews.forEach {
                $0.startShimmer()
            }
        }
    }

    private func makeVenueRow(
        y: CGFloat,
        width: CGFloat,
        pad: CGFloat
    ) {

        let imageSize: CGFloat = 82

        makeShimmer(
            CGRect(
                x: pad,
                y: y,
                width: imageSize,
                height: imageSize
            ),
            corner: 12
        )

        let textX = pad + imageSize + 14
        let textWidth = width - textX - pad

        makeShimmer(
            CGRect(
                x: textX,
                y: y + 8,
                width: textWidth,
                height: 16
            ),
            corner: 8
        )

        makeShimmer(
            CGRect(
                x: textX,
                y: y + 34,
                width: textWidth * 0.72,
                height: 13
            ),
            corner: 7
        )

        makeShimmer(
            CGRect(
                x: textX,
                y: y + 58,
                width: textWidth * 0.52,
                height: 13
            ),
            corner: 7
        )
    }

    private func makeShimmer(
        _ frame: CGRect,
        corner: CGFloat = 8
    ) {

        let view = ShimmerViewV3(
            frame: frame.integral
        )

        view.layer.cornerRadius = corner
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        addSubview(view)
        shimmerViews.append(view)
    }

    func start() {
        shouldAnimate = true
        isHidden = false
        setNeedsLayout()
        layoutIfNeeded()

        shimmerViews.forEach {
            $0.startShimmer()
        }
    }

    func stop() {
        shouldAnimate = false

        shimmerViews.forEach {
            $0.stopShimmer()
        }

        removeFromSuperview()
    }
}

// MARK: - GlassSegmentView

final class GlassSegmentView: UIControl {

    var onIndexChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let glassBackground = LiquidGlassBackgroundView()
    private let selectedView = LiquidGlassBackgroundView()

    private var labels: [UILabel] = []
    private var selectedLeading: NSLayoutConstraint!
    private var selectedWidth: NSLayoutConstraint!
    private var titles: [String] = []

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        glassBackground.layer.cornerRadius = bounds.height / 2
        selectedView.layer.cornerRadius = selectedView.bounds.height / 2

        updateSelectedPosition(animated: false)
    }

    private func setupUI() {
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.isUserInteractionEnabled = false
        glassBackground.cornerRadius = 25
        insertSubview(glassBackground, at: 0)

        NSLayoutConstraint.activate([
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        selectedView.translatesAutoresizingMaskIntoConstraints = false
        selectedView.cornerRadius = 25
        selectedView.isUserInteractionEnabled = false
        addSubview(selectedView)

        setupLabels()
        setupConstraints()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }

    private func setupLabels() {
        for title in titles {
            let lbl = UILabel()
            lbl.text = title
            lbl.textAlignment = .center
            lbl.font = Constant.Font.geistMedium(size: 14)
            lbl.textColor = .white
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.isUserInteractionEnabled = false
            addSubview(lbl)
            labels.append(lbl)
        }
    }

    private func setupConstraints() {
        guard !labels.isEmpty else { return }

        let count = CGFloat(labels.count)

        selectedLeading = selectedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        selectedWidth = selectedView.widthAnchor.constraint(
            equalTo: widthAnchor,
            multiplier: 1 / count,
            constant: -2
        )

        NSLayoutConstraint.activate([
            selectedLeading,
            selectedWidth,
            selectedView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            selectedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        for (i, lbl) in labels.enumerated() {
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: topAnchor),
                lbl.bottomAnchor.constraint(equalTo: bottomAnchor),
                lbl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / count)
            ])

            if i == 0 {
                lbl.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                lbl.leadingAnchor.constraint(equalTo: labels[i - 1].trailingAnchor).isActive = true
            }
        }

        updateLabelAlpha()
    }

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0, index < labels.count else { return }

        selectedIndex = index
        updateSelectedPosition(animated: animated)
        updateLabelAlpha()
    }

    private func updateSelectedPosition(animated: Bool) {
        guard bounds.width > 0, !labels.isEmpty else { return }

        let count = CGFloat(labels.count)
        let slot = bounds.width / count
        let isFirst = selectedIndex == 0
        let isLast = selectedIndex == labels.count - 1

        selectedLeading.constant = slot * CGFloat(selectedIndex) + 4
        selectedWidth.constant = isLast ? -8 : isFirst ? -2 : -2

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.48,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    private func updateLabelAlpha() {
        for (i, lbl) in labels.enumerated() {
            lbl.alpha = i == selectedIndex ? 1.0 : 0.45
        }
    }

    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0, !labels.isEmpty else { return }

        let x = gesture.location(in: self).x
        let index = Int(x / (bounds.width / CGFloat(labels.count)))
        let clamped = max(0, min(index, labels.count - 1))

        guard clamped != selectedIndex else { return }

        onIndexChanged?(clamped)
    }}
