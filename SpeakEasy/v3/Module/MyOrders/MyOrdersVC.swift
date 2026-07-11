//
//  MyOrdersVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/05/26.
//

import UIKit

final class MyOrdersVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let segmentView = OrdersSegmentView()
    private let pageVC = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var isLoggedIn: Bool {
        UserDefault.shared.user != nil
    }

    private let emptyStateView = UIView()

    private let emptyIconContainer = LiquidGlassBackgroundView(
        cornerRadius: 40,
        fillColor: AppColor.primaryWhiteColor.withAlphaComponent(0.08),
        borderColor: AppColor.primaryWhiteColor.withAlphaComponent(0.18),
        borderWidth: 0.8
    )

    private let emptyIcon = UIImageView()

    private let emptyTitle = UILabel()
    private let emptySubtitle = UILabel()

    private let signInButton = PrimaryButton()

    private let featuresStack = UIStackView()

    private lazy var ticketsVC = TicketsOrdersVC()
    private lazy var tablesVC = TablesOrdersVC()

    private let landingHeaderView = LandingHeaderView()
    private var segmentTopConstraint: NSLayoutConstraint!
    private var ordersRefreshObserver: NSObjectProtocol?
    
    var showsBackButtonHeader: Bool = false
    
    private var pages: [UIViewController] {
        [ticketsVC, tablesVC]
    }

    private var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeOrderRefreshRequests()
    }

    deinit {
        if let ordersRefreshObserver {
            NotificationCenter.default.removeObserver(ordersRefreshObserver)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupLandingHeader()
        setupNav()
        setupSegment()
        setupPageVC()
        setupEmptyState()
        setupConstraints()

        updateLoginState()
        updateHeaderUI()
    }
    
    private func updateHeaderUI() {

        landingHeaderView.isHidden = showsBackButtonHeader

        backBtn.isHidden = !showsBackButtonHeader
        titleLabel.isHidden = !showsBackButtonHeader
    }
    
    private func setupLandingHeader() {

        landingHeaderView.setMapHidden(false)
        landingHeaderView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(landingHeaderView)

        NSLayoutConstraint.activate([
            landingHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            landingHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            landingHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            landingHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupEmptyState() {

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        emptyIconContainer.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(emptyIconContainer)

        emptyIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyIcon.image = UIImage(systemName: "ticket.fill")
        emptyIcon.tintColor = .white
        emptyIcon.contentMode = .scaleAspectFit
        emptyIconContainer.addSubview(emptyIcon)

        emptyTitle.text = "Keep track of every booking"
        emptyTitle.textColor = .white
        emptyTitle.font = Constant.Font.geistMedium(size: 20)
        emptyTitle.textAlignment = .center
        emptyTitle.numberOfLines = 0
        emptyTitle.translatesAutoresizingMaskIntoConstraints = false

        emptySubtitle.text = """
        View upcoming tickets, table reservations,
        past orders, and booking details
        after signing in.
        """
        emptySubtitle.textColor = .white.withAlphaComponent(0.65)
        emptySubtitle.font = Constant.Font.geistRegular(size: 12)
        emptySubtitle.textAlignment = .center
        emptySubtitle.numberOfLines = 0
        emptySubtitle.translatesAutoresizingMaskIntoConstraints = false

        signInButton.configure(
            title: "Sign In to Continue",
            fontSize: 16,
            cornerRadius: 14
        )

        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.addTarget(self, action: #selector(onClickLogin), for: .touchUpInside)

        featuresStack.axis = .vertical
        featuresStack.spacing = 14
        featuresStack.translatesAutoresizingMaskIntoConstraints = false

        featuresStack.addArrangedSubview(
            featureRow(
                icon: "ticket.fill",
                title: "Upcoming ticket bookings"
            )
        )

        featuresStack.addArrangedSubview(
            featureRow(
                icon: "fork.knife",
                title: "Table reservations"
            )
        )

        featuresStack.addArrangedSubview(
            featureRow(
                icon: "clock.arrow.circlepath",
                title: "Past orders & booking history"
            )
        )

        emptyStateView.addSubview(emptyTitle)
        emptyStateView.addSubview(emptySubtitle)
        emptyStateView.addSubview(signInButton)
        emptyStateView.addSubview(featuresStack)

        NSLayoutConstraint.activate([

            emptyStateView.topAnchor.constraint(equalTo: segmentView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyIconContainer.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 70),
            emptyIconContainer.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIconContainer.widthAnchor.constraint(equalToConstant: 60),
            emptyIconContainer.heightAnchor.constraint(equalToConstant: 60),

            emptyIcon.centerXAnchor.constraint(equalTo: emptyIconContainer.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: emptyIconContainer.centerYAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 25),
            emptyIcon.heightAnchor.constraint(equalToConstant: 25),

            emptyTitle.topAnchor.constraint(equalTo: emptyIconContainer.bottomAnchor, constant: 28),
            emptyTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            emptySubtitle.topAnchor.constraint(equalTo: emptyTitle.bottomAnchor, constant: 14),
            emptySubtitle.leadingAnchor.constraint(equalTo: emptyTitle.leadingAnchor),
            emptySubtitle.trailingAnchor.constraint(equalTo: emptyTitle.trailingAnchor),

            signInButton.topAnchor.constraint(equalTo: emptySubtitle.bottomAnchor, constant: 24),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            signInButton.heightAnchor.constraint(equalToConstant: 44),

            featuresStack.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 24),
            featuresStack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor)
        ])
    }

    @objc private func onClickLogin() {
        LoginRequiredCoordinator.presentLogin(from: self) { [weak self] in
            self?.reloadAfterLogin()
        }
    }

    private func updateLoginState() {

        let loggedIn = isLoggedIn

        emptyStateView.isHidden = loggedIn

        segmentView.isHidden = !loggedIn
        pageVC.view.isHidden = !loggedIn

        if loggedIn {
            // ticketsVC.fetchOrders()
            // tablesVC.fetchOrders()
        }
    }

    private func reloadAfterLogin() {
        updateLoginState()
        ticketsVC.refreshOrders()
        tablesVC.refreshOrders()
    }

    private func observeOrderRefreshRequests() {
        ordersRefreshObserver = NotificationCenter.default.addObserver(
            forName: .ordersShouldRefresh,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleOrderRefreshRequest(notification)
        }
    }

    private func handleOrderRefreshRequest(_ notification: Notification) {
        guard isLoggedIn else { return }

        let rawKind = notification.userInfo?["kind"] as? String
        let kind = rawKind.flatMap(OrdersRefreshKind.init(rawValue:)) ?? .all

        switch kind {
        case .tickets:
            ticketsVC.refreshOrders()
        case .tables:
            tablesVC.refreshOrders()
        case .all:
            ticketsVC.refreshOrders()
            tablesVC.refreshOrders()
        }
    }

    private func featureRow(icon: String, title: String) -> UIView {

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = .white
        image.contentMode = .scaleAspectFit
        image.widthAnchor.constraint(equalToConstant: 18).isActive = true
        image.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let label = UILabel()
        label.text = title
        label.textColor = .white.withAlphaComponent(0.75)
        label.font = Constant.Font.geistRegular(size: 12)

        stack.addArrangedSubview(image)
        stack.addArrangedSubview(label)

        return stack
    }

    private func setupNav() {
        // Back button styling
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        // Title styling
        titleLabel.text = "My orders"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupSegment() {
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentView.onIndexChanged = { [weak self] index in
            self?.moveToPage(index)
        }
        view.addSubview(segmentView)
    }

    private func setupPageVC() {
        addChild(pageVC)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)

        pageVC.dataSource = self
        pageVC.delegate = self

        pageVC.setViewControllers(
            [ticketsVC],
            direction: .forward,
            animated: false
        )
    }

    private func setupConstraints() {
        let headerBottomAnchor = showsBackButtonHeader
            ? titleLabel.bottomAnchor
            : landingHeaderView.bottomAnchor
        let headerTopConstant = showsBackButtonHeader ? 20 : 10
        let headerRightConstant = showsBackButtonHeader ? 22 : 16
        
        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),

            segmentView.topAnchor.constraint(equalTo: headerBottomAnchor, constant: CGFloat(headerTopConstant)),
            segmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(headerRightConstant)),
            segmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat(headerRightConstant)),
            segmentView.heightAnchor.constraint(equalToConstant: 48),

            pageVC.view.topAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 10),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func moveToPage(_ index: Int) {
        guard index != selectedIndex else { return }

        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        selectedIndex = index

        pageVC.setViewControllers(
            [pages[index]],
            direction: direction,
            animated: true
        )

        segmentView.setSelectedIndex(index, animated: true)
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Page Controller

extension MyOrdersVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: currentVC)
        else { return }

        selectedIndex = index
        segmentView.setSelectedIndex(index, animated: true)
    }
}
